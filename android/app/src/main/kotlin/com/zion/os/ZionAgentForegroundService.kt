package com.zion.os

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.Service
import android.content.Context
import android.content.Intent
import android.os.Build
import android.os.IBinder
import android.os.PowerManager
import androidx.core.app.NotificationCompat
import androidx.core.content.ContextCompat
import java.io.File
import java.util.concurrent.Executors

/**
 * Process-lifetime host for the on-device model session.
 * Native inference is process-wide and must not be owned by an Activity.
 */
class ZionAgentForegroundService : Service() {
    companion object {
        const val ACTION_START = "com.zion.os.AGENT_START"
        const val ACTION_STOP = "com.zion.os.AGENT_STOP"
        const val EXTRA_TASK = "task"
        private const val CHANNEL_ID = "zion_agent_work"
        private const val NOTIFICATION_ID = 4107
        private const val PREFS = "zion_local_ai_session"
        const val KEY_MODEL_PATH = "model_path"
        const val KEY_THREADS = "model_threads"
        const val KEY_LORA_PATH = "lora_path"
        const val KEY_LORA_SCALE = "lora_scale"
        const val KEY_GENERATION_STATUS = "generation_status"
        const val KEY_GENERATION_PROMPT = "generation_prompt"
        const val KEY_GENERATION_TOKENS = "generation_tokens"
        const val KEY_GENERATION_TEMPERATURE = "generation_temperature"
        const val KEY_GENERATION_RETRIES = "generation_retries"
        const val KEY_GENERATION_RESULT = "generation_result"

        // Shared by Activity recreations and Flutter engine reconnects.
        val inferenceExecutor = Executors.newSingleThreadExecutor { r ->
            Thread(r, "zion-local-inference").apply { isDaemon = false }
        }
        val llamaBridge by lazy { com.zion.os.ai.LlamaBridge() }

        fun startSession(context: Context, task: String) {
            val intent = Intent(context, ZionAgentForegroundService::class.java).apply {
                action = ACTION_START
                putExtra(EXTRA_TASK, task)
            }
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                ContextCompat.startForegroundService(context, intent)
            } else {
                context.startService(intent)
            }
        }

