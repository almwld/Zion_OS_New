package com.zion.os

import android.content.Context
import android.system.Os
import android.util.Log
import com.termux.app.TermuxInstaller
import java.io.BufferedReader
import java.io.ByteArrayInputStream
import java.io.File
import java.io.FileOutputStream
import java.io.RandomAccessFile
import java.io.InputStreamReader
import java.util.zip.ZipInputStream

/**
 * Installs the Termux bootstrap payload into Zion's private PREFIX on first
 * terminal launch. Existing non-empty prefixes are never recursively deleted
 * or overwritten: an incomplete prefix is reported for diagnosis instead.
 */
internal object TermuxBootstrapInstaller {
    private const val TAG = "ZionBootstrap"
    private const val BOOTSTRAP_BLOB_OFFSET = 0x520L
    private const val BOOTSTRAP_BLOB_SIZE = 0x1766da7L
    private const val MAX_ARCHIVE_BYTES = 512L * 1024L * 1024L
    private const val MAX_ENTRIES = 100_000
    private const val MAX_UNCOMPRESSED_BYTES = 512L * 1024L * 1024L

    @Synchronized
    fun ensureInstalled(context: Context): Map<String, Any?> {
        val files = context.filesDir
        val prefix = File(files, "usr")
        val bash = File(prefix, "bin/bash")
        val bashReal = File(prefix, "bin/bash.real")
        if (isBashBinary(bash) || isBashBinary(bashReal)) {
            return try {
                configureBashRuntime(prefix, files)
                report(true, "already-installed-runtime-configured",
                    "Termux Bootstrap موجود؛ تم تجهيز zion-bashrc وBash launcher دون إعادة استخراج usr.",
                    prefix, File(prefix, "bin/bash"))
            } catch (t: Throwable) {
                Log.e(TAG, "Unable to configure existing Bash runtime", t)
                report(false, "bash-runtime-configuration-failed",
                    "تعذر إعداد Bash runtime: ${t.javaClass.simpleName}: ${t.message}",
                    prefix, File(prefix, "bin/bash"))
            }
        }

        // Do not overlay a partial installation. It may contain user data,
        // packages, or evidence needed to diagnose why Bash is missing.
        if (prefix.exists() && prefix.isDirectory && (prefix.list()?.isNotEmpty() == true)) {
            return report(false, "preserved-prefix-conflict",
                "مجلد usr موجود وغير فارغ لكن Bash غير صالح؛ احتُفظ بكل الملفات ولم يُستبدل المجلد.",
                prefix, bash)
        }
        if (prefix.exists() && !prefix.isDirectory) {
            return report(false, "prefix-path-conflict", "المسار usr موجود لكنه ليس مجلدًا؛ لم يُحذف.",
                prefix, bash)
        }

        val staging = File(files, "usr.bootstrap-staging")
        try {
            val archive = try {
                loadBootstrapArchive(context)
            } catch (t: Throwable) {
                Log.e(TAG, "Unable to read Termux Bootstrap ZIP stream from JNI or ELF blob", t)
                return report(false, "bootstrap-library-load-failed",
                    "تعذر قراءة Bootstrap من JNI أو من ZIP blob داخل المكتبة: ${t.javaClass.simpleName}: ${t.message}",
                    prefix, bash)
            }
            if (archive.isEmpty() || archive.size.toLong() > MAX_ARCHIVE_BYTES) {
                return report(false, "invalid-archive-size", "حجم أرشيف Bootstrap غير صالح: ${archive.size} bytes.",
                    prefix, bash)
            }

            // A staging directory is isolated from the active PREFIX. If an
            // extraction fails, only staging is removed; existing usr is kept.
            if (staging.exists() && !deleteTreeSafely(staging)) {
                return report(false, "staging-cleanup-failed",
                    "تعذر تنظيف مجلد staging القديم؛ لم يتم لمس usr.", prefix, bash)
            }
            if (!staging.mkdirs() && !staging.isDirectory) {
                return report(false, "staging-create-failed",
                    "تعذر إنشاء مجلد Bootstrap المؤقت: ${staging.absolutePath}", prefix, bash)
            }
            Os.chmod(staging.absolutePath, 448) // 0700

            val symlinks = mutableListOf<Pair<String, String>>()
            var entries = 0
            var extractedBytes = 0L
            val buffer = ByteArray(16 * 1024)
            ZipInputStream(ByteArrayInputStream(archive)).use { zip ->
                while (true) {
                    val entry = zip.nextEntry ?: break
                    if (++entries > MAX_ENTRIES) throw IllegalStateException("Bootstrap has too many entries")
                    val name = entry.name
                    if (name == "SYMLINKS.txt") {
                        // Do not close this reader: it wraps ZipInputStream,
                        // which must remain open for the following ZIP entries.
                        val reader = BufferedReader(InputStreamReader(zip, Charsets.UTF_8))
                        while (true) {
                            val line = reader.readLine() ?: break
                            if (line.isBlank()) continue
                            val split = line.split('←')
                            if (split.size != 2 || split[0].isBlank() || split[1].isBlank()) {
                                throw IllegalStateException("Malformed SYMLINKS.txt line")
                            }
                            val linkFile = safeChild(staging, split[1])
                            val target = rewriteTermuxPrefix(split[0], prefix)
                            symlinks += target to linkFile.absolutePath
                            ensureParent(linkFile.parentFile)
                        }
                    } else {
                        val target = safeChild(staging, name)
                        if (entry.isDirectory) {
                            if (!target.exists() && !target.mkdirs() && !target.isDirectory) {
                                throw IllegalStateException("Cannot create directory: $name")
                            }
                            Os.chmod(target.absolutePath, 448) // 0700
                        } else {
                            ensureParent(target.parentFile)
                            FileOutputStream(target).use { out ->
                                while (true) {
                                    val count = zip.read(buffer)
                                    if (count < 0) break
                                    extractedBytes += count
                                    if (extractedBytes > MAX_UNCOMPRESSED_BYTES) {
                                        throw IllegalStateException("Bootstrap expanded beyond safety limit")
                                    }
                                    out.write(buffer, 0, count)
                                }
                                out.fd.sync()
                            }
                            Os.chmod(target.absolutePath, if (isExecutablePath(name)) 448 else 384)
                        }
                    }
                    zip.closeEntry()
                }
            }

            if (symlinks.isEmpty()) throw IllegalStateException("Bootstrap archive has no SYMLINKS.txt")
            for ((target, link) in symlinks) {
                if (File(link).exists() || readlinkOrNull(link) != null) {
                    throw IllegalStateException("Symlink destination already exists: $link")
                }
                Os.symlink(target, link)
            }

            val stagedBash = File(staging, "bin/bash")
            if (!stagedBash.isFile || stagedBash.length() < 100_000L) {
                throw IllegalStateException("Extracted bootstrap does not contain a valid bin/bash")
            }
            if (!File(staging, "bin/apt").exists()) {
                throw IllegalStateException("Extracted bootstrap does not contain bin/apt")
            }

            // Prefix was absent or empty at entry. Delete only an empty
            // directory, never recursively remove a populated Userland tree.
            if (prefix.exists()) {
                val children = prefix.list()
                if (children == null || children.isNotEmpty()) {
                    throw IllegalStateException("PREFIX changed during install; refusing replacement")
                }
                if (!prefix.delete()) throw IllegalStateException("Cannot remove empty PREFIX directory")
            }
            if (!staging.renameTo(prefix)) throw IllegalStateException("Cannot atomically promote staging to usr")

            listOf("tmp", "var/tmp", "var/cache/apt/archives/partial", "var/lib/apt/lists/partial").forEach {
                val dir = File(prefix, it)
                if (!dir.exists() && !dir.mkdirs() && !dir.isDirectory) {
                    throw IllegalStateException("Cannot create runtime directory: $it")
                }
                Os.chmod(dir.absolutePath, 448)
            }
            File(files, "home").apply { if (!exists()) mkdirs(); Os.chmod(absolutePath, 448) }
            File(files, "tmp").apply { if (!exists()) mkdirs(); Os.chmod(absolutePath, 448) }
            configureBashRuntime(prefix, files)

            return report(true, "installed", "تم استخراج Termux Bootstrap وتجهيز Bash runtime في ${prefix.absolutePath}.",
                prefix, File(prefix, "bin/bash"))
        } catch (t: Throwable) {
            Log.e(TAG, "Bootstrap install failed; preserving active prefix", t)
            try { if (staging.exists()) deleteTreeSafely(staging) } catch (_: Throwable) {}
            return report(false, "bootstrap-extraction-failed",
                "فشل استخراج Bootstrap دون حذف usr: ${t.javaClass.simpleName}: ${t.message}", prefix, bash)
        }
    }

