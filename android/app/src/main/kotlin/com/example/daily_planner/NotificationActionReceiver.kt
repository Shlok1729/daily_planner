package com.example.daily_planner

import android.annotation.SuppressLint
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.os.Build
import android.widget.Toast

class NotificationActionReceiver : BroadcastReceiver() {

    companion object {
        const val ACTION_PAUSE_FOCUS = "com.example.daily_planner.ACTION_PAUSE_FOCUS"
        const val ACTION_RESUME_FOCUS = "com.example.daily_planner.ACTION_RESUME_FOCUS"
        const val ACTION_END_FOCUS = "com.example.daily_planner.ACTION_END_FOCUS"
        const val ACTION_EXTEND_FOCUS = "com.example.daily_planner.ACTION_EXTEND_FOCUS"
    }

    @SuppressLint("LongLogTag")
    override fun onReceive(context: Context, intent: Intent) {
        try {
            when (intent.action) {
                ACTION_PAUSE_FOCUS -> {
                    handlePauseFocus(context)
                }
                ACTION_RESUME_FOCUS -> {
                    handleResumeFocus(context)
                }
                ACTION_END_FOCUS -> {
                    handleEndFocus(context)
                }
                ACTION_EXTEND_FOCUS -> {
                    handleExtendFocus(context)
                }
            }
        } catch (e: Exception) {
            android.util.Log.e("NotificationActionReceiver", "Error handling notification action: ${e.message}")
        }
    }

    @SuppressLint("LongLogTag")
    private fun handlePauseFocus(context: Context) {
        try {
            val appBlocker = AppBlockerPlugin.getInstance(context)
            // Pause focus mode temporarily
            val prefs = context.getSharedPreferences("app_blocker", Context.MODE_PRIVATE)
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.GINGERBREAD) {
                prefs.edit()
                    .putBoolean("focus_paused", true)
                    .putLong("focus_paused_time", System.currentTimeMillis())
                    .apply()
            }

            Toast.makeText(context, "Focus mode paused", Toast.LENGTH_SHORT).show()
            android.util.Log.i("NotificationActionReceiver", "Focus mode paused")
        } catch (e: Exception) {
            android.util.Log.e("NotificationActionReceiver", "Error pausing focus: ${e.message}")
        }
    }

    @SuppressLint("LongLogTag")
    private fun handleResumeFocus(context: Context) {
        try {
            val appBlocker = AppBlockerPlugin.getInstance(context)
            // Resume focus mode
            val prefs = context.getSharedPreferences("app_blocker", Context.MODE_PRIVATE)
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.GINGERBREAD) {
                prefs.edit()
                    .putBoolean("focus_paused", false)
                    .remove("focus_paused_time")
                    .apply()
            }

            Toast.makeText(context, "Focus mode resumed", Toast.LENGTH_SHORT).show()
            android.util.Log.i("NotificationActionReceiver", "Focus mode resumed")
        } catch (e: Exception) {
            android.util.Log.e("NotificationActionReceiver", "Error resuming focus: ${e.message}")
        }
    }

    @SuppressLint("LongLogTag")
    private fun handleEndFocus(context: Context) {
        try {
            val appBlocker = AppBlockerPlugin.getInstance(context)
            appBlocker.stopAppBlocking()

            Toast.makeText(context, "Focus session ended", Toast.LENGTH_SHORT).show()
            android.util.Log.i("NotificationActionReceiver", "Focus session ended")
        } catch (e: Exception) {
            android.util.Log.e("NotificationActionReceiver", "Error ending focus: ${e.message}")
        }
    }

    @SuppressLint("LongLogTag")
    private fun handleExtendFocus(context: Context) {
        try {
            val prefs = context.getSharedPreferences("app_blocker", Context.MODE_PRIVATE)
            val currentEndTime = prefs.getLong("focus_end_time", 0)
            val extendedEndTime = currentEndTime + (15 * 60 * 1000) // Extend by 15 minutes

            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.GINGERBREAD) {
                prefs.edit()
                    .putLong("focus_end_time", extendedEndTime)
                    .apply()
            }

            Toast.makeText(context, "Focus session extended by 15 minutes", Toast.LENGTH_SHORT).show()
            android.util.Log.i("NotificationActionReceiver", "Focus session extended")
        } catch (e: Exception) {
            android.util.Log.e("NotificationActionReceiver", "Error extending focus: ${e.message}")
        }
    }
}
