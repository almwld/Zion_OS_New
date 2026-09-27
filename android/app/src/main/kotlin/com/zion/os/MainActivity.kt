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
import androidx.core.app.ActivityCompat
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.EventChannel
import java.io.BufferedReader
import java.io.InputStreamReader

class MainActivity : FlutterActivity() {
    private var terminalProcess: Process? = null
    private var terminalSink: EventChannel.EventSink? = null
    companion object {
        private const val PLATFORM_CHANNEL = "zion.os/platform"
        private const val PTY_CHANNEL = "zion.os/pty"
        private const val PTY_EVENTS = "zion.os/pty/events"
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

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, PTY_CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "available" -> result.success(true)
                    "start" -> {
                        val rows = call.argument<Int>("rows") ?: 24
                        val cols = call.argument<Int>("cols") ?: 80
                        result.success(startTerminal(rows, cols))
                    }
                    "write" -> {
                        val input = call.argument<String>("input") ?: ""
                        result.success(writeTerminal(input))
                    }
                    "resize" -> {
                        // Process-backed shell does not expose a real PTY resize ioctl.
                        result.success(false)
                    }
                    "stop" -> {
                        stopTerminal()
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
    }

    private fun startTerminal(rows: Int, cols: Int): Boolean {
        if (terminalProcess?.isAlive == true) return true
        return try {
            val process = ProcessBuilder("/system/bin/sh", "-i")
                .redirectErrorStream(true)
                .apply {
                    environment()["HOME"] = filesDir.absolutePath
                    environment()["TERM"] = "xterm-256color"
                    environment()["PATH"] = "/system/bin:/system/xbin"
                    environment()["ZION_TERMINAL"] = "1"
                }
                .start()
            terminalProcess = process
            Thread {
                try {
                    BufferedReader(InputStreamReader(process.inputStream)).use { reader ->
                        val buffer = CharArray(2048)
                        var count: Int
                        while (process.isAlive && reader.read(buffer).also { count = it } != -1) {
                            if (count > 0) {
                                terminalSink?.success(String(buffer, 0, count))
                            }
                        }
                    }
                } catch (t: Throwable) {
                    terminalSink?.error("PTY_STREAM", t.message, null)
                } finally {
                    terminalSink?.success("\r\n[ZION] shell exited\r\n")
                    terminalProcess = null
                }
            }.apply { name = "zion-terminal-reader"; isDaemon = true }.start()
            true
        } catch (_: Throwable) {
            terminalProcess = null
            false
        }
    }

    private fun writeTerminal(input: String): Boolean {
        val process = terminalProcess ?: return false
        if (!process.isAlive) return false
        return try {
            process.outputStream.write(input.toByteArray(Charsets.UTF_8))
            process.outputStream.flush()
            true
        } catch (_: Throwable) {
            false
        }
    }

    private fun stopTerminal() {
        try {
            terminalProcess?.outputStream?.close()
        } catch (_: Throwable) {}
        terminalProcess?.destroy()
        terminalProcess = null
    }

    override fun onDestroy() {
        stopTerminal()
        super.onDestroy()
    }

    private fun readBatteryInfo(): Map<String, Any?> {
        val intent = registerReceiver(null, IntentFilter(Intent.ACTION_BATTERY_CHANGED))
            ?: return mapOf("available" to false)
        val level = intent.getIntExtra(BatteryManager.EXTRA_LEVEL, -1)
        val scale = intent.getIntExtra(BatteryManager.EXTRA_SCALE, -1)
        val temperatureTenths = intent.getIntExtra(BatteryManager.EXTRA_TEMPERATURE, Int.MIN_VALUE)
        val voltageMv = intent.getIntExtra(BatteryManager.EXTRA_VOLTAGE, -1)
        val status = intent.getIntExtra(BatteryManager.EXTRA_STATUS, -1)
        val percentage = if (level >= 0 && scale > 0) (level * 100f / scale).coerceIn(0f, 100f) else null
        return mapOf(
            "available" to (percentage != null),
            "level" to percentage,
            "temperatureC" to if (temperatureTenths != Int.MIN_VALUE) temperatureTenths / 10.0 else null,
            "voltageV" to if (voltageMv > 0) voltageMv / 1000.0 else null,
            "charging" to (status == BatteryManager.BATTERY_STATUS_CHARGING || status == BatteryManager.BATTERY_STATUS_FULL),
        )
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
        return mapOf(
            "available" to true,
            "connected" to capabilities.hasCapability(NetworkCapabilities.NET_CAPABILITY_INTERNET),
            "validated" to capabilities.hasCapability(NetworkCapabilities.NET_CAPABILITY_VALIDATED),
            "vpn" to capabilities.hasTransport(NetworkCapabilities.TRANSPORT_VPN),
            "transport" to transport,
            "ipAddress" to address,
        )
    }

    private fun readStorageInfo(): Map<String, Any?> {
        val path = getExternalFilesDir(null) ?: filesDir
        val stat = StatFs(path.absolutePath)
        val total = stat.totalBytes
        val free = stat.availableBytes
        return mapOf("available" to true, "path" to path.absolutePath, "totalBytes" to total, "freeBytes" to free, "usedBytes" to (total - free).coerceAtLeast(0L))
    }

    private fun scanWifi(): Map<String, Any?> {
        if (!packageManager.hasSystemFeature("android.hardware.wifi")) {
            return mapOf("available" to false, "status" to "UNAVAILABLE", "reason" to "Wi-Fi hardware is not available.", "networks" to emptyList<Map<String, Any?>>())
        }
        if (ActivityCompat.checkSelfPermission(this, Manifest.permission.ACCESS_FINE_LOCATION) != PackageManager.PERMISSION_GRANTED) {
            return mapOf("available" to false, "status" to "PERMISSION_REQUIRED", "reason" to "Precise location permission is required by Android to expose Wi-Fi scan results.", "networks" to emptyList<Map<String, Any?>>())
        }
        val wifiManager = applicationContext.getSystemService(Context.WIFI_SERVICE) as? WifiManager
            ?: return mapOf("available" to false, "status" to "UNAVAILABLE", "reason" to "Android Wi-Fi service is unavailable.", "networks" to emptyList<Map<String, Any?>>())
        if (!wifiManager.isWifiEnabled) {
            return mapOf("available" to false, "status" to "UNAVAILABLE", "reason" to "Wi-Fi is disabled on the device.", "networks" to emptyList<Map<String, Any?>>())
        }
        val results = try { wifiManager.scanResults } catch (e: SecurityException) {
            return mapOf("available" to false, "status" to "PERMISSION_REQUIRED", "reason" to (e.message ?: "Android denied Wi-Fi scan access."), "networks" to emptyList<Map<String, Any?>>())
        }
        val networks = results
            .filter { it.SSID.isNotBlank() }
            .distinctBy { it.BSSID.lowercase() }
            .map { result ->
                mapOf<String, Any?>(
                    "ssid" to result.SSID,
                    "bssid" to result.BSSID,
                    "signal" to result.level,
                    "frequencyMHz" to result.frequency,
                    "channel" to frequencyToChannel(result.frequency),
                    "capabilities" to result.capabilities,
                )
            }
        return mapOf("available" to true, "status" to "AVAILABLE", "reason" to "Results returned by Android WifiManager.", "networks" to networks)
    }

    private fun frequencyToChannel(frequency: Int): Int? {
        return when {
            frequency in 2412..2484 -> if (frequency == 2484) 14 else (frequency - 2407) / 5
            frequency in 5000..5900 -> (frequency - 5000) / 5
            frequency in 5925..7125 -> (frequency - 5950) / 5 + 1
            else -> null
        }
    }
}
