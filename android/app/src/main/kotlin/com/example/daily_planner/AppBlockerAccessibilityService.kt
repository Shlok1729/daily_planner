package com.example.daily_planner

import android.accessibilityservice.AccessibilityService
import android.annotation.SuppressLint
import android.view.accessibility.AccessibilityEvent

@SuppressLint("NewApi")
class AppBlockerAccessibilityService : AccessibilityService() {

    @SuppressLint("LongLogTag")
    override fun onAccessibilityEvent(event: AccessibilityEvent?) {
        try {
            // Handle accessibility events for app blocking
            event?.let {
                if (it.eventType == AccessibilityEvent.TYPE_WINDOW_STATE_CHANGED) {
                    val packageName = it.packageName?.toString()
                    if (packageName != null) {
                        checkAndBlockApp(packageName)
                    }
                }
            }
        } catch (e: Exception) {
            android.util.Log.e("AppBlockerAccessibilityService", "Error: ${e.message}")
        }
    }

    override fun onInterrupt() {
        // Handle service interruption
    }

    @SuppressLint("LongLogTag")
    private fun checkAndBlockApp(packageName: String) {
        try {
            val appBlocker = AppBlockerPlugin.getInstance(this)
            if (appBlocker.shouldBlockApp(packageName)) {
                appBlocker.showBlockingOverlay(packageName)
            }
        } catch (e: Exception) {
            android.util.Log.e("AppBlockerAccessibilityService", "Error checking app: ${e.message}")
        }
    }
}