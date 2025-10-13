package com.example.daily_planner

import android.annotation.TargetApi
import android.app.admin.DeviceAdminReceiver
import android.content.Context
import android.content.Intent
import android.os.Build
import android.widget.Toast

@TargetApi(Build.VERSION_CODES.FROYO)
class AppBlockerDeviceAdminReceiver : DeviceAdminReceiver() {

    override fun onEnabled(context: Context, intent: Intent) {
        super.onEnabled(context, intent)
        try {
            Toast.makeText(context, "Device Admin enabled for app blocking", Toast.LENGTH_SHORT).show()
            android.util.Log.i("AppBlockerDeviceAdmin", "Device admin enabled")
        } catch (e: Exception) {
            android.util.Log.e("AppBlockerDeviceAdmin", "Error enabling: ${e.message}")
        }
    }

    override fun onDisabled(context: Context, intent: Intent) {
        super.onDisabled(context, intent)
        try {
            Toast.makeText(context, "Device Admin disabled", Toast.LENGTH_SHORT).show()
            android.util.Log.i("AppBlockerDeviceAdmin", "Device admin disabled")
        } catch (e: Exception) {
            android.util.Log.e("AppBlockerDeviceAdmin", "Error disabling: ${e.message}")
        }
    }
}