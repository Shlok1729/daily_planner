package com.example.daily_planner

import android.app.Service
import android.content.Intent
import android.os.IBinder
import androidx.core.app.NotificationCompat
import androidx.core.app.NotificationManagerCompat
import android.app.NotificationChannel
import android.app.NotificationManager
import android.content.Context
import android.os.Build

class SupabaseMessagingService : Service() {

    companion object {
        private const val CHANNEL_ID = "supabase_messaging"
        private const val NOTIFICATION_ID = 2001
    }

    override fun onCreate() {
        super.onCreate()
        try {
            createNotificationChannel()
            android.util.Log.d("SupabaseMessaging", "Supabase messaging service created")
        } catch (e: Exception) {
            android.util.Log.e("SupabaseMessaging", "Error creating service: ${e.message}")
        }
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        try {
            // Handle Supabase real-time updates or push notifications
            val messageType = intent?.getStringExtra("type")
            val messageBody = intent?.getStringExtra("message")

            when (messageType) {
                "focus_reminder" -> {
                    showNotification("Focus Reminder", messageBody ?: "Time to focus!")
                }
                "task_update" -> {
                    showNotification("Task Update", messageBody ?: "Your tasks have been updated")
                }
                "productivity_tip" -> {
                    showNotification("Productivity Tip", messageBody ?: "New tip available!")
                }
                else -> {
                    showNotification("Daily Planner", messageBody ?: "New update available")
                }
            }

            return START_NOT_STICKY
        } catch (e: Exception) {
            android.util.Log.e("SupabaseMessaging", "Error in onStartCommand: ${e.message}")
            return START_NOT_STICKY
        }
    }

    override fun onBind(intent: Intent?): IBinder? = null

    fun handleSupabaseRealtimeUpdate(data: Map<String, Any>) {
        try {
            android.util.Log.d("SupabaseMessaging", "Received real-time update: $data")

            when (data["table"] as? String) {
                "tasks" -> {
                    handleTaskUpdate(data)
                }
                "focus_sessions" -> {
                    handleFocusSessionUpdate(data)
                }
                "user_settings" -> {
                    handleUserSettingsUpdate(data)
                }
            }
        } catch (e: Exception) {
            android.util.Log.e("SupabaseMessaging", "Error handling real-time update: ${e.message}")
        }
    }

    private fun handleTaskUpdate(data: Map<String, Any>) {
        try {
            val eventType = data["eventType"] as? String
            when (eventType) {
                "INSERT" -> {
                    showNotification("New Task", "A new task has been added")
                }
                "UPDATE" -> {
                    showNotification("Task Updated", "One of your tasks has been updated")
                }
                "DELETE" -> {
                    showNotification("Task Completed", "Great job completing a task!")
                }
            }
        } catch (e: Exception) {
            android.util.Log.e("SupabaseMessaging", "Error handling task update: ${e.message}")
        }
    }

    private fun handleFocusSessionUpdate(data: Map<String, Any>) {
        try {
            val eventType = data["eventType"] as? String
            when (eventType) {
                "INSERT" -> {
                    showNotification("Focus Session Started", "Your focus session has begun")
                }
                "UPDATE" -> {
                    showNotification("Focus Session", "Focus session status updated")
                }
            }
        } catch (e: Exception) {
            android.util.Log.e("SupabaseMessaging", "Error handling focus session update: ${e.message}")
        }
    }

    private fun handleUserSettingsUpdate(data: Map<String, Any>) {
        try {
            showNotification("Settings Updated", "Your app settings have been synchronized")
        } catch (e: Exception) {
            android.util.Log.e("SupabaseMessaging", "Error handling settings update: ${e.message}")
        }
    }

    private fun showNotification(title: String, body: String) {
        try {
            createNotificationChannel()

            val notificationBuilder = NotificationCompat.Builder(this, CHANNEL_ID)
                .setSmallIcon(android.R.drawable.ic_dialog_info)
                .setContentTitle(title)
                .setContentText(body)
                .setPriority(NotificationCompat.PRIORITY_DEFAULT)
                .setAutoCancel(true)

            with(NotificationManagerCompat.from(this)) {
                // Check for notification permission on Android 13+ (API level 33+)
                if (Build.VERSION.SDK_INT < Build.VERSION_CODES.TIRAMISU ||
                    androidx.core.app.ActivityCompat.checkSelfPermission(
                        this@SupabaseMessagingService,
                        android.Manifest.permission.POST_NOTIFICATIONS
                    ) == android.content.pm.PackageManager.PERMISSION_GRANTED) {
                    notify(NOTIFICATION_ID, notificationBuilder.build())
                } else {
                    android.util.Log.w("SupabaseMessaging", "Notification permission not granted")
                }
            }
        } catch (e: Exception) {
            android.util.Log.e("SupabaseMessaging", "Error showing notification: ${e.message}")
        }
    }

    private fun createNotificationChannel() {
        try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                val name = "Supabase Messaging"
                val descriptionText = "Notifications from Supabase real-time updates"
                val importance = NotificationManager.IMPORTANCE_DEFAULT
                val channel = NotificationChannel(CHANNEL_ID, name, importance).apply {
                    description = descriptionText
                }

                val notificationManager: NotificationManager =
                    getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
                notificationManager.createNotificationChannel(channel)
            }
        } catch (e: Exception) {
            android.util.Log.e("SupabaseMessaging", "Error creating notification channel: ${e.message}")
        }
    }
}