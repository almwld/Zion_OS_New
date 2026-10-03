package com.zion.os

import android.Manifest
import android.app.*
import android.content.*
import android.content.pm.PackageManager
import android.graphics.Color
import android.hardware.*
import android.location.LocationManager
import android.media.*
import android.speech.tts.TextToSpeech
import android.net.Uri
import android.os.*
import android.provider.ContactsContract
import android.provider.Settings
import android.telephony.SmsManager
import android.telephony.SubscriptionManager
import android.view.WindowManager
import android.widget.Toast
import androidx.biometric.BiometricManager
import androidx.biometric.BiometricPrompt
import androidx.core.app.ActivityCompat
import androidx.core.app.NotificationCompat
import androidx.core.content.ContextCompat
import androidx.core.content.FileProvider
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.util.Locale
import java.util.concurrent.ConcurrentHashMap
import org.json.JSONObject
import com.zion.os.handlers.BatteryHandler
import com.zion.os.handlers.SensorHandler
import com.zion.os.handlers.ClipboardHandler
import com.zion.os.utils.PermissionHelper
import com.zion.os.security.TrustVerifier

class ZionApiChannel(private val activity: Activity, messenger: BinaryMessenger) {
    private val channel = MethodChannel(messenger, "zion.os/api")
    private val securityChannel = MethodChannel(messenger, "zion.os/security")
    private val battery = BatteryHandler(activity)
    private val sensors = SensorHandler(activity)
    private val clipboard = ClipboardHandler(activity)
    private var tts: TextToSpeech? = null
    private var recorder: MediaRecorder? = null
    private var recordingFile: File? = null
    private var wakeLock: PowerManager.WakeLock? = null
    private val trustVerifier = TrustVerifier(activity)

    fun handleExternalIntent(intent: Intent) {
        if (intent.action != "com.zion.os.ZION_API") return
        val requestId = intent.getStringExtra("requestId")?.takeIf { TrustVerifier.isValidRequestId(it) } ?: return
        if (!trustVerifier.verify(intent)) {
            ExternalResult(requestId).error("UNAUTHORIZED", "Zion API authentication failed.", null)
            return
        }
        val method = intent.getStringExtra("method")?.takeIf { TrustVerifier.isValidMethod(it) } ?: return
        val args = mutableMapOf<String, Any?>()
        for (key in intent.extras?.keySet().orEmpty()) {
            if (key == "requestId" || key == "method" || key == "token") continue
            args[key] = intent.extras?.get(key)
        }
        val result = ExternalResult(requestId)
        try {
            when (method) {
                "battery" -> result.success(battery.info())
                "device-info" -> result.success(deviceInfo())
                "wifi-info" -> result.success(wifiInfo())
                "sensor" -> result.success(sensors.list((args["type"] as? Int)))
                "camera-photo" -> result.success(cameraPhoto())
                "camera-info" -> result.success(cameraInfo())
                "media-player" -> result.success(mediaPlayer(args["path"] as? String, args["mime"] as? String))
                "audio-record" -> result.success(audioRecord(args["stop"] == true))
                "location" -> result.success(location())
                "gps-status" -> result.success(gpsStatus())
                "notification" -> result.success(notification(MethodCall("notification", args)))
                "toast" -> result.success(toast(args["text"] as? String ?: ""))
                "dialog" -> dialog(MethodCall("dialog", args), result)
                "vibrate" -> result.success(vibrate((args["durationMs"] as? Number)?.toLong() ?: 250L))
                "clipboard-get" -> result.success(clipboard.get())
                "clipboard-set" -> result.success(clipboard.set(args["text"] as? String ?: ""))
                "tts-speak" -> result.success(ttsSpeak(args["text"] as? String ?: ""))
                "tts-stop" -> result.success(ttsStop())
                "sms-list" -> result.success(smsList())
                "sms-send" -> result.success(smsSend(args["number"] as? String ?: "", args["body"] as? String ?: ""))
                "call" -> result.success(callPhone(args["number"] as? String ?: ""))
                "contacts-list" -> result.success(contactsList())
                "setup-storage" -> result.success(setupStorage())
                "storage-get" -> result.success(storageGet())
                "file-share" -> result.success(fileShare(args["path"] as? String ?: "", args["mime"] as? String ?: "*/*"))
                "fingerprint" -> fingerprint(result)
                "keystore" -> result.success(keystore(args["alias"] as? String ?: "zion-api"))
                "wake-lock" -> result.success(wakeLock(args["enabled"] == true))
                "job-scheduler" -> result.success(jobScheduler((args["jobId"] as? Number)?.toInt() ?: 1, (args["delayMs"] as? Number)?.toLong() ?: 1000L))
                "brightness" -> result.success(brightness((args["value"] as? Number)?.toInt()))
                else -> result.error("NOT_IMPLEMENTED", "Unknown Zion API: $method", null)
            }
        } catch (t: Throwable) {
            result.error("UNAVAILABLE", t.message ?: t.javaClass.simpleName, null)
        }
    }

