import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:daily_planner/services/app_blocker_service.dart';
import 'package:daily_planner/models/blocked_app.dart' as blocked_app_model;
import 'package:daily_planner/utils/error_handler.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ============================================================================
// MODELS & DATA CLASSES
// ============================================================================

/// App information for installed apps
class AppInfo {
  final String name;
  final String packageName;
  final String? icon;
  final String? category;
  final bool isLaunchable;
  final bool isSystemApp;

  const AppInfo({
    required this.name,
    required this.packageName,
    this.icon,
    this.category,
    this.isLaunchable = true,
    this.isSystemApp = false,
  });

  /// Convert AppInfo to JSON
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'packageName': packageName,
      'icon': icon,
      'category': category,
      'isLaunchable': isLaunchable,
      'isSystemApp': isSystemApp,
    };
  }

  /// Create AppInfo from JSON
  factory AppInfo.fromJson(Map<String, dynamic> json) {
    return AppInfo(
      name: json['name'] ?? '',
      packageName: json['packageName'] ?? '',
      icon: json['icon'],
      category: json['category'],
      isLaunchable: json['isLaunchable'] ?? true,
      isSystemApp: json['isSystemApp'] ?? false,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AppInfo && other.packageName == packageName;
  }

  @override
  int get hashCode => packageName.hashCode;
}

/// Permission status data class
class PermissionStatus {
  final String name;
  final bool isGranted;
  final bool isPermanentlyDenied;
  final String description;
  final String settingsAction;

  const PermissionStatus({
    required this.name,
    required this.isGranted,
    required this.isPermanentlyDenied,
    required this.description,
    required this.settingsAction,
  });
}

/// Focus session statistics
class FocusStats {
  final int sessionsToday;
  final Duration totalFocusTimeToday;
  final int appsBlockedToday;
  final int blockAttemptsToday;
  final Duration averageSessionLength;
  final int currentStreak;

  const FocusStats({
    required this.sessionsToday,
    required this.totalFocusTimeToday,
    required this.appsBlockedToday,
    required this.blockAttemptsToday,
    required this.averageSessionLength,
    required this.currentStreak,
  });

  factory FocusStats.empty() {
    return const FocusStats(
      sessionsToday: 0,
      totalFocusTimeToday: Duration.zero,
      appsBlockedToday: 0,
      blockAttemptsToday: 0,
      averageSessionLength: Duration.zero,
      currentStreak: 0,
    );
  }
}

// ============================================================================
// APP BLOCKER MANAGER - MAIN SERVICE (PART 1)
// ============================================================================

/// Manager class for app blocking functionality
class AppBlockerManager {
  // ========================================
  // SINGLETON PATTERN
  // ========================================

  static final AppBlockerManager _instance = AppBlockerManager._internal();
  factory AppBlockerManager() => _instance;
  AppBlockerManager._internal();

  // ========================================
  // PRIVATE FIELDS
  // ========================================

  final AppBlockerService _service = AppBlockerService();

  // Method channels for native communication
  static const MethodChannel _appBlockerChannel =
  MethodChannel('com.daily_planner/app_blocker');

  // Cached data
  List<AppInfo>? _cachedInstalledApps;
  DateTime? _lastAppsCacheTime;
  static const Duration _cacheValidDuration = Duration(hours: 1);

  // State management
  bool _isInitialized = false;
  bool _isFocusModeActive = false;
  List<String> _currentlyBlockedPackages = [];
  DateTime? _focusStartTime;
  Duration? _focusDuration;

  // Platform support
  bool? _platformSupported;

  // ========================================
  // PLATFORM SUPPORT CHECK
  // ========================================

  /// Check if app blocking is supported on current platform
  bool get isSupported {
    if (_platformSupported != null) {
      return _platformSupported!;
    }

    // App blocking is primarily supported on Android
    // iOS has more restrictions but basic functionality might work
    if (kIsWeb) {
      _platformSupported = false;
    } else if (Platform.isAndroid) {
      _platformSupported = true;
    } else if (Platform.isIOS) {
      // iOS has limited support - can show blocking UI but can't actually block apps
      _platformSupported = false; // Set to false for now, can be enabled with limited functionality
    } else {
      _platformSupported = false;
    }

    return _platformSupported!;
  }

  /// Force platform support check (for testing)
  void setPlatformSupported(bool supported) {
    _platformSupported = supported;
  }

  // ========================================
  // INITIALIZATION
  // ========================================

  /// Initialize the app blocker manager
  Future<bool> initialize() async {
    return await ErrorHandler.handleAsyncError(() async {
      if (_isInitialized) return true;

      // Check platform support first
      if (!isSupported) {
        ErrorHandler.logInfo('App blocking not supported on this platform');
        return false;
      }

      // Load previous focus state
      await _loadFocusState();

      // Initialize native service
      await _service.init();

      // Initialize native app blocker
      final initResult = await _appBlockerChannel.invokeMethod('initialize');

      if (initResult != null && initResult['initialized'] == true) {
        _isInitialized = true;
        ErrorHandler.logInfo('AppBlockerManager initialized successfully');

        // If there was an active focus session, restore it
        if (_isFocusModeActive && _focusStartTime != null && _focusDuration != null) {
          final elapsed = DateTime.now().difference(_focusStartTime!);
          if (elapsed < _focusDuration!) {
            // Session is still valid, restore blocking
            await _restoreFocusSession();
          } else {
            // Session expired, clean up
            await stopFocusMode();
          }
        }

        return true;
      } else {
        throw Exception('Failed to initialize native app blocker');
      }
    }, context: 'AppBlockerManager.initialize', fallbackValue: false) ?? false;
  }

