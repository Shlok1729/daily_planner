package com.example.daily_planner

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.os.Build

class ScreenStateReceiver : BroadcastReceiver() {

    override fun onReceive(context: Context, intent: Intent) {
        try {
            when (intent.action) {
                Intent.ACTION_SCREEN_ON -> {
                    android.util.Log.d("ScreenStateReceiver", "Screen turned on")
                    // Handle screen on event for focus mode
                    handleScreenOn(context)
                }
                Intent.ACTION_SCREEN_OFF -> {
                    android.util.Log.d("ScreenStateReceiver", "Screen turned off")
                    // Handle screen off event
                    handleScreenOff(context)
                }
                Intent.ACTION_USER_PRESENT -> {
                    android.util.Log.d("ScreenStateReceiver", "User unlocked device")
                    // Handle user present event
                    handleUserPresent(context)
                }
            }
        } catch (e: Exception) {
            android.util.Log.e("ScreenStateReceiver", "Error handling screen state: ${e.message}")
        }
    }

    private fun handleScreenOn(context: Context) {
        try {
            val prefs = context.getSharedPreferences("app_blocker", Context.MODE_PRIVATE)
            val isBlockingActive = prefs.getBoolean("blocking_active", false)

            if (isBlockingActive) {
                // Resume app monitoring when screen turns on
                val appBlocker = AppBlockerPlugin.getInstance(context)
                // Additional logic can be added here
            }
        } catch (e: Exception) {
            android.util.Log.e("ScreenStateReceiver", "Error handling screen on: ${e.message}")
        }
    }

    private fun handleScreenOff(context: Context) {
        try {
            // Save current state when screen turns off
            val prefs = context.getSharedPreferences("app_blocker", Context.MODE_PRIVATE)
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.GINGERBREAD) {
                prefs.edit()
                    .putLong("last_screen_off", System.currentTimeMillis())
                    .apply()
            }
        } catch (e: Exception) {
            android.util.Log.e("ScreenStateReceiver", "Error handling screen off: ${e.message}")
        }
    }

    private fun handleUserPresent(context: Context) {
        try {
            val prefs = context.getSharedPreferences("app_blocker", Context.MODE_PRIVATE)
            val isBlockingActive = prefs.getBoolean("blocking_active", false)

            if (isBlockingActive) {
                // Show focus mode reminder when user unlocks
                val appBlocker = AppBlockerPlugin.getInstance(context)
                // Could show a quick reminder notification
            }
        } catch (e: Exception) {
            android.util.Log.e("ScreenStateReceiver", "Error handling user present: ${e.message}")
        }
    }
}