    private inner class AuditedResult(private val method: String, private val delegate: MethodChannel.Result) : MethodChannel.Result {
        private fun audit(outcome: String, details: Any? = null) {
            try {
                securityChannel.invokeMethod("audit", mapOf(
                    "method" to method,
                    "outcome" to outcome,
                    "details" to details,
                    "source" to "NATIVE_ANDROID_ZION_API"
                ))
            } catch (_: Throwable) {}
        }
        override fun success(result: Any?) { audit("success", result); delegate.success(result) }
        override fun error(errorCode: String, errorMessage: String?, errorDetails: Any?) {
            audit(errorCode, mapOf("message" to errorMessage, "details" to errorDetails)); delegate.error(errorCode, errorMessage, errorDetails)
        }
        override fun notImplemented() { audit("not_implemented"); delegate.notImplemented() }
    }

    private inner class ExternalResult(private val requestId: String) : MethodChannel.Result {
        private val file: File
            get() {
                val dir = File(activity.filesDir, "usr/tmp/zion-api-results")
                dir.mkdirs()
                return File(dir, requestId + ".json")
            }
        private fun write(payload: Map<String, Any?>) {
            try { securityChannel.invokeMethod("audit", mapOf("method" to "external.$requestId", "outcome" to payload["status"], "details" to payload, "source" to "NATIVE_ANDROID_ZION_API_CLI")) } catch (_: Throwable) {}
            val tmp = File(file.parentFile, file.name + ".tmp")
            tmp.writeText(JSONObject(payload).toString())
            if (!tmp.renameTo(file)) {
                file.writeText(JSONObject(payload).toString())
                tmp.delete()
            }
        }
        override fun success(result: Any?) {
            val map = if (result is Map<*, *>) result.entries.associate { it.key.toString() to it.value } else mapOf("available" to true, "status" to "AVAILABLE", "result" to result)
            write(map)
        }
        override fun error(errorCode: String, errorMessage: String?, errorDetails: Any?) =
            write(mapOf("available" to false, "status" to errorCode, "reason" to (errorMessage ?: "Zion API request failed."), "details" to errorDetails))
        override fun notImplemented() =
            write(mapOf("available" to false, "status" to "UNAVAILABLE", "reason" to "Zion API method is not implemented."))
    }

    fun register() {
        channel.setMethodCallHandler { call, result ->
            val audited = AuditedResult(call.method, result)
            try {
                when (call.method) {
                    "battery" -> audited.success(battery.info())
                    "device-info" -> audited.success(deviceInfo())
                    "wifi-info" -> audited.success(wifiInfo())
                    "sensor" -> audited.success(sensors.list(call.argument<Int>("type")))
                    "camera-photo" -> audited.success(cameraPhoto())
                    "camera-info" -> audited.success(cameraInfo())
                    "media-player" -> audited.success(mediaPlayer(call.argument<String>("path"), call.argument<String>("mime")))
                    "audio-record" -> audited.success(audioRecord(call.argument<Boolean>("stop") == true))
                    "location" -> audited.success(location())
                    "gps-status" -> audited.success(gpsStatus())
                    "notification" -> audited.success(notification(call))
                    "toast" -> audited.success(toast(call.argument<String>("text") ?: ""))
                    "dialog" -> dialog(call, audited)
                    "vibrate" -> audited.success(vibrate(call.argument<Long>("durationMs") ?: 250L))
                    "clipboard-get" -> audited.success(clipboard.get())
                    "clipboard-set" -> audited.success(clipboard.set(call.argument<String>("text") ?: ""))
                    "tts-speak" -> audited.success(ttsSpeak(call.argument<String>("text") ?: ""))
                    "tts-stop" -> audited.success(ttsStop())
                    "sms-list" -> audited.success(smsList())
                    "sms-send" -> audited.success(smsSend(call.argument<String>("number") ?: "", call.argument<String>("body") ?: ""))
                    "call" -> audited.success(callPhone(call.argument<String>("number") ?: ""))
                    "contacts-list" -> audited.success(contactsList())
                    "setup-storage" -> audited.success(setupStorage())
                    "storage-get" -> audited.success(storageGet())
                    "file-share" -> audited.success(fileShare(call.argument<String>("path") ?: "", call.argument<String>("mime") ?: "*/*"))
                    "fingerprint" -> fingerprint(audited)
                    "keystore" -> audited.success(keystore(call.argument<String>("alias") ?: "zion-api"))
                    "wake-lock" -> audited.success(wakeLock(call.argument<Boolean>("enabled") == true))
                    "job-scheduler" -> audited.success(jobScheduler(call.argument<Int>("jobId") ?: 1, call.argument<Long>("delayMs") ?: 1000L))
                    "brightness" -> audited.success(brightness(call.argument<Int>("value")))
                    else -> audited.notImplemented()
                }
            } catch (t: Throwable) {
                audited.error("UNAVAILABLE", t.message ?: t.javaClass.simpleName, null)
            }
        }
    }

