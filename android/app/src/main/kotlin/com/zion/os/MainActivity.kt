    }

    private fun vibrateApi(durationMs: Int): Map<String, Any?> {
        val vibrator = getSystemService(Context.VIBRATOR_SERVICE) as Vibrator
        if (!vibrator.hasVibrator()) return mapOf("available" to false, "status" to "UNAVAILABLE", "reason" to "Vibrator is not available.")
        if (android.os.Build.VERSION.SDK_INT >= 26) vibrator.vibrate(VibrationEffect.createOneShot(durationMs.coerceIn(1, 10000).toLong(), VibrationEffect.DEFAULT_AMPLITUDE))
        else @Suppress("DEPRECATION") vibrator.vibrate(durationMs.coerceIn(1, 10000).toLong())
        return mapOf("available" to true, "status" to "AVAILABLE")
    }

    private fun wakeLockApi(enabled: Boolean): Map<String, Any?> {
        val power = getSystemService(Context.POWER_SERVICE) as android.os.PowerManager
        if (enabled) {
            if (wakeLock?.isHeld != true) wakeLock = power.newWakeLock(android.os.PowerManager.PARTIAL_WAKE_LOCK, "ZionOS:Terminal").apply { setReferenceCounted(false); acquire() }
        } else {
            wakeLock?.let { if (it.isHeld) it.release() }
            wakeLock = null
        }
        return mapOf("available" to true, "status" to "AVAILABLE", "enabled" to enabled)
    }



    private fun discoverGgufModels(): List<Map<String, Any?>> {
        val roots = linkedSetOf<File>()
        roots.add(File(filesDir, "models"))
        getExternalFilesDir(null)?.let { roots.add(File(it, "models")) }
        roots.add(File("/storage/emulated/0/Download"))
        roots.add(File("/storage/emulated/0/Models"))
        roots.add(File("/sdcard/Download"))
        roots.add(File("/storage/emulated/0"))
        roots.add(File("/sdcard"))
        val out = mutableListOf<Map<String, Any?>>()
        val seen = HashSet<String>()
        fun visit(dir: File, depth: Int) {
            if (depth > 8 || !dir.exists() || !dir.isDirectory) return
            val children = try { dir.listFiles() ?: return } catch (_: Throwable) { return }
            for (f in children) {
                if (f.isFile && f.name.lowercase().endsWith(".gguf") && seen.add(f.absolutePath)) {
                    val size = try { f.length() } catch (_: Throwable) { 0L }
                    out.add(mapOf("name" to f.name, "path" to f.absolutePath, "sizeBytes" to size, "readable" to f.canRead()))
                } else if (f.isDirectory && !f.name.startsWith(".")) visit(f, depth + 1)
            }
        }
        roots.forEach { visit(it, 0) }
        return out.sortedBy { it["name"].toString().lowercase() }
    }

    private fun importSelectedModel(uri: Uri): Map<String, Any?> {
        return try {
            val name = (contentResolver.query(uri, arrayOf(android.provider.OpenableColumns.DISPLAY_NAME), null, null, null)?.use { cursor ->
                if (cursor.moveToFirst()) cursor.getString(0) else null
            } ?: "model.gguf").replace(Regex("[^A-Za-z0-9._-]+"), "_")
            if (!name.lowercase().endsWith(".gguf")) return mapOf("available" to false, "status" to "INVALID", "reason" to "Only GGUF model files are supported.")
            val dir = File(filesDir, "models").apply { mkdirs() }
            val target = File(dir, name)
            contentResolver.openInputStream(uri)?.use { input ->
                FileOutputStream(target).use { output -> input.copyTo(output, 1024 * 1024) }
            } ?: return mapOf("available" to false, "status" to "ERROR", "reason" to "Unable to open selected model.")
            mapOf("available" to true, "status" to "IMPORTED", "name" to name, "path" to target.absolutePath, "sizeBytes" to target.length())
        } catch (t: Throwable) {
            mapOf("available" to false, "status" to "ERROR", "reason" to (t.message ?: "Model import failed."))
        }