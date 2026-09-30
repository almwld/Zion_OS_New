package com.zion.os

import android.Manifest
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.content.pm.PackageManager
import android.net.ConnectivityManager
import android.net.LinkProperties
import android.net.NetworkCapabilities
import android.net.wifi.WifiManager
import android.os.BatteryManager
import android.os.Handler
import android.os.Looper
import android.os.StatFs
import android.net.TrafficStats
import android.net.wifi.WifiInfo
import android.content.ClipData
import android.content.ClipboardManager
import android.location.LocationManager
import android.hardware.Sensor
import android.hardware.SensorManager
import android.os.VibrationEffect
import android.os.Vibrator
import android.speech.tts.TextToSpeech
import android.telephony.SmsManager
import android.widget.Toast
import android.app.AlertDialog
import android.app.NotificationChannel
import android.app.NotificationManager
import androidx.core.app.NotificationCompat
import androidx.biometric.BiometricManager
import androidx.biometric.BiometricPrompt
import androidx.core.content.ContextCompat
import android.provider.Settings
import android.provider.DocumentsContract
import android.net.Uri
import java.util.Locale
import androidx.core.app.ActivityCompat
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.EventChannel
import java.util.concurrent.ConcurrentHashMap
import java.util.concurrent.Executors
import java.io.File
import java.io.FileOutputStream

class MainActivity : FlutterFragmentActivity() {
    private external fun nativePtyAvailable(): Boolean
    private external fun nativeStartPty(rows: Int, cols: Int, shell: String?): Int
    private external fun nativeReadPty(handle: Int): ByteArray?
    private external fun nativeWritePty(handle: Int, data: ByteArray): Int
    private external fun nativeResizePty(handle: Int, rows: Int, cols: Int): Boolean
    private external fun nativeStopPty(handle: Int)

    private val terminalReaders = ConcurrentHashMap<Int, Thread>()
    private var terminalSink: EventChannel.EventSink? = null
    private var radarSink: EventChannel.EventSink? = null
    @Volatile private var radarRunning = false
    private var radarThread: Thread? = null
    private var radarNetworkCallback: ConnectivityManager.NetworkCallback? = null
    private var wakeLock: android.os.PowerManager.WakeLock? = null
    private lateinit var zionApiChannel: ZionApiChannel
    private lateinit var zionPkgChannel: MethodChannel
    private var pendingTreeResult: MethodChannel.Result? = null
    private var pendingModelResult: MethodChannel.Result? = null
    private val aiExecutor = Executors.newSingleThreadExecutor { r -> Thread(r, "zion-ai").apply { isDaemon = true } }
    private val llamaBridge by lazy { com.zion.os.ai.LlamaBridge() }