    private fun deviceInfo(): Map<String, Any?> = mapOf(
        "available" to true, "status" to "AVAILABLE",
        "manufacturer" to Build.MANUFACTURER, "brand" to Build.BRAND, "model" to Build.MODEL,
        "device" to Build.DEVICE, "product" to Build.PRODUCT, "hardware" to Build.HARDWARE,
        "androidVersion" to Build.VERSION.RELEASE, "sdk" to Build.VERSION.SDK_INT,
        "supportedAbis" to Build.SUPPORTED_ABIS.toList(), "isEmulator" to (Build.FINGERPRINT.startsWith("generic") || Build.MODEL.contains("emulator", true))
    )

    private fun wifiInfo(): Map<String, Any?> {
        val manager = activity.applicationContext.getSystemService(Context.WIFI_SERVICE) as android.net.wifi.WifiManager
        val info = manager.connectionInfo ?: return mapOf("available" to false, "status" to "UNAVAILABLE", "reason" to "Wi-Fi information unavailable.")
        val ssid = info.ssid?.trim('"')
        return mapOf("available" to true, "status" to "AVAILABLE", "enabled" to manager.isWifiEnabled,
            "ssid" to if (ssid == "<unknown ssid>") null else ssid, "bssid" to info.bssid,
            "rssi" to info.rssi, "linkSpeedMbps" to info.linkSpeed, "frequencyMHz" to info.frequency,
            "networkId" to info.networkId)
    }

    private fun cameraPhoto(): Map<String, Any?> {
        if (!PermissionHelper.camera(activity)) return mapOf("available" to false, "status" to "PERMISSION_REQUIRED", "reason" to "Camera permission requested.")
        val intent = Intent(android.provider.MediaStore.ACTION_IMAGE_CAPTURE)
        if (intent.resolveActivity(activity.packageManager) == null) return mapOf("available" to false, "status" to "UNAVAILABLE", "reason" to "No camera application is available.")
        activity.startActivity(intent)
        return mapOf("available" to true, "status" to "AVAILABLE", "action" to "camera_launched")
    }

    private fun cameraInfo(): Map<String, Any?> {
        val manager = activity.getSystemService(Context.CAMERA_SERVICE) as android.hardware.camera2.CameraManager
        val cameras = manager.cameraIdList.mapNotNull { id ->
            try {
                val c = manager.getCameraCharacteristics(id)
                val map = c.get(android.hardware.camera2.CameraCharacteristics.LENS_FACING)
                mapOf("id" to id, "lensFacing" to map, "hardwareLevel" to c.get(android.hardware.camera2.CameraCharacteristics.INFO_SUPPORTED_HARDWARE_LEVEL))
            } catch (_: Throwable) { null }
        }
        return if (cameras.isEmpty()) mapOf("available" to false, "status" to "UNAVAILABLE", "reason" to "No camera is available.")
        else mapOf("available" to true, "status" to "AVAILABLE", "cameras" to cameras)
    }

