package com.zion.os.security

import android.content.Intent
import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Test

class ZionApiAuthTest {
    private val token = "0123456789abcdef".repeat(4)

    private fun intent(tokenValue: String? = token, requestId: String = "req-1", method: String = "battery"): Intent =
        Intent(TrustVerifier.ACTION).apply {
            putExtra("requestId", requestId)
            putExtra("method", method)
            tokenValue?.let { putExtra("token", it) }
        }

    @Test fun validTokenIsAccepted() {
        assertTrue(TrustVerifier.verify(intent(), token))
    }

    @Test fun wrongTokenIsRejected() {
        assertFalse(TrustVerifier.verify(intent("f".repeat(64)), token))
    }

    @Test fun missingTokenIsRejected() {
        assertFalse(TrustVerifier.verify(intent(null), token))
    }

    @Test fun malformedRequestIdIsRejected() {
        assertFalse(TrustVerifier.verify(intent(requestId = "../escape"), token))
    }

    @Test fun malformedMethodIsRejected() {
        assertFalse(TrustVerifier.verify(intent(method = "sms;send"), token))
    }
}
