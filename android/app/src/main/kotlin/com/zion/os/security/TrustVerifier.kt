package com.zion.os.security

import android.content.Context
import android.content.Intent
import java.security.MessageDigest

/**
 * Defense-in-depth verifier for external Zion API intents.
 *
 * Component-level signature permission blocks ordinary third-party apps.
 * This verifier adds a per-install secret so an accidentally exposed or
 * internally forwarded intent still cannot execute without the local token.
 */
class TrustVerifier(private val context: Context) {
    fun verify(intent: Intent): Boolean {
        if (intent.action != ACTION) return false
        return verify(
            intent = intent,
            expectedToken = ZionToken.read(context),
        )
    }

    companion object {
        const val ACTION = "com.zion.os.ZION_API"

        fun verify(intent: Intent, expectedToken: String?): Boolean {
            if (expectedToken == null || !ZionToken.isValidToken(expectedToken)) return false
            val requestId = intent.getStringExtra("requestId") ?: return false
            val method = intent.getStringExtra("method") ?: return false
            if (!isValidRequestId(requestId) || !isValidMethod(method)) return false

            val supplied = intent.getStringExtra("token") ?: return false
            if (!ZionToken.isValidToken(supplied)) return false

            return MessageDigest.isEqual(
                supplied.lowercase().toByteArray(Charsets.UTF_8),
                expectedToken.lowercase().toByteArray(Charsets.UTF_8),
            )
        }

        fun isValidRequestId(value: String): Boolean =
            value.matches(Regex("^[A-Za-z0-9_-]{1,80}$"))

        fun isValidMethod(value: String): Boolean =
            value.matches(Regex("^[A-Za-z0-9_-]{1,64}$"))
    }
}
