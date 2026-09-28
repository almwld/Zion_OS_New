package com.zion.os.handlers

import android.content.Context
import android.content.Intent
import android.os.BatteryManager

class BatteryHandler(private val context: Context) {
    fun info(): Map<String, Any?> {
        val intent = context.registerReceiver(null, android.content.IntentFilter(Intent.ACTION_BATTERY_CHANGED))
            ?: return mapOf("available" to false, "status" to "UNAVAILABLE", "reason" to "Battery service unavailable.")
        val level = intent.getIntExtra(BatteryManager.EXTRA_LEVEL, -1)
        val scale = intent.getIntExtra(BatteryManager.EXTRA_SCALE, 100).coerceAtLeast(1)
        val status = intent.getIntExtra(BatteryManager.EXTRA_STATUS, -1)
        return mapOf(
            "available" to (level >= 0),
            "status" to if (level >= 0) "AVAILABLE" else "UNAVAILABLE",
            "levelPercent" to if (level >= 0) level * 100.0 / scale else -1,
            "charging" to (status == BatteryManager.BATTERY_STATUS_CHARGING || status == BatteryManager.BATTERY_STATUS_FULL),
            "statusCode" to status,
            "temperatureC" to intent.getIntExtra(BatteryManager.EXTRA_TEMPERATURE, 0) / 10.0,
            "voltageMv" to intent.getIntExtra(BatteryManager.EXTRA_VOLTAGE, 0),
            "technology" to intent.getStringExtra(BatteryManager.EXTRA_TECHNOLOGY)
        )
    }
}
