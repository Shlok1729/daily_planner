package com.example.daily_planner

import android.app.Service
import android.content.Intent
import android.os.Build
import android.os.IBinder
import androidx.core.app.NotificationCompat
import android.app.NotificationChannel
import android.app.NotificationManager
import android.content.Context

class AppUsageMonitorService : Service() {
    companion object {
        private const val SERVICE_ID = 1004
        private const val NOTIFICATION_CHANNEL_ID = "app_usage_monitor"
        private const val CHANNEL_NAME = "App Usage Monitor"
    }

    override fun onCreate() {
        super.onCreate()
        createNotificationChannel()
        createForegroundNotification()
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        return START_STICKY
    }

    override fun onBind(intent: Intent?): IBinder? = null

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                NOTIFICATION_CHANNEL_ID,
                CHANNEL_NAME,
                NotificationManager.IMPORTANCE_LOW
            ).apply {
                description = "Notifications for App Usage Monitor Service"
                setShowBadge(false)
            }

            val notificationManager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            notificationManager.createNotificationChannel(channel)
        }
    }

    private fun createForegroundNotification() {
        try {
            val notification = NotificationCompat.Builder(this, NOTIFICATION_CHANNEL_ID)
                .setContentTitle("App Usage Monitor")
                .setContentText("Monitoring app usage patterns")
                .setSmallIcon(android.R.drawable.ic_menu_info_details)
                .setPriority(NotificationCompat.PRIORITY_LOW)
                .setOngoing(true)
                .setShowWhen(false)
                .build()

            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.ECLAIR) {
                startForeground(SERVICE_ID, notification)
            }
        } catch (e: Exception) {
            android.util.Log.e("AppUsageMonitorService", "Error creating foreground notification: ${e.message}")
        }
    }

    override fun onDestroy() {
        super.onDestroy()
        try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
                stopForeground(STOP_FOREGROUND_REMOVE)
            } else {
                @Suppress("DEPRECATION")
                stopForeground(true)
            }
        } catch (e: Exception) {
            android.util.Log.e("AppUsageMonitorService", "Error stopping foreground service: ${e.message}")
        }
    }
}