    private fun isBashBinary(file: File): Boolean =
        file.isFile && file.length() >= 100_000L

    /**
     * Keep the real Bash ELF as bash.real and create a small launcher for
     * environments that can invoke scripts. PTY startup itself uses linker64
     * directly because SELinux may reject execve on app-private ELF files.
     */
    private fun configureBashRuntime(prefix: File, files: File) {
        val bin = File(prefix, "bin")
        val etc = File(prefix, "etc")
        if (!bin.isDirectory && !bin.mkdirs()) {
            throw IllegalStateException("Cannot create Userland bin directory")
        }
        if (!etc.isDirectory && !etc.mkdirs()) {
            throw IllegalStateException("Cannot create Userland etc directory")
        }

        val bash = File(bin, "bash")
        val real = File(bin, "bash.real")
        if (!isBashBinary(real)) {
            if (!isBashBinary(bash)) {
                throw IllegalStateException("Neither bin/bash nor bin/bash.real is a valid Bash ELF")
            }
            if (real.exists() && !real.delete()) {
                throw IllegalStateException("Cannot replace invalid bash.real")
            }
            if (!bash.renameTo(real)) {
                throw IllegalStateException("Cannot move Bash ELF to bash.real")
            }
        }

        val launcher = "#!/system/bin/sh\n" +
            "export PREFIX=\"${prefix.absolutePath}\"\n" +
            "export HOME=\"${File(files, "home").absolutePath}\"\n" +
            "export PATH=\"\$PREFIX/bin:\$PREFIX/sbin:/system/bin:/system/xbin:/vendor/bin\"\n" +
            "export LD_LIBRARY_PATH=\"\$PREFIX/lib:\$PREFIX/lib64\"\n" +
            "export BASH_ENV=\"\$PREFIX/etc/zion-bashrc\"\n" +
            "exec /system/bin/linker64 \"${real.absolutePath}\" \"\$@\"\n"
        FileOutputStream(bash).use { out ->
            out.write(launcher.toByteArray(Charsets.UTF_8))
            out.fd.sync()
        }
        Os.chmod(bash.absolutePath, 493) // 0755
        Os.chmod(real.absolutePath, 493) // 0755

        val coreutils = File(bin, "coreutils")
        val rc = StringBuilder()
        rc.appendLine("# Zion interactive Bash configuration")
        rc.appendLine("# External ELF programs are invoked through Android's linker; this is not an SELinux bypass.")
        rc.appendLine("export PREFIX=\"${prefix.absolutePath}\"")
        rc.appendLine("export HOME=\"${File(files, "home").absolutePath}\"")
        rc.appendLine("export PATH=\"\$PREFIX/bin:\$PREFIX/sbin:/system/bin:/system/xbin:/vendor/bin\"")
        rc.appendLine("export LD_LIBRARY_PATH=\"\$PREFIX/lib:\$PREFIX/lib64\"")
        rc.appendLine("export TERM=xterm-256color")
        rc.appendLine("export COLORTERM=truecolor")
        rc.appendLine("export ZION_TERMINAL=1")
        // Non-interactive Bash does not read --init-file/.bashrc. BASH_ENV makes
        // the same linker-backed aliases available to scripts, where direct
        // execve of app-private ELF tools can be denied by Android SELinux.
        rc.appendLine("export BASH_ENV=\"\$PREFIX/etc/zion-bashrc\"")
        rc.appendLine("shopt -s expand_aliases")
        rc.appendLine("alias bash='/system/bin/linker64 \"\$PREFIX/bin/bash.real\"'")
        if (coreutils.isFile) {
            rc.appendLine("alias coreutils='/system/bin/linker64 \"\$PREFIX/bin/coreutils\"'")
            listOf("ls", "cat", "head", "tail", "wc", "sort", "uniq", "cut", "tr", "tee",
                "cp", "mv", "rm", "mkdir", "rmdir", "touch", "chmod", "basename", "dirname",
                "date", "df", "du", "id", "readlink", "realpath", "stat", "test", "whoami").forEach { applet ->
                rc.appendLine("alias $applet='/system/bin/linker64 \"\$PREFIX/bin/coreutils\" --coreutils-prog=$applet'")
            }
        }
        listOf("grep", "sed", "gawk", "find", "python3", "node").forEach { tool ->
            if (File(bin, tool).isFile) {
                rc.appendLine("alias $tool='/system/bin/linker64 \"\$PREFIX/bin/$tool\"'")
            }
        }
        val rcFile = File(etc, "zion-bashrc")
        FileOutputStream(rcFile).use { out ->
            out.write(rc.toString().toByteArray(Charsets.UTF_8))
            out.fd.sync()
        }
        Os.chmod(rcFile.absolutePath, 420) // 0644
    }

