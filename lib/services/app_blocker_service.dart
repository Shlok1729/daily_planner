import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:daily_planner/models/blocked_app.dart';
import 'package:daily_planner/utils/error_handler.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:installed_apps/installed_apps.dart';
import 'package:installed_apps/app_info.dart';

// ============================================================================
// ENUMS AND CONSTANTS
// ============================================================================

/// Message theme types for blocking notifications
enum MessageTheme { motivational, humorous, challenging, supportive, funny }

// ============================================================================
// BLOCK MESSAGE DATA CLASS
// ============================================================================

/// Block message data class for displaying blocking notifications
class BlockMessage {
  final String title;
  final String subtitle;
  final String footer;
  final String emoji;
  final Color backgroundColor;

  const BlockMessage({
    required this.title,
    required this.subtitle,
    required this.footer,
    required this.emoji,
    required this.backgroundColor,
  });

  static const BlockMessage motivational = BlockMessage(
    title: "Stay focused!",
    subtitle: "Great things take time and focus",
    footer: "You're building something amazing",
    emoji: "🎯",
    backgroundColor: Colors.blue,
  );

  static const BlockMessage humorous = BlockMessage(
    title: "Nope, not today!",
    subtitle: "Deadass thought you could break focus mode?",
    footer: "Back to the grind 💪",
    emoji: "😤",
    backgroundColor: Colors.orange,
  );

  static const BlockMessage challenging = BlockMessage(
    title: "Resist the urge!",
    subtitle: "Embrace the grind, avoid the scroll",
    footer: "Your goals > instant gratification",
    emoji: "⚡",
    backgroundColor: Colors.red,
  );

  static const BlockMessage supportive = BlockMessage(
    title: "You've got this!",
    subtitle: "Focus mode is helping you succeed",
    footer: "Stay strong and keep going",
    emoji: "💪",
    backgroundColor: Colors.green,
  );

  static const BlockMessage funny = BlockMessage(
    title: "Ain't no way! 💀",
    subtitle: "Bro really thought he could open this app",
    footer: "Get back to the grind fr fr",
    emoji: "💀",
    backgroundColor: Colors.purple,
  );

  static const List<BlockMessage> allMessages = [
    motivational,
    humorous,
    challenging,
    supportive,
    funny,
  ];
}

// ============================================================================
// DEVICE APP DATA CLASS (ENHANCED FOR REAL APPS)
// ============================================================================

/// Represents an app installed on the device (compatible with installed_apps)
class DeviceApp {
  final String name;
  final String packageName;
  final String icon; // base64 image string (from AppInfo.icon)
  final String category;
  final bool isSystemApp;
  final bool isBlocked;
  final bool isLaunchable;
  final int
  installTime; // installed_apps does not provide installTime, default to 0

  const DeviceApp({
    required this.name,
    required this.packageName,
    required this.icon,
    required this.category,
    this.isSystemApp = false,
    this.isBlocked = false,
    this.isLaunchable = true,
    this.installTime = 0,
  });

  /// Creates a DeviceApp instance from installed_apps AppInfo
  factory DeviceApp.fromAppInfo(AppInfo app) {
    return DeviceApp(
      name: app.name,
      packageName: app.packageName,
      icon: (app.icon is String) ? app.icon as String : '📱',
      // fall back to emoji if icon is null
      category: 'Other',
      isSystemApp: app.isSystemApp,
      isBlocked: false,
      isLaunchable: true,
      installTime: 0, // AppInfo does not provide install time
    );
  }

  /// Creates a DeviceApp instance from JSON map
  factory DeviceApp.fromJson(Map<String, dynamic> json) {
    return DeviceApp(
      name: json['name'] ?? '',
      packageName: json['packageName'] ?? '',
      icon: json['icon'] ?? '📱',
      category: json['category'] ?? 'Other',
      isSystemApp: json['isSystemApp'] ?? false,
      isBlocked: json['isBlocked'] ?? false,
      isLaunchable: json['isLaunchable'] ?? true,
      installTime: json['installTime'] ?? 0,
    );
  }

  /// Converts DeviceApp instance to JSON map
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'packageName': packageName,
      'icon': icon,
      'category': category,
      'isSystemApp': isSystemApp,
      'isBlocked': isBlocked,
      'isLaunchable': isLaunchable,
      'installTime': installTime,
    };
  }

  /// Returns a copy of this DeviceApp with updated fields
  DeviceApp copyWith({
    String? name,
    String? packageName,
    String? icon,
    String? category,
    bool? isSystemApp,
    bool? isBlocked,
    bool? isLaunchable,
    int? installTime,
  }) {
    return DeviceApp(
      name: name ?? this.name,
      packageName: packageName ?? this.packageName,
      icon: icon ?? this.icon,
      category: category ?? this.category,
      isSystemApp: isSystemApp ?? this.isSystemApp,
      isBlocked: isBlocked ?? this.isBlocked,
      isLaunchable: isLaunchable ?? this.isLaunchable,
      installTime: installTime ?? this.installTime,
    );
  }

  @override
  String toString() {
    return 'DeviceApp(name: $name, packageName: $packageName, category: $category, launchable: $isLaunchable)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is DeviceApp && other.packageName == packageName;
  }

  @override
  int get hashCode => packageName.hashCode;
}

// ============================================================================
// STRING EXTENSION FOR CAPITALIZE METHOD - FIXED
// ============================================================================

/// FIXED: Added missing capitalize extension for String
extension StringExtensions on String {
  String capitalize() {
    if (isEmpty) return this;
    return '${this[0].toUpperCase()}${substring(1).toLowerCase()}';
  }

  String capitalizeWords() {
    return split(' ').map((word) => word.capitalize()).join(' ');
  }
}

// ============================================================================
// APP BLOCKER SERVICE (FIXED FOR REAL DEVICE APPS AND BETTER PERMISSIONS)
// ============================================================================

/// Service that handles app blocking functionality with real permissions
/// FIXED: Now loads real device apps and handles permissions properly
class AppBlockerService {
  static const MethodChannel _channel = MethodChannel(
    'com.example.daily_planner/app_blocker',
  );

  // Hive boxes for data persistence
  Box<BlockedApp>? _appsBox;
  Box<Map<dynamic, dynamic>>? _statsBox;
  Box<Map<dynamic, dynamic>>? _settingsBox;
  Box<Map<dynamic, dynamic>>? _deviceAppsBox;
  Box<Map<dynamic, dynamic>>? _installedAppsBox;

  // In-memory state
  List<BlockedApp> _blockedApps = [];
  List<DeviceApp> _deviceApps = [];
  Map<String, dynamic> _settings = {};
  Map<String, int> _blockedAttempts = {};
  bool _isInitialized = false;
  bool _focusModeActive = false;

  // FIXED: Track permission status
  Map<String, bool> _permissionStatus = {
    'usageStats': false,
    'overlay': false,
    'notification': false,
    'accessibility': false,
    'deviceAdmin': false,
  };

  // Singleton pattern
  static final AppBlockerService _instance = AppBlockerService._internal();
  factory AppBlockerService() => _instance;
  AppBlockerService._internal();

  // ============================================================================
  // GETTERS
  // ============================================================================

  /// Check if service is initialized
  bool get isInitialized => _isInitialized;

  /// Get all blocked apps
  List<BlockedApp> get blockedApps => List.unmodifiable(_blockedApps);

