package com.zion.os

import android.util.Log
import java.io.File
import java.util.concurrent.TimeUnit

/**
 * Optional Magisk/su capability probe for Zion OS.
 * Detection is metadata-only. Root is requested only by explicit user action.
 * SELinux is never disabled.
 */
internal object RootAccessManager {
    private const val TAG = "ZionRoot"
    private val knownSuPaths = listOf(
        "/system/bin/su", "/system/xbin/su", "/sbin/su",
        "/su/bin/su", "/debug_ramdisk/su"
    )

    fun detect(): Map<String, Any?> {
        val path = knownSuPaths.firstOrNull { File(it).canExecute() }
        return mapOf(
            "available" to (path != null),
            "suPath" to path,
            "granted" to false,
            "requested" to false,
            "message" to if (path == null) {
                "No su binary found at common paths; Magisk may expose su through PATH."
            } else {
                "A possible su binary was found. Root permission has not been requested."
            }
        )
    }

    fun request(): Map<String, Any?> {
        var process: Process? = null
        return try {
            val child = ProcessBuilder("su", "-c", "id")
                .redirectErrorStream(true)
                .start()
            process = child
            if (!child.waitFor(8, TimeUnit.SECONDS)) {
                child.destroyForcibly()
                mapOf("available" to true, "granted" to false, "requested" to true,
                    "message" to "The su authorization request timed out.")
            } else {
                val output = child.inputStream.bufferedReader().use { it.readText().trim() }
                val granted = child.exitValue() == 0 &&
                    Regex("(^|\\s)uid=0(?:\\(|\\s|$)").containsMatchIn(output)
                mapOf("available" to true, "granted" to granted, "requested" to true,
                    "output" to output.take(512),
                    "message" to if (granted) "Root access was granted." else "Root access was denied or su is unavailable.")
            }
        } catch (t: Throwable) {
            Log.i(TAG, "Optional root request unavailable: ${t.javaClass.simpleName}: ${t.message}")
            mapOf("available" to knownSuPaths.any { File(it).canExecute() },
                "granted" to false, "requested" to true,
                "message" to "Unable to request root access: ${t.message ?: t.javaClass.simpleName}")
        } finally {
            try { process?.destroy() } catch (_: Throwable) {}
        }
    }
}