  /// Check if manager is initialized
  bool get isInitialized => _isInitialized;

  /// Restore focus session after app restart
  Future<void> _restoreFocusSession() async {
    if (!_isFocusModeActive || _currentlyBlockedPackages.isEmpty) return;

    try {
      final remainingDuration = _focusDuration! - DateTime.now().difference(_focusStartTime!);

      if (remainingDuration.inMinutes > 0) {
        // Re-enable blocking with remaining time
        final result = await _appBlockerChannel.invokeMethod('enableAppBlocking', {
          'blockedApps': _currentlyBlockedPackages,
          'blockMessage': 'App blocked during focus mode',
          'duration': remainingDuration.inMinutes,
        });

        if (result != null && result['enabled'] == true) {
          ErrorHandler.logInfo('Focus session restored with ${remainingDuration.inMinutes} minutes remaining');
        }
      }
    } catch (e) {
      // FIXED: ErrorHandler.logError now uses the correct signature with 2 parameters
      ErrorHandler.logError('Failed to restore focus session', e);
      await stopFocusMode();
    }
  }

  // ========================================
  // PERMISSION MANAGEMENT
  // ========================================

  /// Check all required permissions
  Future<Map<String, bool>> checkPermissions() async {
    return await ErrorHandler.handleAsyncError(() async {
      if (!isSupported) {
        return <String, bool>{
          'usageStats': false,
          'overlay': false,
          'notification': false,
        };
      }

      if (!_isInitialized) await initialize();

      final result = await _appBlockerChannel.invokeMethod('checkPermissions');

      if (result != null && result is Map) {
        return Map<String, bool>.from(result);
      }

      return <String, bool>{
        'usageStats': false,
        'overlay': false,
        'notification': false,
      };
    }, context: 'Check permissions', fallbackValue: <String, bool>{}) ?? <String, bool>{};
  }

  /// Request all required permissions
  Future<bool> requestPermissions() async {
    return await ErrorHandler.handleAsyncError(() async {
      if (!isSupported) {
        ErrorHandler.logInfo('Permissions not requested - platform not supported');
        return false;
      }

      if (!_isInitialized) await initialize();

      final result = await _appBlockerChannel.invokeMethod('requestPermissions');

      return result != null && result['started'] == true;
    }, context: 'Request permissions', fallbackValue: false) ?? false;
  }

  /// Request specific permission
  Future<bool> requestSpecificPermission(String permission) async {
    return await ErrorHandler.handleAsyncError(() async {
      if (!isSupported) {
        ErrorHandler.logInfo('Permission not requested - platform not supported');
        return false;
      }

      if (!_isInitialized) await initialize();

      final methodName = 'request${_capitalizeString(permission)}Permission';
      final result = await _appBlockerChannel.invokeMethod(methodName);

      return result != null && result['requested'] == true;
    }, context: 'Request $permission permission', fallbackValue: false) ?? false;
  }

  /// Helper method to capitalize strings (avoiding extension conflicts)
  String _capitalizeString(String input) {
    if (input.isEmpty) return input;
    return '${input[0].toUpperCase()}${input.substring(1)}';
  }

  /// Check if all critical permissions are granted
  Future<bool> hasRequiredPermissions() async {
    if (!isSupported) return false;

    final permissions = await checkPermissions();
    return permissions['usageStats'] == true &&
        permissions['overlay'] == true;
  }

  /// Get detailed permission statuses
  Future<List<PermissionStatus>> getDetailedPermissionStatuses() async {
    final permissions = await checkPermissions();

    return [
      PermissionStatus(
        name: 'Usage Stats',
        isGranted: permissions['usageStats'] ?? false,
        isPermanentlyDenied: false,
        description: 'Required to monitor which apps are currently running',
        settingsAction: 'Open Usage Access Settings',
      ),
      PermissionStatus(
        name: 'Display Over Other Apps',
        isGranted: permissions['overlay'] ?? false,
        isPermanentlyDenied: false,
        description: 'Required to show blocking overlay when apps are blocked',
        settingsAction: 'Open Overlay Settings',
      ),
      PermissionStatus(
        name: 'Notifications',
        isGranted: permissions['notification'] ?? false,
        isPermanentlyDenied: false,
        description: 'Required to show focus session notifications',
        settingsAction: 'Open Notification Settings',
      ),
    ];
  }

  // ========================================
  // INSTALLED APPS MANAGEMENT
  // ========================================

