package com.zion.os

import android.content.Context
import android.os.Build
import android.net.wifi.WifiManager
import android.os.ParcelFileDescriptor
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel
import java.io.BufferedReader
import java.io.File
import java.io.InputStreamReader
import java.io.OutputStream
import java.nio.charset.StandardCharsets

class MainActivity : FlutterActivity() {
    private val wifiChannelName = "zion.os/wifi"
    private val ptyChannelName = "zion.os/pty"
    private val ptyEventsName = "zion.os/pty/events"

    private var ptyDescriptor: ParcelFileDescriptor? = null
    private var ptyOutput: OutputStream? = null
    private var ptyPid: Int = -1
    private var ptyMasterFd: Int = -1
    private var ptyReaderThread: Thread? = null
    @Volatile private var ptyRunning = false
    @Volatile private var ptySink: EventChannel.EventSink? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, wifiChannelName)
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

        EventChannel(flutterEngine.dartExecutor.binaryMessenger, ptyEventsName)
            .setStreamHandler(object : EventChannel.StreamHandler {
                override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                    ptySink = events
                }

                override fun onCancel(arguments: Any?) {
                    ptySink = null
                }
            })

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, ptyChannelName)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "available" -> {
                        result.success(
                            Build.VERSION.SDK_INT >= Build.VERSION_CODES.M &&
                                File("/system/bin/sh").canExecute(),
                        )
                    }
                    "start" -> {
                        val rows = call.argument<Int>("rows") ?: 24
                        val cols = call.argument<Int>("cols") ?: 80
                        startPty(rows, cols, result)
                    }
                    "write" -> {
                        val input = call.argument<String>("input") ?: ""
                        try {
                            ptyOutput?.write(input.toByteArray(StandardCharsets.UTF_8))
                            ptyOutput?.flush()
                            result.success(true)
                        } catch (e: Exception) {
                            result.error("PTY_WRITE_FAILED", e.message, null)
                        }
                    }
                    "resize" -> {
                        val rows = call.argument<Int>("rows") ?: 24
                        val cols = call.argument<Int>("cols") ?: 80
                        val rc = PtyNative.resize(ptyMasterFd, rows, cols)
                        if (rc == 0) result.success(true)
                        else result.error("PTY_RESIZE_FAILED", "native errno=$rc", null)
                    }
                    "stop" -> {
                        stopPty()
                        result.success(true)
                    }
                    "status" -> {
                        result.success(
                            mapOf(
                                "running" to ptyRunning,
                                "pid" to ptyPid,
                                "masterFd" to ptyMasterFd,
                            ),
                        )
                    }
                    else -> result.notImplemented()
                }
            }
    }

    private fun startPty(rows: Int, cols: Int, result: MethodChannel.Result) {
        if (ptyRunning) {
            result.success(mapOf("running" to true, "pid" to ptyPid))
            return
        }
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.M) {
            result.error("PTY_UNAVAILABLE", "Android PTY requires API 23+", null)
            return
        }

        try {
            val masterFd = PtyNative.start("/system/bin/sh", rows, cols)
            if (masterFd < 0) {
                result.error("PTY_START_FAILED", "native errno=${-masterFd}", null)
                return
            }

            ptyPid = PtyNative.pid()
            ptyMasterFd = masterFd
            ptyDescriptor = ParcelFileDescriptor.adoptFd(masterFd)
            val input = ParcelFileDescriptor.AutoCloseInputStream(ptyDescriptor)
            ptyOutput = ParcelFileDescriptor.AutoCloseOutputStream(
                ParcelFileDescriptor.fromFd(masterFd),
            )
            ptyRunning = true

            ptyReaderThread = Thread {
                try {
                    BufferedReader(InputStreamReader(input, StandardCharsets.UTF_8)).use { reader ->
                        val buffer = CharArray(4096)
                        while (ptyRunning) {
                            val count = reader.read(buffer)
                            if (count < 0) break
                            if (count > 0) {
                                ptySink?.success(String(buffer, 0, count))
                            }
                        }
                    }
                } catch (e: Exception) {
                    if (ptyRunning) ptySink?.error("PTY_READ_FAILED", e.message, null)
                } finally {
                    if (ptyRunning) {
                        ptyRunning = false
                        ptySink?.success("\r\n[ZION] PTY session ended.\r\n")
                    }
                }
            }.apply {
                name = "zion-pty-reader"
                isDaemon = true
                start()
            }

            result.success(mapOf("running" to true, "pid" to ptyPid, "masterFd" to ptyMasterFd))
        } catch (e: UnsatisfiedLinkError) {
            result.error("PTY_NATIVE_UNAVAILABLE", e.message, null)
        } catch (e: Exception) {
            stopPty()
            result.error("PTY_START_FAILED", e.message, null)
        }
    }

    private fun stopPty() {
        val pid = ptyPid
        ptyRunning = false
        if (pid > 0) {
            try {
                PtyNative.stop(pid)
            } catch (_: Exception) {
            }
        }
        try {
            ptyOutput?.close()
        } catch (_: Exception) {
        }
        ptyOutput = null
        try {
            ptyDescriptor?.close()
        } catch (_: Exception) {
        }
        ptyDescriptor = null
        ptyReaderThread = null
        ptyPid = -1
        ptyMasterFd = -1
    }

    override fun onDestroy() {
        stopPty()
        super.onDestroy()
    }
}