    private fun mediaPlayer(path: String?, mime: String?): Map<String, Any?> {
        if (path.isNullOrBlank()) return mapOf("available" to false, "status" to "UNAVAILABLE", "reason" to "Media path is required.")
        val file = File(path)
        if (!file.exists()) return mapOf("available" to false, "status" to "UNAVAILABLE", "reason" to "Media file does not exist.")
        val intent = Intent(Intent.ACTION_VIEW).apply {
            flags = Intent.FLAG_GRANT_READ_URI_PERMISSION or Intent.FLAG_ACTIVITY_NEW_TASK
            setDataAndType(FileProvider.getUriForFile(activity, activity.packageName + ".zion.files", file), mime ?: "*/*")
        }
        if (intent.resolveActivity(activity.packageManager) == null) return mapOf("available" to false, "status" to "UNAVAILABLE", "reason" to "No compatible media player is installed.")
        activity.startActivity(intent)
        return mapOf("available" to true, "status" to "AVAILABLE")
    }

    private fun audioRecord(stop: Boolean): Map<String, Any?> {
        if (stop) {
            val r = recorder ?: return mapOf("available" to false, "status" to "UNAVAILABLE", "reason" to "No active recording.")
            return try {
                r.stop(); r.reset(); r.release(); recorder = null
                mapOf("available" to true, "status" to "AVAILABLE", "path" to recordingFile?.absolutePath)
            } catch (t: Throwable) {
                recorder = null; mapOf("available" to false, "status" to "UNAVAILABLE", "reason" to (t.message ?: "Recording failed."))
            }
        }
        if (!PermissionHelper.microphone(activity)) return mapOf("available" to false, "status" to "PERMISSION_REQUIRED", "reason" to "Microphone permission requested.")
        if (recorder != null) return mapOf("available" to false, "status" to "UNAVAILABLE", "reason" to "A recording is already active.")
        val file = File(activity.cacheDir, "zion-audio-" + System.currentTimeMillis() + ".m4a")
        val r = if (Build.VERSION.SDK_INT >= 31) MediaRecorder(activity) else MediaRecorder()
        return try {
            r.setAudioSource(MediaRecorder.AudioSource.MIC)
            r.setOutputFormat(MediaRecorder.OutputFormat.MPEG_4)
            r.setAudioEncoder(MediaRecorder.AudioEncoder.AAC)
            r.setAudioEncodingBitRate(128000); r.setAudioSamplingRate(44100); r.setOutputFile(file.absolutePath)
            r.prepare(); r.start(); recorder = r; recordingFile = file
            mapOf("available" to true, "status" to "AVAILABLE", "recording" to true, "path" to file.absolutePath)
        } catch (t: Throwable) {
            r.release(); mapOf("available" to false, "status" to "UNAVAILABLE", "reason" to (t.message ?: "Unable to start recording."))
        }
    }

    private fun location(): Map<String, Any?> {
        if (!PermissionHelper.location(activity)) return mapOf("available" to false, "status" to "PERMISSION_REQUIRED", "reason" to "Location permission requested.")
        val manager = activity.getSystemService(Context.LOCATION_SERVICE) as LocationManager
        val provider = when { manager.isProviderEnabled(LocationManager.GPS_PROVIDER) -> LocationManager.GPS_PROVIDER
            manager.isProviderEnabled(LocationManager.NETWORK_PROVIDER) -> LocationManager.NETWORK_PROVIDER else -> null }
            ?: return mapOf("available" to false, "status" to "UNAVAILABLE", "reason" to "No location provider is enabled.")
        val l = try { manager.getLastKnownLocation(provider) } catch (_: SecurityException) { null }
            ?: return mapOf("available" to false, "status" to "UNAVAILABLE", "reason" to "No cached location is available.")
        return mapOf("available" to true, "status" to "AVAILABLE", "latitude" to l.latitude, "longitude" to l.longitude, "accuracyM" to l.accuracy, "provider" to provider, "timestampMs" to l.time)
    }

    private fun gpsStatus(): Map<String, Any?> {
        val manager = activity.getSystemService(Context.LOCATION_SERVICE) as LocationManager
        return mapOf("available" to true, "status" to "AVAILABLE", "gpsEnabled" to manager.isProviderEnabled(LocationManager.GPS_PROVIDER), "networkEnabled" to manager.isProviderEnabled(LocationManager.NETWORK_PROVIDER))
    }