    /**
     * Prefer the official JNI accessor. Some packaged builds expose the ZIP
     * payload only as a raw stream embedded in the ELF shared object, without
     * a ZIP central directory/EOCD. ZipInputStream is a streaming reader and
     * does not require the EOCD record.
     */
    private fun loadBootstrapArchive(context: Context): ByteArray {
        // The packaged library's known payload is a raw ZIP stream embedded
        // in an ELF, and intentionally has no ZIP EOCD/central directory.
        // Try this path first; ZipInputStream consumes local entries in order.
        var blobError: Throwable? = null
        val soFile = File(context.applicationInfo.nativeLibraryDir, "libtermux-bootstrap.so")
        try {
            if (soFile.isFile) {
                val offset = BOOTSTRAP_BLOB_OFFSET
                val size = BOOTSTRAP_BLOB_SIZE
                RandomAccessFile(soFile, "r").use { raf ->
                    if (raf.length() < offset + size) {
                        throw IllegalStateException(
                            "Bootstrap ELF is too small for the expected blob: size=${raf.length()}, required=${offset + size}"
                        )
                    }
                    raf.seek(offset)
                    val bytes = ByteArray(size.toInt())
                    raf.readFully(bytes)
                    if (!looksLikeZipStream(bytes)) {
                        throw IllegalStateException("Embedded bootstrap blob does not begin with a ZIP local header")
                    }
                    return bytes
                }
            }
            blobError = IllegalStateException("Bootstrap ELF not found: ${soFile.absolutePath}")
        } catch (t: Throwable) {
            blobError = t
            Log.w(TAG, "Embedded bootstrap blob unavailable; trying JNI getZip", t)
        }

        try {
            val bytes = TermuxInstaller.getZip()
            if (looksLikeZipStream(bytes)) return bytes
            throw IllegalStateException("TermuxInstaller.getZip() returned an invalid ZIP stream", blobError)
        } catch (t: Throwable) {
            throw IllegalStateException("Unable to read bootstrap ZIP stream from ELF blob or JNI", t)
        }
    }

