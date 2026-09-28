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
import java.util.Locale
import androidx.core.app.ActivityCompat
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.EventChannel
import java.util.concurrent.ConcurrentHashMap

class MainActivity : FlutterActivity() {
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

    companion object {
        init { System.loadLibrary("zionpty") }
        private const val PLATFORM_CHANNEL = "zion.os/platform"
        private const val PTY_CHANNEL = "zion.os/pty"
        private const val PTY_EVENTS = "zion.os/pty/events"
        private const val RADAR_EVENTS = "zion.os/network/radar"
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, PLATFORM_CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "batteryInfo" -> result.success(readBatteryInfo())
                    "networkInfo" -> result.success(readNetworkInfo())
                    "storageInfo" -> result.success(readStorageInfo())
                    "wifiScan" -> result.success(scanWifi())
                    else -> result.notImplemented()
                }
            }

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "zion.os/termux")
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "setup-storage" -> result.success(setupStorageApi())
                    "battery" -> result.success(readBatteryInfo())
                    "camera" -> result.success(openCameraApi())
                    "clipboard-get" -> result.success(clipboardGetApi())
                    "clipboard-set" -> result.success(clipboardSetApi(call.argument<String>("text") ?: ""))
                    "dialog" -> showDialogApi(
                        call.argument<String>("title") ?: "Zion OS",
                        call.argument<String>("message") ?: "",
                        call.argument<String>("positive") ?: "OK",
                        call.argument<String>("negative") ?: "Cancel",
                        result
                    )
                    "fingerprint" -> fingerprintApi(result)
                    "location" -> result.success(locationApi())
                    "notification" -> result.success(notificationApi(
                        call.argument<String>("title") ?: "Zion OS",
                        call.argument<String>("content") ?: "",
                        call.argument<String>("channelId") ?: "zion_default"
                    ))
                    "sensor" -> result.success(sensorApi(call.argument<Int>("sensorType") ?: Sensor.TYPE_ACCELEROMETER))
                    "sms" -> result.success(smsApi(
                        call.argument<String>("number") ?: "",
                        call.argument<String>("body")
                    ))
                    "toast" -> result.success(toastApi(call.argument<String>("text") ?: ""))
                    "tts" -> result.success(ttsApi(call.argument<String>("text") ?: ""))
                    "vibrate" -> result.success(vibrateApi(call.argument<Int>("durationMs") ?: 250))
                    "wake-lock" -> result.success(wakeLockApi(call.argument<Boolean>("enabled") ?: false))
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
        val prompt = BiometricPrompt(this, executor, object : BiometricPrompt.AuthenticationCallback() {
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

    private fun ttsApi(text: String): Map<String, Any?> {
        if (text.isBlank()) return mapOf("available" to false, "status" to "UNAVAILABLE", "reason" to "Text is empty.")
        var initialized = false
        val tts = TextToSpeech(this) { status ->
            initialized = status == TextToSpeech.SUCCESS
            if (initialized) {
                tts?.language = Locale.getDefault()
                tts?.speak(text, TextToSpeech.QUEUE_FLUSH, null, "zion-" + System.currentTimeMillis())
            }
        }
        return mapOf("available" to true, "status" to "AVAILABLE", "queued" to true)
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

    override fun onDestroy() {
        stopNetworkRadar()
        stopAllTerminals()
        wakeLock?.let { if (it.isHeld) it.release() }
        wakeLock = null
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

    private fun scanWifi(): Map<String, Any?> {
        if (!packageManager.hasSystemFeature("android.hardware.wifi")) return mapOf("available" to false, "status" to "UNAVAILABLE", "reason" to "Wi-Fi hardware is not available.", "networks" to emptyList<Map<String, Any?>>())
        if (ActivityCompat.checkSelfPermission(this, Manifest.permission.ACCESS_FINE_LOCATION) != PackageManager.PERMISSION_GRANTED) return mapOf("available" to false, "status" to "PERMISSION_REQUIRED", "reason" to "Precise location permission is required by Android to expose Wi-Fi scan results.", "networks" to emptyList<Map<String, Any?>>())
        val wifiManager = applicationContext.getSystemService(Context.WIFI_SERVICE) as? WifiManager ?: return mapOf("available" to false, "status" to "UNAVAILABLE", "reason" to "Android Wi-Fi service is unavailable.", "networks" to emptyList<Map<String, Any?>>())
        if (!wifiManager.isWifiEnabled) return mapOf("available" to false, "status" to "UNAVAILABLE", "reason" to "Wi-Fi is disabled on the device.", "networks" to emptyList<Map<String, Any?>>())
        val results = try { wifiManager.scanResults } catch (e: SecurityException) { return mapOf("available" to false, "status" to "PERMISSION_REQUIRED", "reason" to (e.message ?: "Android denied Wi-Fi scan access."), "networks" to emptyList<Map<String, Any?>>()) }
        val networks = results.filter { it.SSID.isNotBlank() }.distinctBy { it.BSSID.lowercase() }.map { result ->
            mapOf<String, Any?>("ssid" to result.SSID, "bssid" to result.BSSID, "signal" to result.level, "frequencyMHz" to result.frequency, "channel" to frequencyToChannel(result.frequency), "capabilities" to result.capabilities)
        }
        return mapOf("available" to true, "status" to "AVAILABLE", "reason" to "Results returned by Android WifiManager.", "networks" to networks)
    }

    private fun frequencyToChannel(frequency: Int): Int? = when {
        frequency in 2412..2484 -> if (frequency == 2484) 14 else (frequency - 2407) / 5
        frequency in 5000..5900 -> (frequency - 5000) / 5
        frequency in 5925..7125 -> (frequency - 5950) / 5 + 1
        else -> null
    }
}