  /// Get list of installed apps from device
  Future<List<AppInfo>> getInstalledApps({bool forceRefresh = false}) async {
    return await ErrorHandler.handleAsyncError(() async {
      if (!isSupported) {
        ErrorHandler.logInfo('Cannot get installed apps - platform not supported');
        return <AppInfo>[];
      }

      if (!_isInitialized) await initialize();

      // Check cache validity
      if (!forceRefresh &&
          _cachedInstalledApps != null &&
          _lastAppsCacheTime != null &&
          DateTime.now().difference(_lastAppsCacheTime!) < _cacheValidDuration) {
        return _cachedInstalledApps!;
      }

      // Get apps from native code
      final result = await _appBlockerChannel.invokeMethod('getInstalledApps');

      if (result != null && result['success'] == true) {
        final appsData = List<Map<String, dynamic>>.from(result['apps'] ?? []);

        final apps = appsData.map((app) => AppInfo(
          name: app['name'] ?? '',
          packageName: app['packageName'] ?? '',
          icon: app['icon'],
          category: app['category'],
          isLaunchable: app['isLaunchable'] ?? true,
          isSystemApp: app['isSystemApp'] ?? false,
        )).toList();

        // Update cache
        _cachedInstalledApps = apps;
        _lastAppsCacheTime = DateTime.now();

        ErrorHandler.logInfo('Loaded ${apps.length} installed apps');
        return apps;
      } else {
        throw Exception('Failed to get installed apps: ${result?['message'] ?? 'Unknown error'}');
      }
    }, context: 'Get installed apps', fallbackValue: <AppInfo>[]) ?? <AppInfo>[];
  }

  /// Get apps filtered by category
  Future<List<AppInfo>> getAppsByCategory(String category) async {
    final allApps = await getInstalledApps();
    return allApps.where((app) => app.category?.toLowerCase() == category.toLowerCase()).toList();
  }

  /// Search apps by name or package name
  Future<List<AppInfo>> searchApps(String query) async {
    if (query.isEmpty) return await getInstalledApps();

    final allApps = await getInstalledApps();
    final lowercaseQuery = query.toLowerCase();

    return allApps.where((app) =>
    app.name.toLowerCase().contains(lowercaseQuery) ||
        app.packageName.toLowerCase().contains(lowercaseQuery)
    ).toList();
  }

  /// Get available app categories
  Future<List<String>> getAvailableCategories() async {
    final allApps = await getInstalledApps();
    final categories = allApps
        .where((app) => app.category != null)
        .map((app) => app.category!)
        .toSet()
        .toList();

    categories.sort();
    return categories;
  }

  // ========================================
  // BLOCKED APP MANAGEMENT
  // ========================================

  /// Get all blocked apps
  Future<List<blocked_app_model.BlockedApp>> getBlockedApps() async {
    return await ErrorHandler.handleAsyncError(() async {
      if (!_isInitialized) await initialize();
      return await _service.getAllBlockedApps();
    }, context: 'Get blocked apps', fallbackValue: <blocked_app_model.BlockedApp>[]) ?? <blocked_app_model.BlockedApp>[];
  }

  /// Add a new blocked app
  Future<bool> addBlockedApp(blocked_app_model.BlockedApp app) async {
    return await ErrorHandler.handleAsyncError(() async {
      if (!_isInitialized) await initialize();

      await _service.addBlockedApp(app);

      // Update native blocking if focus mode is active
      if (_isFocusModeActive) {
        await _updateNativeBlocking();
      }

      ErrorHandler.logInfo('Added blocked app: ${app.name}');
      return true;
    }, context: 'Add blocked app', fallbackValue: false) ?? false;
  }

  /// Add multiple apps to blocked list
  Future<bool> addMultipleBlockedApps(List<blocked_app_model.BlockedApp> apps) async {
    return await ErrorHandler.handleAsyncError(() async {
      if (!_isInitialized) await initialize();

      for (final app in apps) {
        await _service.addBlockedApp(app);
      }

      // Update native blocking if focus mode is active
      if (_isFocusModeActive) {
        await _updateNativeBlocking();
      }

      ErrorHandler.logInfo('Added ${apps.length} blocked apps');
      return true;
    }, context: 'Add multiple blocked apps', fallbackValue: false) ?? false;
  }

  /// Remove a blocked app
  Future<bool> removeBlockedApp(String appId) async {
    return await ErrorHandler.handleAsyncError(() async {
      if (!_isInitialized) await initialize();

      await _service.removeBlockedApp(appId);

      // Update native blocking if focus mode is active
      if (_isFocusModeActive) {
        await _updateNativeBlocking();
      }

      ErrorHandler.logInfo('Removed blocked app: $appId');
      return true;
    }, context: 'Remove blocked app', fallbackValue: false) ?? false;
  }

  /// Update a blocked app
  Future<bool> updateBlockedApp(blocked_app_model.BlockedApp app) async {
    return await ErrorHandler.handleAsyncError(() async {
      if (!_isInitialized) await initialize();

      await _service.updateBlockedApp(app);

      // Update native blocking if focus mode is active
      if (_isFocusModeActive) {
        await _updateNativeBlocking();
      }

      ErrorHandler.logInfo('Updated blocked app: ${app.name}');
      return true;
    }, context: 'Update blocked app', fallbackValue: false) ?? false;
  }

