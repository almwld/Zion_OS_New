package com.zion.os

import android.content.Context
import android.net.wifi.WifiManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val channelName = "zion.os/wifi"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channelName)
            .setMethodCallHandler { call, result ->
                val wifiManager = applicationContext
                    .getSystemService(Context.WIFI_SERVICE) as WifiManager

                when (call.method) {
                    "scan" -> {
                        try {
                            @Suppress("DEPRECATION")
                            wifiManager.startScan()
                            @Suppress("DEPRECATION")
                            val networks = wifiManager.scanResults.map { network ->
                                mapOf(
                                    "ssid" to network.SSID,
                                    "bssid" to network.BSSID,
                                    "capabilities" to network.capabilities,
                                    "frequency" to network.frequency,
                                    "level" to network.level,
                                    "channelWidth" to network.channelWidth,
                                )
                            }
                            result.success(networks)
                        } catch (e: SecurityException) {
                            result.error("PERMISSION_DENIED", e.message, null)
                        } catch (e: Exception) {
                            result.error("WIFI_SCAN_FAILED", e.message, null)
                        }
                    }
                    "connection" -> {
                        try {
                            @Suppress("DEPRECATION")
                            val info = wifiManager.connectionInfo
                            result.success(
                                mapOf(
                                    "ssid" to info.ssid,
                                    "bssid" to info.bssid,
                                    "rssi" to info.rssi,
                                    "linkSpeed" to info.linkSpeed,
                                    "frequency" to info.frequency,
                                ),
                            )
                        } catch (e: SecurityException) {
                            result.error("PERMISSION_DENIED", e.message, null)
                        } catch (e: Exception) {
                            result.error("WIFI_INFO_FAILED", e.message, null)
                        }
                    }
                    else -> result.notImplemented()
                }
            }
    }
}
