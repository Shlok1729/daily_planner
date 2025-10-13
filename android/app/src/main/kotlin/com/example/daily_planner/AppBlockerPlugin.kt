package com.example.daily_planner

import android.app.NotificationChannel
import android.app.NotificationManager
import android.content.Context
import android.content.Intent
import android.content.pm.ApplicationInfo
import android.content.pm.PackageManager
import android.graphics.PixelFormat
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.provider.Settings
import android.util.Log
import android.view.Gravity
import android.view.View
import android.view.WindowManager
import android.widget.TextView
import androidx.core.app.NotificationCompat

/**
 * AppBlockerPlugin - Complete implementation for real app blocking functionality.
 * UPDATED: Background monitoring is now handled by a dedicated Service for reliability.
 * This class acts as a controller and utility provider for the MainActivity.
 */
class AppBlockerPlugin(private val context: Context) {
    companion object {
        const val NOTIFICATION_CHANNEL_ID = "app_blocker_service"
        const val NOTIFICATION_ID = 1001

        // Shared instance for global access
        @Volatile
        private var INSTANCE: AppBlockerPlugin? = null

        fun getInstance(context: Context): AppBlockerPlugin {
            return INSTANCE ?: synchronized(this) {
                INSTANCE ?: AppBlockerPlugin(context.applicationContext).also { INSTANCE = it }
            }
        }
    }

    // --- Properties ---
    private val packageManager: PackageManager = context.packageManager
    private val windowManager: WindowManager = context.getSystemService(Context.WINDOW_SERVICE) as WindowManager
    private val notificationManager: NotificationManager = context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
    private val sharedPrefs: android.content.SharedPreferences = context.getSharedPreferences("app_blocker_plugin", Context.MODE_PRIVATE)

    private var overlayView: View? = null
    private var blockingMessage = "App blocked during focus mode"

    init {
        createNotificationChannel()
    }

    // ============================================================================
    // Public API Methods (Called from MainActivity)
    // ============================================================================

    /**
     * Starts the app blocking focus session.
     * This now starts a foreground service to handle monitoring reliably.
     */
    fun startAppBlocking(appsToBlock: Set<String>, message: String, duration: Long): Boolean {
        return try {
            // Save state to SharedPreferences so the service can access it
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.HONEYCOMB) {
                sharedPrefs.edit()
                    .putStringSet("blocked_apps", appsToBlock)
                    .putBoolean("blocking_active", true)
                    .putString("blocking_message", message)
                    .apply()
            }

            blockingMessage = message

            // Start the dedicated service to handle background monitoring
            val serviceIntent = Intent(context, FocusModeService::class.java).apply {
                action = "START"
                putExtra("duration", duration)
            }

            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                context.startForegroundService(serviceIntent)
            } else {
                context.startService(serviceIntent)
            }