    private fun looksLikeZipStream(bytes: ByteArray): Boolean =
        bytes.size >= 4 &&
            bytes[0] == 0x50.toByte() &&
            bytes[1] == 0x4b.toByte() &&
            bytes[2] == 0x03.toByte() &&
            bytes[3] == 0x04.toByte()

    private fun report(success: Boolean, status: String, message: String, prefix: File, bash: File) =
        mapOf<String, Any?>(
            "success" to success,
            "status" to status,
            "message" to message,
            "prefix" to prefix.absolutePath,
            "prefixExists" to prefix.isDirectory,
            "bashExists" to bash.isFile,
            "bashSizeBytes" to if (bash.isFile) bash.length() else 0L
        )

    private fun safeChild(root: File, relative: String): File {
        if (relative.startsWith("/") || relative.contains('\u0000')) {
            throw IllegalStateException("Unsafe absolute/NUL archive path")
        }
        val rootPath = root.canonicalPath.trimEnd(File.separatorChar)
        val childPath = File(root, relative).canonicalPath
        if (childPath != rootPath && !childPath.startsWith(rootPath + File.separator)) {
            throw IllegalStateException("Archive path escapes staging: $relative")
        }
        return File(root, relative)
    }

    private fun ensureParent(parent: File?) {
        if (parent == null) throw IllegalStateException("Missing parent directory")
        if (!parent.exists() && !parent.mkdirs() && !parent.isDirectory) {
            throw IllegalStateException("Cannot create parent: ${parent.absolutePath}")
        }
    }

    private fun isExecutablePath(name: String): Boolean =
        name.startsWith("bin/") ||
        name.startsWith("libexec/") ||
        name.startsWith("lib/apt/apt-helper") ||
        name.startsWith("lib/apt/methods/")

    private fun rewriteTermuxPrefix(target: String, prefix: File): String =
        target.replace("/data/data/com.termux/files/usr", prefix.absolutePath)
            .replace("/data/user/0/com.termux/files/usr", prefix.absolutePath)
            .replace("/data/user_de/0/com.termux/files/usr", prefix.absolutePath)

    private fun readlinkOrNull(path: String): String? =
        try { Os.readlink(path) } catch (_: Throwable) { null }

    private fun deleteTreeSafely(root: File): Boolean {
        if (!root.exists() && readlinkOrNull(root.absolutePath) == null) return true
        if (root.isDirectory && readlinkOrNull(root.absolutePath) == null) {
            val children = root.listFiles() ?: return false
            for (child in children) if (!deleteTreeSafely(child)) return false
        }
        return root.delete()
    }
}
