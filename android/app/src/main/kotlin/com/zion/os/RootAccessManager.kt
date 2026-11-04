package com.zion.os

import android.content.Context
import android.util.Log
import java.io.File
import java.io.FileInputStream
import java.nio.ByteBuffer
import java.nio.ByteOrder
import java.util.concurrent.TimeUnit

/**
 * Optional root and native-payload diagnostics for Zion OS.
 *
 * Detection is metadata-only. Third-party native payloads are never loaded or
 * executed by this class. A discovered su binary is only a hint; only a
 * successful explicit "su -c id" request confirms UID 0. SELinux is untouched.
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

    private val optionalNativePayloads = listOf("libextract.so", "libghostlock.so")

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

    /**
     * Reports whether optional payloads are packaged in the app's native
     * library search paths and whether their ELF headers match 64-bit AArch64.
     * This is strictly a read-only inventory: no System.load/loadLibrary,
     * JNI entry point, subprocess, or payload execution is attempted.
     */
    private fun inspectOptionalNativePayloads(context: Context): Map<String, Any?> {
        // Include Android's authoritative APK native-library directory first.
        val nativeDir = File(context.applicationInfo.nativeLibraryDir)
        val libraryDirs = (listOf(nativeDir) + System.getProperty("java.library.path")
            .orEmpty()
            .split(File.pathSeparator)
            .filter { it.isNotBlank() }
            .map { File(it) })
            .distinctBy { it.absolutePath }

        val payloads = optionalNativePayloads.associateWith { name ->
            val file = libraryDirs.asSequence()
                .map { File(it, name) }
                .firstOrNull { it.isFile }
            if (file == null) {
                mapOf(
                    "present" to false,
                    "sizeBytes" to 0L,
                    "elf64" to false,
                    "aarch64" to false,
                    "loaded" to false,
                    "executed" to false,
                )
            } else {
                var elf64 = false
                var aarch64 = false
                try {
                    FileInputStream(file).use { input ->
                        val header = ByteArray(20)
                        var offset = 0
                        while (offset < header.size) {
                            val count = input.read(header, offset, header.size - offset)
                            if (count <= 0) break
                            offset += count
                        }
                        if (offset >= header.size &&
                            header[0] == 0x7f.toByte() &&
                            header[1] == 'E'.code.toByte() &&
                            header[2] == 'L'.code.toByte() &&
                            header[3] == 'F'.code.toByte()
                        ) {
                            elf64 = header[4] == 2.toByte()
                            val endian = if (header[5] == 1.toByte()) ByteOrder.LITTLE_ENDIAN else ByteOrder.BIG_ENDIAN
                            val machine = ByteBuffer.wrap(header, 18, 2).order(endian).short.toInt() and 0xffff
                            aarch64 = machine == 183
                        }
                    }
                } catch (t: Throwable) {
                    Log.i(TAG, "Could not inspect native payload header for $name: ${t.javaClass.simpleName}")
                }
                mapOf(
                    "present" to true,
                    "path" to file.absolutePath,
                    "sizeBytes" to file.length(),
                    "elf64" to elf64,
                    "aarch64" to aarch64,
                    "abiCompatible" to (elf64 && aarch64),
                    "loaded" to false,
                    "executed" to false,
                    "integration" to "inventory-only; not a JNI library API",
                )
            }
        }
        val presentCount = payloads.values.count { it["present"] == true }
        return mapOf(
            "status" to if (presentCount == optionalNativePayloads.size) "BOTH_PRESENT_NOT_LOADED" else if (presentCount > 0) "PARTIAL" else "NOT_FOUND",
            "librarySearchPaths" to libraryDirs.map { it.absolutePath },
            "payloads" to payloads,
            "note" to "Presence and ELF headers are checked only. These payloads are not loaded or executed and no root capability is inferred."
        )
    }

    fun detect(context: Context): Map<String, Any?> {
        val path = findSuPath()
        return mapOf(
            "available" to (path != null),
            "suPath" to path,
            "granted" to false,
            "requested" to false,
            "nativePayloads" to inspectOptionalNativePayloads(context),
            "message" to if (path == null) {
                "No executable su binary was found in known locations or PATH. This does not prove the bootloader state."
            } else {
                "A possible su binary was found at $path. Root is not confirmed until the user explicitly requests access."
            }
        )
    }

    fun request(context: Context): Map<String, Any?> {
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
                    "nativePayloads" to inspectOptionalNativePayloads(context),
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
                    "nativePayloads" to inspectOptionalNativePayloads(context),
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
                "nativePayloads" to inspectOptionalNativePayloads(context),
                "message" to "Unable to request root access: ${t.message ?: t.javaClass.simpleName}"
            )
        } finally {
            try { process?.destroy() } catch (_: Throwable) {}
        }
    }
}