  /// Block an app by package name (convenience method)
  Future<bool> blockAppByPackageName(String packageName) async {
    return await ErrorHandler.handleAsyncError(() async {
      if (!_isInitialized) await initialize();

      final existingApps = await getBlockedApps();
      final existingApp = existingApps.firstWhere(
            (app) => app.packageName == packageName,
        orElse: () => blocked_app_model.BlockedApp(
          name: packageName,
          packageName: packageName,
          icon: '📱',
          category: blocked_app_model.AppCategory.other,
          isBlocked: true,
        ),
      );

      if (existingApp.id.isEmpty) {
        // Create new blocked app
        final installedApps = await getInstalledApps();
        final appInfo = installedApps.firstWhere(
              (app) => app.packageName == packageName,
          orElse: () => AppInfo(name: packageName, packageName: packageName),
        );

        final newBlockedApp = blocked_app_model.BlockedApp(
          name: appInfo.name,
          packageName: packageName,
          icon: appInfo.icon ?? '📱',
          category: blocked_app_model.AppCategory.values.firstWhere(
                (cat) => cat.name == appInfo.category?.toLowerCase(),
            orElse: () => blocked_app_model.AppCategory.other,
          ),
          isBlocked: true,
          blockDuringFocus: true,
        );

        return await addBlockedApp(newBlockedApp);
      } else {
        // Update existing app
        return await updateBlockedApp(existingApp.copyWith(isBlocked: true));
      }
    }, context: 'Block app by package name', fallbackValue: false) ?? false;
  }

  /// Unblock an app by package name
  Future<bool> unblockAppByPackageName(String packageName) async {
    return await ErrorHandler.handleAsyncError(() async {
      if (!_isInitialized) await initialize();

      final existingApps = await getBlockedApps();
      final existingApp = existingApps.firstWhere(
            (app) => app.packageName == packageName,
        orElse: () => blocked_app_model.BlockedApp(
          name: '',
          packageName: '',
          icon: '',
          category: blocked_app_model.AppCategory.other,
        ),
      );

      if (existingApp.id.isNotEmpty) {
        return await updateBlockedApp(existingApp.copyWith(isBlocked: false));
      }

      return true; // App wasn't blocked anyway
    }, context: 'Unblock app by package name', fallbackValue: false) ?? false;
  }

  /// Check if an app is currently blocked
  Future<bool> isAppBlocked(String packageName) async {
    return await ErrorHandler.handleAsyncError(() async {
      if (!_isInitialized) await initialize();
      return await _service.isAppBlocked(packageName);
    }, context: 'Check if app is blocked', fallbackValue: false) ?? false;
  }

  /// Get currently blocked apps (only those that are actively blocked)
  Future<List<blocked_app_model.BlockedApp>> getActivelyBlockedApps() async {
    final allBlockedApps = await getBlockedApps();
    return allBlockedApps.where((app) => app.isCurrentlyBlocked).toList();
  }

  // ========================================
  // PRIVATE HELPER METHODS (PART 1)
  // ========================================

  /// Update native blocking with current blocked apps
  Future<void> _updateNativeBlocking() async {
    if (!_isFocusModeActive) return;

    final blockedApps = await getActivelyBlockedApps();
    final packageNames = blockedApps.map((app) => app.packageName).toList();

    await _appBlockerChannel.invokeMethod('enableAppBlocking', {
      'blockedApps': packageNames,
      'blockMessage': 'App blocked during focus mode',
      'duration': _focusDuration?.inMinutes ?? 25,
    });
  }

  /// Load focus state from preferences
  Future<void> _loadFocusState() async {
    final prefs = await SharedPreferences.getInstance();

    _isFocusModeActive = prefs.getBool('appBlocker_focusActive') ?? false;

    final startTimeStr = prefs.getString('appBlocker_focusStartTime');
    if (startTimeStr != null) {
      _focusStartTime = DateTime.tryParse(startTimeStr);
    }

    final durationMinutes = prefs.getInt('appBlocker_focusDuration');
    if (durationMinutes != null) {
      _focusDuration = Duration(minutes: durationMinutes);
    }

    _currentlyBlockedPackages = prefs.getStringList('appBlocker_blockedPackages') ?? [];
  }
  // ========================================
  // FOCUS MODE MANAGEMENT
  // ========================================