  /// FIXED: Get all device apps (real apps, not demo)
  List<DeviceApp> get deviceApps => List.unmodifiable(_deviceApps);

  /// Get blocked attempts
  Map<String, int> get blockedAttempts => Map.unmodifiable(_blockedAttempts);

  /// FIXED: Get permission status
  Map<String, bool> get permissionStatus => Map.unmodifiable(_permissionStatus);

  /// Check if all critical permissions are granted
  bool get hasRequiredPermissions {
    return _permissionStatus['usageStats'] == true &&
        _permissionStatus['overlay'] == true;
  }

  /// Check if app blocking is supported on this device
  bool get isSupported => Platform.isAndroid;

  /// Check if emergency override is active
  bool get isEmergencyOverrideActive {
    final isActive = _settings['isEmergencyOverrideActive'] ?? false;
    if (!isActive) return false;

    final expiryTime = _settings['emergencyOverrideExpiry'];
    if (expiryTime == null) return false;

    return DateTime.now().isBefore(
      DateTime.fromMillisecondsSinceEpoch(expiryTime),
    );
  }

  // ============================================================================
  // INITIALIZATION
  // ============================================================================

  /// Initialize the app blocker service
  Future<void> init() async {
    if (_isInitialized) return;

    try {
      await _initializeHiveBoxes();
      await _loadPersistedData();
      await _setupNativeChannel();

      // FIXED: Load real device apps and check permissions
      await _checkAndUpdatePermissions();
      await _loadRealDeviceApps();

      _isInitialized = true;

      if (kDebugMode) {
        print('✅ AppBlockerService initialized successfully');
        print('📱 Found ${_deviceApps.length} real device apps');
        print('🚫 Configured ${_blockedApps.length} blocked apps');
        print('🔒 Required permissions: ${hasRequiredPermissions ? "✅" : "❌"}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ AppBlockerService initialization failed: $e');
      }
      rethrow;
    }
  }

  /// Initialize Hive boxes for data storage
  Future<void> _initializeHiveBoxes() async {
    try {
      _appsBox = await Hive.openBox<BlockedApp>('blocked_apps');
      _statsBox = await Hive.openBox<Map<dynamic, dynamic>>(
        'app_blocker_stats',
      );
      _settingsBox = await Hive.openBox<Map<dynamic, dynamic>>(
        'app_blocker_settings',
      );
      _installedAppsBox = await Hive.openBox<Map<dynamic, dynamic>>(
        'installed_apps_cache',
      );
    } catch (e) {
      if (kDebugMode) {
        print('❌ Failed to initialize Hive boxes: $e');
      }
      rethrow;
    }
  }

  /// Load persisted data from storage
  Future<void> _loadPersistedData() async {
    try {
      // Load blocked apps
      _blockedApps = _appsBox?.values.toList() ?? [];

      // Load settings
      _settings = Map<String, dynamic>.from(
        _settingsBox?.get('settings', defaultValue: <String, dynamic>{}) ?? {},
      );

      // Set default settings if not present
      _settings.putIfAbsent('autoBlockDuringFocus', () => true);
      _settings.putIfAbsent('showBlockNotifications', () => true);
      _settings.putIfAbsent('messageTheme', () => 0);
      _settings.putIfAbsent('currentStreak', () => 0);
      _settings.putIfAbsent('isFocusModeActive', () => false);
      _settings.putIfAbsent('isEmergencyOverrideActive', () => false);
      _settings.putIfAbsent('emergencyOverrideExpiry', () => null);

      // Load focus mode state
      _focusModeActive = _settings['isFocusModeActive'] ?? false;

      // Load today's blocked attempts
      final cachedApps =
          _installedAppsBox?.values
              .map(
                (json) => DeviceApp.fromJson(Map<String, dynamic>.from(json)),
              )
              .toList() ??
          [];

      final today = DateTime.now().toIso8601String().split('T')[0];
      final todayStats = _statsBox?.get(
        'stats_$today',
        defaultValue: <String, dynamic>{},
      );
      _blockedAttempts = Map<String, int>.from(
        todayStats?['blockAttempts'] ?? {},
      );

      if (kDebugMode) {
        print('📁 Loaded ${_blockedApps.length} blocked apps');
        print('🎯 Focus mode active: $_focusModeActive');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Failed to load persisted data: $e');
      }
    }
  }

  /// Setup native platform channel for app blocking
  Future<void> _setupNativeChannel() async {
    try {
      _channel.setMethodCallHandler(_handleMethodCall);

      // Initialize native module
      if (Platform.isAndroid) {
        await _channel.invokeMethod('initialize');
      }

      if (kDebugMode) {
        print('🔗 Native channel setup completed');
      }
    } catch (e) {
      if (kDebugMode) {
        print('⚠️ Native channel setup failed: $e');
      }
      // Continue without native functionality for non-Android platforms
    }
  }

  /// Handle method calls from native platform
  Future<dynamic> _handleMethodCall(MethodCall call) async {
    switch (call.method) {
      case 'onAppLaunchBlocked':
        final packageName = call.arguments['packageName'] as String?;
        if (packageName != null) {
          await _handleAppLaunchBlocked(packageName);
        }
        break;
      case 'onFocusModeEnded':
        await _handleFocusModeEnded();
        break;
      case 'onPermissionResult':
        _handlePermissionResult(call.arguments);
        break;
      case 'onPermissionStatusChanged':
        _handlePermissionStatusChanged(call.arguments);
        break;
      default:
        if (kDebugMode) {
          print('⚠️ Unknown method call: ${call.method}');
        }
    }
  }
  // ============================================================================
  // REAL DEVICE APPS INTEGRATION - FIXED
  // ============================================================================

