package com.example.daily_planner

import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.Service
import android.app.usage.UsageStatsManager
import android.content.Context
import android.content.Intent
import android.os.Build
import android.os.Handler
import android.os.IBinder
import android.os.Looper
import android.util.Log
import androidx.core.app.NotificationCompat

class FocusModeService : Service() {
    companion object {
        private const val SERVICE_ID = 1003
        private const val NOTIFICATION_CHANNEL_ID = "focus_mode_service"
        private const val CHANNEL_NAME = "Focus Mode Service"
        private const val MONITORING_INTERVAL_MS = 1000L // 1 second
    }

    private lateinit var appBlockerPlugin: AppBlockerPlugin
    private val monitoringHandler = Handler(Looper.getMainLooper())
    private lateinit var monitoringRunnable: Runnable

    override fun onCreate() {
        super.onCreate()
        appBlockerPlugin = AppBlockerPlugin.getInstance(this)
        createNotificationChannel()
        setupMonitoringRunnable()
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        when (intent?.action) {
            "START" -> {
                Log.i("FocusModeService", "Starting focus mode monitoring.")
                createForegroundNotification()
                monitoringHandler.post(monitoringRunnable)
            }
            "STOP" -> {
                Log.i("FocusModeService", "Stopping focus mode monitoring.")
                monitoringHandler.removeCallbacks(monitoringRunnable)
                stopSelf()
            }
        }
        return START_STICKY
    }

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onDestroy() {
        super.onDestroy()
        monitoringHandler.removeCallbacks(monitoringRunnable)
        Log.i("FocusModeService", "FocusModeService destroyed.")
    }

    private fun setupMonitoringRunnable() {
        monitoringRunnable = Runnable {
            val foregroundApp = getCurrentForegroundApp()
            if (foregroundApp != null && appBlockerPlugin.shouldBlockApp(foregroundApp)) {
                Log.d("FocusModeService", "Blocking app: $foregroundApp")
                appBlockerPlugin.showBlockingOverlay(foregroundApp)
            }
            // Schedule the next check
            monitoringHandler.postDelayed(monitoringRunnable, MONITORING_INTERVAL_MS)
        }
    }

    private fun getCurrentForegroundApp(): String? {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.LOLLIPOP) return null
        return try {
            val usageStatsManager = getSystemService(Context.USAGE_STATS_SERVICE) as UsageStatsManager
            val time = System.currentTimeMillis()
            val stats = usageStatsManager.queryUsageStats(
                UsageStatsManager.INTERVAL_DAILY,
                time - 1000 * 10,
                time
            )
            stats?.sortedByDescending { it.lastTimeUsed }?.firstOrNull()?.packageName
        } catch (e: Exception) {
            Log.e("FocusModeService", "Could not get foreground app: ${e.message}")
            null
        }
    }

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                NOTIFICATION_CHANNEL_ID,
                CHANNEL_NAME,
                NotificationManager.IMPORTANCE_LOW
            ).apply {
                description = "Notifications for Focus Mode Service"
                setShowBadge(false)
            }
            val notificationManager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            notificationManager.createNotificationChannel(channel)
        }
    }

    private fun createForegroundNotification() {
        try {
            val notification = NotificationCompat.Builder(this, NOTIFICATION_CHANNEL_ID)
                .setContentTitle("Focus Mode Active")
                .setContentText("Stay focused on your goals.")
                .setSmallIcon(android.R.drawable.ic_lock_idle_lock)
                .setPriority(NotificationCompat.PRIORITY_LOW)
                .setOngoing(true)
                .setShowWhen(false)
                .build()
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.ECLAIR) {
                startForeground(SERVICE_ID, notification)
            }
        } catch (e: Exception) {
            Log.e("FocusModeService", "Error creating foreground notification: ${e.message}")
        }
    }
}