        fun sessionPreferences(context: Context) =
            context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
    }

    private var wakeLock: PowerManager.WakeLock? = null

    override fun onCreate() {
        super.onCreate()
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                CHANNEL_ID, "Zion Super Agent", NotificationManager.IMPORTANCE_LOW
            ).apply {
                description = "إشعار استمرار جلسة الذكاء الاصطناعي المحلي"
                setShowBadge(false)
            }
            getSystemService(NotificationManager::class.java).createNotificationChannel(channel)
        }
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        if (intent?.action == ACTION_STOP) {
            inferenceExecutor.execute {
                try {
                    llamaBridge.nativeCancelGeneration()
                    llamaBridge.nativeFreeModel()
                } catch (t: Throwable) {
                    android.util.Log.w("ZionAgent", "Native cleanup after explicit stop failed", t)
                } finally {
                    sessionPreferences(this).edit().clear().apply()
                    releaseInferenceWakeLock()
                    stopForegroundCompat()
                    stopSelf(startId)
                }
            }
            return START_NOT_STICKY
        }

        val task = intent?.getStringExtra(EXTRA_TASK)?.trim().orEmpty()
        startForeground(NOTIFICATION_ID, buildNotification(
            if (task.isBlank()) "جلسة الذكاء الاصطناعي المحلي نشطة" else task
        ))

        // A null sticky restart means Android recreated this service after the
        // process was reclaimed. Restore the model and one interrupted request.
        if (intent == null) {
            inferenceExecutor.execute { restoreInterruptedSession() }
        }
        return START_STICKY
    }

    private fun restoreInterruptedSession() {
        val prefs = sessionPreferences(this)
        val modelPath = prefs.getString(KEY_MODEL_PATH, null)
        if (!modelPath.isNullOrBlank()) {
            val model = File(modelPath)
            if (!model.isFile || !model.canRead()) {
                prefs.edit()
                    .putString(KEY_GENERATION_STATUS, "MODEL_MISSING")
                    .putString(KEY_GENERATION_RESULT, "ERROR: ملف النموذج المحفوظ لم يعد متاحاً.")
                    .apply()
                return
            }
            val loaded = try {
                llamaBridge.nativeIsLoaded() || llamaBridge.nativeLoadModel(
                    modelPath,
                    prefs.getInt(KEY_THREADS, 2),
                    prefs.getString(KEY_LORA_PATH, null),
                    prefs.getFloat(KEY_LORA_SCALE, 1.0f)
                )
            } catch (t: Throwable) {
                android.util.Log.e("ZionAgent", "Model restoration failed", t)
                false
            }
            if (!loaded) {
                prefs.edit()
                    .putString(KEY_GENERATION_STATUS, "RESTORE_FAILED")
                    .putString(KEY_GENERATION_RESULT, "ERROR: تعذرت استعادة النموذج المحلي بعد إعادة تشغيل الجلسة.")
                    .apply()
                return
            }
        }

        if (prefs.getString(KEY_GENERATION_STATUS, "") != "RUNNING") return
        if (prefs.getInt(KEY_GENERATION_RETRIES, 0) >= 1) {
            prefs.edit()
                .putString(KEY_GENERATION_STATUS, "INTERRUPTED")
                .putString(KEY_GENERATION_RESULT, "ERROR: توقفت عملية التوليد مرتين؛ أعد إرسال الطلب يدوياً.")
                .apply()
            return
        }

        val prompt = prefs.getString(KEY_GENERATION_PROMPT, null).orEmpty()
        if (prompt.isBlank() || !tryAcquireInferenceWakeLock()) {
            prefs.edit()
                .putString(KEY_GENERATION_STATUS, "INTERRUPTED")
                .putString(KEY_GENERATION_RESULT, "ERROR: تعذر استئناف الطلب المحفوظ.")
                .apply()
            return
        }

        prefs.edit().putInt(KEY_GENERATION_RETRIES, 1).apply()
        val response = try {
            llamaBridge.nativeGenerate(
                prompt,
                prefs.getInt(KEY_GENERATION_TOKENS, 512),
                prefs.getFloat(KEY_GENERATION_TEMPERATURE, 0.7f)
            )
        } catch (t: Throwable) {
            "ERROR: ${t.message ?: "local inference recovery failed"}"
        }
        prefs.edit()
            .putString(KEY_GENERATION_STATUS, if (response.startsWith("ERROR:")) "FAILED" else "COMPLETED")
            .putString(KEY_GENERATION_RESULT, response)
            .putLong("generation_completed_at", System.currentTimeMillis())
            .apply()
        releaseInferenceWakeLock()
    }

    fun tryAcquireInferenceWakeLock(): Boolean = try {
        val manager = getSystemService(Context.POWER_SERVICE) as PowerManager
        val lock = wakeLock ?: manager.newWakeLock(
            PowerManager.PARTIAL_WAKE_LOCK, "ZionOS:LocalAIInference"
        ).also { wakeLock = it }
        if (!lock.isHeld) lock.acquire(2 * 60 * 60 * 1000L)
        true
    } catch (t: Throwable) {
        android.util.Log.e("ZionAgent", "Could not acquire inference wake lock", t)
        false
    }

    fun releaseInferenceWakeLock() {
        try { wakeLock?.let { if (it.isHeld) it.release() } } catch (_: Throwable) { }
    }

    private fun buildNotification(message: String): Notification =
        NotificationCompat.Builder(this, CHANNEL_ID)
            .setSmallIcon(android.R.drawable.stat_notify_sync)
            .setContentTitle("Zion Super Agent")
            .setContentText(message.take(120))
            .setStyle(NotificationCompat.BigTextStyle().bigText(message))
            .setCategory(NotificationCompat.CATEGORY_SERVICE)
            .setOngoing(true)
            .setOnlyAlertOnce(true)
            .setProgress(0, 0, true)
            .build()

    private fun stopForegroundCompat() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) stopForeground(STOP_FOREGROUND_REMOVE)
        else {
            @Suppress("DEPRECATION")
            stopForeground(true)
        }
    }

    override fun onTaskRemoved(rootIntent: Intent?) {
        // Keep the explicitly user-started session alive after task swipe-away.
        super.onTaskRemoved(rootIntent)
    }

    override fun onDestroy() {
        releaseInferenceWakeLock()
        // Do not free the model here; START_STICKY recovery needs its saved path.
        super.onDestroy()
    }

    override fun onBind(intent: Intent?): IBinder? = null
}