  /// Start focus mode with specified duration and apps
  Future<bool> startFocusMode({
    required Duration duration,
    List<String>? specificAppsToBlock,
    String? customMessage,
  }) async {
    return await ErrorHandler.handleAsyncError(() async {
      if (!_isInitialized) await initialize();

      // Check permissions first
      if (!await hasRequiredPermissions()) {
        throw Exception('Required permissions not granted');
      }

      // Determine which apps to block
      List<String> appsToBlock;
      if (specificAppsToBlock != null && specificAppsToBlock.isNotEmpty) {
        appsToBlock = specificAppsToBlock;
      } else {
        // Block all apps marked for focus blocking
        final blockedApps = await getBlockedApps();
        appsToBlock = blockedApps
            .where((app) => app.blockDuringFocus && app.isBlocked)
            .map((app) => app.packageName)
            .toList();
      }

      if (appsToBlock.isEmpty) {
        throw Exception('No apps selected for blocking');
      }

      // Start native app blocking
      final result = await _appBlockerChannel.invokeMethod('enableAppBlocking', {
        'blockedApps': appsToBlock,
        'blockMessage': customMessage ?? 'App blocked during focus mode',
        'duration': duration.inMinutes,
      });

      if (result != null && result['enabled'] == true) {
        _isFocusModeActive = true;
        _focusStartTime = DateTime.now();
        _focusDuration = duration;
        _currentlyBlockedPackages = appsToBlock;

        // Save focus session state
        await _saveFocusState();

        ErrorHandler.logInfo('Focus mode started: ${duration.inMinutes} minutes, ${appsToBlock.length} apps blocked');
        return true;
      } else {
        throw Exception('Failed to enable app blocking: ${result?['message'] ?? 'Unknown error'}');
      }
    }, context: 'Start focus mode', fallbackValue: false) ?? false;
  }

  /// Stop focus mode
  Future<bool> stopFocusMode() async {
    return await ErrorHandler.handleAsyncError(() async {
      if (!_isInitialized) await initialize();

      final result = await _appBlockerChannel.invokeMethod('disableAppBlocking');

      if (result != null && result['disabled'] == true) {
        // Calculate session stats
        final sessionDuration = _focusStartTime != null
            ? DateTime.now().difference(_focusStartTime!)
            : Duration.zero;

        // Update app statistics
        await _updateAppStatistics(sessionDuration);

        // Clear focus state
        _isFocusModeActive = false;
        _focusStartTime = null;
        _focusDuration = null;
        _currentlyBlockedPackages.clear();

        // Save state
        await _saveFocusState();

        // Show completion notification
        await _showFocusCompletionNotification(sessionDuration);

        ErrorHandler.logInfo('Focus mode stopped after ${sessionDuration.inMinutes} minutes');
        return true;
      } else {
        throw Exception('Failed to disable app blocking');
      }
    }, context: 'Stop focus mode', fallbackValue: false) ?? false;
  }

  /// Check if focus mode is currently active
  bool get isFocusModeActive => _isFocusModeActive;

  /// Get current focus session info
  Map<String, dynamic>? get currentFocusSession {
    if (!_isFocusModeActive || _focusStartTime == null) return null;

    final elapsed = DateTime.now().difference(_focusStartTime!);
    final remaining = _focusDuration != null
        ? _focusDuration! - elapsed
        : Duration.zero;

    return {
      'isActive': _isFocusModeActive,
      'startTime': _focusStartTime!.toIso8601String(),
      'duration': _focusDuration?.inMinutes ?? 0,
      'elapsed': elapsed.inMinutes,
      'remaining': remaining.inMinutes.clamp(0, double.infinity).toInt(),
      'blockedApps': _currentlyBlockedPackages,
    };
  }

  /// Extend current focus session
  Future<bool> extendFocusSession(Duration additionalTime) async {
    return await ErrorHandler.handleAsyncError(() async {
      if (!_isFocusModeActive || _focusDuration == null) {
        throw Exception('No active focus session to extend');
      }

      _focusDuration = _focusDuration! + additionalTime;
      await _saveFocusState();

      ErrorHandler.logInfo('Focus session extended by ${additionalTime.inMinutes} minutes');
      return true;
    }, context: 'Extend focus session', fallbackValue: false) ?? false;
  }

  /// Pause focus session (temporarily disable blocking)
  Future<bool> pauseFocusSession() async {
    return await ErrorHandler.handleAsyncError(() async {
      if (!_isFocusModeActive) {
        throw Exception('No active focus session to pause');
      }

      // Temporarily disable blocking but keep session state
      await _appBlockerChannel.invokeMethod('disableAppBlocking');

      ErrorHandler.logInfo('Focus session paused');
      return true;
    }, context: 'Pause focus session', fallbackValue: false) ?? false;
  }

  /// Resume paused focus session
  Future<bool> resumeFocusSession() async {
    return await ErrorHandler.handleAsyncError(() async {
      if (!_isFocusModeActive) {
        throw Exception('No focus session to resume');
      }

      // Re-enable blocking with current settings
      final result = await _appBlockerChannel.invokeMethod('enableAppBlocking', {
        'blockedApps': _currentlyBlockedPackages,
        'blockMessage': 'App blocked during focus mode',
        'duration': _focusDuration?.inMinutes ?? 25,
      });

      if (result != null && result['enabled'] == true) {
        ErrorHandler.logInfo('Focus session resumed');
        return true;
      } else {
        throw Exception('Failed to resume focus session');
      }
    }, context: 'Resume focus session', fallbackValue: false) ?? false;
  }

  // ========================================
  // STATISTICS & ANALYTICS
  // ========================================