    private fun notification(call: MethodCall): Map<String, Any?> {
        if (Build.VERSION.SDK_INT >= 33 && !PermissionHelper.notifications(activity)) return mapOf("available" to false, "status" to "PERMISSION_REQUIRED", "reason" to "Notification permission requested.")
        val title = call.argument<String>("title") ?: "Zion OS"; val text = call.argument<String>("content") ?: ""
        val id = call.argument<String>("channelId") ?: "zion_api"
        val nm = activity.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        if (Build.VERSION.SDK_INT >= 26) nm.createNotificationChannel(NotificationChannel(id, "Zion API", NotificationManager.IMPORTANCE_DEFAULT))
        nm.notify((System.currentTimeMillis() and 0x7fffffff).toInt(), NotificationCompat.Builder(activity, id).setSmallIcon(activity.applicationInfo.icon).setContentTitle(title).setContentText(text).setAutoCancel(true).build())
        return mapOf("available" to true, "status" to "AVAILABLE")
    }

    private fun toast(text: String): Map<String, Any?> { activity.runOnUiThread { Toast.makeText(activity, text, Toast.LENGTH_SHORT).show() }; return mapOf("available" to true, "status" to "AVAILABLE") }

    private fun dialog(call: MethodCall, result: MethodChannel.Result) {
        activity.runOnUiThread {
            val edit = android.widget.EditText(activity).apply { setText(call.argument<String>("value") ?: ""); hint = call.argument<String>("hint") ?: "" }
            AlertDialog.Builder(activity).setTitle(call.argument<String>("title") ?: "Zion OS").setMessage(call.argument<String>("message") ?: "")
                .setView(edit).setPositiveButton(call.argument<String>("positive") ?: "OK") { _, _ -> result.success(mapOf("available" to true, "status" to "AVAILABLE", "action" to "positive", "text" to edit.text.toString())) }
                .setNegativeButton(call.argument<String>("negative") ?: "Cancel") { _, _ -> result.success(mapOf("available" to true, "status" to "AVAILABLE", "action" to "negative")) }
                .setOnCancelListener { result.success(mapOf("available" to true, "status" to "AVAILABLE", "action" to "cancel")) }.show()
        }
    }

    private fun vibrate(duration: Long): Map<String, Any?> {
        val v = activity.getSystemService(Context.VIBRATOR_SERVICE) as Vibrator
        if (!v.hasVibrator()) return mapOf("available" to false, "status" to "UNAVAILABLE", "reason" to "Vibrator is not available.")
        if (Build.VERSION.SDK_INT >= 26) v.vibrate(VibrationEffect.createOneShot(duration.coerceIn(1,10000), VibrationEffect.DEFAULT_AMPLITUDE)) else @Suppress("DEPRECATION") v.vibrate(duration.coerceIn(1,10000))
        return mapOf("available" to true, "status" to "AVAILABLE")
    }

    private fun ttsSpeak(text: String): Map<String, Any?> {
        if (text.isBlank()) return mapOf("available" to false, "status" to "UNAVAILABLE", "reason" to "Text is empty.")
        if (tts == null) tts = TextToSpeech(activity) { if (it == TextToSpeech.SUCCESS) tts?.language = Locale.getDefault() }
        tts?.speak(text, TextToSpeech.QUEUE_FLUSH, null, "zion-" + System.currentTimeMillis())
        return mapOf("available" to true, "status" to "AVAILABLE")
    }
    private fun ttsStop(): Map<String, Any?> { tts?.stop(); return mapOf("available" to true, "status" to "AVAILABLE") }

    private fun smsList(): Map<String, Any?> {
        if (!PermissionHelper.smsRead(activity)) return mapOf("available" to false, "status" to "PERMISSION_REQUIRED", "reason" to "SMS read permission requested.")
        val resolver = activity.contentResolver; val list = mutableListOf<Map<String, Any?>>()
        resolver.query(Uri.parse("content://sms"), arrayOf("address","body","date","type"), null, null, "date DESC")?.use { c ->
            val address = c.getColumnIndex("address"); val body = c.getColumnIndex("body"); val date = c.getColumnIndex("date"); val type = c.getColumnIndex("type")
            var count=0; while(c.moveToNext() && count++<200) list += mapOf("address" to c.getString(address), "body" to c.getString(body), "dateMs" to c.getLong(date), "type" to c.getInt(type))
        }
        return mapOf("available" to true, "status" to "AVAILABLE", "messages" to list)
    }

