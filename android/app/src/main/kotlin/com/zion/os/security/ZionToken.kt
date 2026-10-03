package com.zion.os.security

import android.content.Context
import java.io.File
import java.security.SecureRandom

/**
 * Canonical local credential for the Zion API IPC bridge.
 *
 * The token is generated once and kept in app-private SharedPreferences.
 * A private filesystem mirror is maintained for the in-app Userland CLI,
 * which runs under the same application UID and therefore can use the same
 * credential without exposing it to other applications.
 */
object ZionToken {
    private const val PREFS = "zion_security"
    private const val KEY_API_TOKEN = "zion_api_token"
    private const val TOKEN_BYTES = 32
    private const val TOKEN_FILE = "etc/zion-api.token"

    @Synchronized
    fun ensure(context: Context): String {
        val prefs = context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
        val existing = prefs.getString(KEY_API_TOKEN, null)?.trim()
        val token = if (isValidToken(existing)) {
            existing!!
        } else {
            val bytes = ByteArray(TOKEN_BYTES)
            SecureRandom().nextBytes(bytes)
            bytes.joinToString("") { "%02x".format(it.toInt() and 0xff) }
                .also { prefs.edit().putString(KEY_API_TOKEN, it).commit() }
        }

        val file = File(context.filesDir, TOKEN_FILE)
        file.parentFile?.mkdirs()
        if (!file.exists() || file.readText().trim() != token) {
            file.writeText(token)
        }
        return token
    }

    fun read(context: Context): String? =
        context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
            .getString(KEY_API_TOKEN, null)
            ?.trim()
            ?.takeIf(::isValidToken)

    fun isValidToken(token: String?): Boolean =
        token != null && token.length == TOKEN_BYTES * 2 &&
            token.all { it in '0'..'9' || it in 'a'..'f' || it in 'A'..'F' }
}
