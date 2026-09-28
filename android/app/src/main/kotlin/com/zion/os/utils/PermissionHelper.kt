package com.zion.os.utils

import android.Manifest
import android.app.Activity
import android.content.pm.PackageManager
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat

object PermissionHelper {
    const val REQUEST_BASE = 7400

    fun has(activity: Activity, permission: String): Boolean =
        ContextCompat.checkSelfPermission(activity, permission) == PackageManager.PERMISSION_GRANTED

    fun request(activity: Activity, permissions: Array<String>, requestCode: Int): Boolean {
        val missing = permissions.filterNot { has(activity, it) }.toTypedArray()
        if (missing.isEmpty()) return true
        ActivityCompat.requestPermissions(activity, missing, requestCode)
        return false
    }

    fun camera(activity: Activity) = request(activity, arrayOf(Manifest.permission.CAMERA), REQUEST_BASE + 1)
    fun microphone(activity: Activity) = request(activity, arrayOf(Manifest.permission.RECORD_AUDIO), REQUEST_BASE + 2)
    fun location(activity: Activity) = request(activity, arrayOf(Manifest.permission.ACCESS_FINE_LOCATION, Manifest.permission.ACCESS_COARSE_LOCATION), REQUEST_BASE + 3)
    fun smsRead(activity: Activity) = request(activity, arrayOf(Manifest.permission.READ_SMS), REQUEST_BASE + 4)
    fun smsSend(activity: Activity) = request(activity, arrayOf(Manifest.permission.SEND_SMS), REQUEST_BASE + 5)
    fun contacts(activity: Activity) = request(activity, arrayOf(Manifest.permission.READ_CONTACTS), REQUEST_BASE + 6)
    fun notifications(activity: Activity) = if (android.os.Build.VERSION.SDK_INT >= 33) request(activity, arrayOf(Manifest.permission.POST_NOTIFICATIONS), REQUEST_BASE + 7) else true
    fun storage(activity: Activity) = request(activity, arrayOf(Manifest.permission.READ_MEDIA_IMAGES), REQUEST_BASE + 8)
}