    private fun smsSend(number: String, body: String): Map<String, Any?> {
        if (number.isBlank() || body.isBlank()) return mapOf("available" to false, "status" to "UNAVAILABLE", "reason" to "Number and body are required.")
        if (!PermissionHelper.smsSend(activity)) return mapOf("available" to false, "status" to "PERMISSION_REQUIRED", "reason" to "SMS send permission requested.")
        SmsManager.getDefault().sendTextMessage(number, null, body, null, null)
        return mapOf("available" to true, "status" to "AVAILABLE")
    }

    private fun callPhone(number: String): Map<String, Any?> {
        if (number.isBlank()) return mapOf("available" to false, "status" to "UNAVAILABLE", "reason" to "Phone number is required.")
        if (!PermissionHelper.call(activity)) return mapOf("available" to false, "status" to "PERMISSION_REQUIRED", "reason" to "Phone call permission requested.")
        val intent = Intent(Intent.ACTION_CALL, Uri.parse("tel:" + Uri.encode(number)))
        if (intent.resolveActivity(activity.packageManager) == null) return mapOf("available" to false, "status" to "UNAVAILABLE", "reason" to "No dialer is available.")
        activity.startActivity(intent); return mapOf("available" to true, "status" to "AVAILABLE", "action" to "dialer_opened")
    }

    private fun contactsList(): Map<String, Any?> {
        if (!PermissionHelper.contacts(activity)) return mapOf("available" to false, "status" to "PERMISSION_REQUIRED", "reason" to "Contacts permission requested.")
        val list=mutableListOf<Map<String,Any?>>(); val cr=activity.contentResolver
        cr.query(ContactsContract.Contacts.CONTENT_URI, arrayOf(ContactsContract.Contacts._ID,ContactsContract.Contacts.DISPLAY_NAME,ContactsContract.Contacts.HAS_PHONE_NUMBER), null,null,ContactsContract.Contacts.DISPLAY_NAME+" ASC")?.use { c ->
            var count=0; while(c.moveToNext() && count++<1000) list += mapOf("id" to c.getString(0), "name" to c.getString(1), "hasPhone" to (c.getInt(2)==1))
        }
        return mapOf("available" to true, "status" to "AVAILABLE", "contacts" to list)
    }

    private fun setupStorage(): Map<String, Any?> {
        val root = Environment.getExternalStorageDirectory()
        if (!root.exists()) return mapOf("available" to false, "status" to "UNAVAILABLE", "reason" to "External storage unavailable.")
        val base = File(activity.filesDir, "storage")
        val dirs = mapOf("shared" to root.absolutePath, "downloads" to Environment.DIRECTORY_DOWNLOADS, "dcim" to Environment.DIRECTORY_DCIM, "pictures" to Environment.DIRECTORY_PICTURES, "music" to Environment.DIRECTORY_MUSIC, "movies" to Environment.DIRECTORY_MOVIES, "documents" to Environment.DIRECTORY_DOCUMENTS)
        dirs.forEach { (name, system) -> File(base, name).mkdirs() }
        return mapOf("available" to true, "status" to "AVAILABLE", "path" to root.absolutePath, "zionStorage" to base.absolutePath, "directories" to dirs.keys.toList(),
            "note" to "Scoped Storage/SAF remains authoritative on modern Android.")
    }

    private fun storageGet(): Map<String, Any?> {
        val stat = StatFs(Environment.getExternalStorageDirectory().path)
        return mapOf("available" to true, "status" to "AVAILABLE", "path" to Environment.getExternalStorageDirectory().absolutePath,
            "totalBytes" to stat.totalBytes, "availableBytes" to stat.availableBytes, "freeBytes" to stat.freeBytes)
    }

