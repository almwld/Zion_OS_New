package com.zion.os.handlers

import android.content.ClipData
import android.content.ClipboardManager
import android.content.Context

class ClipboardHandler(private val context: Context) {
    private val clipboard = context.getSystemService(Context.CLIPBOARD_SERVICE) as ClipboardManager
    fun get(): Map<String, Any?> {
        val text = if (clipboard.hasPrimaryClip()) clipboard.primaryClip?.getItemAt(0)?.coerceToText(context)?.toString() else null
        return mapOf("available" to true, "status" to "AVAILABLE", "text" to text)
    }
    fun set(text: String): Map<String, Any?> {
        clipboard.setPrimaryClip(ClipData.newPlainText("Zion OS", text))
        return mapOf("available" to true, "status" to "AVAILABLE")
    }
}
