package com.zion.os

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.Service
import android.content.Intent
import android.os.Build
import android.os.IBinder
import androidx.core.app.NotificationCompat

/**
 * Keeps the app process important while an already-running Super Agent task
 * continues in the Flutter engine. It does not execute agent code itself.
 */
class ZionAgentForegroundService : Service() {
    companion object {
        const val ACTION_START = "com.zion.os.AGENT_START"
        const val ACTION_STOP = "com.zion.os.AGENT_STOP"
        const val EXTRA_TASK = "task"
        private const val CHANNEL_ID = "zion_agent_work"
        private const val NOTIFICATION_ID = 4107
    }

    override fun onCreate() {
        super.onCreate()
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                CHANNEL_ID,
                "Zion Super Agent",
                NotificationManager.IMPORTANCE_LOW
            ).apply {
                description = "إشعار استمرار تنفيذ مهام الوكلاء المحليين"
                setShowBadge(false)
            }
            getSystemService(NotificationManager::class.java).createNotificationChannel(channel)
        }
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        when (intent?.action) {
            ACTION_STOP -> {
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
                    stopForeground(STOP_FOREGROUND_REMOVE)
                } else {
                    @Suppress("DEPRECATION")
                    stopForeground(true)
                }
                stopSelf()
                return START_NOT_STICKY
            }
            ACTION_START -> {
                val task = intent.getStringExtra(EXTRA_TASK)?.trim().orEmpty()
                val notification: Notification = NotificationCompat.Builder(this, CHANNEL_ID)
                    .setSmallIcon(android.R.drawable.stat_notify_sync)
                    .setContentTitle("Zion Super Agent")
                    .setContentText(if (task.isBlank()) "مهمة محلية قيد التنفيذ" else task.take(120))
                    .setStyle(NotificationCompat.BigTextStyle().bigText(
                        if (task.isBlank()) "تستمر جلسة الوكلاء أثناء التنقل بين الشاشات."
                        else "تستمر جلسة الوكلاء أثناء التنقل بين الشاشات: $task"
                    ))
                    .setCategory(NotificationCompat.CATEGORY_SERVICE)
                    .setOngoing(true)
                    .setOnlyAlertOnce(true)
                    .setProgress(0, 0, true)
                    .build()
                startForeground(NOTIFICATION_ID, notification)
                return START_STICKY
            }
            else -> {
                stopSelf()
                return START_NOT_STICKY
            }
        }
    }

    override fun onBind(intent: Intent?): IBinder? = null
}