    private fun fileShare(path: String, mime: String): Map<String, Any?> {
        val file=File(path); if(!file.exists()) return mapOf("available" to false,"status" to "UNAVAILABLE","reason" to "File does not exist.")
        val uri=FileProvider.getUriForFile(activity, activity.packageName+".zion.files",file)
        val intent=Intent(Intent.ACTION_SEND).apply { type=mime; putExtra(Intent.EXTRA_STREAM,uri); addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION) }
        if(intent.resolveActivity(activity.packageManager)==null) return mapOf("available" to false,"status" to "UNAVAILABLE","reason" to "No compatible share target is installed.")
        activity.startActivity(Intent.createChooser(intent,"Share with Zion OS"))
        return mapOf("available" to true,"status" to "AVAILABLE")
    }

    private fun fingerprint(result: MethodChannel.Result) {
        val authenticators=BiometricManager.Authenticators.BIOMETRIC_STRONG or BiometricManager.Authenticators.BIOMETRIC_WEAK
        if(BiometricManager.from(activity).canAuthenticate(authenticators)!=BiometricManager.BIOMETRIC_SUCCESS){ result.success(mapOf("available" to false,"status" to "UNAVAILABLE","reason" to "Biometric authentication is unavailable or not enrolled.")); return }
        val executor=ContextCompat.getMainExecutor(activity)
        BiometricPrompt(activity as androidx.fragment.app.FragmentActivity,executor,object:BiometricPrompt.AuthenticationCallback(){
            override fun onAuthenticationSucceeded(r:BiometricPrompt.AuthenticationResult){result.success(mapOf("available" to true,"status" to "AVAILABLE","authenticated" to true))}
            override fun onAuthenticationError(code:Int,err:CharSequence){result.success(mapOf("available" to false,"status" to "UNAVAILABLE","authenticated" to false,"reason" to err.toString()))}
        }).authenticate(BiometricPrompt.PromptInfo.Builder().setTitle("Zion OS").setSubtitle("Authenticate").setNegativeButtonText("Cancel").build())
    }

    private fun keystore(alias: String): Map<String, Any?> {
        val ks=java.security.KeyStore.getInstance("AndroidKeyStore").apply { load(null) }
        if(!ks.containsAlias(alias)){
            val gen=javax.crypto.KeyGenerator.getInstance("AES","AndroidKeyStore")
            gen.init(android.security.keystore.KeyGenParameterSpec.Builder(alias,android.security.keystore.KeyProperties.PURPOSE_ENCRYPT or android.security.keystore.KeyProperties.PURPOSE_DECRYPT).setBlockModes(android.security.keystore.KeyProperties.BLOCK_MODE_GCM).setEncryptionPaddings(android.security.keystore.KeyProperties.ENCRYPTION_PADDING_NONE).build())
            gen.generateKey()
        }
        return mapOf("available" to true,"status" to "AVAILABLE","alias" to alias,"provider" to "AndroidKeyStore")
    }

    private fun wakeLock(enabled: Boolean): Map<String, Any?> {
        val pm=activity.getSystemService(Context.POWER_SERVICE) as PowerManager
        if(enabled){if(wakeLock?.isHeld!=true) wakeLock=pm.newWakeLock(PowerManager.PARTIAL_WAKE_LOCK,"ZionOS:API").apply{setReferenceCounted(false);acquire()}}
        else {wakeLock?.let{if(it.isHeld)it.release()};wakeLock=null}
        return mapOf("available" to true,"status" to "AVAILABLE","enabled" to enabled)
    }

    private fun jobScheduler(id: Int, delayMs: Long): Map<String, Any?> {
        val js=activity.getSystemService(Context.JOB_SCHEDULER_SERVICE) as android.app.job.JobScheduler
        val service=ComponentName(activity, ZionJobService::class.java)
        val job=android.app.job.JobInfo.Builder(id,service).setMinimumLatency(delayMs.coerceAtLeast(0)).setPersisted(false).build()
        js.schedule(job)
        return mapOf("available" to true,"status" to "AVAILABLE","jobId" to id,"delayMs" to delayMs)
    }

    private fun brightness(value: Int?): Map<String, Any?> {
        if(value==null) return mapOf("available" to false,"status" to "UNAVAILABLE","reason" to "Brightness value 0..255 is required.")
        if(!Settings.System.canWrite(activity)) return mapOf("available" to false,"status" to "PERMISSION_REQUIRED","reason" to "WRITE_SETTINGS permission required.","settingsAction" to Settings.ACTION_MANAGE_WRITE_SETTINGS)
        Settings.System.putInt(activity.contentResolver,Settings.System.SCREEN_BRIGHTNESS,value.coerceIn(0,255))
        return mapOf("available" to true,"status" to "AVAILABLE","value" to value.coerceIn(0,255))
    }

    fun dispose() {
        recorder?.let { try { it.stop() } catch (_: Throwable) {}; it.release() }; recorder=null
        tts?.stop(); tts?.shutdown(); tts=null
        wakeLock?.let { if(it.isHeld)it.release() }; wakeLock=null
    }
}
