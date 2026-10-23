package com.zion.os

import android.util.Log
import java.io.File
import java.util.concurrent.TimeUnit

/**
 * Optional Magisk/su capability probe for Zion OS.
 *
 * Detection is metadata-only and never attempts to obtain root. Root is
 * requested only after an explicit user action, through the installed su
 * manager. A discovered binary is only a hint; only a successful "id" probe
 * confirms that the manager granted UID 0. SELinux is never disabled.
 */
internal object RootAccessManager {
    private const val TAG = "ZionRoot"
    private val knownSuPaths = listOf(
        "/system/bin/su",
        "/system/xbin/su",
        "/sbin/su",
        "/su/bin/su",
        "/debug_ramdisk/su",
        "/data/adb/magisk/su",
        "/data/adb/ksu/bin/su",
    )

    private fun findSuPath(): String? {
        val pathEntries = System.getenv("PATH")
            .orEmpty()
            .split(File.pathSeparator)
            .filter { it.isNotBlank() }
            .map { "$it/su" }
        return (knownSuPaths + pathEntries)
            .distinct()
            .firstOrNull { candidate ->
                try {
                    File(candidate).let { it.isFile && it.canExecute() }
                } catch (_: Throwable) {
                    false
                }
            }
    }

    fun detect(): Map<String, Any?> {
        val path = findSuPath()
        return mapOf(
            "available" to (path != null),
            "suPath" to path,
            "granted" to false,
            "requested" to false,
            "message" to if (path == null) {
                "No executable su binary was found in known locations or PATH. This does not prove the bootloader state."
            } else {
                "A possible su binary was found at $path. Root is not confirmed until the user explicitly requests access."
            }
        )
    }

    fun request(): Map<String, Any?> {
        var process: Process? = null
        val suPath = findSuPath() ?: "su"
        return try {
            val child = ProcessBuilder(suPath, "-c", "id")
                .redirectErrorStream(true)
                .start()
            process = child
            if (!child.waitFor(8, TimeUnit.SECONDS)) {
                child.destroyForcibly()
                mapOf(
                    "available" to true,
                    "suPath" to suPath,
                    "granted" to false,
                    "requested" to true,
                    "message" to "The su authorization request timed out."
                )
            } else {
                val output = child.inputStream.bufferedReader().use { it.readText().trim() }
                val granted = child.exitValue() == 0 &&
                    Regex("(^|\\s)uid=0(?:\\(|\\s|$)").containsMatchIn(output)
                mapOf(
                    "available" to true,
                    "suPath" to suPath,
                    "granted" to granted,
                    "requested" to true,
                    "output" to output.take(512),
                    "message" to if (granted) {
                        "Root access was granted by the installed su manager."
                    } else {
                        "Root access was denied or su is unavailable."
                    }
                )
            }
        } catch (t: Throwable) {
            Log.i(TAG, "Optional root request unavailable: ${t.javaClass.simpleName}: ${t.message}")
            mapOf(
                "available" to (findSuPath() != null),
                "suPath" to findSuPath(),
                "granted" to false,
                "requested" to true,
                "message" to "Unable to request root access: ${t.message ?: t.javaClass.simpleName}"
            )
        } finally {
            try { process?.destroy() } catch (_: Throwable) {}
        }
    }
}
