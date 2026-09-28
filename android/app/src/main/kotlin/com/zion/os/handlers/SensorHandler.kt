package com.zion.os.handlers

import android.content.Context
import android.hardware.Sensor
import android.hardware.SensorManager

class SensorHandler(context: Context) {
    private val manager = context.getSystemService(Context.SENSOR_SERVICE) as SensorManager
    fun list(type: Int? = null): Map<String, Any?> {
        val sensors = if (type == null) manager.getSensorList(Sensor.TYPE_ALL) else manager.getSensorList(type)
        return mapOf("available" to sensors.isNotEmpty(), "status" to if (sensors.isNotEmpty()) "AVAILABLE" else "UNAVAILABLE",
            "sensors" to sensors.map { mapOf("type" to it.type, "name" to it.name, "vendor" to it.vendor, "version" to it.version, "resolution" to it.resolution, "maxRange" to it.maximumRange, "minDelayUs" to it.minDelay) })
    }
}
