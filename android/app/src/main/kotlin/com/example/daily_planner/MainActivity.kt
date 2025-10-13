package com.example.daily_planner

import android.Manifest
import android.app.AppOpsManager
import android.app.NotificationChannel
import android.app.NotificationManager
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.net.Uri
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.os.Process
import android.provider.Settings
import android.util.Log
import androidx.annotation.NonNull
import androidx.core.app.ActivityCompat
import androidx.core.app.NotificationCompat
import androidx.core.content.ContextCompat
import com.google.android.gms.auth.api.signin.GoogleSignIn
import com.google.android.gms.auth.api.signin.GoogleSignInClient
import com.google.android.gms.auth.api.signin.GoogleSignInOptions
import com.google.android.gms.common.api.ApiException
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

/**
 * MainActivity - FIXED: All 144 compilation errors resolved
 * PART 1: Class definition, initialization, and core setup
 */
class MainActivity: FlutterActivity() {
    companion object {
        private const val CHANNEL = "com.example.daily_planner/app_blocker"
        private const val OAUTH_CHANNEL = "com.example.daily_planner/oauth"
        private const val NOTIFICATION_CHANNEL_ID = "app_blocker_notifications"

        // Request codes for permissions
        private const val REQUEST_USAGE_STATS = 1001
        private const val REQUEST_OVERLAY_PERMISSION = 1002
        private const val REQUEST_DEVICE_ADMIN = 1003
        private const val REQUEST_ACCESSIBILITY = 1004
        private const val REQUEST_NOTIFICATION_PERMISSION = 1005
        private const val RC_GOOGLE_SIGN_IN = 1006
    }

    private var appBlockerChannel: MethodChannel? = null
    private var oauthChannel: MethodChannel? = null
    private var isDestroyed = false

    // Google Sign-In integration
    private var googleSignInClient: GoogleSignInClient? = null

    // AppBlockerPlugin instance - will be created only when needed
    private var appBlockerPlugin: AppBlockerPlugin? = null

    // Store pending result for Google Sign-In
    private var pendingGoogleSignInResult: MethodChannel.Result? = null

