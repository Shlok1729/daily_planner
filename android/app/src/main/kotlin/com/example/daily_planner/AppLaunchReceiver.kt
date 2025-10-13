package com.example.daily_planner

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.os.Build

class AppLaunchReceiver : BroadcastReceiver() {

    override fun onReceive(context: Context, intent: Intent) {
        try {
            when (intent.action) {
                Intent.ACTION_PACKAGE_ADDED -> {
                    val packageName = intent.dataString?.removePrefix("package:")
                    android.util.Log.d("AppLaunchReceiver", "App installed: $packageName")
                    handleAppInstalled(context, packageName)
                }
                Intent.ACTION_PACKAGE_REMOVED -> {
                    val packageName = intent.dataString?.removePrefix("package:")
                    android.util.Log.d("AppLaunchReceiver", "App removed: $packageName")
                    handleAppRemoved(context, packageName)
                }
            }
        } catch (e: Exception) {
            android.util.Log.e("AppLaunchReceiver", "Error handling app launch: ${e.message}")
        }
    }

    private fun handleAppInstalled(context: Context, packageName: String?) {
        try {
            if (packageName != null) {
                // Update app list cache if needed
                val prefs = context.getSharedPreferences("app_blocker", Context.MODE_PRIVATE)
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.GINGERBREAD) {
                    prefs.edit()
                        .putLong("apps_list_last_updated", System.currentTimeMillis())
                        .apply()
                }
            }
        } catch (e: Exception) {
            android.util.Log.e("AppLaunchReceiver", "Error handling app installed: ${e.message}")
        }
    }

    private fun handleAppRemoved(context: Context, packageName: String?) {
        try {
            if (packageName != null) {
                // Remove from blocked apps list if it was blocked
                val prefs = context.getSharedPreferences("app_blocker", Context.MODE_PRIVATE)
                val blockedApps = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.HONEYCOMB) {
                    prefs.getStringSet("blocked_apps", emptySet())?.toMutableSet()
                } else {
                    TODO("VERSION.SDK_INT < HONEYCOMB")
                }

                if (blockedApps?.remove(packageName) == true) {
                    prefs.edit()
                        .putStringSet("blocked_apps", blockedApps)
                        .apply()
                }
            }
        } catch (e: Exception) {
            android.util.Log.e("AppLaunchReceiver", "Error handling app removed: ${e.message}")
        }
    }
}
