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
                installProotLibs(prefix)
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
        var preserveIncompletePrefix = false
        if (prefix.exists() && prefix.isDirectory && (prefix.list()?.isNotEmpty() == true)) {
            // Remove only a known empty placeholder. Keep populated incomplete
            // PREFIX trees intact until a fully validated replacement is ready.
            if (isEmptyPlaceholderPrefix(prefix)) {
                if (!deleteTreeSafely(prefix)) {
                    return report(false, "placeholder-prefix-cleanup-failed",
                        "تعذر تنظيف مجلد usr المؤقت الفارغ؛ لم يتم حذف أي ملفات.", prefix, bash)
                }
            } else {
                preserveIncompletePrefix = true
            }
        }
        if (prefix.exists() && !prefix.isDirectory) {
            return report(false, "prefix-path-conflict", "المسار usr موجود لكنه ليس مجلدًا؛ لم يُحذف.",
                prefix, bash)
        }

        // The JNI archive reader depends on libtermux-bootstrap.so being
        // packaged in this APK. Check before touching JNI: calling
        // System.loadLibrary when the library is absent poisons the class
        // initializer and caused the same stack trace on every terminal start.
        // The caller can still recover from an existing local Userland backup.
        val bootstrapLibrary = File(context.applicationInfo.nativeLibraryDir, "libtermux-bootstrap.so")
        if (!bootstrapLibrary.isFile || bootstrapLibrary.length() == 0L) {
            return report(
                false,
                "bootstrap-library-missing",
                "مكتبة libtermux-bootstrap.so غير موجودة داخل APK؛ لم تتم محاولة JNI ولم تُمس ملفات usr. استعادة Userland المحلي ما زالت متاحة.",
                prefix,
                bash
            )
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
            if (!isBashBinary(stagedBash)) {
                throw IllegalStateException("Extracted bootstrap bin/bash is not a valid ELF executable")
            }
            if (!File(staging, "bin/apt").exists()) {
                throw IllegalStateException("Extracted bootstrap does not contain bin/apt")
            }

            // Move a populated incomplete PREFIX aside only after the staged archive
            // has passed validation. Keep the backup recoverable; never recursively delete it.
            var incompleteBackup: File? = null
            if (prefix.exists()) {
                val children = prefix.list() ?: throw IllegalStateException("Cannot inspect PREFIX before promotion")
                if (children.isNotEmpty()) {
                    if (!preserveIncompletePrefix) throw IllegalStateException("PREFIX changed during install; refusing replacement")
                    val backup = File(files, "usr.incomplete-backup-${System.currentTimeMillis()}")
                    if (backup.exists() || !prefix.renameTo(backup)) {
                        throw IllegalStateException("Cannot preserve incomplete PREFIX before promotion")
                    }
                    incompleteBackup = backup
                } else if (!prefix.delete()) {
                    throw IllegalStateException("Cannot remove empty PREFIX directory")
                }
            }
            if (!staging.renameTo(prefix)) {
                if (incompleteBackup != null && !prefix.exists() && !incompleteBackup.renameTo(prefix)) {
                    Log.e(TAG, "Unable to restore incomplete PREFIX backup after promotion failure")
                }
                throw IllegalStateException("Cannot atomically promote staging to usr")
            }

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
            installProotLibs(prefix)

            val backupNote = incompleteBackup?.let {
                " تم حفظ النسخة غير المكتملة دون حذفها في ${it.absolutePath}."
            } ?: ""
            return report(true, "installed", "تم استخراج Termux Bootstrap وتجهيز Bash runtime في ${prefix.absolutePath}.$backupNote",
                prefix, File(prefix, "bin/bash"))
        } catch (t: Throwable) {
            Log.e(TAG, "Bootstrap install failed; preserving active prefix", t)
            try { if (staging.exists()) deleteTreeSafely(staging) } catch (_: Throwable) {}
            return report(false, "bootstrap-extraction-failed",
                "فشل استخراج Bootstrap دون حذف usr: ${t.javaClass.simpleName}: ${t.message}", prefix, bash)
        }
    }

    private fun isEmptyPlaceholderPrefix(prefix: File): Boolean {
        val allowed = setOf("bin", "sbin", "lib", "lib64", "etc", "include", "libexec", "share", "tmp", "var")
        val children = prefix.listFiles() ?: return false
        if (children.isEmpty() || children.any { it.name !in allowed }) return false
        return isEmptyDirectoryTree(prefix)
    }

    private fun isEmptyDirectoryTree(directory: File): Boolean {
        if (readlinkOrNull(directory.absolutePath) != null || !directory.isDirectory) return false
        val children = directory.listFiles() ?: return false
        for (child in children) {
            if (readlinkOrNull(child.absolutePath) != null) return false
            if (!child.isDirectory || !isEmptyDirectoryTree(child)) return false
        }
        return true
    }

    private fun isBashBinary(file: File): Boolean {
        if (!file.isFile || file.length() < 100_000L) return false
        return try {
            RandomAccessFile(file, "r").use { raf ->
                if (raf.readUnsignedByte() != 0x7f ||
                    raf.readUnsignedByte() != 0x45 ||
                    raf.readUnsignedByte() != 0x4c ||
                    raf.readUnsignedByte() != 0x46) return@use false
                val elfClass = raf.readUnsignedByte()
                val elfData = raf.readUnsignedByte()
                val elfVersion = raf.readUnsignedByte()
                elfClass in 1..2 && elfData in 1..2 && elfVersion == 1
            }
        } catch (_: Throwable) {
            false
        }
    }

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
            "export LD_LIBRARY_PATH=\"\$PREFIX/lib:\$PREFIX/lib64:\$PREFIX/libexec\"\n" +
            "export TMPDIR=\"${File(files, "tmp").absolutePath}\"\n" +
            "export TERM=\"xterm-256color\"\n" +
            "export COLORTERM=\"truecolor\"\n" +
            "export LANG=\"C.UTF-8\"\n" +
            "export LC_ALL=\"C.UTF-8\"\n" +
            "export SHELL=\"${File(prefix, "bin/bash").absolutePath}\"\n" +
            "export ZION_TERMINAL=1\n" +
            "export TERMINFO=\"\$PREFIX/share/terminfo\"\n" +
            "export TERMINFO_DIRS=\"\$PREFIX/share/terminfo:\$PREFIX/lib/terminfo\"\n" +
            "if [ -f \"\$PREFIX/etc/tls/cert.pem\" ]; then export SSL_CERT_FILE=\"\$PREFIX/etc/tls/cert.pem\"; export CURL_CA_BUNDLE=\"\$PREFIX/etc/tls/cert.pem\"; fi\n" +
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
        rc.appendLine("export LD_LIBRARY_PATH=\"\$PREFIX/lib:\$PREFIX/lib64:\$PREFIX/libexec\"")
        rc.appendLine("export TMPDIR=\"${File(files, "tmp").absolutePath}\"")
        rc.appendLine("export SHELL=\"${File(prefix, "bin/bash").absolutePath}\"")
        rc.appendLine("export LANG=C.UTF-8")
        rc.appendLine("export LC_ALL=C.UTF-8")
        rc.appendLine("export TERMINFO=\"\$PREFIX/share/terminfo\"")
        rc.appendLine("export TERMINFO_DIRS=\"\$PREFIX/share/terminfo:\$PREFIX/lib/terminfo:/system/usr/share/terminfo\"")
        rc.appendLine("if [ -f \"\$PREFIX/etc/tls/cert.pem\" ]; then export SSL_CERT_FILE=\"\$PREFIX/etc/tls/cert.pem\"; export CURL_CA_BUNDLE=\"\$PREFIX/etc/tls/cert.pem\"; fi")
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
                "date", "du", "id", "readlink", "realpath", "stat", "test", "whoami").forEach { applet ->
                rc.appendLine("alias $applet='/system/bin/linker64 \"\$PREFIX/bin/coreutils\" --coreutils-prog=$applet'")
            }
        }
        listOf("grep", "sed", "gawk", "find", "xargs", "curl", "wget", "tar", "unzip",
            "python3", "node", "git", "nano", "which", "file").forEach { tool ->
            if (File(bin, tool).isFile) {
                rc.appendLine("alias $tool='/system/bin/linker64 \"\$PREFIX/bin/$tool\"'")
            }
        }
        // Android provides these applets in toybox; they are not guaranteed to
        // exist in the Termux coreutils multi-call binary.
        rc.appendLine("df() { /system/bin/toybox df \"\$@\"; }")
        rc.appendLine("ps() { /system/bin/toybox ps \"\$@\"; }")
        rc.appendLine("top() { /system/bin/toybox top \"\$@\"; }")
        rc.appendLine("free() { /system/bin/toybox free \"\$@\"; }")
        rc.appendLine("alias ll='ls -alF'")
        rc.appendLine("alias la='ls -A'")
        rc.appendLine("alias l='ls -CF'")
        rc.appendLine("PS1='\\n\\[\\e[1;38;5;117m\\]╭─\\[\\e[1;38;5;39m\\][ZION]\\[\\e[1;38;5;117m\\]─\\[\\e[1;38;5;45m\\][OS]\\[\\e[1;38;5;117m\\]─\\[\\e[1;38;5;222m\\][\\w]\\[\\e[0m\\]\\n\\[\\e[1;38;5;117m\\]╰─\\[\\e[1;32m\\]\\$\\[\\e[0m\\] '")
        val rcFile = File(etc, "zion-bashrc")
        FileOutputStream(rcFile).use { out ->
            out.write(rc.toString().toByteArray(Charsets.UTF_8))
            out.fd.sync()
        }
        Os.chmod(rcFile.absolutePath, 420) // 0644
    }

    /**
     * Fill missing PRoot runtime dependencies from known local bootstrap
     * folders. External files are never trusted by name alone: only regular
     * ELF64 little-endian AArch64 libraries are copied, and each copy is
     * validated before it can replace anything in the active PREFIX.
     *
     * This is best-effort; absence of an optional local library source must
     * not make an otherwise usable Zion shell unavailable.
     */
    private fun installProotLibs(prefix: File) {
        val libDir = File(prefix, "lib")
        if (!libDir.isDirectory && !libDir.mkdirs() && !libDir.isDirectory) {
            Log.w(TAG, "Cannot create PRoot library directory: ${libDir.absolutePath}")
            return
        }
        val sourceDirs = listOf(
            File("/storage/emulated/0/zion-libs-complete"),
            File("/storage/emulated/0/lib-fix-all"),
            File("/storage/emulated/0/bootstrap-extracted/usr/lib")
        )
        val requiredLibraries = listOf(
            "libtalloc.so.2",
            "libandroid-shmem.so",
            "libandroid-support.so",
            "libcap.so.2",
            "libattr.so.1",
            "libiconv.so",
            "libpcre2-8.so"
        )

        fun validArm64Library(file: File): Boolean {
            if (!file.isFile || file.length() < 4096L) return false
            return try {
                RandomAccessFile(file, "r").use { raf ->
                    raf.readUnsignedByte() == 0x7f &&
                        raf.readUnsignedByte() == 0x45 &&
                        raf.readUnsignedByte() == 0x4c &&
                        raf.readUnsignedByte() == 0x46 &&
                        raf.readUnsignedByte() == 2 &&
                        raf.readUnsignedByte() == 1 &&
                        raf.readUnsignedByte() == 1 &&
                        run {
                            raf.seek(18L)
                            raf.readUnsignedByte() == 183 && raf.readUnsignedByte() == 0
                        }
                }
            } catch (_: Throwable) {
                false
            }
        }

        for (name in requiredLibraries) {
            val destination = File(libDir, name)
            if (validArm64Library(destination)) continue

            var installed = false
            for (sourceDir in sourceDirs) {
                try {
                    val source = File(sourceDir, name)
                    val canonicalSourceDir = sourceDir.canonicalFile
                    if (!source.canonicalPath.startsWith(canonicalSourceDir.path + File.separator) ||
                        !validArm64Library(source)) continue

                    val staged = File(libDir, "$name.zion-staging")
                    if (staged.exists() && !staged.delete()) continue
                    source.inputStream().use { input ->
                        FileOutputStream(staged).use { output ->
                            input.copyTo(output)
                            output.fd.sync()
                        }
                    }
                    if (!validArm64Library(staged)) {
                        staged.delete()
                        continue
                    }
                    staged.setReadable(true, true)
                    var backup: File? = null
                    if (destination.exists()) {
                        backup = File(libDir, "$name.invalid-backup-${System.currentTimeMillis()}")
                        if (!destination.renameTo(backup)) {
                            staged.delete()
                            continue
                        }
                    }
                    if (!staged.renameTo(destination)) {
                        if (backup != null && !destination.exists()) {
                            backup.renameTo(destination)
                        }
                        staged.delete()
                        continue
                    }
                    destination.setReadable(true, true)
                    installed = validArm64Library(destination)
                    if (installed) {
                        Log.i(TAG, "Installed local PRoot dependency: $name from ${source.absolutePath}")
                        break
                    }
                } catch (t: Throwable) {
                    Log.w(TAG, "Skipped local PRoot dependency source for $name", t)
                }
            }
            if (!installed && !validArm64Library(destination)) {
                Log.i(TAG, "Optional local PRoot dependency unavailable: $name")
            }
        }
    }

    /**
     * Prefer the official JNI accessor. Some packaged builds expose the ZIP
     * payload only as a raw stream embedded in the ELF shared object, without
     * a ZIP central directory/EOCD. ZipInputStream is a streaming reader and
     * does not require the EOCD record.
     */
    private fun loadBootstrapArchive(context: Context): ByteArray {
        // The bootstrap may be stored as a raw ZIP stream inside the ELF. Builds
        // can change section layout, so the old fixed offset is only a fast path;
        // validate the entries and scan for a real stream before attempting JNI.
        var blobError: Throwable? = null
        val soFile = File(context.applicationInfo.nativeLibraryDir, "libtermux-bootstrap.so")
        try {
            if (!soFile.isFile || soFile.length() == 0L) {
                throw IllegalStateException("Bootstrap ELF not found or empty: ${soFile.absolutePath}")
            }
            if (soFile.length() > MAX_ARCHIVE_BYTES + 64L * 1024L * 1024L) {
                throw IllegalStateException("Bootstrap ELF exceeds the bounded scan size: ${soFile.length()}")
            }
            val elf = soFile.readBytes()
            val candidates = LinkedHashSet<Int>()
            if (BOOTSTRAP_BLOB_OFFSET >= 0L && BOOTSTRAP_BLOB_OFFSET < elf.size.toLong()) {
                candidates.add(BOOTSTRAP_BLOB_OFFSET.toInt())
            }
            var i = 0
            while (i + 4 <= elf.size && candidates.size < 128) {
                if (elf[i] == 0x50.toByte() && elf[i + 1] == 0x4b.toByte() &&
                    elf[i + 2] == 0x03.toByte() && elf[i + 3] == 0x04.toByte()) {
                    candidates.add(i)
                    i += 3
                }
                i++
            }

            for (offset in candidates) {
                val remaining = elf.size - offset
                if (remaining < 4) continue
                // Prefer the known payload length at every discovered header,
                // not only the historical offset. If the payload was rebuilt
                // with a different size, also test the remaining ELF tail.
                val lengths = if (BOOTSTRAP_BLOB_SIZE > 0L &&
                    BOOTSTRAP_BLOB_SIZE <= remaining.toLong()) {
                    listOf(BOOTSTRAP_BLOB_SIZE.toInt(), remaining).distinct()
                } else {
                    listOf(remaining)
                }
                for (length in lengths) {
                    if (!isBootstrapZipStream(elf, offset, length)) continue
                    Log.i(TAG, "Validated embedded bootstrap ZIP stream at ELF offset=$offset length=$length")
                    return elf.copyOfRange(offset, offset + length)
                }
            }
            throw IllegalStateException(
                "No valid bootstrap ZIP stream found in ELF; size=${elf.size}, candidates=${candidates.size}"
            )
        } catch (t: Throwable) {
            blobError = t
            Log.w(TAG, "Embedded bootstrap ZIP scan unavailable; trying JNI getZip", t)
        }

        try {
            val bytes = TermuxInstaller.getZip()
            if (isBootstrapZipStream(bytes, 0, bytes.size)) return bytes
            throw IllegalStateException("TermuxInstaller.getZip() returned an invalid bootstrap ZIP stream", blobError)
        } catch (t: Throwable) {
            throw IllegalStateException(
                "Unable to read bootstrap ZIP stream from ELF blob or JNI (ELF: ${blobError?.message})", t
            )
        }
    }

    /** Validate real bootstrap entries, not a coincidental PK local-header byte sequence. */
    private fun isBootstrapZipStream(bytes: ByteArray, offset: Int, length: Int): Boolean {
        if (offset < 0 || length < 4 || offset.toLong() + length > bytes.size.toLong()) return false
        var hasBash = false
        var hasApt = false
        var hasSymlinks = false
        var entries = 0
        var expanded = 0L
        val buffer = ByteArray(8 * 1024)
        return try {
            ZipInputStream(ByteArrayInputStream(bytes, offset, length)).use { zip ->
                while (true) {
                    val entry = zip.nextEntry ?: break
                    if (++entries > MAX_ENTRIES) return false
                    val name = entry.name.removePrefix("./").trimStart('/')
                    if (name == "bin/bash" || name == "usr/bin/bash") hasBash = true
                    if (name == "bin/apt" || name == "usr/bin/apt") hasApt = true
                    if (name == "SYMLINKS.txt" || name == "usr/SYMLINKS.txt") hasSymlinks = true
                    while (true) {
                        val count = zip.read(buffer)
                        if (count < 0) break
                        expanded += count.toLong()
                        if (expanded > MAX_UNCOMPRESSED_BYTES) return false
                    }
                    zip.closeEntry()
                }
            }
            hasBash && hasApt && hasSymlinks
        } catch (t: Throwable) {
            Log.v(TAG, "ZIP candidate rejected at offset=$offset: ${t.javaClass.simpleName}: ${t.message}")
            false
        }
    }

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