    /**
     * FIXED: Flutter engine configuration - lightweight and non-blocking
     */
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        try {
            Log.i("MainActivity", "Starting Flutter engine configuration...")

            // 1. Create notification channel (lightweight)
            createNotificationChannel()

            // 2. Setup method channels first (critical for Flutter communication)
            setupMethodChannels(flutterEngine)

            // 3. Initialize services in background thread (non-blocking)
            initializeServicesAsync()

            Log.i("MainActivity", "Flutter engine configured successfully")
        } catch (e: Exception) {
            Log.e("MainActivity", "Error configuring Flutter engine: ${e.message}")
            // Never crash here - Flutter must start
        }
    }

    /**
     * FIXED: Setup method channels with proper error handling
     */
    private fun setupMethodChannels(flutterEngine: FlutterEngine) {
        try {
            // App blocker method channel
            appBlockerChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
            appBlockerChannel?.setMethodCallHandler { call: MethodCall, result: MethodChannel.Result ->
                if (!isDestroyed) {
                    try {
                        handleAppBlockerMethod(call, result)
                    } catch (e: Exception) {
                        Log.e("MainActivity", "App blocker method error: ${e.message}")
                        result.error("METHOD_ERROR", "Method execution failed: ${e.message}", null)
                    }
                }
            }

            // OAuth method channel
            oauthChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, OAUTH_CHANNEL)
            oauthChannel?.setMethodCallHandler { call: MethodCall, result: MethodChannel.Result ->
                if (!isDestroyed) {
                    try {
                        handleOAuthMethod(call, result)
                    } catch (e: Exception) {
                        Log.e("MainActivity", "OAuth method error: ${e.message}")
                        result.error("OAUTH_ERROR", "OAuth method failed: ${e.message}", null)
                    }
                }
            }

            Log.i("MainActivity", "Method channels setup completed")
        } catch (e: Exception) {
            Log.e("MainActivity", "Failed to setup method channels: ${e.message}")
        }
    }

    /**
     * FIXED: Initialize services asynchronously to prevent loading screen hang
     */
    private fun initializeServicesAsync() {
        Thread {
            try {
                // Initialize Google Sign-In
                initializeGoogleSignIn()
                Log.i("MainActivity", "Background service initialization completed")
            } catch (e: Exception) {
                Log.w("MainActivity", "Background initialization warning: ${e.message}")
            }
        }.start()
    }

    /**
     * FIXED: Create notification channel safely
     */
    private fun createNotificationChannel() {
        try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                val name = "App Blocker Notifications"
                val descriptionText = "Notifications for app blocking and focus sessions"
                val importance = NotificationManager.IMPORTANCE_DEFAULT
                val channel = NotificationChannel(NOTIFICATION_CHANNEL_ID, name, importance).apply {
                    description = descriptionText
                }

                val notificationManager: NotificationManager =
                    getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
                notificationManager.createNotificationChannel(channel)
                Log.i("MainActivity", "Notification channel created")
            }
        } catch (e: Exception) {
            Log.w("MainActivity", "Failed to create notification channel: ${e.message}")
        }
    }

    /**
     * FIXED: Initialize Google Sign-In with proper error handling
     */
    private fun initializeGoogleSignIn() {
        try {
            val gso = GoogleSignInOptions.Builder(GoogleSignInOptions.DEFAULT_SIGN_IN)
                .requestEmail()
                .requestProfile()
                .requestIdToken("595435556740-mqk3g3ctu3bg4825ubqjsvcuubkjr97s.apps.googleusercontent.com")
                .build()

            googleSignInClient = GoogleSignIn.getClient(this, gso)
            Log.i("MainActivity", "Google Sign-In initialized")
        } catch (e: Exception) {
            Log.w("MainActivity", "Google Sign-In initialization failed: ${e.message}")
        }
    }

    /**
     * FIXED: Lazy initialization of AppBlockerPlugin
     */
    private fun getOrCreateAppBlockerPlugin(): AppBlockerPlugin? {
        if (appBlockerPlugin == null) {
            try {
                appBlockerPlugin = AppBlockerPlugin.getInstance(this)
                Log.i("MainActivity", "AppBlockerPlugin lazy-initialized")
            } catch (e: Exception) {
                Log.w("MainActivity", "AppBlockerPlugin initialization failed: ${e.message}")
                return null
            }
        }
        return appBlockerPlugin
    }

    /**
     * FIXED: Handle app blocker method calls with proper error boundaries
     */
    private fun handleAppBlockerMethod(call: MethodCall, result: MethodChannel.Result) {
        try {
            when (call.method) {
                "initialize" -> initializeAppBlocker(result)
                "checkPermissions" -> checkAllPermissions(result)
                "requestPermissions" -> requestAllPermissions(result)
                "requestUsageStatsPermission" -> requestUsageStatsPermission(result)
                "requestOverlayPermission" -> requestOverlayPermission(result)
                "requestDeviceAdminPermission" -> requestDeviceAdminPermission(result)
                "requestAccessibilityPermission" -> requestAccessibilityPermission(result)
                "requestNotificationPermission" -> requestNotificationPermission(result)
                "getInstalledApps" -> getInstalledApps(result)
                "enableAppBlocking" -> enableAppBlocking(call, result)
                "disableAppBlocking" -> disableAppBlocking(result)
                "showBlockingMessage" -> showBlockingMessage(call, result)
                "showFocusCompleted" -> showFocusCompleted(call, result)
                "isAppBlocked" -> isAppBlocked(call, result)
                "getBlockedApps" -> getBlockedApps(result)
                "showBlockNotification" -> showBlockNotification(call, result)
                "getTodayStatistics" -> getTodayStatistics(result)
                "clearAllData" -> clearAllData(result)
                else -> result.notImplemented()
            }
        } catch (e: Exception) {
            Log.e("MainActivity", "App blocker method failed: ${e.message}")
            result.error("APP_BLOCKER_ERROR", "App blocker method failed: ${e.message}", null)
        }
    }

    /**
     * FIXED: Handle OAuth method calls with proper error boundaries
     */
    private fun handleOAuthMethod(call: MethodCall, result: MethodChannel.Result) {
        try {
            when (call.method) {
                "initialize" -> initializeOAuth(call, result)
                "signInWithGoogle" -> signInWithGoogle(result)
                "signOut" -> signOutGoogle(result)
                "getCurrentUser" -> getCurrentGoogleUser(result)
                else -> result.notImplemented()
            }
        } catch (e: Exception) {
            Log.e("MainActivity", "OAuth method failed: ${e.message}")
            result.error("OAUTH_ERROR", "OAuth method failed: ${e.message}", null)
        }
    }

    // ============================================================================
    // APP BLOCKER IMPLEMENTATION - SAFE METHODS
    // ============================================================================

    /**
     * FIXED: Initialize app blocker service
     */
    private fun initializeAppBlocker(result: MethodChannel.Result) {
        try {
            val prefs = getSharedPreferences("app_blocker", Context.MODE_PRIVATE)
            createNotificationChannel()

            val permissionStatus = mapOf(
                "initialized" to true,
                "hasUsageStats" to hasUsageStatsPermission(),
                "hasOverlay" to hasOverlayPermission(),
                "hasNotification" to hasNotificationPermission(),
                "hasDeviceAdmin" to false,
                "hasAccessibility" to hasAccessibilityPermission()
            )

            result.success(permissionStatus)
            Log.i("MainActivity", "App blocker initialized successfully")
        } catch (e: Exception) {
            Log.e("MainActivity", "Failed to initialize app blocker: ${e.message}")
            result.error("INIT_ERROR", "Failed to initialize app blocker: ${e.message}", null)
        }
    }

    /**
     * FIXED: Check all required permissions
     */
    private fun checkAllPermissions(result: MethodChannel.Result) {
        try {
            val permissions = mutableMapOf<String, Boolean>()

            permissions["usageStats"] = hasUsageStatsPermission()
            permissions["overlay"] = hasOverlayPermission()
            permissions["notification"] = hasNotificationPermission()
            permissions["deviceAdmin"] = false
            permissions["accessibility"] = hasAccessibilityPermission()

            val criticalPermissions = listOf("usageStats", "overlay")
            permissions["allCriticalGranted"] = criticalPermissions.all { permissions[it] == true }

            result.success(permissions)
        } catch (e: Exception) {
            Log.e("MainActivity", "Failed to check permissions: ${e.message}")
            result.error("PERMISSION_CHECK_ERROR", "Failed to check permissions: ${e.message}", null)
        }
    }

    /**
     * FIXED: Request all necessary permissions
     */
    private fun requestAllPermissions(result: MethodChannel.Result) {
        try {
            val missingPermissions = mutableListOf<String>()

            if (!hasUsageStatsPermission()) missingPermissions.add("usageStats")
            if (!hasOverlayPermission()) missingPermissions.add("overlay")
            if (!hasNotificationPermission()) missingPermissions.add("notification")

            if (missingPermissions.isNotEmpty()) {
                requestNextPermission(missingPermissions.first())
                result.success(mapOf(
                    "started" to true,
                    "missingPermissions" to missingPermissions,
                    "message" to "Permission request started"
                ))
            } else {
                result.success(mapOf(
                    "started" to false,
                    "allGranted" to true,
                    "message" to "All permissions already granted"
                ))
            }
        } catch (e: Exception) {
            Log.e("MainActivity", "Failed to request permissions: ${e.message}")
            result.error("PERMISSION_REQUEST_ERROR", "Failed to request permissions: ${e.message}", null)
        }
    }

    /**
     * Request next permission in sequence
     */
    private fun requestNextPermission(permission: String) {
        try {
            when (permission) {
                "usageStats" -> requestUsageStats()
                "overlay" -> requestOverlay()
                "notification" -> requestNotification()
                "accessibility" -> requestAccessibility()
            }
        } catch (e: Exception) {
            Log.e("MainActivity", "Failed to request $permission: ${e.message}")
        }
    }
    // ============================================================================
    // PERMISSION METHODS - FIXED WITH PROPER ERROR HANDLING
    // ============================================================================

    /**
     * FIXED: Check if Usage Stats permission is granted
     */
    private fun hasUsageStatsPermission(): Boolean {
        return try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP) {
                val appOps = getSystemService(Context.APP_OPS_SERVICE) as? AppOpsManager
                if (appOps != null) {
                    val mode = appOps.checkOpNoThrow(
                        AppOpsManager.OPSTR_GET_USAGE_STATS,
                        Process.myUid(),
                        packageName
                    )
                    mode == AppOpsManager.MODE_ALLOWED
                } else {
                    false
                }
            } else {
                false
            }
        } catch (e: Exception) {
            Log.e("MainActivity", "Error checking usage stats permission: ${e.message}")
            false
        }
    }

    /**
     * FIXED: Check if Overlay permission is granted
     */
    private fun hasOverlayPermission(): Boolean {
        return try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                Settings.canDrawOverlays(this)
            } else {
                true
            }
        } catch (e: Exception) {
            Log.e("MainActivity", "Error checking overlay permission: ${e.message}")
            false
        }
    }

    /**
     * FIXED: Check if Notification permission is granted
     */
    private fun hasNotificationPermission(): Boolean {
        return try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                ContextCompat.checkSelfPermission(
                    this,
                    Manifest.permission.POST_NOTIFICATIONS
                ) == PackageManager.PERMISSION_GRANTED
            } else {
                true
            }
        } catch (e: Exception) {
            Log.e("MainActivity", "Error checking notification permission: ${e.message}")
            false
        }
    }

    /**
     * FIXED: Check if Accessibility permission is granted
     */
    private fun hasAccessibilityPermission(): Boolean {
        return try {
            false // Not implemented yet
        } catch (e: Exception) {
            Log.e("MainActivity", "Error checking accessibility permission: ${e.message}")
            false
        }
    }

    // ============================================================================
    // PERMISSION REQUEST METHODS - FIXED
    // ============================================================================

    private fun requestUsageStatsPermission(result: MethodChannel.Result) {
        try {
            requestUsageStats()
            result.success(mapOf(
                "requested" to true,
                "message" to "Usage stats permission request launched"
            ))
        } catch (e: Exception) {
            result.error("REQUEST_ERROR", "Failed to request usage stats permission: ${e.message}", null)
        }
    }

    private fun requestUsageStats() {
        try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP) {
                val intent = Intent(Settings.ACTION_USAGE_ACCESS_SETTINGS)
                if (intent.resolveActivity(packageManager) != null) {
                    startActivityForResult(intent, REQUEST_USAGE_STATS)
                }
            }
        } catch (e: Exception) {
            Log.e("MainActivity", "Failed to request usage stats: ${e.message}")
        }
    }

    private fun requestOverlayPermission(result: MethodChannel.Result) {
        try {
            requestOverlay()
            result.success(mapOf(
                "requested" to true,
                "message" to "Overlay permission request launched"
            ))
        } catch (e: Exception) {
            result.error("REQUEST_ERROR", "Failed to request overlay permission: ${e.message}", null)
        }
    }

    private fun requestOverlay() {
        try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                val intent = Intent(
                    Settings.ACTION_MANAGE_OVERLAY_PERMISSION,
                    Uri.parse("package:$packageName")
                )
                if (intent.resolveActivity(packageManager) != null) {
                    startActivityForResult(intent, REQUEST_OVERLAY_PERMISSION)
                }
            }
        } catch (e: Exception) {
            Log.e("MainActivity", "Failed to request overlay permission: ${e.message}")
        }
    }

    private fun requestNotificationPermission(result: MethodChannel.Result) {
        try {
            requestNotification()
            result.success(mapOf(
                "requested" to true,
                "message" to "Notification permission request launched"
            ))
        } catch (e: Exception) {
            result.error("REQUEST_ERROR", "Failed to request notification permission: ${e.message}", null)
        }
    }

    private fun requestNotification() {
        try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                ActivityCompat.requestPermissions(
                    this,
                    arrayOf(Manifest.permission.POST_NOTIFICATIONS),
                    REQUEST_NOTIFICATION_PERMISSION
                )
            }
        } catch (e: Exception) {
            Log.e("MainActivity", "Failed to request notification permission: ${e.message}")
        }
    }

    private fun requestDeviceAdminPermission(result: MethodChannel.Result) {
        result.success(mapOf(
            "requested" to false,
            "message" to "Device Admin functionality not implemented yet",
            "available" to false
        ))
    }

    private fun requestAccessibilityPermission(result: MethodChannel.Result) {
        try {
            requestAccessibility()
            result.success(mapOf(
                "requested" to true,
                "message" to "Accessibility settings opened"
            ))
        } catch (e: Exception) {
            result.error("REQUEST_ERROR", "Failed to request accessibility permission: ${e.message}", null)
        }
    }

    private fun requestAccessibility() {
        try {
            val intent = Intent(Settings.ACTION_ACCESSIBILITY_SETTINGS)
            if (intent.resolveActivity(packageManager) != null) {
                startActivityForResult(intent, REQUEST_ACCESSIBILITY)
            }
        } catch (e: Exception) {
            Log.e("MainActivity", "Failed to open accessibility settings: ${e.message}")
        }
    }

    // ============================================================================
    // APP BLOCKER METHODS - FIXED
    // ============================================================================

    private fun getInstalledApps(result: MethodChannel.Result) {
        try {
            val plugin = getOrCreateAppBlockerPlugin()
            if (plugin == null) {
                result.error("PLUGIN_ERROR", "AppBlockerPlugin not available", null)
                return
            }

            val apps = plugin.getInstalledApps()
            result.success(mapOf(
                "apps" to apps,
                "count" to apps.size,
                "success" to true,
                "message" to "Real device apps loaded successfully"
            ))

            Log.i("MainActivity", "Loaded ${apps.size} real device apps")
        } catch (e: Exception) {
            Log.e("MainActivity", "Failed to get installed apps: ${e.message}")
            result.error("GET_APPS_ERROR", "Failed to get installed apps: ${e.message}", null)
        }
    }

    private fun isAppBlocked(call: MethodCall, result: MethodChannel.Result) {
        try {
            val packageName = call.argument<String>("packageName")
            if (packageName.isNullOrEmpty()) {
                result.error("INVALID_ARGS", "Package name is required", null)
                return
            }

            val plugin = getOrCreateAppBlockerPlugin()
            val isBlocked = plugin?.shouldBlockApp(packageName) ?: false

            result.success(mapOf(
                "packageName" to packageName,
                "isBlocked" to isBlocked,
                "success" to true
            ))
        } catch (e: Exception) {
            result.error("CHECK_BLOCKED_ERROR", "Failed to check if app is blocked: ${e.message}", null)
        }
    }

    private fun getBlockedApps(result: MethodChannel.Result) {
        try {
            val prefs = getSharedPreferences("app_blocker", Context.MODE_PRIVATE)
            val blockedApps = prefs.getStringSet("blocked_apps", emptySet())?.toList() ?: emptyList()
            val blockingEnabled = prefs.getBoolean("blocking_active", false)

            result.success(mapOf(
                "blockedApps" to blockedApps,
                "blockingEnabled" to blockingEnabled,
                "count" to blockedApps.size,
                "success" to true
            ))
        } catch (e: Exception) {
            result.error("GET_BLOCKED_ERROR", "Failed to get blocked apps: ${e.message}", null)
        }
    }

    private fun enableAppBlocking(call: MethodCall, result: MethodChannel.Result) {
        try {
            val blockedApps = call.argument<List<String>>("blockedApps") ?: emptyList()
            val blockMessage = call.argument<String>("blockMessage") ?: "App blocked during focus mode"
            val duration = call.argument<Int>("duration") ?: 25

            if (blockedApps.isEmpty()) {
                result.error("INVALID_ARGS", "At least one app must be specified for blocking", null)
                return
            }

            if (!hasUsageStatsPermission() || !hasOverlayPermission()) {
                result.error("MISSING_PERMISSIONS", "Required permissions not granted", mapOf(
                    "usageStats" to hasUsageStatsPermission(),
                    "overlay" to hasOverlayPermission()
                ))
                return
            }

            val plugin = getOrCreateAppBlockerPlugin()
            if (plugin == null) {
                result.error("PLUGIN_ERROR", "AppBlockerPlugin not available", null)
                return
            }

            val success = plugin.startAppBlocking(
                appsToBlock = blockedApps.toSet(),
                message = blockMessage,
                duration = duration * 60 * 1000L
            )

            if (success) {
                result.success(mapOf(
                    "enabled" to true,
                    "blockedApps" to blockedApps,
                    "duration" to duration,
                    "message" to blockMessage,
                    "success" to true
                ))
                Log.i("MainActivity", "App blocking enabled for ${blockedApps.size} apps")
            } else {
                result.error("ENABLE_FAILED", "Failed to enable app blocking", null)
            }
        } catch (e: Exception) {
            result.error("ENABLE_BLOCKING_ERROR", "Failed to enable app blocking: ${e.message}", null)
        }
    }

    private fun disableAppBlocking(result: MethodChannel.Result) {
        try {
            val plugin = getOrCreateAppBlockerPlugin()
            val success = plugin?.stopAppBlocking() ?: false

            result.success(mapOf(
                "disabled" to success,
                "success" to true
            ))
            Log.i("MainActivity", "App blocking disabled")
        } catch (e: Exception) {
            result.error("DISABLE_BLOCKING_ERROR", "Failed to disable app blocking: ${e.message}", null)
        }
    }

    private fun showBlockingMessage(call: MethodCall, result: MethodChannel.Result) {
        try {
            val appName = call.argument<String>("appName") ?: "App"
            val message = call.argument<String>("message") ?: "App blocked during focus mode"
            val packageName = call.argument<String>("packageName") ?: ""

            val plugin = getOrCreateAppBlockerPlugin()
            if (packageName.isNotEmpty() && plugin != null) {
                plugin.showBlockingOverlay(packageName)
            }

            result.success(mapOf(
                "shown" to true,
                "appName" to appName,
                "method" to "overlay",
                "success" to true
            ))
        } catch (e: Exception) {
            result.error("SHOW_BLOCKING_ERROR", "Failed to show blocking message: ${e.message}", null)
        }
    }

    private fun showBlockNotification(call: MethodCall, result: MethodChannel.Result) {
        try {
            val appName = call.argument<String>("appName") ?: "App"
            val message = call.argument<String>("message") ?: "App blocked during focus mode"

            showNotification("🚫 $appName Blocked", message)

            result.success(mapOf(
                "shown" to true,
                "appName" to appName,
                "success" to true
            ))
        } catch (e: Exception) {
            result.error("NOTIFICATION_ERROR", "Failed to show notification: ${e.message}", null)
        }
    }

    private fun showFocusCompleted(call: MethodCall, result: MethodChannel.Result) {
        try {
            val message = call.argument<String>("message") ?: "Focus session completed!"
            val timeBlocked = call.argument<Int>("timeBlocked") ?: 0
            val appsBlocked = call.argument<Int>("appsBlocked") ?: 0
            val blockedAttempts = call.argument<Int>("blockedAttempts") ?: 0

            val detailMessage = buildString {
                append(message)
                if (timeBlocked > 0) append("\n⏱️ Time focused: $timeBlocked minutes")
                if (appsBlocked > 0) append("\n🚫 Apps blocked: $appsBlocked")
                if (blockedAttempts > 0) append("\n🛡️ Distractions blocked: $blockedAttempts")
            }

            showNotification("🎉 Focus Complete!", detailMessage)

            val prefs = getSharedPreferences("app_blocker_stats", Context.MODE_PRIVATE)
            val totalSessions = prefs.getInt("total_sessions", 0)
            val totalTime = prefs.getInt("total_focus_time", 0)

            prefs.edit()
                .putInt("total_sessions", totalSessions + 1)
                .putInt("total_focus_time", totalTime + timeBlocked)
                .putLong("last_session", System.currentTimeMillis())
                .apply()

            result.success(mapOf(
                "shown" to true,
                "timeBlocked" to timeBlocked,
                "appsBlocked" to appsBlocked,
                "blockedAttempts" to blockedAttempts,
                "success" to true
            ))
        } catch (e: Exception) {
            result.error("SHOW_COMPLETED_ERROR", "Failed to show completion: ${e.message}", null)
        }
    }

    private fun getTodayStatistics(result: MethodChannel.Result) {
        try {
            val plugin = getOrCreateAppBlockerPlugin()
            val stats = plugin?.getTodayStatistics() ?: mapOf(
                "totalFocusTime" to 0,
                "sessionsCompleted" to 0,
                "appsBlocked" to 0,
                "distractionsBlocked" to 0,
                "success" to false
            )
            result.success(stats)
        } catch (e: Exception) {
            result.error("GET_STATS_ERROR", "Failed to get statistics: ${e.message}", null)
        }
    }

    private fun clearAllData(result: MethodChannel.Result) {
        try {
            val plugin = getOrCreateAppBlockerPlugin()
            plugin?.clearAllData()
            result.success(mapOf("cleared" to true, "success" to true))
        } catch (e: Exception) {
            result.error("CLEAR_DATA_ERROR", "Failed to clear data: ${e.message}", null)
        }
    }

    // ============================================================================
    // OAUTH METHODS - FIXED GOOGLE SIGN-IN
    // ============================================================================

    private fun initializeOAuth(call: MethodCall, result: MethodChannel.Result) {
        try {
            result.success(mapOf(
                "initialized" to true,
                "providers" to mapOf(
                    "google" to true,
                    "facebook" to false,
                    "github" to false,
                    "apple" to false
                ),
                "success" to true
            ))
        } catch (e: Exception) {
            result.error("OAUTH_INIT_ERROR", "Failed to initialize OAuth: ${e.message}", null)
        }
    }

    private fun signInWithGoogle(result: MethodChannel.Result) {
        try {
            val client = googleSignInClient
            if (client == null) {
                result.error("GOOGLE_SIGNIN_ERROR", "Google Sign-In client not initialized", null)
                return
            }

            val signInIntent = client.signInIntent
            startActivityForResult(signInIntent, RC_GOOGLE_SIGN_IN)
            pendingGoogleSignInResult = result
            Log.i("MainActivity", "Google Sign-In intent launched")
        } catch (e: Exception) {
            result.error("GOOGLE_SIGNIN_ERROR", "Google sign-in failed: ${e.message}", null)
        }
    }

    private fun signOutGoogle(result: MethodChannel.Result) {
        try {
            val client = googleSignInClient
            if (client == null) {
                result.error("SIGNOUT_ERROR", "Google Sign-In client not initialized", null)
                return
            }

            client.signOut().addOnCompleteListener(this) { task ->
                if (task.isSuccessful) {
                    result.success(mapOf("success" to true, "message" to "Signed out successfully"))
                    Log.i("MainActivity", "Google Sign-Out successful")
                } else {
                    result.error("SIGNOUT_ERROR", "Failed to sign out", null)
                }
            }
        } catch (e: Exception) {
            result.error("SIGNOUT_ERROR", "Sign out failed: ${e.message}", null)
        }
    }

    private fun getCurrentGoogleUser(result: MethodChannel.Result) {
        try {
            val account = GoogleSignIn.getLastSignedInAccount(this)
            if (account != null) {
                val userData = mapOf(
                    "success" to true,
                    "user" to mapOf(
                        "id" to (account.id ?: ""),
                        "email" to (account.email ?: ""),
                        "displayName" to (account.displayName ?: ""),
                        "photoUrl" to (account.photoUrl?.toString() ?: ""),
                        "idToken" to (account.idToken ?: "")
                    ),
                    "provider" to "google"
                )
                result.success(userData)
            } else {
                result.success(mapOf("success" to false, "user" to null))
            }
        } catch (e: Exception) {
            result.error("GET_USER_ERROR", "Failed to get current user: ${e.message}", null)
        }
    }

    // ============================================================================
    // UTILITY METHODS - FIXED
    // ============================================================================

    private fun showNotification(title: String, message: String) {
        try {
            val notificationManager = getSystemService(Context.NOTIFICATION_SERVICE) as? NotificationManager
            if (notificationManager == null) {
                Log.w("MainActivity", "NotificationManager not available")
                return
            }

            val notification = NotificationCompat.Builder(this, NOTIFICATION_CHANNEL_ID)
                .setContentTitle(title)
                .setContentText(message)
                .setStyle(NotificationCompat.BigTextStyle().bigText(message))
                .setSmallIcon(android.R.drawable.ic_dialog_info)
                .setPriority(NotificationCompat.PRIORITY_DEFAULT)
                .setAutoCancel(true)
                .build()

            val notificationId = (System.currentTimeMillis() % Int.MAX_VALUE).toInt()
            notificationManager.notify(notificationId, notification)
        } catch (e: Exception) {
            Log.e("MainActivity", "Failed to show notification: ${e.message}")
        }
    }

    private fun safeInvokeMethod(method: String, arguments: Map<String, Any>) {
        try {
            if (!isDestroyed && appBlockerChannel != null) {
                Handler(Looper.getMainLooper()).post {
                    try {
                        appBlockerChannel?.invokeMethod(method, arguments)
                    } catch (e: Exception) {
                        Log.w("MainActivity", "Failed to invoke Flutter method $method: ${e.message}")
                    }
                }
            }
        } catch (e: Exception) {
            Log.w("MainActivity", "Failed to safely invoke method: ${e.message}")
        }
    }

    // ============================================================================
    // ACTIVITY RESULT HANDLING - FIXED
    // ============================================================================

    @Deprecated("Deprecated in Java")
    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)

        try {
            when (requestCode) {
                REQUEST_USAGE_STATS -> {
                    val granted = hasUsageStatsPermission()
                    notifyPermissionResult("usageStats", granted)
                    if (granted) {
                        checkAndRequestNextPermission()
                    }
                }
                REQUEST_OVERLAY_PERMISSION -> {
                    val granted = hasOverlayPermission()
                    notifyPermissionResult("overlay", granted)
                    if (granted) {
                        checkAndRequestNextPermission()
                    }
                }
                REQUEST_ACCESSIBILITY -> {
                    val granted = hasAccessibilityPermission()
                    notifyPermissionResult("accessibility", granted)
                    if (granted) {
                        checkAndRequestNextPermission()
                    }
                }
                RC_GOOGLE_SIGN_IN -> {
                    handleGoogleSignInResult(data)
                }
            }
        } catch (e: Exception) {
            Log.e("MainActivity", "Error handling activity result: ${e.message}")
        }
    }

    private fun handleGoogleSignInResult(data: Intent?) {
        try {
            val task = GoogleSignIn.getSignedInAccountFromIntent(data)
            val account = task.getResult(ApiException::class.java)

            if (account != null) {
                val userData = mapOf(
                    "success" to true,
                    "user" to mapOf(
                        "id" to (account.id ?: ""),
                        "email" to (account.email ?: ""),
                        "displayName" to (account.displayName ?: ""),
                        "photoUrl" to (account.photoUrl?.toString() ?: ""),
                        "idToken" to (account.idToken ?: "")
                    ),
                    "provider" to "google"
                )

                pendingGoogleSignInResult?.success(userData)
                Log.i("MainActivity", "Google Sign-In successful for: ${account.email}")
            } else {
                pendingGoogleSignInResult?.error(
                    "GOOGLE_SIGNIN_ERROR",
                    "Google Sign-In failed: No account data",
                    null
                )
            }
        } catch (e: ApiException) {
            val errorMessage = when (e.statusCode) {
                12501 -> "Sign-in was cancelled by user"
                12502 -> "Sign-in is currently in progress"
                7 -> "Network error - please check your connection"
                else -> "Sign-in failed with code: ${e.statusCode}"
            }

            pendingGoogleSignInResult?.error(
                "GOOGLE_SIGNIN_ERROR",
                errorMessage,
                null
            )
            Log.e("MainActivity", "Google Sign-In failed: $errorMessage")
        } catch (e: Exception) {
            pendingGoogleSignInResult?.error(
                "GOOGLE_SIGNIN_ERROR",
                "Unexpected error: ${e.message}",
                null
            )
            Log.e("MainActivity", "Google Sign-In unexpected error: ${e.message}")
        } finally {
            pendingGoogleSignInResult = null
        }
    }

    override fun onRequestPermissionsResult(
        requestCode: Int,
        permissions: Array<out String>,
        grantResults: IntArray
    ) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)

        try {
            when (requestCode) {
                REQUEST_NOTIFICATION_PERMISSION -> {
                    val granted = grantResults.isNotEmpty() &&
                            grantResults[0] == PackageManager.PERMISSION_GRANTED
                    notifyPermissionResult("notification", granted)
                    if (granted) {
                        checkAndRequestNextPermission()
                    }
                }
            }
        } catch (e: Exception) {
            Log.e("MainActivity", "Error handling permission result: ${e.message}")
        }
    }

    private fun checkAndRequestNextPermission() {
        try {
            val missingPermissions = mutableListOf<String>()

            if (!hasUsageStatsPermission()) missingPermissions.add("usageStats")
            if (!hasOverlayPermission()) missingPermissions.add("overlay")
            if (!hasNotificationPermission()) missingPermissions.add("notification")

            if (missingPermissions.isNotEmpty()) {
                Handler(Looper.getMainLooper()).postDelayed({
                    requestNextPermission(missingPermissions.first())
                }, 1000)
            } else {
                safeInvokeMethod("onAllPermissionsGranted", mapOf("allGranted" to true))
            }
        } catch (e: Exception) {
            Log.e("MainActivity", "Error checking next permission: ${e.message}")
        }
    }

    private fun notifyPermissionResult(permission: String, granted: Boolean) {
        try {
            val result = mapOf(
                "permission" to permission,
                "granted" to granted,
                "timestamp" to System.currentTimeMillis()
            )

            safeInvokeMethod("onPermissionResult", result)
        } catch (e: Exception) {
            Log.e("MainActivity", "Error notifying permission result: ${e.message}")
        }
    }

    // ============================================================================
    // LIFECYCLE METHODS - FIXED
    // ============================================================================

    override fun onResume() {
        super.onResume()
        try {
            checkPermissionChanges()
        } catch (e: Exception) {
            Log.e("MainActivity", "Error in onResume: ${e.message}")
        }
    }

    override fun onPause() {
        super.onPause()
        try {
            saveAppState()
        } catch (e: Exception) {
            Log.e("MainActivity", "Error in onPause: ${e.message}")
        }
    }

    override fun onDestroy() {
        try {
            isDestroyed = true
            appBlockerChannel?.setMethodCallHandler(null)
            oauthChannel?.setMethodCallHandler(null)
            super.onDestroy()
        } catch (e: Exception) {
            Log.e("MainActivity", "Error in onDestroy: ${e.message}")
        }
    }

    private fun checkPermissionChanges() {
        try {
            val currentPermissions = mapOf(
                "usageStats" to hasUsageStatsPermission(),
                "overlay" to hasOverlayPermission(),
                "notification" to hasNotificationPermission(),
                "accessibility" to hasAccessibilityPermission()
            )

            safeInvokeMethod("onPermissionStatusChanged", currentPermissions)
        } catch (e: Exception) {
            Log.e("MainActivity", "Error checking permission changes: ${e.message}")
        }
    }

    private fun saveAppState() {
        try {
            val prefs = getSharedPreferences("app_blocker", Context.MODE_PRIVATE)
            prefs.edit()
                .putLong("last_active", System.currentTimeMillis())
                .apply()
        } catch (e: Exception) {
            Log.e("MainActivity", "Error saving app state: ${e.message}")
        }
    }
}