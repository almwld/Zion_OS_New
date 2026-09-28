package com.zion.os.utils

import org.json.JSONObject

object JsonHelper {
    fun unavailable(reason: String, status: String = "UNAVAILABLE"): Map<String, Any?> =
        mapOf("available" to false, "status" to status, "reason" to reason)

    fun available(data: Map<String, Any?> = emptyMap()): Map<String, Any?> =
        buildMap { put("available", true); put("status", "AVAILABLE"); putAll(data) }

    fun json(data: Map<String, Any?>): String = JSONObject(data).toString()
}