    companion object {
        init { System.loadLibrary("zionpty") }
        private const val PLATFORM_CHANNEL = "zion.os/platform"
        private const val WIFI_CHANNEL = "zion.os/wifi"
        private const val PTY_CHANNEL = "zion.os/pty"
        private const val PTY_EVENTS = "zion.os/pty/events"
        private const val RADAR_EVENTS = "zion.os/network/radar"
        private const val ZION_PKG_ACTION = "com.zion.os.ZION_PKG"
        private const val ZION_PKG_CHANNEL = "zion.os/pkg-external"
        private const val STORAGE_CHANNEL = "zion.os/storage"
        private const val REQUEST_OPEN_TREE = 4101
        private const val AI_CHANNEL = "zion.os/ai"
        private const val REQUEST_OPEN_MODEL = 4102
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        zionApiChannel = ZionApiChannel(this, flutterEngine.dartExecutor.binaryMessenger).also { it.register() }
        zionPkgChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, ZION_PKG_CHANNEL)
        handleZionApiIntent(intent)
        Handler(Looper.getMainLooper()).postDelayed({ handleZionPkgIntent(intent) }, 500L)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, WIFI_CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "scan" -> scanWifiTelemetryAsync(result)
                    "connection" -> result.success(readCurrentWifiConnection())
                    else -> result.notImplemented()
                }
            }


        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, AI_CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "discoverModels" -> result.success(discoverGgufModels())
                    "pickModel" -> {
                        if (pendingModelResult != null) {
                            result.error("BUSY", "A model picker is already open.", null)
                            return@setMethodCallHandler
                        }
                        pendingModelResult = result
                        val intent = Intent(Intent.ACTION_OPEN_DOCUMENT).apply {
                            type = "application/octet-stream"
                            addCategory(Intent.CATEGORY_OPENABLE)
                            addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION or Intent.FLAG_GRANT_PERSISTABLE_URI_PERMISSION)
                        }
                        try { startActivityForResult(intent, REQUEST_OPEN_MODEL) }
                        catch (t: Throwable) {
                            pendingModelResult = null
                            result.success(mapOf("available" to false, "status" to "UNAVAILABLE", "reason" to (t.message ?: "Model picker unavailable.")))
                        }
                    }
                    "loadModel" -> {
                        val path = call.argument<String>("path") ?: ""
                        val threads = call.argument<Int>("threads") ?: 4
                        val loraPath = call.argument<String>("loraPath")
                        val loraScale = (call.argument<Double>("loraScale") ?: 1.0).toFloat()
                        aiExecutor.execute {
                            val ok = try {
                                llamaBridge.nativeLoadModel(path, threads, loraPath, loraScale)
                            } catch (_: Throwable) { false }
                            runOnUiThread { result.success(ok) }
                        }
                    }
                    "generate" -> {
                        val prompt = call.argument<String>("prompt") ?: ""
                        val maxTokens = call.argument<Int>("maxTokens") ?: 512
                        val temperature = (call.argument<Double>("temperature") ?: 0.7).toFloat()
                        aiExecutor.execute {
                            val response = try { llamaBridge.nativeGenerate(prompt, maxTokens, temperature) } catch (t: Throwable) { "ERROR: ${t.message ?: "native inference failed"}" }
                            runOnUiThread { result.success(response) }
                        }
                    }
                    "freeModel" -> {
                        aiExecutor.execute {
                            try { llamaBridge.nativeFreeModel() } catch (_: Throwable) {}
                            runOnUiThread { result.success(null) }
                        }
                    }
                    "isLoaded" -> result.success(try { llamaBridge.nativeIsLoaded() } catch (_: Throwable) { false })
                    "version" -> result.success(try { llamaBridge.nativeVersion() } catch (_: Throwable) { "unavailable" })
                    else -> result.notImplemented()
                }
            }

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, STORAGE_CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "pickTree" -> {
                        if (pendingTreeResult != null) {
                            result.error("BUSY", "A storage picker is already open.", null)
                            return@setMethodCallHandler
                        }
                        pendingTreeResult = result
                        val intent = Intent(Intent.ACTION_OPEN_DOCUMENT_TREE).apply {
                            addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION or Intent.FLAG_GRANT_WRITE_URI_PERMISSION or Intent.FLAG_GRANT_PERSISTABLE_URI_PERMISSION or Intent.FLAG_GRANT_PREFIX_URI_PERMISSION)
                        }
                        try { startActivityForResult(intent, REQUEST_OPEN_TREE) }
                        catch (t: Throwable) { pendingTreeResult = null; result.success(mapOf("available" to false, "status" to "UNAVAILABLE", "reason" to (t.message ?: "Storage picker unavailable."))) }
                    }
                    "listTree" -> result.success(listTree(call.argument<String>("uri") ?: ""))
                    "delete" -> result.success(deleteTreeDocument(call.argument<String>("uri") ?: ""))
                    "createDirectory" -> result.success(createTreeDirectory(call.argument<String>("parentUri") ?: "", call.argument<String>("name") ?: ""))
                    else -> result.notImplemented()
                }
            }

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, PLATFORM_CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "batteryInfo" -> result.success(readBatteryInfo())
                    "networkInfo" -> result.success(readNetworkInfo())
                    "storageInfo" -> result.success(readStorageInfo())
                    "wifiScan" -> scanWifiAsync(result)
                    else -> result.notImplemented()
                }
            }

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, PTY_CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "available" -> result.success(nativePtyAvailable())
                    "start" -> {
                        val rows = call.argument<Int>("rows") ?: 24
                        val cols = call.argument<Int>("cols") ?: 80
                        val shell = call.argument<String>("shell")
                        result.success(startTerminal(rows, cols, shell))
                    }
                    "write" -> {
                        val handle = call.argument<Int>("handle") ?: 0
                        val input = call.argument<String>("input") ?: ""
                        result.success(writeTerminal(handle, input))
                    }
                    "resize" -> {
                        val handle = call.argument<Int>("handle") ?: 0
                        val rows = call.argument<Int>("rows") ?: 24
                        val cols = call.argument<Int>("cols") ?: 80
                        result.success(resizeTerminal(handle, rows, cols))
                    }
                    "stop" -> {
                        val handle = call.argument<Int>("handle") ?: 0
                        stopTerminal(handle)
                        result.success(null)
                    }
                    else -> result.notImplemented()
                }
            }

        EventChannel(flutterEngine.dartExecutor.binaryMessenger, PTY_EVENTS)
            .setStreamHandler(object : EventChannel.StreamHandler {
                override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                    terminalSink = events
                }
                override fun onCancel(arguments: Any?) {
                    terminalSink = null
                }
            })

        EventChannel(flutterEngine.dartExecutor.binaryMessenger, RADAR_EVENTS)
            .setStreamHandler(object : EventChannel.StreamHandler {
                override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                    radarSink = events
                    startNetworkRadar()
                }
                override fun onCancel(arguments: Any?) {
                    radarSink = null
                    stopNetworkRadar()
                }
            })
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        if (::zionApiChannel.isInitialized) handleZionApiIntent(intent)
        if (::zionPkgChannel.isInitialized) handleZionPkgIntent(intent)
    }

    private fun handleZionApiIntent(intent: Intent) {
        if (intent.action == "com.zion.os.ZION_API" && ::zionApiChannel.isInitialized) {
            zionApiChannel.handleExternalIntent(intent)
        }
    }

    private fun handleZionPkgIntent(intent: Intent) {
        if (intent.action != ZION_PKG_ACTION || !::zionPkgChannel.isInitialized) return
        val token = intent.getStringExtra("token") ?: return
        val expected = try {
            java.io.File(applicationInfo.dataDir + "/files/etc/zion-pkg.token").readText().trim()
        } catch (_: Throwable) {
            return
        }
        if (token.isEmpty() || !java.security.MessageDigest.isEqual(token.toByteArray(), expected.toByteArray())) return
        val requestId = intent.getStringExtra("requestId") ?: return
        if (!requestId.matches(Regex("^[A-Za-z0-9_-]{1,80}$"))) return
        val command = intent.getStringExtra("command") ?: "help"
        val value = intent.getStringExtra("value") ?: ""
        Handler(Looper.getMainLooper()).post {
            zionPkgChannel.invokeMethod(
                "execute",
                mapOf("requestId" to requestId, "command" to command, "value" to value)
            )
        }
    }

    private fun startTerminal(rows: Int, cols: Int, shell: String?): Int {
        if (!nativePtyAvailable()) return 0
        return try {
            val handle = nativeStartPty(rows, cols, shell)
            if (handle <= 0) return 0
            terminalReaders[handle] = Thread {
                try {
                    while (!Thread.currentThread().isInterrupted) {
                        val data = nativeReadPty(handle) ?: break
                        if (data.isEmpty()) {
                            try { Thread.sleep(8) } catch (_: InterruptedException) { break }
                            continue
                        }
                        terminalSink?.success(
                            mapOf(
                                "sessionId" to handle,
                                "data" to String(data, Charsets.UTF_8),
                            )
                        )
                    }
                } catch (t: Throwable) {
                    terminalSink?.error("PTY_STREAM", t.message, mapOf("sessionId" to handle))
                } finally {
                    terminalSink?.success(mapOf("sessionId" to handle, "closed" to true))
                    terminalReaders.remove(handle)
                }
            }.apply {
                name = "zion-native-pty-$handle"
                isDaemon = true
                start()
            }
            handle
        } catch (_: Throwable) {
            0
        }
    }

    private fun writeTerminal(handle: Int, input: String): Boolean {
        if (handle <= 0) return false
        return try {
            val data = input.toByteArray(Charsets.UTF_8)
            nativeWritePty(handle, data) == data.size
        } catch (_: Throwable) {
            false
        }
    }

    private fun resizeTerminal(handle: Int, rows: Int, cols: Int): Boolean {
        if (handle <= 0) return false
        return try { nativeResizePty(handle, rows, cols) } catch (_: Throwable) { false }
    }

    private fun stopTerminal(handle: Int) {
        if (handle <= 0) return
        try { nativeStopPty(handle) } catch (_: Throwable) {}
        terminalReaders.remove(handle)?.interrupt()
    }

    private fun stopAllTerminals() {
        terminalReaders.keys.toList().forEach(::stopTerminal)
        terminalReaders.clear()
    }

    private fun startNetworkRadar() {
        registerNetworkRadarCallback()
        if (radarRunning) return
        radarRunning = true
        radarThread = Thread {
            var lastRx = TrafficStats.getTotalRxBytes()
            var lastTx = TrafficStats.getTotalTxBytes()
            var lastRxPackets = TrafficStats.getTotalRxPackets()
            var lastTxPackets = TrafficStats.getTotalTxPackets()
            var lastTime = System.nanoTime()
            while (radarRunning) {
                val now = System.nanoTime()
                val elapsed = ((now - lastTime).coerceAtLeast(1L)) / 1_000_000_000.0
                val rx = TrafficStats.getTotalRxBytes()
                val tx = TrafficStats.getTotalTxBytes()
                val rxPackets = TrafficStats.getTotalRxPackets()
                val txPackets = TrafficStats.getTotalTxPackets()
                radarSink?.success(readNetworkRadar(
                    rx, tx, rxPackets, txPackets,
                    ((rx - lastRx).coerceAtLeast(0L) / elapsed).toLong(),
                    ((tx - lastTx).coerceAtLeast(0L) / elapsed).toLong(),
                    ((rxPackets - lastRxPackets).coerceAtLeast(0L) / elapsed).toLong(),
                    ((txPackets - lastTxPackets).coerceAtLeast(0L) / elapsed).toLong()
                ))
                lastRx = rx
                lastTx = tx
                lastRxPackets = rxPackets
                lastTxPackets = txPackets
                lastTime = now
                try { Thread.sleep(750) } catch (_: InterruptedException) { break }
            }
        }.apply { name = "zion-network-radar"; isDaemon = true; start() }
    }

    private fun registerNetworkRadarCallback() {
        if (radarNetworkCallback != null) return
        val connectivity = getSystemService(Context.CONNECTIVITY_SERVICE) as ConnectivityManager
        radarNetworkCallback = object : ConnectivityManager.NetworkCallback() {
            override fun onAvailable(network: android.net.Network) { emitRadarEvent("networkEvent", "available") }
            override fun onLost(network: android.net.Network) { emitRadarEvent("networkEvent", "lost") }
            override fun onCapabilitiesChanged(network: android.net.Network, capabilities: NetworkCapabilities) { emitRadarEvent("networkEvent", "capabilitiesChanged") }
            override fun onLinkPropertiesChanged(network: android.net.Network, properties: LinkProperties) { emitRadarEvent("networkEvent", "linkPropertiesChanged") }
        }
        try { connectivity.registerDefaultNetworkCallback(radarNetworkCallback!!) } catch (_: Throwable) { radarNetworkCallback = null }
    }

    private fun emitRadarEvent(key: String, value: String) {
        radarSink?.success(mapOf("timestampMs" to System.currentTimeMillis(), key to value, "event" to true))
    }

    private fun stopNetworkRadar() {
        radarRunning = false
        radarThread?.interrupt()
        radarThread = null
        radarNetworkCallback?.let { callback ->
            try { (getSystemService(Context.CONNECTIVITY_SERVICE) as ConnectivityManager).unregisterNetworkCallback(callback) } catch (_: Throwable) {}
        }
        radarNetworkCallback = null
    }

    private fun readNetworkRadar(rxBytes: Long, txBytes: Long, rxPackets: Long, txPackets: Long, rxRate: Long, txRate: Long, rxPacketRate: Long, txPacketRate: Long): Map<String, Any?> {
        val connectivity = getSystemService(Context.CONNECTIVITY_SERVICE) as ConnectivityManager
        val network = connectivity.activeNetwork
        val caps = network?.let { connectivity.getNetworkCapabilities(it) }
        val links = network?.let { connectivity.getLinkProperties(it) }
        val wifi = applicationContext.getSystemService(Context.WIFI_SERVICE) as? WifiManager
        val wifiInfo: WifiInfo? = try { wifi?.connectionInfo } catch (_: SecurityException) { null }
        val transport = when {
            caps?.hasTransport(NetworkCapabilities.TRANSPORT_WIFI) == true -> "wifi"
            caps?.hasTransport(NetworkCapabilities.TRANSPORT_CELLULAR) == true -> "cellular"
            caps?.hasTransport(NetworkCapabilities.TRANSPORT_ETHERNET) == true -> "ethernet"
            caps?.hasTransport(NetworkCapabilities.TRANSPORT_VPN) == true -> "vpn"
            else -> "none"
        }
        val address = links?.linkAddresses?.firstOrNull { !it.address.isLoopbackAddress }?.address?.hostAddress
        return mapOf(
            "timestampMs" to System.currentTimeMillis(),
            "connected" to (caps?.hasCapability(NetworkCapabilities.NET_CAPABILITY_INTERNET) == true),
            "validated" to (caps?.hasCapability(NetworkCapabilities.NET_CAPABILITY_VALIDATED) == true),
            "metered" to !(caps?.hasCapability(NetworkCapabilities.NET_CAPABILITY_NOT_METERED) ?: false),
            "vpn" to (caps?.hasTransport(NetworkCapabilities.TRANSPORT_VPN) == true),
            "transport" to transport,
            "interface" to (links?.interfaceName ?: "unknown"),
            "ipAddress" to address,
            "dns" to (links?.dnsServers?.mapNotNull { it.hostAddress } ?: emptyList<String>()),
            "routes" to (links?.routes?.size ?: 0),
            "downstreamKbps" to (caps?.linkDownstreamBandwidthKbps ?: 0),
            "upstreamKbps" to (caps?.linkUpstreamBandwidthKbps ?: 0),
            "wifiRssi" to if (transport == "wifi") wifiInfo?.rssi else null,
            "wifiLinkSpeedMbps" to if (transport == "wifi") wifiInfo?.linkSpeed else null,
            "rxBytes" to rxBytes,
            "txBytes" to txBytes,
            "rxPackets" to rxPackets,
            "txPackets" to txPackets,
            "rxBytesPerSec" to rxRate,
            "txBytesPerSec" to txRate,
            "rxPacketsPerSec" to rxPacketRate,
            "txPacketsPerSec" to txPacketRate,
        )
    }


    private fun setupStorageApi(): Map<String, Any?> {
        val shared = android.os.Environment.getExternalStorageDirectory()
        return if (shared.exists()) mapOf(
            "available" to true,
            "status" to "AVAILABLE",
            "path" to shared.absolutePath,
            "reason" to "Android shared storage is present. Scoped Storage/SAF remains authoritative for app access."
        ) else mapOf(
            "available" to false,
            "status" to "UNAVAILABLE",
            "reason" to "Android shared storage is not available."
        )
    }

    private fun openCameraApi(): Map<String, Any?> {
        return try {
            val intent = Intent(android.provider.MediaStore.ACTION_IMAGE_CAPTURE)
            if (intent.resolveActivity(packageManager) == null) return mapOf(
                "available" to false, "status" to "UNAVAILABLE",
                "reason" to "No camera application is available."
            )
            startActivity(intent)
            mapOf("available" to true, "status" to "AVAILABLE")
        } catch (t: Throwable) {
            mapOf("available" to false, "status" to "UNAVAILABLE", "reason" to (t.message ?: "Unable to open camera."))
        }
    }

    private fun clipboardGetApi(): Map<String, Any?> {
        val manager = getSystemService(Context.CLIPBOARD_SERVICE) as ClipboardManager
        val value = if (manager.hasPrimaryClip()) manager.primaryClip?.getItemAt(0)?.coerceToText(this)?.toString() else null
        return mapOf("available" to true, "status" to "AVAILABLE", "text" to value)
    }

    private fun clipboardSetApi(text: String): Map<String, Any?> {
        val manager = getSystemService(Context.CLIPBOARD_SERVICE) as ClipboardManager
        manager.setPrimaryClip(ClipData.newPlainText("Zion OS", text))
        return mapOf("available" to true, "status" to "AVAILABLE")
    }

    private fun showDialogApi(title: String, message: String, positive: String, negative: String, result: MethodChannel.Result) {
        runOnUiThread {
            AlertDialog.Builder(this)
                .setTitle(title).setMessage(message)
                .setPositiveButton(positive) { _, _ -> result.success(mapOf("available" to true, "status" to "AVAILABLE", "action" to "positive")) }
                .setNegativeButton(negative) { _, _ -> result.success(mapOf("available" to true, "status" to "AVAILABLE", "action" to "negative")) }
                .setOnCancelListener { result.success(mapOf("available" to true, "status" to "AVAILABLE", "action" to "cancel")) }
                .show()
        }
    }

    private fun fingerprintApi(result: MethodChannel.Result) {
        val manager = BiometricManager.from(this)
        if (manager.canAuthenticate(BiometricManager.Authenticators.BIOMETRIC_STRONG or BiometricManager.Authenticators.BIOMETRIC_WEAK) != BiometricManager.BIOMETRIC_SUCCESS) {
            result.success(mapOf("available" to false, "status" to "UNAVAILABLE", "reason" to "Biometric authentication is unavailable or not enrolled."))
            return
        }
        val executor = ContextCompat.getMainExecutor(this)
        val prompt = BiometricPrompt(this as androidx.fragment.app.FragmentActivity, executor, object : BiometricPrompt.AuthenticationCallback() {
            override fun onAuthenticationSucceeded(res: BiometricPrompt.AuthenticationResult) =
                result.success(mapOf("available" to true, "status" to "AVAILABLE", "authenticated" to true))
            override fun onAuthenticationError(code: Int, err: CharSequence) =
                result.success(mapOf("available" to true, "status" to "UNAVAILABLE", "authenticated" to false, "reason" to err.toString()))
            override fun onAuthenticationFailed() {}
        })
        prompt.authenticate(
            BiometricPrompt.PromptInfo.Builder()
                .setTitle("Zion OS")
                .setSubtitle("Authenticate to continue")
                .setNegativeButtonText("Cancel")
                .build()
        )
    }

    private fun locationApi(): Map<String, Any?> {
        if (ActivityCompat.checkSelfPermission(this, Manifest.permission.ACCESS_FINE_LOCATION) != PackageManager.PERMISSION_GRANTED &&
            ActivityCompat.checkSelfPermission(this, Manifest.permission.ACCESS_COARSE_LOCATION) != PackageManager.PERMISSION_GRANTED) {
            return mapOf("available" to false, "status" to "PERMISSION_REQUIRED", "reason" to "Location permission is required.")
        }
        val manager = getSystemService(Context.LOCATION_SERVICE) as LocationManager
        val provider = when {
            manager.isProviderEnabled(LocationManager.GPS_PROVIDER) -> LocationManager.GPS_PROVIDER
            manager.isProviderEnabled(LocationManager.NETWORK_PROVIDER) -> LocationManager.NETWORK_PROVIDER
            else -> null
        } ?: return mapOf("available" to false, "status" to "UNAVAILABLE", "reason" to "No location provider is enabled.")
        val location = try { manager.getLastKnownLocation(provider) } catch (_: SecurityException) { null }
            ?: return mapOf("available" to false, "status" to "UNAVAILABLE", "reason" to "No cached location is available.")
        return mapOf("available" to true, "status" to "AVAILABLE", "latitude" to location.latitude, "longitude" to location.longitude, "accuracyM" to location.accuracy, "provider" to provider)
    }

    private fun notificationApi(title: String, content: String, channelId: String): Map<String, Any?> {
        if (android.os.Build.VERSION.SDK_INT >= 33 && ActivityCompat.checkSelfPermission(this, Manifest.permission.POST_NOTIFICATIONS) != PackageManager.PERMISSION_GRANTED) {
            return mapOf("available" to false, "status" to "PERMISSION_REQUIRED", "reason" to "POST_NOTIFICATIONS permission is required.")
        }
        val manager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        if (android.os.Build.VERSION.SDK_INT >= 26) {
            manager.createNotificationChannel(NotificationChannel(channelId, "Zion OS", NotificationManager.IMPORTANCE_DEFAULT))
        }
        manager.notify((System.currentTimeMillis() and 0x7fffffff).toInt(),
            NotificationCompat.Builder(this, channelId)
                .setSmallIcon(applicationInfo.icon).setContentTitle(title).setContentText(content)
                .setAutoCancel(true).build())
        return mapOf("available" to true, "status" to "AVAILABLE")
    }

    private fun sensorApi(type: Int): Map<String, Any?> {
        val manager = getSystemService(Context.SENSOR_SERVICE) as SensorManager
        val sensor = manager.getDefaultSensor(type)
            ?: return mapOf("available" to false, "status" to "UNAVAILABLE", "reason" to "Requested sensor is not present.", "sensorType" to type)
        return mapOf("available" to true, "status" to "AVAILABLE", "sensorType" to sensor.type, "name" to sensor.name, "vendor" to sensor.vendor, "minDelayUs" to sensor.minDelay)
    }

    private fun smsApi(number: String, body: String?): Map<String, Any?> {
        if (number.isBlank()) return mapOf("available" to false, "status" to "UNAVAILABLE", "reason" to "A destination number is required.")
        return try {
            val intent = Intent(Intent.ACTION_SENDTO).apply {
                data = android.net.Uri.parse("smsto:" + android.net.Uri.encode(number))
                if (body != null) putExtra("sms_body", body)
            }
            if (intent.resolveActivity(packageManager) == null) mapOf("available" to false, "status" to "UNAVAILABLE", "reason" to "No SMS application is available.")
            else { startActivity(intent); mapOf("available" to true, "status" to "AVAILABLE") }
        } catch (t: Throwable) { mapOf("available" to false, "status" to "UNAVAILABLE", "reason" to (t.message ?: "Unable to open SMS composer.")) }
    }

    private fun toastApi(text: String): Map<String, Any?> {
        runOnUiThread { Toast.makeText(this, text, Toast.LENGTH_SHORT).show() }
        return mapOf("available" to true, "status" to "AVAILABLE")
    }

    private var ttsEngine: TextToSpeech? = null

    private fun ttsApi(text: String): Map<String, Any?> {
        if (text.isBlank()) return mapOf("available" to false, "status" to "UNAVAILABLE", "reason" to "Text is empty.")
        try {
            if (ttsEngine == null) {
                ttsEngine = TextToSpeech(this) { status ->
                    if (status == TextToSpeech.SUCCESS) {
                        ttsEngine?.language = Locale.getDefault()
                    }
                }
            }
            ttsEngine?.speak(text, TextToSpeech.QUEUE_FLUSH, null, "zion-" + System.currentTimeMillis())
            return mapOf("available" to true, "status" to "AVAILABLE", "queued" to true)
        } catch (t: Throwable) {
            return mapOf("available" to false, "status" to "UNAVAILABLE", "reason" to (t.message ?: "Text-to-speech is unavailable."))
        }
    }

    private fun vibrateApi(durationMs: Int): Map<String, Any?> {
        val vibrator = getSystemService(Context.VIBRATOR_SERVICE) as Vibrator
        if (!vibrator.hasVibrator()) return mapOf("available" to false, "status" to "UNAVAILABLE", "reason" to "Vibrator is not available.")
        if (android.os.Build.VERSION.SDK_INT >= 26) vibrator.vibrate(VibrationEffect.createOneShot(durationMs.coerceIn(1, 10000).toLong(), VibrationEffect.DEFAULT_AMPLITUDE))
        else @Suppress("DEPRECATION") vibrator.vibrate(durationMs.coerceIn(1, 10000).toLong())
        return mapOf("available" to true, "status" to "AVAILABLE")
    }

    private fun wakeLockApi(enabled: Boolean): Map<String, Any?> {
        val power = getSystemService(Context.POWER_SERVICE) as android.os.PowerManager
        if (enabled) {
            if (wakeLock?.isHeld != true) wakeLock = power.newWakeLock(android.os.PowerManager.PARTIAL_WAKE_LOCK, "ZionOS:Terminal").apply { setReferenceCounted(false); acquire() }
        } else {
            wakeLock?.let { if (it.isHeld) it.release() }
            wakeLock = null
        }
        return mapOf("available" to true, "status" to "AVAILABLE", "enabled" to enabled)
    }



    private fun discoverGgufModels(): List<Map<String, Any?>> {
        val roots = linkedSetOf<File>()
        roots.add(File(filesDir, "models"))
        getExternalFilesDir(null)?.let { roots.add(File(it, "models")) }
        roots.add(File("/storage/emulated/0/Download"))
        roots.add(File("/storage/emulated/0/Models"))
        roots.add(File("/sdcard/Download"))
        val out = mutableListOf<Map<String, Any?>>()
        val seen = HashSet<String>()
        fun visit(dir: File, depth: Int) {
            if (depth > 3 || !dir.exists() || !dir.isDirectory) return
            val children = try { dir.listFiles() ?: return } catch (_: Throwable) { return }
            for (f in children) {
                if (f.isFile && f.name.lowercase().endsWith(".gguf") && seen.add(f.absolutePath)) {
                    val size = try { f.length() } catch (_: Throwable) { 0L }
                    out.add(mapOf("name" to f.name, "path" to f.absolutePath, "sizeBytes" to size, "readable" to f.canRead()))
                } else if (f.isDirectory && !f.name.startsWith(".")) visit(f, depth + 1)
            }
        }
        roots.forEach { visit(it, 0) }
        return out.sortedBy { it["name"].toString().lowercase() }
    }

    private fun importSelectedModel(uri: Uri): Map<String, Any?> {
        return try {
            val name = (contentResolver.query(uri, arrayOf(android.provider.OpenableColumns.DISPLAY_NAME), null, null, null)?.use { cursor ->
                if (cursor.moveToFirst()) cursor.getString(0) else null
            } ?: "model.gguf").replace(Regex("[^A-Za-z0-9._-]+"), "_")
            if (!name.lowercase().endsWith(".gguf")) return mapOf("available" to false, "status" to "INVALID", "reason" to "Only GGUF model files are supported.")
            val dir = File(filesDir, "models").apply { mkdirs() }
            val target = File(dir, name)
            contentResolver.openInputStream(uri)?.use { input ->
                FileOutputStream(target).use { output -> input.copyTo(output, 1024 * 1024) }
            } ?: return mapOf("available" to false, "status" to "ERROR", "reason" to "Unable to open selected model.")
            mapOf("available" to true, "status" to "IMPORTED", "name" to name, "path" to target.absolutePath, "sizeBytes" to target.length())
        } catch (t: Throwable) {
            mapOf("available" to false, "status" to "ERROR", "reason" to (t.message ?: "Model import failed."))
        }
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        if (requestCode == REQUEST_OPEN_MODEL) {
            val pending = pendingModelResult
            pendingModelResult = null
            if (resultCode != RESULT_OK || data?.data == null) {
                pending?.success(mapOf("available" to false, "status" to "CANCELLED"))
            } else {
                val uri = data.data!!
                try { contentResolver.takePersistableUriPermission(uri, data.flags and Intent.FLAG_GRANT_READ_URI_PERMISSION) } catch (_: Throwable) {}
                aiExecutor.execute {
                    val response = importSelectedModel(uri)
                    runOnUiThread { pending?.success(response) }
                }
            }
            super.onActivityResult(requestCode, resultCode, data)
            return
        }

        if (requestCode == REQUEST_OPEN_TREE) {
            val pending = pendingTreeResult
            pendingTreeResult = null
            if (resultCode != RESULT_OK || data?.data == null) {
                pending?.success(mapOf("available" to false, "status" to "CANCELLED"))
            } else {
                val uri = data.data!!
                try {
                    contentResolver.takePersistableUriPermission(uri, data.flags and (Intent.FLAG_GRANT_READ_URI_PERMISSION or Intent.FLAG_GRANT_WRITE_URI_PERMISSION))
                } catch (_: Throwable) {}
                pending?.success(mapOf("available" to true, "status" to "AVAILABLE", "uri" to uri.toString(), "name" to (uri.lastPathSegment ?: "External storage")))
            }
            super.onActivityResult(requestCode, resultCode, data)
            return
        }
        super.onActivityResult(requestCode, resultCode, data)
    }

    private fun listTree(uriString: String): Map<String, Any?> {
        if (uriString.isBlank()) return mapOf("available" to false, "status" to "INVALID", "items" to emptyList<Map<String, Any?>>())
        return try {
            val tree = Uri.parse(uriString)
            val children = DocumentsContract.buildChildDocumentsUriUsingTree(tree, DocumentsContract.getTreeDocumentId(tree))
            val projection = arrayOf(DocumentsContract.Document.COLUMN_DOCUMENT_ID, DocumentsContract.Document.COLUMN_DISPLAY_NAME, DocumentsContract.Document.COLUMN_MIME_TYPE, DocumentsContract.Document.COLUMN_SIZE, DocumentsContract.Document.COLUMN_LAST_MODIFIED)
            val items = mutableListOf<Map<String, Any?>>()
            contentResolver.query(children, projection, null, null, DocumentsContract.Document.COLUMN_DISPLAY_NAME) ?.use { cursor ->
                val id = cursor.getColumnIndexOrThrow(DocumentsContract.Document.COLUMN_DOCUMENT_ID)
                val name = cursor.getColumnIndexOrThrow(DocumentsContract.Document.COLUMN_DISPLAY_NAME)
                val mime = cursor.getColumnIndexOrThrow(DocumentsContract.Document.COLUMN_MIME_TYPE)
                val size = cursor.getColumnIndexOrThrow(DocumentsContract.Document.COLUMN_SIZE)
                val modified = cursor.getColumnIndexOrThrow(DocumentsContract.Document.COLUMN_LAST_MODIFIED)
                while (cursor.moveToNext()) {
                    val childId = cursor.getString(id)
                    items.add(mapOf("name" to cursor.getString(name), "mimeType" to cursor.getString(mime), "size" to if (cursor.isNull(size)) null else cursor.getLong(size), "modified" to if (cursor.isNull(modified)) null else cursor.getLong(modified), "isDirectory" to (cursor.getString(mime) == DocumentsContract.Document.MIME_TYPE_DIR), "uri" to DocumentsContract.buildDocumentUriUsingTree(tree, childId).toString()))
                }
            }
            mapOf("available" to true, "status" to "AVAILABLE", "items" to items)
        } catch (t: Throwable) { mapOf("available" to false, "status" to "ERROR", "reason" to (t.message ?: "Unable to list external storage.")) }
    }

    private fun deleteTreeDocument(uriString: String): Map<String, Any?> {
        if (uriString.isBlank()) return mapOf("available" to false, "status" to "INVALID")
        return try {
            mapOf("available" to true, "status" to if (DocumentsContract.deleteDocument(contentResolver, Uri.parse(uriString))) "DELETED" else "FAILED")
        } catch (t: Throwable) {
            mapOf("available" to false, "status" to "ERROR", "reason" to (t.message ?: "Delete failed."))
        }
    }

    private fun createTreeDirectory(parentUri: String, name: String): Map<String, Any?> {
        if (parentUri.isBlank() || name.isBlank() || name.contains("/")) return mapOf("available" to false, "status" to "INVALID")
        return try {
            val uri = DocumentsContract.createDocument(contentResolver, Uri.parse(parentUri), DocumentsContract.Document.MIME_TYPE_DIR, name)
            if (uri == null) mapOf("available" to false, "status" to "FAILED") else mapOf("available" to true, "status" to "CREATED", "uri" to uri.toString())
        } catch (t: Throwable) {
            mapOf("available" to false, "status" to "ERROR", "reason" to (t.message ?: "Create directory failed."))
        }
    }

    override fun onDestroy() {
        stopNetworkRadar()
        stopAllTerminals()
        wakeLock?.let { if (it.isHeld) it.release() }
        wakeLock = null
        ttsEngine?.stop()
        ttsEngine?.shutdown()
        ttsEngine = null
        if (::zionApiChannel.isInitialized) zionApiChannel.dispose()
        aiExecutor.shutdownNow()
        try { llamaBridge.nativeFreeModel() } catch (_: Throwable) {}
        super.onDestroy()
    }

    private fun readBatteryInfo(): Map<String, Any?> {
        val intent = registerReceiver(null, IntentFilter(Intent.ACTION_BATTERY_CHANGED)) ?: return mapOf("available" to false)
        val level = intent.getIntExtra(BatteryManager.EXTRA_LEVEL, -1)
        val scale = intent.getIntExtra(BatteryManager.EXTRA_SCALE, -1)
        val temperatureTenths = intent.getIntExtra(BatteryManager.EXTRA_TEMPERATURE, Int.MIN_VALUE)
        val voltageMv = intent.getIntExtra(BatteryManager.EXTRA_VOLTAGE, -1)
        val status = intent.getIntExtra(BatteryManager.EXTRA_STATUS, -1)
        val percentage = if (level >= 0 && scale > 0) (level * 100f / scale).coerceIn(0f, 100f) else null
        return mapOf("available" to (percentage != null), "level" to percentage, "temperatureC" to if (temperatureTenths != Int.MIN_VALUE) temperatureTenths / 10.0 else null, "voltageV" to if (voltageMv > 0) voltageMv / 1000.0 else null, "charging" to (status == BatteryManager.BATTERY_STATUS_CHARGING || status == BatteryManager.BATTERY_STATUS_FULL))
    }

    private fun readNetworkInfo(): Map<String, Any?> {
        val connectivity = getSystemService(Context.CONNECTIVITY_SERVICE) as ConnectivityManager
        val network = connectivity.activeNetwork ?: return mapOf("available" to true, "connected" to false, "validated" to false, "vpn" to false, "transport" to "none", "ipAddress" to null)
        val capabilities = connectivity.getNetworkCapabilities(network) ?: return mapOf("available" to true, "connected" to false, "validated" to false, "vpn" to false, "transport" to "none", "ipAddress" to null)
        val linkProperties: LinkProperties? = connectivity.getLinkProperties(network)
        val transport = when {
            capabilities.hasTransport(NetworkCapabilities.TRANSPORT_WIFI) -> "wifi"
            capabilities.hasTransport(NetworkCapabilities.TRANSPORT_CELLULAR) -> "cellular"
            capabilities.hasTransport(NetworkCapabilities.TRANSPORT_ETHERNET) -> "ethernet"
            capabilities.hasTransport(NetworkCapabilities.TRANSPORT_VPN) -> "vpn"
            else -> "other"
        }
        val address = linkProperties?.linkAddresses?.firstOrNull { !it.address.isLoopbackAddress }?.address?.hostAddress
        return mapOf("available" to true, "connected" to capabilities.hasCapability(NetworkCapabilities.NET_CAPABILITY_INTERNET), "validated" to capabilities.hasCapability(NetworkCapabilities.NET_CAPABILITY_VALIDATED), "vpn" to capabilities.hasTransport(NetworkCapabilities.TRANSPORT_VPN), "transport" to transport, "ipAddress" to address)
    }

    private fun readStorageInfo(): Map<String, Any?> {
        val path = getExternalFilesDir(null) ?: filesDir
        val stat = StatFs(path.absolutePath)
        val total = stat.totalBytes
        val free = stat.availableBytes
        return mapOf("available" to true, "path" to path.absolutePath, "totalBytes" to total, "freeBytes" to free, "usedBytes" to (total - free).coerceAtLeast(0L))
    }

    private fun scanWifiAsync(result: MethodChannel.Result) {
        if (!packageManager.hasSystemFeature("android.hardware.wifi")) {
            result.success(mapOf(
                "available" to false,
                "status" to "UNAVAILABLE",
                "reason" to "Wi-Fi hardware is not available.",
                "networks" to emptyList<Map<String, Any?>>()
            ))
            return
        }

        val hasLocation =
            ActivityCompat.checkSelfPermission(this, Manifest.permission.ACCESS_FINE_LOCATION) == PackageManager.PERMISSION_GRANTED ||
            ActivityCompat.checkSelfPermission(this, Manifest.permission.ACCESS_COARSE_LOCATION) == PackageManager.PERMISSION_GRANTED
        if (!hasLocation) {
            result.success(mapOf(
                "available" to false,
                "status" to "PERMISSION_REQUIRED",
                "reason" to "Location permission is required by Android to expose Wi-Fi scan results.",
                "networks" to emptyList<Map<String, Any?>>()
            ))
            return
        }

        if (android.os.Build.VERSION.SDK_INT >= 33 &&
            ActivityCompat.checkSelfPermission(this, Manifest.permission.NEARBY_WIFI_DEVICES) != PackageManager.PERMISSION_GRANTED) {
            result.success(mapOf(
                "available" to false,
                "status" to "PERMISSION_REQUIRED",
                "reason" to "Nearby Wi-Fi permission is required to scan networks.",
                "networks" to emptyList<Map<String, Any?>>()
            ))
            return
        }

        val locationManager = getSystemService(Context.LOCATION_SERVICE) as LocationManager
        if (!locationManager.isLocationEnabled) {
            result.success(mapOf(
                "available" to false,
                "status" to "PERMISSION_REQUIRED",
                "reason" to "Android Location services must be enabled for Wi-Fi scanning.",
                "networks" to emptyList<Map<String, Any?>>()
            ))
            return
        }

        val wifiManager = applicationContext.getSystemService(Context.WIFI_SERVICE) as? WifiManager
        if (wifiManager == null) {
            result.success(mapOf(
                "available" to false,
                "status" to "UNAVAILABLE",
                "reason" to "Android Wi-Fi service is unavailable.",
                "networks" to emptyList<Map<String, Any?>>()
            ))
            return
        }

        if (!wifiManager.isWifiEnabled) {
            result.success(mapOf(
                "available" to false,
                "status" to "UNAVAILABLE",
                "reason" to "Wi-Fi is disabled on the device.",
                "networks" to emptyList<Map<String, Any?>>()
            ))
            return
        }

        val started = try { wifiManager.startScan() } catch (_: SecurityException) { false }

        // Android throttles active scans. Even when startScan() returns false,
        // scanResults can contain the most recent real scan and must not be discarded.
        Handler(Looper.getMainLooper()).postDelayed({
            val networks = try {
                wifiManager.scanResults
                    .distinctBy { it.BSSID.lowercase() }
                    .map { scan ->
                        mapOf<String, Any?>(
                            "ssid" to scan.SSID,
                            "bssid" to scan.BSSID,
                            "signal" to scan.level,
                            "frequency" to scan.frequency,
                            "frequencyMHz" to scan.frequency,
                            "channel" to frequencyToChannel(scan.frequency),
                            "channelWidth" to scan.channelWidth,
                            "capabilities" to scan.capabilities,
                            "standard" to wifiStandard(scan),
                            "band" to wifiBand(scan.frequency),
                            "hidden" to scan.SSID.isBlank()
                        )
                    }
            } catch (e: SecurityException) {
                result.success(mapOf(
                    "available" to false,
                    "status" to "PERMISSION_REQUIRED",
                    "reason" to (e.message ?: "Android denied Wi-Fi scan access."),
                    "networks" to emptyList<Map<String, Any?>>()
                ))
                return@postDelayed
            }

            result.success(mapOf(
                "available" to networks.isNotEmpty(),
                "status" to if (networks.isNotEmpty()) "AVAILABLE" else if (!started) "THROTTLED_OR_UNAVAILABLE" else "NO_RESULTS",
                "reason" to if (started) "Results returned by Android WifiManager." else "Android returned the latest cached Wi-Fi scan because active scanning is throttled.",
                "networks" to networks
            ))
        }, 1200L)
    }

    private fun wifiBand(frequency: Int): String = when {
        frequency in 2400..2500 -> "2.4 GHz"
        frequency in 4900..5895 -> "5 GHz"
        frequency in 5925..7125 -> "6 GHz"
        frequency in 57000..71000 -> "60 GHz"
        else -> "Unknown"
    }

    @Suppress("DEPRECATION")
    private fun wifiStandard(scan: android.net.wifi.ScanResult): String = when {
        android.os.Build.VERSION.SDK_INT >= 30 && scan.wifiStandard == android.net.wifi.ScanResult.WIFI_STANDARD_11AX -> "Wi-Fi 6"
        android.os.Build.VERSION.SDK_INT >= 30 && scan.wifiStandard == android.net.wifi.ScanResult.WIFI_STANDARD_11AC -> "Wi-Fi 5"
        android.os.Build.VERSION.SDK_INT >= 30 && scan.wifiStandard == android.net.wifi.ScanResult.WIFI_STANDARD_11N -> "Wi-Fi 4"
        android.os.Build.VERSION.SDK_INT >= 30 && scan.wifiStandard == android.net.wifi.ScanResult.WIFI_STANDARD_LEGACY -> "802.11 legacy"
        else -> "Unknown"
    }

    private fun readCurrentWifiConnection(): Map<String, Any?> {
        val manager = getSystemService(Context.WIFI_SERVICE) as? WifiManager ?: return emptyMap()
        return try {
            val info = manager.connectionInfo
            mapOf(
                "ssid" to (info.ssid ?: "").removeSurrounding("\""),
                "bssid" to info.bssid,
                "rssi" to info.rssi,
                "linkSpeed" to info.linkSpeed,
                "frequency" to info.frequency
            )
        } catch (_: SecurityException) {
            emptyMap()
        }
    }

    private fun scanWifiTelemetryAsync(result: MethodChannel.Result) {
        scanWifiAsync(object : MethodChannel.Result {
            override fun success(value: Any?) {
                val payload = value as? Map<*, *> ?: return result.success(emptyList<Map<String, Any?>>())
                result.success(payload["networks"] ?: emptyList<Map<String, Any?>>())
            }
            override fun error(code: String, message: String?, details: Any?) = result.error(code, message, details)
            override fun notImplemented() = result.notImplemented()
        })
    }

    private fun frequencyToChannel(frequency: Int): Int? = when {
        frequency in 2412..2484 -> if (frequency == 2484) 14 else (frequency - 2407) / 5
        frequency in 5000..5900 -> (frequency - 5000) / 5
        frequency in 5925..7125 -> (frequency - 5950) / 5 + 1
        else -> null
    }
}
