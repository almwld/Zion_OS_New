package com.zion.os

import android.content.ActivityNotFoundException
import android.content.Context
import android.content.Intent
import android.net.Uri
import android.provider.DocumentsContract
import android.util.Log
import io.flutter.plugin.common.MethodChannel

/**
 * Bridge for the documented USB WiFi Monitor API (package com.usbwifimon.app).
 * API control is an explicit VIEW intent to CaptureCtrl with action=start|stop|get_status.
 */
class UsbWifiMonitorBridge(private val context: Context) {
    companion object {
        private const val TAG = "ZionUsbWifi"
        private const val APP_PACKAGE = "com.usbwifimon.app"
        private const val CAPTURE_COMPONENT = "com.usbwifimon.app.CaptureCtrl"
    }

    fun startCapture(result: MethodChannel.Result, channel: Int, pcapName: String) {
        if (channel !in -1..11 || (channel != -1 && channel !in 1..11)) {
            result.error("USB_WIFI_INVALID_CHANNEL", "Channel must be -1 (channel hopping) or 1-11.", null)
            return
        }
        val safeName = pcapName.trim()
        if (!safeName.matches(Regex("[A-Za-z0-9][A-Za-z0-9._-]{0,95}")) ||
            safeName.contains("..") || safeName.contains("/") || safeName.contains("\\")) {
            result.error("USB_WIFI_INVALID_PCAP_NAME", "Use a simple filename without path separators.", null)
            return
        }
        val filename = if (safeName.endsWith(".pcap", ignoreCase = true)) safeName else "$safeName.pcap"
        val intent = Intent(Intent.ACTION_VIEW).apply {
            setClassName(APP_PACKAGE, CAPTURE_COMPONENT)
            putExtra("action", "start")
            putExtra("channel", channel)
            putExtra("pcap_name", filename)
            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
        }
        launchControl(intent, result, "USB_WIFI_START_FAILED")
    }

    fun stopCapture(result: MethodChannel.Result) {
        val intent = Intent(Intent.ACTION_VIEW).apply {
            setClassName(APP_PACKAGE, CAPTURE_COMPONENT)
            putExtra("action", "stop")
            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
        }
        launchControl(intent, result, "USB_WIFI_STOP_FAILED")
    }

    fun isInstalled(): Boolean = try {
        @Suppress("DEPRECATION")
        context.packageManager.getPackageInfo(APP_PACKAGE, 0)
        true
    } catch (_: Exception) {
        false
    }

    fun openPcapFolder(result: MethodChannel.Result) {
        // SAF opens the actual directory in the system picker; an arbitrary content:// URI
        // is not a valid way to launch a file manager on modern Android.
        val treeUri = Uri.parse(
            "content://com.android.externalstorage.documents/tree/primary%3ADownload%2FUsbWifiMonitor"
        )
        val intent = Intent(Intent.ACTION_OPEN_DOCUMENT_TREE).apply {
            putExtra(DocumentsContract.EXTRA_INITIAL_URI, treeUri)
            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION or Intent.FLAG_GRANT_WRITE_URI_PERMISSION)
        }
        try {
            context.startActivity(intent)
            result.success(true)
        } catch (e: Exception) {
            Log.e(TAG, "Unable to open PCAP folder picker", e)
            result.error("USB_WIFI_FOLDER_FAILED", e.message ?: "Folder picker unavailable", null)
        }
    }

    private fun launchControl(intent: Intent, result: MethodChannel.Result, errorCode: String) {
        try {
            if (!isInstalled()) {
                result.error("USB_WIFI_NOT_INSTALLED", "Install USB WiFi Monitor (com.usbwifimon.app) first.", null)
                return
            }
            context.startActivity(intent)
            result.success(true)
        } catch (e: ActivityNotFoundException) {
            result.error(errorCode, "USB WiFi Monitor API activity was not found: ${e.message}", null)
        } catch (e: Exception) {
            Log.e(TAG, "Capture control intent failed", e)
            result.error(errorCode, e.message ?: "Capture control failed", null)
        }
    }
}