  /// FIXED: Load real device apps from the system
  Future<void> _loadRealDeviceApps() async {
    try {
      if (!Platform.isAndroid) {
        _deviceApps = _getMockDeviceApps();
        if (kDebugMode) {
          print(
            '🔧 Loaded ${_deviceApps.length} mock apps for non-Android platform',
          );
        }
        return;
      }

      // Check cache first
      final cacheKey = 'installed_apps_${DateTime.now().day}';

      final cachedData = _installedAppsBox?.get(cacheKey);

      if (cachedData != null && cachedData['apps'] != null) {
        // Load from cache if it's recent (same day)
        final appsList = List<Map<String, dynamic>>.from(cachedData['apps']);
        _deviceApps = appsList.map((app) => DeviceApp.fromJson(app)).toList();

        if (kDebugMode) {
          print('📦 Loaded ${_deviceApps.length} apps from cache');
        }

        // Update blocked status
        _updateDeviceAppsBlockedStatus();
        return;
      }

      // Fetch installed apps using installed_apps package
      final apps = await InstalledApps.getInstalledApps(
        excludeSystemApps: false,
        excludeNonLaunchableApps: false,
        withIcon: true,
        packageNamePrefix: null,
        platformType: null,
      );

      _deviceApps = apps
          .map((appInfo) => DeviceApp.fromAppInfo(appInfo))
          .toList();

      // Cache the results
      await _installedAppsBox?.put(cacheKey, {
        'apps': _deviceApps.map((app) => app.toJson()).toList(),
        'cached_at': DateTime.now().millisecondsSinceEpoch,
        'count': _deviceApps.length,
      });

      if (kDebugMode) {
        print(
          '📱 Loaded ${_deviceApps.length} real device apps from installed_apps package',
        );
        print(
          '   User apps: ${_deviceApps.where((app) => !app.isSystemApp).length}',
        );
        print(
          '   Launchable apps: ${_deviceApps.where((app) => app.isLaunchable).length}',
        );
      }

      // Update blocked status based on current blocked apps
      _updateDeviceAppsBlockedStatus();
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error loading device apps: $e');
      }
      // Fallback to mock data
      _deviceApps = _getMockDeviceApps();
    }
  }

  /// Get installed apps from the system - FIXED: Now returns real apps
  Future<List<Map<String, dynamic>>> getInstalledApps() async {
    try {
      if (!Platform.isAndroid) {
        return _getMockDeviceApps().map((app) => app.toJson()).toList();
      }

      final result = await _channel.invokeMethod('getInstalledApps');
      if (result != null &&
          result['apps'] != null &&
          result['success'] == true) {
        return List<Map<String, dynamic>>.from(result['apps']);
      }

      return [];
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error getting installed apps: $e');
      }
      return _getMockDeviceApps().map((app) => app.toJson()).toList();
    }
  }

  /// Update blocked status for device apps
  void _updateDeviceAppsBlockedStatus() {
    final blockedPackages = _blockedApps.map((app) => app.packageName).toSet();
    _deviceApps = _deviceApps
        .map(
          (app) => app.copyWith(
            isBlocked: blockedPackages.contains(app.packageName),
          ),
        )
        .toList();
  }

  /// Get mock device apps for testing and non-Android platforms
  List<DeviceApp> _getMockDeviceApps() {
    return [
      DeviceApp(
        name: 'Instagram',
        packageName: 'com.instagram.android',
        icon: '📷',
        category: 'Social',
        isLaunchable: true,
      ),
      DeviceApp(
        name: 'TikTok',
        packageName: 'com.zhiliaoapp.musically',
        icon: '🎵',
        category: 'Social',
        isLaunchable: true,
      ),
      DeviceApp(
        name: 'Facebook',
        packageName: 'com.facebook.katana',
        icon: '📘',
        category: 'Social',
        isLaunchable: true,
      ),
      DeviceApp(
        name: 'Twitter',
        packageName: 'com.twitter.android',
        icon: '🐦',
        category: 'Social',
        isLaunchable: true,
      ),
      DeviceApp(
        name: 'YouTube',
        packageName: 'com.google.android.youtube',
        icon: '📺',
        category: 'Entertainment',
        isLaunchable: true,
      ),
      DeviceApp(
        name: 'WhatsApp',
        packageName: 'com.whatsapp',
        icon: '💬',
        category: 'Communication',
        isLaunchable: true,
      ),
      DeviceApp(
        name: 'Telegram',
        packageName: 'org.telegram.messenger',
        icon: '✈️',
        category: 'Communication',
        isLaunchable: true,
      ),
      DeviceApp(
        name: 'Reddit',
        packageName: 'com.reddit.frontpage',
        icon: '🔶',
        category: 'Social',
        isLaunchable: true,
      ),
      DeviceApp(
        name: 'Snapchat',
        packageName: 'com.snapchat.android',
        icon: '👻',
        category: 'Social',
        isLaunchable: true,
      ),
      DeviceApp(
        name: 'Discord',
        packageName: 'com.discord',
        icon: '🎧',
        category: 'Communication',
        isLaunchable: true,
      ),
      DeviceApp(
        name: 'Spotify',
        packageName: 'com.spotify.music',
        icon: '🎵',
        category: 'Entertainment',
        isLaunchable: true,
      ),
      DeviceApp(
        name: 'Netflix',
        packageName: 'com.netflix.mediaclient',
        icon: '🎬',
        category: 'Entertainment',
        isLaunchable: true,
      ),
      DeviceApp(
        name: 'Chrome',
        packageName: 'com.android.chrome',
        icon: '🌐',
        category: 'Productivity',
        isLaunchable: true,
      ),
      DeviceApp(
        name: 'Gmail',
        packageName: 'com.google.android.gm',
        icon: '📧',
        category: 'Productivity',
        isLaunchable: true,
      ),
      DeviceApp(
        name: 'Maps',
        packageName: 'com.google.android.apps.maps',
        icon: '🗺️',
        category: 'Productivity',
        isLaunchable: true,
      ),
    ];
  }

  /// Refresh device apps list
  Future<void> refreshDeviceApps() async {
    try {
      final cacheKey = 'installed_apps_${DateTime.now().day}';

      // Clear cache for the day
      await _installedAppsBox?.delete(cacheKey);

      // Reload apps (will fetch fresh from installed_apps package)
      await _loadRealDeviceApps();

      if (kDebugMode) {
        print('🔄 Device apps refreshed: ${_deviceApps.length} apps');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error refreshing device apps: $e');
      }
    }
  }

  /// Get device apps by category
  Map<String, List<DeviceApp>> getDeviceAppsByCategory() {
    final categories = <String, List<DeviceApp>>{};

    for (final app in _deviceApps) {
      categories.putIfAbsent(app.category, () => []).add(app);
    }

    // Sort each category by app name
    categories.forEach((category, apps) {
      apps.sort((a, b) => a.name.compareTo(b.name));
    });

    return categories;
  }

  /// Get only user-installed apps (excluding system apps)
  List<DeviceApp> getUserApps() {
    return _deviceApps
        .where((app) => !app.isSystemApp || app.isLaunchable)
        .toList();
  }

  /// Get only launchable apps
  List<DeviceApp> getLaunchableApps() {
    return _deviceApps.where((app) => app.isLaunchable).toList();
  }

  /// Search device apps
  List<DeviceApp> searchDeviceApps(String query) {
    if (query.isEmpty) return _deviceApps;

    final lowercaseQuery = query.toLowerCase();
    return _deviceApps
        .where(
          (app) =>
              app.name.toLowerCase().contains(lowercaseQuery) ||
              app.packageName.toLowerCase().contains(lowercaseQuery) ||
              app.category.toLowerCase().contains(lowercaseQuery),
        )
        .toList();
  }

  // ============================================================================
  // PERMISSION MANAGEMENT - FIXED
  // ============================================================================

  /// FIXED: Check and update all permission statuses
  Future<void> _checkAndUpdatePermissions() async {
    try {
      if (!Platform.isAndroid) {
        _permissionStatus = {
          'usageStats': false,
          'overlay': false,
          'notification': false,
          'accessibility': false,
          'deviceAdmin': false,
        };
        return;
      }

      final result = await _channel.invokeMethod('checkPermissions');
      if (result != null) {
        _permissionStatus = Map<String, bool>.from(result);
      }

      if (kDebugMode) {
        print('🔒 Permission status updated:');
        _permissionStatus.forEach((permission, granted) {
          print('   $permission: ${granted ? "✅" : "❌"}');
        });
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error checking permissions: $e');
      }
    }
  }

  /// Request all necessary permissions for app blocking
  Future<Map<String, bool>> requestPermissions() async {
    try {
      if (!Platform.isAndroid) {
        return {'message': false}; // App blocking only works on Android
      }

      final result = await _channel.invokeMethod('requestPermissions');
      final permissions = Map<String, bool>.from(result ?? {});

      // Update internal permission status
      _permissionStatus.addAll(permissions);

      return permissions;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Permission request failed: $e');
      }
      return {'error': false};
    }
  }

  /// Check current permission status
  Future<Map<String, bool>> checkPermissions() async {
    try {
      await _checkAndUpdatePermissions();
      return Map<String, bool>.from(_permissionStatus);
    } catch (e) {
      if (kDebugMode) {
        print('❌ Permission check failed: $e');
      }
      return {
        'usageStats': false,
        'overlay': false,
        'notification': false,
        'deviceAdmin': false,
        'accessibility': false,
      };
    }
  }

  /// Request specific permission
  Future<bool> requestSpecificPermission(String permission) async {
    try {
      if (!Platform.isAndroid) return false;

      final result = await _channel.invokeMethod(
        'request${permission.capitalize()}Permission',
      );
      final granted = result?['granted'] ?? false;

      // Update permission status
      _permissionStatus[permission] = granted;

      return granted;
    } catch (e) {
      if (kDebugMode) {
        print('❌ $permission permission request failed: $e');
      }
      return false;
    }
  }

  /// Handle permission result from native
  void _handlePermissionResult(Map<dynamic, dynamic> arguments) {
    final permission = arguments['permission'] as String?;
    final granted = arguments['granted'] as bool? ?? false;

    if (permission != null) {
      _permissionStatus[permission] = granted;
    }

    if (kDebugMode) {
      print('🔒 Permission result: $permission = $granted');
    }
  }

  /// Handle permission status changes
  void _handlePermissionStatusChanged(Map<dynamic, dynamic> arguments) {
    // Update permission status from native
    arguments.forEach((key, value) {
      if (key is String && value is bool) {
        _permissionStatus[key] = value;
      }
    });

    if (kDebugMode) {
      print('🔄 Permission status changed: $arguments');
    }
  }

  // ============================================================================
  // FOCUS MODE AND APP BLOCKING
  // ============================================================================

  /// Start focus mode with app blocking
  Future<bool> startFocusMode({Duration? duration}) async {
    try {
      // Check permissions first
      if (!hasRequiredPermissions) {
        if (kDebugMode) {
          print('❌ Cannot start focus mode: Missing required permissions');
        }
        return false;
      }

      _focusModeActive = true;
      await updateSetting('isFocusModeActive', true);
      await updateSetting(
        'focusStartTime',
        DateTime.now().millisecondsSinceEpoch,
      );

      if (duration != null) {
        await updateSetting('focusDuration', duration.inMinutes);
      }

      // Enable app blocking on native side
      await _enableAppBlocking();

      if (kDebugMode) {
        print('🎯 Focus mode started successfully');
      }

      return true;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Failed to start focus mode: $e');
      }
      return false;
    }
  }

  /// Stop focus mode and disable app blocking
  Future<bool> stopFocusMode() async {
    try {
      _focusModeActive = false;
      await updateSetting('isFocusModeActive', false);
      await updateSetting('focusStartTime', null);

      // Disable app blocking on native side
      await _disableAppBlocking();

      if (kDebugMode) {
        print('🎯 Focus mode stopped successfully');
      }

      return true;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Failed to stop focus mode: $e');
      }
      return false;
    }
  }

  /// End focus mode (alias for stopFocusMode)
  Future<bool> endFocusMode() async {
    return await stopFocusMode();
  }

  /// Check if focus mode is currently active
  Future<bool> isFocusModeActive() async {
    if (!_isInitialized) await init();
    return _focusModeActive;
  }

  /// Enable app blocking on native platform
  Future<void> _enableAppBlocking() async {
    try {
      if (!Platform.isAndroid) return;

      final blockedPackages = _blockedApps
          .where((app) => app.isBlocked)
          .map((app) => app.packageName)
          .toList();

      await _channel.invokeMethod('enableAppBlocking', {
        'blockedApps': blockedPackages,
        'blockMessage': 'Stay focused! This app is blocked during focus mode.',
        'duration': _settings['focusDuration'] ?? 25,
      });

      if (kDebugMode) {
        print('🚫 App blocking enabled for ${blockedPackages.length} apps');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Failed to enable app blocking: $e');
      }
    }
  }

  /// Disable app blocking on native platform
  Future<void> _disableAppBlocking() async {
    try {
      if (!Platform.isAndroid) return;

      await _channel.invokeMethod('disableAppBlocking');

      if (kDebugMode) {
        print('✅ App blocking disabled');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Failed to disable app blocking: $e');
      }
    }
  }

  /// Check if an app is currently blocked
  Future<bool> isAppBlocked(String packageName) async {
    if (!_isInitialized) await init();

    final blockedApp = _blockedApps.firstWhere(
      (app) => app.packageName == packageName,
      orElse: () => BlockedApp(
        name: '',
        packageName: '',
        icon: '',
        category: AppCategory.other,
      ),
    );

    return blockedApp.isBlocked &&
        blockedApp.packageName.isNotEmpty &&
        _focusModeActive &&
        !isEmergencyOverrideActive;
  }

  /// Handle when a blocked app launch is attempted
  Future<void> _handleAppLaunchBlocked(String packageName) async {
    try {
      // Record the block attempt
      await recordBlockAttempt(packageName);

      // Show blocking message/notification
      await _showBlockingMessage(packageName);

      if (kDebugMode) {
        print('🚫 Blocked app launch attempt: $packageName');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error handling blocked app: $e');
      }
    }
  }

  /// Show blocking message to user
  Future<void> _showBlockingMessage(String packageName) async {
    try {
      final deviceApp = _deviceApps.firstWhere(
        (app) => app.packageName == packageName,
        orElse: () => DeviceApp(
          name: 'Unknown App',
          packageName: packageName,
          icon: '📱',
          category: 'Other',
        ),
      );

      final message = getRandomMessage();

      if (Platform.isAndroid) {
        await _channel.invokeMethod('showBlockingMessage', {
          'appName': deviceApp.name,
          'packageName': packageName,
          'message': message.subtitle,
          'motivationalQuote': message.footer,
        });
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Failed to show blocking message: $e');
      }
    }
  }

  /// Handle when focus mode ends naturally
  Future<void> _handleFocusModeEnded() async {
    try {
      await stopFocusMode();

      // Show focus session completed message
      if (Platform.isAndroid) {
        await _channel.invokeMethod('showFocusCompleted', {
          'message': 'Great job! Focus session completed! 🎉',
          'timeBlocked': _calculateTimeSaved(),
          'appsBlocked': _blockedApps.where((app) => app.isBlocked).length,
          'blockedAttempts': _blockedAttempts.values.fold(
            0,
            (sum, attempts) => sum + attempts,
          ),
        });
      }

      if (kDebugMode) {
        print('🎉 Focus mode ended naturally');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error handling focus mode end: $e');
      }
    }
  }

  // ============================================================================
  // APP MANAGEMENT - FIXED: Added missing addBlockedApp method
  // ============================================================================

  /// Add a new blocked app - FIXED: Added missing method
  Future<void> addBlockedApp(BlockedApp app) async {
    await ErrorHandler.handleAsyncError(() async {
      if (!_isInitialized) await init();

      // Check if app already exists
      final existingIndex = _blockedApps.indexWhere(
        (existing) => existing.packageName == app.packageName,
      );

      if (existingIndex >= 0) {
        // Update existing app
        _blockedApps[existingIndex] = app;
      } else {
        // Add new app
        _blockedApps.add(app);
      }

      await _saveBlockedApps();
      _updateDeviceAppsBlockedStatus();

      // Update native blocking if focus mode is active
      if (_focusModeActive) {
        await _enableAppBlocking();
      }

      if (kDebugMode) {
        print('➕ Added blocked app: ${app.name}');
      }
    }, context: 'Add blocked app');
  }

  /// Add a new blocked app from device app
  Future<void> addBlockedAppFromDevice(DeviceApp deviceApp) async {
    await ErrorHandler.handleAsyncError(() async {
      if (!_isInitialized) await init();

      // Check if app already exists
      final existingIndex = _blockedApps.indexWhere(
        (existing) => existing.packageName == deviceApp.packageName,
      );

      final blockedApp = BlockedApp(
        id: existingIndex >= 0
            ? _blockedApps[existingIndex].id
            : DateTime.now().millisecondsSinceEpoch.toString(),
        name: deviceApp.name,
        packageName: deviceApp.packageName,
        icon: deviceApp.icon,
        category: _getAppCategoryFromString(deviceApp.category),
        isBlocked: true,
      );

      if (existingIndex >= 0) {
        // Update existing app
        _blockedApps[existingIndex] = blockedApp;
      } else {
        // Add new app
        _blockedApps.add(blockedApp);
      }

      await _saveBlockedApps();
      _updateDeviceAppsBlockedStatus();

      // Update native blocking if focus mode is active
      if (_focusModeActive) {
        await _enableAppBlocking();
      }

      if (kDebugMode) {
        print('➕ Added blocked app: ${blockedApp.name}');
      }
    }, context: 'Add blocked app from device');
  }

  /// Remove a blocked app
  Future<void> removeBlockedApp(String appId) async {
    await ErrorHandler.handleAsyncError(() async {
      if (!_isInitialized) await init();

      _blockedApps.removeWhere((app) => app.id == appId);
      await _appsBox?.delete(appId);
      await _saveBlockedApps();
      _updateDeviceAppsBlockedStatus();

      // Update native blocking if focus mode is active
      if (_focusModeActive) {
        await _enableAppBlocking();
      }

      if (kDebugMode) {
        print('➖ Removed blocked app: $appId');
      }
    }, context: 'Remove blocked app');
  }

  /// Update a blocked app
  Future<void> updateBlockedApp(BlockedApp updatedApp) async {
    await ErrorHandler.handleAsyncError(() async {
      if (!_isInitialized) await init();

      final index = _blockedApps.indexWhere((app) => app.id == updatedApp.id);
      if (index != -1) {
        _blockedApps[index] = updatedApp;
        await _saveBlockedApps();
        _updateDeviceAppsBlockedStatus();

        // Update native blocking if focus mode is active
        if (_focusModeActive) {
          await _enableAppBlocking();
        }

        if (kDebugMode) {
          print('🔄 Updated blocked app: ${updatedApp.name}');
        }
      }
    }, context: 'Update blocked app');
  }

  /// Get all blocked apps
  Future<List<BlockedApp>> getAllBlockedApps() async {
    if (!_isInitialized) await init();
    return List<BlockedApp>.from(_blockedApps);
  }

  /// Save blocked apps to storage
  Future<void> _saveBlockedApps() async {
    try {
      await _appsBox?.clear();
      for (final app in _blockedApps) {
        await _appsBox?.put(app.id, app);
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Failed to save blocked apps: $e');
      }
    }
  }

  /// Convert string category to AppCategory enum
  AppCategory _getAppCategoryFromString(String category) {
    switch (category.toLowerCase()) {
      case 'social':
        return AppCategory.social;
      case 'entertainment':
        return AppCategory.entertainment;
      case 'communication':
        return AppCategory.communication;
      case 'games':
        return AppCategory.games;
      case 'productivity':
        return AppCategory.productivity;
      default:
        return AppCategory.other;
    }
  }
  // ============================================================================
  // STATISTICS AND MONITORING
  // ============================================================================

  /// Record a blocked app attempt
  Future<void> recordBlockAttempt(String packageName) async {
    await ErrorHandler.handleAsyncError(() async {
      if (!_isInitialized) await init();

      final today = DateTime.now().toIso8601String().split('T')[0];
      final todayStats =
          _statsBox?.get('stats_$today', defaultValue: <String, dynamic>{}) ??
          <String, dynamic>{};

      final blockAttempts = Map<String, int>.from(
        todayStats['blockAttempts'] ?? {},
      );
      blockAttempts[packageName] = (blockAttempts[packageName] ?? 0) + 1;

      todayStats['blockAttempts'] = blockAttempts;
      todayStats['timeSaved'] =
          (todayStats['timeSaved'] ?? 0) +
          2; // Assume 2 minutes saved per block

      await _statsBox?.put('stats_$today', todayStats);
      _blockedAttempts[packageName] = blockAttempts[packageName]!;

      if (kDebugMode) {
        print(
          '📊 Recorded block attempt: $packageName (${blockAttempts[packageName]} today)',
        );
      }
    }, context: 'Record block attempt');
  }

  /// Record blocked attempt (alias)
  Future<void> recordBlockedAttempt(String packageName) async {
    await recordBlockAttempt(packageName);
  }

  /// Get blocked attempts
  Future<Map<String, int>> getBlockedAttempts() async {
    if (!_isInitialized) await init();
    return Map<String, int>.from(_blockedAttempts);
  }

  /// Get all blocked attempts (alias)
  Future<Map<String, int>> getAllBlockedAttempts() async {
    return await getBlockedAttempts();
  }

  /// Get today's statistics
  Future<Map<String, dynamic>> getTodayStatistics() async {
    return await ErrorHandler.handleAsyncError(() async {
          if (!_isInitialized) await init();

          final today = DateTime.now().toIso8601String().split('T')[0];
          final todayStats =
              _statsBox?.get(
                'stats_$today',
                defaultValue: <String, dynamic>{},
              ) ??
              <String, dynamic>{};
          final blockAttempts = Map<String, int>.from(
            todayStats['blockAttempts'] ?? {},
          );

          return {
            'blockAttempts': blockAttempts,
            'timeSaved': todayStats['timeSaved'] ?? 0,
            'totalBlocks': blockAttempts.values.fold(
              0,
              (sum, attempts) => sum + attempts,
            ),
            'focusSessionsCompleted': todayStats['focusSessionsCompleted'] ?? 0,
            'mostBlockedApp': _getMostBlockedApp(blockAttempts),
            'currentStreak': _settings['currentStreak'] ?? 0,
          };
        }, context: 'Get today statistics') ??
        {
          'blockAttempts': <String, int>{},
          'timeSaved': 0,
          'totalBlocks': 0,
          'focusSessionsCompleted': 0,
          'mostBlockedApp': null,
          'currentStreak': 0,
        };
  }

  /// Get weekly statistics
  Future<Map<String, dynamic>> getWeeklyStatistics() async {
    return await ErrorHandler.handleAsyncError(() async {
          if (!_isInitialized) await init();

          final now = DateTime.now();
          final weekStart = now.subtract(Duration(days: now.weekday - 1));

          Map<String, dynamic> weeklyStats = {
            'totalBlocks': 0,
            'dailyBlocks': <String, int>{},
            'topBlockedApps': <String, int>{},
            'totalTimeSaved': 0,
            'averageFocusTime': 0,
            'streak': await _calculateStreak(),
            'productivity': 0,
          };

          for (int i = 0; i < 7; i++) {
            final day = weekStart.add(Duration(days: i));
            final dayKey = day.toIso8601String().split('T')[0];
            final dayStats =
                _statsBox?.get(
                  'stats_$dayKey',
                  defaultValue: <String, dynamic>{},
                ) ??
                <String, dynamic>{};

            final dayBlocks = Map<String, int>.from(
              dayStats['blockAttempts'] ?? {},
            );
            final dayTotal = dayBlocks.values.fold(
              0,
              (sum, attempts) => sum + attempts,
            );

            weeklyStats['dailyBlocks'][dayKey] = dayTotal;
            weeklyStats['totalBlocks'] += dayTotal;
            weeklyStats['totalTimeSaved'] += dayStats['timeSaved'] ?? 0;

            dayBlocks.forEach((app, blocks) {
              weeklyStats['topBlockedApps'][app] =
                  (weeklyStats['topBlockedApps'][app] ?? 0) + blocks;
            });
          }

          // Calculate productivity score
          weeklyStats['productivity'] = _calculateProductivityScore(
            weeklyStats,
          );

          return weeklyStats;
        }, context: 'Get weekly statistics') ??
        {
          'totalBlocks': 0,
          'dailyBlocks': <String, int>{},
          'topBlockedApps': <String, int>{},
          'totalTimeSaved': 0,
          'averageFocusTime': 0,
          'streak': 0,
          'productivity': 0,
        };
  }

  /// Get most blocked app from attempts map
  String? _getMostBlockedApp(Map<String, int> blockAttempts) {
    if (blockAttempts.isEmpty) return null;

    final sortedEntries = blockAttempts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final mostBlockedPackage = sortedEntries.first.key;
    final deviceApp = _deviceApps.firstWhere(
      (app) => app.packageName == mostBlockedPackage,
      orElse: () => DeviceApp(
        name: 'Unknown App',
        packageName: mostBlockedPackage,
        icon: '📱',
        category: 'Other',
      ),
    );

    return deviceApp.name;
  }

  /// Calculate current focus streak
  Future<int> _calculateStreak() async {
    try {
      final streakData =
          _settingsBox?.get('streak', defaultValue: <String, dynamic>{}) ??
          <String, dynamic>{};
      return streakData['currentStreak'] ?? 0;
    } catch (e) {
      return 0;
    }
  }

  /// Calculate productivity score
  int _calculateProductivityScore(Map<String, dynamic> weeklyStats) {
    try {
      final totalBlocks = weeklyStats['totalBlocks'] as int;
      final streak = weeklyStats['streak'] as int;
      final timeSaved = weeklyStats['totalTimeSaved'] as int;

      // Simple scoring algorithm (0-100)
      int score = 0;
      score += (totalBlocks * 2).clamp(0, 40); // Max 40 points for blocks
      score += (streak * 5).clamp(0, 30); // Max 30 points for streak
      score += (timeSaved ~/ 10).clamp(0, 30); // Max 30 points for time saved

      return score.clamp(0, 100);
    } catch (e) {
      return 0;
    }
  }

  /// Calculate time saved during current session
  int _calculateTimeSaved() {
    final totalAttempts = _blockedAttempts.values.fold(
      0,
      (sum, attempts) => sum + attempts,
    );
    return totalAttempts * 2; // Assume 2 minutes saved per blocked attempt
  }

  // ============================================================================
  // NOTIFICATION AND MESSAGING
  // ============================================================================

  /// Show block notification
  Future<void> showBlockNotification(String appName, String message) async {
    try {
      if (Platform.isAndroid) {
        await _channel.invokeMethod('showBlockNotification', {
          'appName': appName,
          'message': message,
        });
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error showing block notification: $e');
      }
    }
  }

  /// Get random block message
  BlockMessage getRandomMessage() {
    final messages = BlockMessage.allMessages;
    final randomIndex = DateTime.now().millisecondsSinceEpoch % messages.length;
    return messages[randomIndex];
  }

  /// Get block message based on theme
  BlockMessage getBlockMessage(MessageTheme theme) {
    switch (theme) {
      case MessageTheme.motivational:
        return BlockMessage.motivational;
      case MessageTheme.humorous:
        return BlockMessage.humorous;
      case MessageTheme.challenging:
        return BlockMessage.challenging;
      case MessageTheme.supportive:
        return BlockMessage.supportive;
      case MessageTheme.funny:
        return BlockMessage.funny;
    }
  }

  // ============================================================================
  // EMERGENCY OVERRIDE
  // ============================================================================

  /// Activate emergency override
  Future<void> activateEmergencyOverride({
    Duration duration = const Duration(minutes: 15),
  }) async {
    try {
      final expiryTime = DateTime.now().add(duration);
      await updateSetting('isEmergencyOverrideActive', true);
      await updateSetting(
        'emergencyOverrideExpiry',
        expiryTime.millisecondsSinceEpoch,
      );

      if (kDebugMode) {
        print(
          '🚨 Emergency override activated for ${duration.inMinutes} minutes',
        );
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error activating emergency override: $e');
      }
    }
  }

  /// Deactivate emergency override
  Future<void> deactivateEmergencyOverride() async {
    try {
      await updateSetting('isEmergencyOverrideActive', false);
      await updateSetting('emergencyOverrideExpiry', null);

      if (kDebugMode) {
        print('✅ Emergency override deactivated');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error deactivating emergency override: $e');
      }
    }
  }

  // ============================================================================
  // STREAK MANAGEMENT
  // ============================================================================

  /// Update streak
  Future<void> updateStreak() async {
    try {
      final currentStreak = _settings['currentStreak'] ?? 0;
      await updateSetting('currentStreak', currentStreak + 1);

      if (kDebugMode) {
        print('🔥 Streak updated to: ${currentStreak + 1}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error updating streak: $e');
      }
    }
  }

  // ============================================================================
  // SETTINGS MANAGEMENT
  // ============================================================================

  /// Get app settings
  Future<Map<String, dynamic>> getSettings() async {
    if (!_isInitialized) await init();
    return Map<String, dynamic>.from(_settings);
  }

  /// Update a specific setting
  Future<void> updateSetting(String key, dynamic value) async {
    await ErrorHandler.handleAsyncError(() async {
      if (!_isInitialized) await init();

      _settings[key] = value;
      await _saveSettings();

      if (kDebugMode) {
        print('⚙️ Setting updated: $key = $value');
      }
    }, context: 'Update setting');
  }

  /// Save settings to storage
  Future<void> _saveSettings() async {
    try {
      await _settingsBox?.put('settings', _settings);
    } catch (e) {
      if (kDebugMode) {
        print('❌ Failed to save settings: $e');
      }
    }
  }

  // ============================================================================
  // UTILITY METHODS
  // ============================================================================

  /// Get current focus session info
  Future<Map<String, dynamic>?> getCurrentFocusSession() async {
    if (!_focusModeActive) return null;

    final startTime = _settings['focusStartTime'] as int?;
    final duration = _settings['focusDuration'] as int?;

    if (startTime == null) return null;

    final sessionStart = DateTime.fromMillisecondsSinceEpoch(startTime);
    final now = DateTime.now();
    final elapsed = now.difference(sessionStart);

    return {
      'startTime': sessionStart.toIso8601String(),
      'elapsedMinutes': elapsed.inMinutes,
      'totalMinutes': duration ?? 25,
      'remainingMinutes': (duration ?? 25) - elapsed.inMinutes,
      'isActive': _focusModeActive,
      'blockedApps': _blockedApps.where((app) => app.isBlocked).length,
      'blockedAttempts': _blockedAttempts.values.fold(
        0,
        (sum, attempts) => sum + attempts,
      ),
    };
  }

  /// Clear all data
  Future<void> clearAllData() async {
    try {
      await _appsBox?.clear();
      await _statsBox?.clear();
      await _settingsBox?.clear();
      await _deviceAppsBox?.clear();

      _blockedApps.clear();
      _deviceApps.clear();
      _settings.clear();
      _blockedAttempts.clear();
      _focusModeActive = false;

      // Reset to default settings
      _settings = {
        'autoBlockDuringFocus': true,
        'showBlockNotifications': true,
        'messageTheme': 0,
        'currentStreak': 0,
        'isFocusModeActive': false,
        'isEmergencyOverrideActive': false,
        'emergencyOverrideExpiry': null,
      };

      if (kDebugMode) {
        print('🗑️ All app blocker data cleared');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Failed to clear data: $e');
      }
    }
  }

  /// Dispose and cleanup resources
  Future<void> dispose() async {
    try {
      await _appsBox?.close();
      await _statsBox?.close();
      await _settingsBox?.close();
      await _deviceAppsBox?.close();

      _isInitialized = false;

      if (kDebugMode) {
        print('♻️ AppBlockerService disposed');
      }
    } catch (e) {
      if (kDebugMode) {
        print('⚠️ Error during disposal: $e');
      }
    }
  }

  // ============================================================================
  // PRODUCTIVITY FEATURES
  // ============================================================================

  /// Get productivity insights
  Future<Map<String, dynamic>> getProductivityInsights() async {
    try {
      final todayStats = await getTodayStatistics();
      final weeklyStats = await getWeeklyStatistics();

      return {
        'focusScore': _calculateFocusScore(todayStats, weeklyStats),
        'improvementSuggestions': _getImprovementSuggestions(todayStats),
        'achievements': _getAchievements(weeklyStats),
        'nextGoal': _getNextGoal(weeklyStats),
        'weeklyProgress': _getWeeklyProgress(weeklyStats),
        'topDistractingApps': _getTopDistractingApps(weeklyStats),
      };
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error getting productivity insights: $e');
      }
      return {};
    }
  }

  /// Calculate focus score based on statistics
  int _calculateFocusScore(
    Map<String, dynamic> todayStats,
    Map<String, dynamic> weeklyStats,
  ) {
    try {
      final todayBlocks = (todayStats['totalBlocks'] as num?)?.toInt() ?? 0;
      final streak = (weeklyStats['streak'] as num?)?.toInt() ?? 0;
      final weeklyBlocks = (weeklyStats['totalBlocks'] as num?)?.toInt() ?? 0;

      // Advanced scoring algorithm
      int score = 0;
      score += (todayBlocks * 5).clamp(
        0,
        50,
      ); // Max 50 points for today's blocks
      score += (streak * 10).clamp(0, 30); // Max 30 points for streak
      score += (weeklyBlocks ~/ 7 * 3).clamp(
        0,
        20,
      ); // Max 20 points for average weekly blocks

      return score.clamp(0, 100);
    } catch (e) {
      return 0;
    }
  }

  /// Get improvement suggestions
  List<String> _getImprovementSuggestions(Map<String, dynamic> todayStats) {
    final suggestions = <String>[];
    final totalBlocks = todayStats['totalBlocks'] ?? 0;

    if (totalBlocks == 0) {
      suggestions.add('Try blocking some distracting apps to improve focus');
      suggestions.add('Start with just 2-3 apps that distract you most');
    } else if (totalBlocks < 5) {
      suggestions.add('Consider extending your focus sessions');
      suggestions.add('Try blocking additional social media apps');
    } else if (totalBlocks > 20) {
      suggestions.add('Great self-control! Try longer focus sessions');
      suggestions.add('Consider using productivity apps during breaks');
    }

    suggestions.add('Set specific times for checking blocked apps');
    suggestions.add('Use the Pomodoro technique with focus mode');

    return suggestions;
  }

  /// Get achievements
  List<String> _getAchievements(Map<String, dynamic> weeklyStats) {
    final achievements = <String>[];
    final streak = weeklyStats['streak'] ?? 0;
    final totalBlocks = weeklyStats['totalBlocks'] ?? 0;
    final timeSaved = weeklyStats['totalTimeSaved'] ?? 0;

    if (streak >= 3) achievements.add('🔥 3-Day Streak');
    if (streak >= 7) achievements.add('🏆 Week Warrior');
    if (streak >= 30) achievements.add('🎖️ Focus Master');
    if (totalBlocks >= 50) achievements.add('🛡️ Distraction Defender');
    if (totalBlocks >= 100) achievements.add('⚔️ Focus Champion');
    if (timeSaved >= 60) achievements.add('⏰ Time Saver');
    if (timeSaved >= 300) achievements.add('🚀 Productivity Pro');

    return achievements;
  }

  /// Get next goal
  String _getNextGoal(Map<String, dynamic> weeklyStats) {
    final streak = weeklyStats['streak'] ?? 0;
    final totalBlocks = weeklyStats['totalBlocks'] ?? 0;
    final timeSaved = weeklyStats['totalTimeSaved'] ?? 0;

    if (streak < 3) return 'Reach a 3-day focus streak';
    if (streak < 7) return 'Achieve a 7-day focus streak';
    if (streak < 30) return 'Maintain focus for 30 days';
    if (totalBlocks < 50) return 'Block 50 distraction attempts';
    if (timeSaved < 300) return 'Save 5 hours through blocking';
    return 'Master your focus habits';
  }

  /// Get weekly progress
  Map<String, dynamic> _getWeeklyProgress(Map<String, dynamic> weeklyStats) {
    final dailyBlocks = Map<String, int>.from(weeklyStats['dailyBlocks'] ?? {});
    final totalBlocks = weeklyStats['totalBlocks'] ?? 0;

    return {
      'dailyAverage': totalBlocks / 7,
      'mostProductiveDay': _getMostProductiveDay(dailyBlocks),
      'improvementTrend': _getImprovementTrend(dailyBlocks),
      'consistency': _getConsistencyScore(dailyBlocks),
    };
  }

  /// Get most productive day
  String _getMostProductiveDay(Map<String, int> dailyBlocks) {
    if (dailyBlocks.isEmpty) return 'No data';

    final maxEntry = dailyBlocks.entries.reduce(
      (a, b) => a.value > b.value ? a : b,
    );
    final date = DateTime.parse(maxEntry.key);
    return '${_getDayName(date.weekday)} (${maxEntry.value} blocks)';
  }

  /// Get day name from weekday number
  String _getDayName(int weekday) {
    const days = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ];
    return days[weekday - 1];
  }

  /// Get improvement trend
  String _getImprovementTrend(Map<String, int> dailyBlocks) {
    if (dailyBlocks.length < 2) return 'Not enough data';

    final values = dailyBlocks.values.toList();
    final recent = values.sublist(values.length - 3);
    final earlier = values.sublist(0, values.length - 3);

    final recentAvg = recent.isEmpty
        ? 0
        : recent.reduce((a, b) => a + b) / recent.length;
    final earlierAvg = earlier.isEmpty
        ? 0
        : earlier.reduce((a, b) => a + b) / earlier.length;

    if (recentAvg > earlierAvg * 1.1) return 'Improving ↗️';
    if (recentAvg < earlierAvg * 0.9) return 'Declining ↘️';
    return 'Stable →';
  }

  /// Get consistency score
  double _getConsistencyScore(Map<String, int> dailyBlocks) {
    if (dailyBlocks.isEmpty) return 0.0;

    final values = dailyBlocks.values.toList();
    final avg = values.reduce((a, b) => a + b) / values.length;
    final variance =
        values.map((v) => (v - avg) * (v - avg)).reduce((a, b) => a + b) /
        values.length;

    // Convert variance to consistency score (0-1, higher is more consistent)
    return (1 / (1 + variance)).clamp(0.0, 1.0);
  }

  /// Get top distracting apps
  List<Map<String, dynamic>> _getTopDistractingApps(
    Map<String, dynamic> weeklyStats,
  ) {
    final topApps = Map<String, int>.from(weeklyStats['topBlockedApps'] ?? {});

    final sortedApps = topApps.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return sortedApps.take(5).map((entry) {
      final deviceApp = _deviceApps.firstWhere(
        (app) => app.packageName == entry.key,
        orElse: () => DeviceApp(
          name: 'Unknown App',
          packageName: entry.key,
          icon: '📱',
          category: 'Other',
        ),
      );

      return {
        'name': deviceApp.name,
        'icon': deviceApp.icon,
        'blocks': entry.value,
        'category': deviceApp.category,
      };
    }).toList();
  }

  // ============================================================================
  // EXPORT AND BACKUP - FIXED: Fixed return type issue
  // ============================================================================

  /// FIXED: Export app blocker data - Fixed return type
  Future<Map<String, dynamic>> exportData() async {
    try {
      return {
        'version': '2.0',
        'exportDate': DateTime.now().toIso8601String(),
        'blockedApps': _blockedApps.map((app) => app.toJson()).toList(),
        'deviceApps': _deviceApps.map((app) => app.toJson()).toList(),
        'settings': _settings,
        'statistics': await getWeeklyStatistics(),
        'productivity': await getProductivityInsights(),
        'permissionStatus': _permissionStatus,
      };
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error exporting data: $e');
      }
      // Return empty map instead of false to match return type
      return <String, dynamic>{};
    }
  }

  /// Import app blocker data
  Future<bool> importData(Map<String, dynamic> data) async {
    try {
      if (!_isInitialized) await init();

      // Validate data format
      if (data['version'] == null || data['blockedApps'] == null) {
        throw Exception('Invalid data format');
      }

      // Clear existing data
      await clearAllData();

      // Import blocked apps
      final blockedAppsData = List<Map<String, dynamic>>.from(
        data['blockedApps'] ?? [],
      );
      for (final appData in blockedAppsData) {
        try {
          final blockedApp = BlockedApp.fromJson(appData);
          await addBlockedApp(blockedApp);
        } catch (e) {
          if (kDebugMode) {
            print('⚠️ Failed to import blocked app: $e');
          }
        }
      }

      // Import settings
      final importedSettings = Map<String, dynamic>.from(
        data['settings'] ?? {},
      );
      for (final entry in importedSettings.entries) {
        await updateSetting(entry.key, entry.value);
      }

      // Import statistics if available
      final statisticsData = data['statistics'] as Map<String, dynamic>?;
      if (statisticsData != null) {
        // Import daily statistics
        final dailyBlocks = Map<String, int>.from(
          statisticsData['dailyBlocks'] ?? {},
        );
        for (final entry in dailyBlocks.entries) {
          final dayStats = {
            'blockAttempts': <String, int>{},
            'timeSaved': entry.value * 2, // Estimate time saved
          };
          await _statsBox?.put('stats_${entry.key}', dayStats);
        }
      }

      if (kDebugMode) {
        print('✅ Data imported successfully');
        print('   Blocked apps: ${blockedAppsData.length}');
        print('   Settings: ${importedSettings.length}');
      }

      return true;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error importing data: $e');
      }
      return false;
    }
  }

  /// Create backup of current data
  Future<Map<String, dynamic>> createBackup() async {
    try {
      final backup = await exportData();
      backup['backupType'] = 'full';
      backup['backupDate'] = DateTime.now().toIso8601String();
      backup['appVersion'] = '2.0';

      return backup;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error creating backup: $e');
      }
      return <String, dynamic>{};
    }
  }

  /// Restore from backup
  Future<bool> restoreFromBackup(Map<String, dynamic> backup) async {
    try {
      // Validate backup format
      if (backup['backupType'] != 'full' || backup['blockedApps'] == null) {
        throw Exception('Invalid backup format');
      }

      return await importData(backup);
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error restoring from backup: $e');
      }
      return false;
    }
  }

  // ============================================================================
  // ADDITIONAL UTILITY METHODS
  // ============================================================================

  /// Get app blocker version
  String getVersion() => '2.0';

  /// Check if service needs migration
  Future<bool> needsMigration() async {
    try {
      final version = _settings['version'] as String?;
      return version == null || version != getVersion();
    } catch (e) {
      return true;
    }
  }

  /// Perform data migration if needed
  Future<void> migrateData() async {
    try {
      if (!await needsMigration()) return;

      // Migration logic for different versions
      final currentVersion = _settings['version'] as String?;

      if (currentVersion == null || currentVersion == '1.0') {
        // Migrate from v1.0 to v2.0
        await _migrateFromV1ToV2();
      }

      // Update version
      await updateSetting('version', getVersion());

      if (kDebugMode) {
        print('✅ Data migration completed to version ${getVersion()}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Data migration failed: $e');
      }
    }
  }

  /// Migrate from version 1.0 to 2.0
  Future<void> _migrateFromV1ToV2() async {
    try {
      // Add new default settings
      _settings.putIfAbsent('messageTheme', () => 0);
      _settings.putIfAbsent('autoBlockDuringFocus', () => true);
      _settings.putIfAbsent('showBlockNotifications', () => true);

      // Convert old blocked apps format if needed
      for (int i = 0; i < _blockedApps.length; i++) {
        final app = _blockedApps[i];
        if (app.id.isEmpty) {
          // Generate ID for apps without one
          final updatedApp = BlockedApp(
            id: DateTime.now().millisecondsSinceEpoch.toString() + '_$i',
            name: app.name,
            packageName: app.packageName,
            icon: app.icon,
            category: app.category,
            isBlocked: app.isBlocked,
          );
          _blockedApps[i] = updatedApp;
        }
      }

      await _saveBlockedApps();
      await _saveSettings();

      if (kDebugMode) {
        print('✅ Migrated from v1.0 to v2.0');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ V1 to V2 migration failed: $e');
      }
    }
  }

  /// Get service health status
  Map<String, dynamic> getHealthStatus() {
    return {
      'isInitialized': _isInitialized,
      'hasRequiredPermissions': hasRequiredPermissions,
      'isSupportedPlatform': isSupported,
      'focusModeActive': _focusModeActive,
      'blockedAppsCount': _blockedApps.length,
      'deviceAppsCount': _deviceApps.length,
      'version': getVersion(),
      'permissionStatus': _permissionStatus,
      'emergencyOverrideActive': isEmergencyOverrideActive,
    };
  }
}