  /// Get today's focus statistics
  Future<FocusStats> getTodayStatistics() async {
    return await ErrorHandler.handleAsyncError(() async {
      if (!_isInitialized) await initialize();

      final result = await _appBlockerChannel.invokeMethod('getTodayStatistics');

      if (result != null) {
        return FocusStats(
          sessionsToday: result['totalSessions'] ?? 0,
          totalFocusTimeToday: Duration(minutes: result['totalFocusTime'] ?? 0),
          appsBlockedToday: result['appsBlocked'] ?? 0,
          blockAttemptsToday: result['totalBlocks'] ?? 0,
          averageSessionLength: Duration(minutes: result['averageSessionLength'] ?? 0),
          currentStreak: result['currentStreak'] ?? 0,
        );
      }

      return FocusStats.empty();
    }, context: 'Get today statistics', fallbackValue: FocusStats.empty()) ?? FocusStats.empty();
  }

  /// Get app-specific blocking statistics
  Future<Map<String, int>> getAppBlockingStats() async {
    return await ErrorHandler.handleAsyncError(() async {
      if (!_isInitialized) await initialize();

      final result = await _appBlockerChannel.invokeMethod('getTodayStatistics');

      if (result != null && result['appBlocks'] != null) {
        return Map<String, int>.from(result['appBlocks']);
      }

      return <String, int>{};
    }, context: 'Get app blocking stats', fallbackValue: <String, int>{}) ?? <String, int>{};
  }

  /// Record a manual block attempt (when user tries to open blocked app)
  Future<void> recordBlockAttempt(String packageName) async {
    await ErrorHandler.handleAsyncError(() async {
      if (!_isInitialized) await initialize();

      // Update app statistics
      final blockedApps = await getBlockedApps();
      final app = blockedApps.firstWhere(
            (app) => app.packageName == packageName,
        orElse: () => blocked_app_model.BlockedApp(
          name: packageName,
          packageName: packageName,
          icon: '📱',
          category: blocked_app_model.AppCategory.other,
        ),
      );

      if (app.id.isNotEmpty) {
        final updatedApp = app.recordBlockAttempt();
        await updateBlockedApp(updatedApp);
      }

      ErrorHandler.logInfo('Recorded block attempt for $packageName');
    }, context: 'Record block attempt');
  }

  // ========================================
  // BLOCKING MESSAGES & NOTIFICATIONS
  // ========================================

  /// Show blocking message for specific app
  Future<void> showBlockingMessage(String packageName, {String? customMessage}) async {
    await ErrorHandler.handleAsyncError(() async {
      if (!_isInitialized) await initialize();

      final blockedApps = await getBlockedApps();
      final app = blockedApps.firstWhere(
            (app) => app.packageName == packageName,
        orElse: () => blocked_app_model.BlockedApp(
          name: packageName,
          packageName: packageName,
          icon: '📱',
          category: blocked_app_model.AppCategory.other,
        ),
      );

      final message = customMessage ?? app.currentBlockMessage;

      await _appBlockerChannel.invokeMethod('showBlockingMessage', {
        'appName': app.name,
        'packageName': packageName,
        'message': message,
      });

      // Record the block attempt
      await recordBlockAttempt(packageName);
    }, context: 'Show blocking message');
  }

  /// Show focus completion notification
  Future<void> _showFocusCompletionNotification(Duration sessionLength) async {
    await ErrorHandler.handleAsyncError(() async {
      final stats = await getTodayStatistics();

      await _appBlockerChannel.invokeMethod('showFocusCompleted', {
        'message': 'Focus session completed! 🎉',
        'timeBlocked': sessionLength.inMinutes,
        'appsBlocked': _currentlyBlockedPackages.length,
        'blockedAttempts': stats.blockAttemptsToday,
      });
    }, context: 'Show focus completion notification');
  }

  // ========================================
  // SETTINGS & PREFERENCES
  // ========================================

  /// Get app blocker settings
  Future<Map<String, dynamic>> getSettings() async {
    return await ErrorHandler.handleAsyncError(() async {
      final prefs = await SharedPreferences.getInstance();

      return {
        'autoBlockDuringFocus': prefs.getBool('autoBlockDuringFocus') ?? true,
        'showBlockNotifications': prefs.getBool('showBlockNotifications') ?? true,
        'messageTheme': prefs.getInt('messageTheme') ?? blocked_app_model.MessageTheme.funny.index,
        'defaultFocusDuration': prefs.getInt('defaultFocusDuration') ?? 25,
        'enableHapticFeedback': prefs.getBool('enableHapticFeedback') ?? true,
        'soundEnabled': prefs.getBool('soundEnabled') ?? true,
      };
    }, context: 'Get settings', fallbackValue: <String, dynamic>{}) ?? <String, dynamic>{};
  }

  /// Update app blocker settings
  Future<bool> updateSettings(Map<String, dynamic> settings) async {
    return await ErrorHandler.handleAsyncError(() async {
      final prefs = await SharedPreferences.getInstance();

      for (final entry in settings.entries) {
        final key = entry.key;
        final value = entry.value;

        if (value is bool) {
          await prefs.setBool(key, value);
        } else if (value is int) {
          await prefs.setInt(key, value);
        } else if (value is double) {
          await prefs.setDouble(key, value);
        } else if (value is String) {
          await prefs.setString(key, value);
        }
      }

      ErrorHandler.logInfo('Settings updated: ${settings.keys.join(', ')}');
      return true;
    }, context: 'Update settings', fallbackValue: false) ?? false;
  }

