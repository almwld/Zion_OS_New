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

class MainActivity : FlutterActivity() {
    companion object {
        private const val PLATFORM_CHANNEL = "zion.os/platform"
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