            Log.i("AppBlockerPlugin", "App blocking service started for ${appsToBlock.size} apps")
            true
        } catch (e: Exception) {
            Log.e("AppBlockerPlugin", "Failed to start app blocking service: ${e.message}")
            false
        }
    }

    /**
     * Stops the app blocking focus session.
     * This now stops the foreground service.
     */
    fun stopAppBlocking(): Boolean {
        return try {
            // Update state in SharedPreferences
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.GINGERBREAD) {
                sharedPrefs.edit()
                    .putBoolean("blocking_active", false)
                    .apply()
            }

            // Stop the dedicated service
            val serviceIntent = Intent(context, FocusModeService::class.java).apply {
                action = "STOP"
            }
            context.startService(serviceIntent)

            val blockedAppsCount = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.HONEYCOMB) {
                sharedPrefs.getStringSet("blocked_apps", emptySet())?.size ?: 0
            } else {
                TODO("VERSION.SDK_INT < HONEYCOMB")
            }
            showCompletionNotification(blockedAppsCount)

            Log.i("AppBlockerPlugin", "App blocking service stopped")
            true
        } catch (e: Exception) {
            Log.e("AppBlockerPlugin", "Failed to stop app blocking service: ${e.message}")
            false
        }
    }

    /**
     * Gets a list of all user-installed applications.
     */
    fun getInstalledApps(): List<Map<String, Any>> {
        val apps = mutableListOf<Map<String, Any>>()
        try {
            val installedApps = packageManager.getInstalledApplications(PackageManager.GET_META_DATA)
            for (appInfo in installedApps) {
                // Filter to primarily include non-system, launchable apps
                if (if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.CUPCAKE) {
                        (appInfo.flags and ApplicationInfo.FLAG_SYSTEM) == 0 && packageManager.getLaunchIntentForPackage(appInfo.packageName) != null
                    } else {
                        TODO("VERSION.SDK_INT < CUPCAKE")
                    }) {
                    apps.add(mapOf(
                        "name" to packageManager.getApplicationLabel(appInfo).toString(),
                        "packageName" to appInfo.packageName,
                        "icon" to getAppIconEmoji(appInfo.packageName),
                        "category" to categorizeApp(appInfo.packageName),
                        "isSystemApp" to false,
                        "isLaunchable" to true,
                        "isBlocked" to isAppBlocked(appInfo.packageName)
                    ))
                }
            }
            apps.sortBy { it["name"] as String }
            Log.i("AppBlockerPlugin", "Loaded ${apps.size} launchable, non-system apps")
        } catch (e: Exception) {
            Log.e("AppBlockerPlugin", "Failed to get installed apps: ${e.message}")
        }
        return apps
    }

    /**
     * Checks if a specific app should be blocked based on current state.
     * Reads from SharedPreferences, which is the single source of truth.
     */
    fun shouldBlockApp(packageName: String): Boolean {
        val isActive = sharedPrefs.getBoolean("blocking_active", false)
        val blockedApps = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.HONEYCOMB) {
            sharedPrefs.getStringSet("blocked_apps", emptySet()) ?: emptySet()
        } else {
            TODO("VERSION.SDK_INT < HONEYCOMB")
        }
        return isActive && blockedApps.contains(packageName)
    }

    /**
     * Checks if a specific app is in the last-known block list.
     */
    fun isAppBlocked(packageName: String): Boolean {
        val blockedApps = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.HONEYCOMB) {
            sharedPrefs.getStringSet("blocked_apps", emptySet()) ?: emptySet()
        } else {
            TODO("VERSION.SDK_INT < HONEYCOMB")
        }
        return blockedApps.contains(packageName)
    }

    /**
     * Shows a temporary blocking overlay.
     * This can be triggered by the service or MainActivity.
     */
    fun showBlockingOverlay(packageName: String) {
        try {
            // Ensure this runs on the main thread
            Handler(Looper.getMainLooper()).post {
                removeBlockingOverlay() // Remove any existing overlay first

                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M && !Settings.canDrawOverlays(context)) {
                    Log.w("AppBlockerPlugin", "Overlay permission not granted. Falling back to notification.")
                    showBlockNotification(packageName)
                    return@post
                }

                overlayView = createBlockingOverlayView(packageName)
                val params = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                    WindowManager.LayoutParams(
                        WindowManager.LayoutParams.MATCH_PARENT, WindowManager.LayoutParams.MATCH_PARENT,
                        WindowManager.LayoutParams.TYPE_APPLICATION_OVERLAY,
                        WindowManager.LayoutParams.FLAG_NOT_FOCUSABLE or WindowManager.LayoutParams.FLAG_NOT_TOUCH_MODAL,
                        PixelFormat.TRANSLUCENT
                    )
                } else {
                    @Suppress("DEPRECATION")
                    WindowManager.LayoutParams(
                        WindowManager.LayoutParams.MATCH_PARENT, WindowManager.LayoutParams.MATCH_PARENT,
                        WindowManager.LayoutParams.TYPE_PHONE,
                        WindowManager.LayoutParams.FLAG_NOT_FOCUSABLE or WindowManager.LayoutParams.FLAG_NOT_TOUCH_MODAL,
                        PixelFormat.TRANSLUCENT
                    )
                }
                params.gravity = Gravity.CENTER
                windowManager.addView(overlayView, params)

                // Auto-remove after a few seconds
                Handler(Looper.getMainLooper()).postDelayed({ removeBlockingOverlay() }, 3000)
            }
        } catch (e: Exception) {
            Log.e("AppBlockerPlugin", "Failed to show blocking overlay: ${e.message}")
        }
    }

    /**
     * Removes the blocking overlay from the screen.
     */
    fun removeBlockingOverlay() {
        try {
            overlayView?.let { view ->
                if (if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.KITKAT) {
                        view.isAttachedToWindow
                    } else {
                        TODO("VERSION.SDK_INT < KITKAT")
                    }
                ) {
                    windowManager.removeView(view)
                }
                overlayView = null
            }
        } catch (e: Exception) {
            Log.w("AppBlockerPlugin", "Failed to remove overlay (it may have already been removed): ${e.message}")
        }
    }

    /**
     * Gets focus session statistics.
     */
    fun getTodayStatistics(): Map<String, Any> {
        return try {
            val allKeys = sharedPrefs.all.keys
            var totalBlocks = 0
            val appBlocks = mutableMapOf<String, Int>()

            for (key in allKeys) {
                if (key.startsWith("block_attempts_")) {
                    val packageName = key.removePrefix("block_attempts_")
                    val count = sharedPrefs.getInt(key, 0)
                    if (count > 0) {
                        appBlocks[packageName] = count
                        totalBlocks += count
                    }
                }
            }
            mapOf(
                "totalBlocks" to totalBlocks,
                "appBlocks" to appBlocks,
                "lastBlockTime" to sharedPrefs.getLong("last_block_attempt", 0),
                "focusSessionsToday" to sharedPrefs.getInt("focus_sessions_today", 0)
            )
        } catch (e: Exception) {
            Log.e("AppBlockerPlugin", "Failed to get statistics: ${e.message}")
            emptyMap()
        }
    }

    /**
     * Clears all stored data related to the app blocker.
     */
    fun clearAllData() {
        try {
            stopAppBlocking() // Ensure service is stopped
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.GINGERBREAD) {
                sharedPrefs.edit().clear().apply()
            }
            Log.i("AppBlockerPlugin", "All app blocker data cleared")
        } catch (e: Exception) {
            Log.e("AppBlockerPlugin", "Failed to clear data: ${e.message}")
        }
    }

    // ============================================================================
    // Private Helper Methods
    // ============================================================================

    private fun createBlockingOverlayView(packageName: String): View {
        return TextView(context).apply {
            text = "🚫 App Blocked\n\n$blockingMessage"
            textSize = 24f
            setTextColor(android.graphics.Color.WHITE)
            gravity = Gravity.CENTER
            setBackgroundColor(android.graphics.Color.parseColor("#CC000000"))
            setPadding(40, 40, 40, 40)
            setOnClickListener { removeBlockingOverlay() }
        }
    }

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                NOTIFICATION_CHANNEL_ID,
                "App Blocker Service",
                NotificationManager.IMPORTANCE_LOW
            ).apply {
                description = "Notifications for app blocking service"
                setShowBadge(false)
            }
            notificationManager.createNotificationChannel(channel)
        }
    }

    private fun showBlockNotification(packageName: String) {
        try {
            val appName = try {
                packageManager.getApplicationLabel(packageManager.getApplicationInfo(packageName, 0)).toString()
            } catch (e: Exception) { "App" }

            val notification = NotificationCompat.Builder(context, NOTIFICATION_CHANNEL_ID)
                .setSmallIcon(android.R.drawable.ic_dialog_alert)
                .setContentTitle("🚫 $appName Blocked")
                .setContentText(blockingMessage)
                .setPriority(NotificationCompat.PRIORITY_HIGH)
                .build()

            notificationManager.notify(packageName.hashCode(), notification)
        } catch (e: Exception) {
            Log.e("AppBlockerPlugin", "Failed to show block notification: ${e.message}")
        }
    }

    private fun showCompletionNotification(blockedAppsCount: Int) {
        try {
            val notification = NotificationCompat.Builder(context, NOTIFICATION_CHANNEL_ID)
                .setSmallIcon(android.R.drawable.ic_dialog_info)
                .setContentTitle("🎉 Focus Session Complete!")
                .setContentText("Great job! You successfully blocked $blockedAppsCount apps.")
                .setPriority(NotificationCompat.PRIORITY_DEFAULT)
                .setAutoCancel(true)
                .build()

            notificationManager.notify((System.currentTimeMillis() % Int.MAX_VALUE).toInt(), notification)
        } catch (e: Exception) {
            Log.e("AppBlockerPlugin", "Failed to show completion notification: ${e.message}")
        }
    }

    private fun categorizeApp(packageName: String): String {
        return when {
            packageName.contains("facebook") || packageName.contains("instagram") || packageName.contains("twitter") || packageName.contains("tiktok") || packageName.contains("snapchat") -> "Social"
            packageName.contains("youtube") || packageName.contains("netflix") || packageName.contains("spotify") || packageName.contains("twitch") -> "Entertainment"
            packageName.contains("game") || packageName.contains("pubg") || packageName.contains("clash") -> "Games"
            packageName.contains("whatsapp") || packageName.contains("telegram") || packageName.contains("messenger") -> "Communication"
            else -> "Other"
        }
    }

    private fun getAppIconEmoji(packageName: String): String {
        return when {
            packageName.contains("facebook") -> "📘"
            packageName.contains("instagram") -> "📷"
            packageName.contains("twitter") -> "🐦"
            packageName.contains("youtube") -> "📺"
            packageName.contains("whatsapp") -> "💬"
            packageName.contains("game") -> "🎮"
            packageName.contains("chrome") -> "🌐"
            packageName.contains("gmail") -> "📧"
            else -> "📱"
        }
    }
}