  // ========================================
  // UTILITY METHODS
  // ========================================

  /// Clear all app blocker data
  Future<bool> clearAllData() async {
    return await ErrorHandler.handleAsyncError(() async {
      if (!_isInitialized) await initialize();

      // Stop focus mode if active
      if (_isFocusModeActive) {
        await stopFocusMode();
      }

      // Clear service data
      await _service.clearAllData();

      // Clear native data
      await _appBlockerChannel.invokeMethod('clearAllData');

      // Clear cached data
      _cachedInstalledApps = null;
      _lastAppsCacheTime = null;

      // Clear shared preferences
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys();
      for (final key in keys) {
        if (key.startsWith('appBlocker_')) {
          await prefs.remove(key);
        }
      }

      ErrorHandler.logInfo('All app blocker data cleared');
      return true;
    }, context: 'Clear all data', fallbackValue: false) ?? false;
  }

  /// Reset to default settings
  Future<bool> resetToDefaults() async {
    return await ErrorHandler.handleAsyncError(() async {
      final defaultSettings = {
        'autoBlockDuringFocus': true,
        'showBlockNotifications': true,
        'messageTheme': blocked_app_model.MessageTheme.funny.index,
        'defaultFocusDuration': 25,
        'enableHapticFeedback': true,
        'soundEnabled': true,
      };

      return await updateSettings(defaultSettings);
    }, context: 'Reset to defaults', fallbackValue: false) ?? false;
  }

  /// Export app blocker data for backup
  Future<Map<String, dynamic>> exportData() async {
    return await ErrorHandler.handleAsyncError(() async {
      final blockedApps = await getBlockedApps();
      final settings = await getSettings();
      final stats = await getTodayStatistics();

      return {
        'version': 1,
        'exportedAt': DateTime.now().toIso8601String(),
        'blockedApps': blockedApps.map((app) => app.toJson()).toList(),
        'settings': settings,
        'statistics': {
          'totalSessions': stats.sessionsToday,
          'totalFocusTime': stats.totalFocusTimeToday.inMinutes,
          'currentStreak': stats.currentStreak,
        },
      };
    }, context: 'Export data', fallbackValue: <String, dynamic>{}) ?? <String, dynamic>{};
  }

  /// Import app blocker data from backup
  Future<bool> importData(Map<String, dynamic> data) async {
    return await ErrorHandler.handleAsyncError(() async {
      if (data['version'] != 1) {
        throw Exception('Unsupported data version');
      }

      // Import blocked apps
      if (data['blockedApps'] != null) {
        final appsData = List<Map<String, dynamic>>.from(data['blockedApps']);
        final apps = appsData.map((appData) => blocked_app_model.BlockedApp.fromJson(appData)).toList();

        for (final app in apps) {
          await addBlockedApp(app);
        }
      }

      // Import settings
      if (data['settings'] != null) {
        await updateSettings(Map<String, dynamic>.from(data['settings']));
      }

      ErrorHandler.logInfo('Data import completed');
      return true;
    }, context: 'Import data', fallbackValue: false) ?? false;
  }

  /// Check system health and report issues
  Future<Map<String, dynamic>> performHealthCheck() async {
    return await ErrorHandler.handleAsyncError(() async {
      final healthReport = <String, dynamic>{
        'timestamp': DateTime.now().toIso8601String(),
        'isInitialized': _isInitialized,
        'isSupported': isSupported,
        'platformInfo': {
          'platform': Platform.operatingSystem,
          'isAndroid': Platform.isAndroid,
          'isIOS': Platform.isIOS,
        },
        'permissions': {},
        'focusMode': {
          'isActive': _isFocusModeActive,
          'hasActiveSession': currentFocusSession != null,
        },
        'data': {
          'cachedAppsCount': _cachedInstalledApps?.length ?? 0,
          'cacheAge': _lastAppsCacheTime != null
              ? DateTime.now().difference(_lastAppsCacheTime!).inMinutes
              : null,
        },
        'issues': <String>[],
        'recommendations': <String>[],
      };

      // Check permissions if supported
      if (isSupported) {
        try {
          final permissions = await checkPermissions();
          healthReport['permissions'] = permissions;

          if (permissions['usageStats'] != true) {
            healthReport['issues'].add('Usage Stats permission not granted');
            healthReport['recommendations'].add('Grant Usage Stats permission for app monitoring');
          }

          if (permissions['overlay'] != true) {
            healthReport['issues'].add('Display Over Other Apps permission not granted');
            healthReport['recommendations'].add('Grant overlay permission for blocking functionality');
          }
        } catch (e) {
          healthReport['issues'].add('Failed to check permissions: $e');
        }
      }

      // Check blocked apps
      try {
        final blockedApps = await getBlockedApps();
        healthReport['data']['blockedAppsCount'] = blockedApps.length;

        if (blockedApps.isEmpty) {
          healthReport['recommendations'].add('Add some apps to block for better focus');
        }
      } catch (e) {
        healthReport['issues'].add('Failed to load blocked apps: $e');
      }

      // Check cache validity
      if (_lastAppsCacheTime != null &&
          DateTime.now().difference(_lastAppsCacheTime!) > _cacheValidDuration) {
        healthReport['recommendations'].add('Refresh installed apps cache');
      }

      return healthReport;
    }, context: 'Health check', fallbackValue: <String, dynamic>{}) ?? <String, dynamic>{};
  }

