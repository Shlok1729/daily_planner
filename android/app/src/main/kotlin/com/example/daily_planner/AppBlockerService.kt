package com.example.daily_planner

import android.app.Notification
import android.app.Service
import android.app.usage.UsageStatsManager
import android.content.Context
import android.content.Intent
import android.os.Build
import android.os.Handler
import android.os.IBinder
import android.os.Looper
import androidx.core.app.NotificationCompat
import android.app.NotificationChannel
import android.app.NotificationManager

class AppBlockerService : Service() {

    private lateinit var handler: Handler
    private lateinit var runnable: Runnable
    private lateinit var blockedApps: Set<String>
    private lateinit var blockingMessage: String
    private var lastForegroundApp: String? = null
    private lateinit var appBlockerPlugin: AppBlockerPlugin

    companion object {
        private const val SERVICE_NOTIFICATION_ID = 12345
        private const val NOTIFICATION_CHANNEL_ID = "app_blocker_service"
        private const val CHANNEL_NAME = "App Blocker Service"
    }

    override fun onCreate() {
        super.onCreate()
        handler = Handler(Looper.getMainLooper())
        appBlockerPlugin = AppBlockerPlugin.getInstance(this)
        createNotificationChannel()
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        // Start the service in the foreground
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.ECLAIR) {
            startForeground(SERVICE_NOTIFICATION_ID, createNotification())
        }

        // Get data from the intent
        blockedApps = intent?.getStringArrayListExtra("appsToBlock")?.toSet() ?: setOf()
        blockingMessage = intent?.getStringExtra("message") ?: "This app is blocked."

        // Start the monitoring task
        startMonitoring()

        return START_STICKY
    }

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                NOTIFICATION_CHANNEL_ID,
                CHANNEL_NAME,
                NotificationManager.IMPORTANCE_LOW
            ).apply {
                description = "Notifications for App Blocker Service"
                setShowBadge(false)
            }

            val notificationManager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            notificationManager.createNotificationChannel(channel)
        }
    }

    private fun startMonitoring() {
        runnable = Runnable {
            val foregroundApp = getForegroundApp()

            if (foregroundApp != null && foregroundApp != lastForegroundApp) {
                if (blockedApps.contains(foregroundApp)) {
                    // App is in the block list, show overlay
                    appBlockerPlugin.showBlockingOverlay(foregroundApp)
                } else {
                    // App is not in the block list, remove overlay
                    appBlockerPlugin.removeBlockingOverlay()
                }
                lastForegroundApp = foregroundApp
            }

            // Repeat this check every second
            handler.postDelayed(runnable, 1000)
        }
        handler.post(runnable)
    }

    private fun getForegroundApp(): String? {
        return try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP) {
                val usageStatsManager = getSystemService(USAGE_STATS_SERVICE) as? UsageStatsManager
                if (usageStatsManager != null) {
                    val time = System.currentTimeMillis()
                    val stats = usageStatsManager.queryUsageStats(
                        UsageStatsManager.INTERVAL_DAILY,
                        time - 1000 * 10,
                        time
                    )

                    if (stats != null && stats.isNotEmpty()) {
                        stats.sortedBy { it.lastTimeUsed }.lastOrNull()?.packageName
                    } else {
                        null
                    }
                } else {
                    null
                }
            } else {
                null
            }
        } catch (e: Exception) {
            android.util.Log.w("AppBlockerService", "Failed to get foreground app: ${e.message}")
            null
        }
    }

    override fun onDestroy() {
        super.onDestroy()
        try {
            // Stop the monitoring task
            if (::handler.isInitialized && ::runnable.isInitialized) {
                handler.removeCallbacks(runnable)
            }
            // Remove the overlay if it's showing
            if (::appBlockerPlugin.isInitialized) {
                appBlockerPlugin.removeBlockingOverlay()
            }

            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
                stopForeground(STOP_FOREGROUND_REMOVE)
            } else {
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.ECLAIR) {
                    @Suppress("DEPRECATION")
                    stopForeground(true)
                }
            }
        } catch (e: Exception) {
            android.util.Log.e("AppBlockerService", "Error during service destruction: ${e.message}")
        }
    }

    private fun createNotification(): Notification {
        return NotificationCompat.Builder(this, NOTIFICATION_CHANNEL_ID)
            .setContentTitle("Focus Mode Active")
            .setContentText("Monitoring apps to help you stay focused.")
            .setSmallIcon(android.R.drawable.ic_lock_idle_lock)
            .setPriority(NotificationCompat.PRIORITY_LOW)
            .setOngoing(true)
            .setShowWhen(false)
            .build()
    }

    override fun onBind(intent: Intent?): IBinder? {
        return null
    }
}