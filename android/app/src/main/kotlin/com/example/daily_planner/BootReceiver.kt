package com.example.daily_planner

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.os.Build

class BootReceiver : BroadcastReceiver() {

    override fun onReceive(context: Context, intent: Intent) {
        try {
            when (intent.action) {
                Intent.ACTION_BOOT_COMPLETED,
                Intent.ACTION_LOCKED_BOOT_COMPLETED,
                "android.intent.action.QUICKBOOT_POWERON" -> {
                    android.util.Log.i("BootReceiver", "Device boot completed, starting services")

                    // Start app blocker service if needed
                    val prefs = context.getSharedPreferences("app_blocker", Context.MODE_PRIVATE)
                    val wasBlockingActive = prefs.getBoolean("blocking_active", false)

                    if (wasBlockingActive) {
                        val serviceIntent = Intent(context, AppBlockerService::class.java)
                        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                            context.startForegroundService(serviceIntent)
                        } else {
                            context.startService(serviceIntent)
                        }
                    }
                }
            }
        } catch (e: Exception) {
            android.util.Log.e("BootReceiver", "Error handling boot: ${e.message}")
        }
    }
}