  /// Get debugging information
  /// FIXED: Added fallback for _service.getDebugInfo() method call
  Future<Map<String, dynamic>> getDebugInfo() async {
    return await ErrorHandler.handleAsyncError(() async {
      final debugInfo = <String, dynamic>{
        'version': '2.0.0',
        'manager': {
          'isInitialized': _isInitialized,
          'isSupported': isSupported,
          'isFocusModeActive': _isFocusModeActive,
          'focusStartTime': _focusStartTime?.toIso8601String(),
          'focusDuration': _focusDuration?.inMinutes,
          'blockedPackagesCount': _currentlyBlockedPackages.length,
        },
        'cache': {
          'installedAppsCount': _cachedInstalledApps?.length ?? 0,
          'lastCacheTime': _lastAppsCacheTime?.toIso8601String(),
          'cacheAgeMinutes': _lastAppsCacheTime != null
              ? DateTime.now().difference(_lastAppsCacheTime!).inMinutes
              : null,
        },
        'settings': await getSettings(),
      };

      // FIXED: Safe call to _service.getDebugInfo() with fallback
      try {
        // Try to get service debug info if the method exists
        final serviceDebugInfo = await _getServiceDebugInfo();
        debugInfo['service'] = serviceDebugInfo;
      } catch (e) {
        // Fallback if getDebugInfo method doesn't exist in AppBlockerService
        debugInfo['service'] = {
          'isInitialized': _service.isInitialized,
          'error': 'getDebugInfo method not available: $e',
          'fallbackInfo': {
            'blockedAppsCount': (await getBlockedApps()).length,
            'serviceType': 'AppBlockerService',
          }
        };
      }

      if (isSupported) {
        try {
          debugInfo['permissions'] = await checkPermissions();
          debugInfo['stats'] = await getTodayStatistics();
        } catch (e) {
          debugInfo['permissionsError'] = e.toString();
        }
      }

      return debugInfo;
    }, context: 'Get debug info', fallbackValue: <String, dynamic>{}) ?? <String, dynamic>{};
  }

  /// FIXED: Safe method to get service debug info with fallback
  Future<Map<String, dynamic>> _getServiceDebugInfo() async {
    try {
      // Check if the service has getDebugInfo method using reflection-like approach
      // Since Dart doesn't have direct reflection, we'll use a try-catch approach

      // Try to call a method that might exist on the service
      final blockedApps = await _service.getAllBlockedApps();

      // Create our own debug info for the service
      return {
        'isInitialized': _service.isInitialized,
        'blockedAppsCount': blockedApps.length,
        'serviceType': 'AppBlockerService',
        'lastUpdate': DateTime.now().toIso8601String(),
        'hasData': blockedApps.isNotEmpty,
      };
    } catch (e) {
      // Return minimal debug info if service methods fail
      return {
        'isInitialized': false,
        'error': 'Service debug info unavailable: $e',
        'serviceType': 'AppBlockerService',
        'fallback': true,
      };
    }
  }

  // ========================================
  // PRIVATE HELPER METHODS (PART 2)
  // ========================================

  /// Save current focus state to preferences
  Future<void> _saveFocusState() async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setBool('appBlocker_focusActive', _isFocusModeActive);

    if (_focusStartTime != null) {
      await prefs.setString('appBlocker_focusStartTime', _focusStartTime!.toIso8601String());
    }

    if (_focusDuration != null) {
      await prefs.setInt('appBlocker_focusDuration', _focusDuration!.inMinutes);
    }

    await prefs.setStringList('appBlocker_blockedPackages', _currentlyBlockedPackages);
  }

  /// Update app statistics after focus session
  Future<void> _updateAppStatistics(Duration sessionDuration) async {
    final blockedApps = await getBlockedApps();

    for (final packageName in _currentlyBlockedPackages) {
      final app = blockedApps.firstWhere(
            (app) => app.packageName == packageName,
        orElse: () => blocked_app_model.BlockedApp(
          name: packageName,
          packageName: packageName,
          icon: '📱',
          category: blocked_app_model.AppCategory.other,
        ),
      );

      if (app.id.isNotEmpty) {
        final updatedApp = app.copyWith(
          totalTimeSaved: app.totalTimeSaved + sessionDuration,
        );
        await updateBlockedApp(updatedApp);
      }
    }
  }

  /// Cleanup resources and stop all operations
  Future<void> dispose() async {
    await ErrorHandler.handleAsyncError(() async {
      // Stop focus mode if active
      if (_isFocusModeActive) {
        await stopFocusMode();
      }

      // Clear state
      _isInitialized = false;
      _cachedInstalledApps = null;
      _lastAppsCacheTime = null;
      _currentlyBlockedPackages.clear();
      _focusStartTime = null;
      _focusDuration = null;
      _platformSupported = null;

      ErrorHandler.logInfo('AppBlockerManager disposed');
    }, context: 'Dispose manager');
  }
}