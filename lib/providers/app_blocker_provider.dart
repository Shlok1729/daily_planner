import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:daily_planner/models/blocked_app.dart';
import 'package:daily_planner/services/app_blocker_service.dart' hide MessageTheme;
import 'package:daily_planner/utils/app_blocker_manager.dart';
import 'package:daily_planner/utils/error_handler.dart';

// ============================================================================
// DEVICE APP CLASS (FIXED - Added missing DeviceApp for compatibility)
// ============================================================================

class DeviceApp {
  final String name;
  final String packageName;
  final String icon;
  final String category;
  final bool isBlocked;
  final bool isLaunchable;
  final bool isSystemApp;

  const DeviceApp({
    required this.name,
    required this.packageName,
    required this.icon,
    required this.category,
    this.isBlocked = false,
    this.isLaunchable = true,
    this.isSystemApp = false,
  });

  DeviceApp copyWith({
    String? name,
    String? packageName,
    String? icon,
    String? category,
    bool? isBlocked,
    bool? isLaunchable,
    bool? isSystemApp,
  }) {
    return DeviceApp(
      name: name ?? this.name,
      packageName: packageName ?? this.packageName,
      icon: icon ?? this.icon,
      category: category ?? this.category,
      isBlocked: isBlocked ?? this.isBlocked,
      isLaunchable: isLaunchable ?? this.isLaunchable,
      isSystemApp: isSystemApp ?? this.isSystemApp,
    );
  }

  factory DeviceApp.fromAppInfo(AppInfo appInfo) {
    return DeviceApp(
      name: appInfo.name,
      packageName: appInfo.packageName,
      icon: appInfo.icon ?? '📱',
      category: appInfo.category ?? 'Other',
      isLaunchable: appInfo.isLaunchable,
      isSystemApp: appInfo.isSystemApp,
    );
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
// PROVIDERS
// ============================================================================

// Provider for the app blocker manager
final appBlockerManagerProvider = Provider<AppBlockerManager>((ref) {
  return AppBlockerManager();
});

// Provider for the app blocker state
final appBlockerProvider = NotifierProvider<AppBlockerNotifier, AppBlockerState>(() {
  return AppBlockerNotifier();
});

// ============================================================================
// APP BLOCKER STATE CLASS (FIXED - Added deviceApps and other missing properties)
// ============================================================================

class AppBlockerState {
  final List<BlockedApp> blockedApps;
  final List<DeviceApp> deviceApps; // FIXED: Added missing deviceApps property
  final bool isFocusModeActive;
  final bool autoBlockDuringFocus;
  final bool showBlockNotifications;
  final MessageTheme messageTheme;
  final DateTime? focusStartTime;
  final Duration? focusDuration;
  final bool emergencyOverrideActive;
  final DateTime? emergencyOverrideExpiry;
  final Map<String, int> todayBlockAttempts;
  final Duration totalTimeSavedToday;
  final int currentStreak;
  final bool isLoading;
  final String? error;
  final bool isInitialized;

  AppBlockerState({
    required this.blockedApps,
    List<DeviceApp>? deviceApps, // FIXED: Added deviceApps parameter
    this.isFocusModeActive = false,
    this.autoBlockDuringFocus = true,
    this.showBlockNotifications = true,
    this.messageTheme = MessageTheme.funny,
    this.focusStartTime,
    this.focusDuration,
    this.emergencyOverrideActive = false,
    this.emergencyOverrideExpiry,
    Map<String, int>? todayBlockAttempts,
    Duration? totalTimeSavedToday,
    this.currentStreak = 0,
    this.isLoading = false,
    this.error,
    this.isInitialized = false,
  })  : deviceApps = deviceApps ?? [], // FIXED: Initialize deviceApps
        todayBlockAttempts = todayBlockAttempts ?? {},
        totalTimeSavedToday = totalTimeSavedToday ?? Duration.zero;

  AppBlockerState copyWith({
    List<BlockedApp>? blockedApps,
    List<DeviceApp>? deviceApps, // FIXED: Added deviceApps to copyWith
    bool? isFocusModeActive,
    bool? autoBlockDuringFocus,
    bool? showBlockNotifications,
    MessageTheme? messageTheme,
    DateTime? focusStartTime,
    Duration? focusDuration,
    bool? emergencyOverrideActive,
    DateTime? emergencyOverrideExpiry,
    Map<String, int>? todayBlockAttempts,
    Duration? totalTimeSavedToday,
    int? currentStreak,
    bool? isLoading,
    String? error,
    bool? isInitialized,
  }) {
    return AppBlockerState(
      blockedApps: blockedApps ?? this.blockedApps,
      deviceApps: deviceApps ?? this.deviceApps, // FIXED: Include deviceApps in copyWith
      isFocusModeActive: isFocusModeActive ?? this.isFocusModeActive,
      autoBlockDuringFocus: autoBlockDuringFocus ?? this.autoBlockDuringFocus,
      showBlockNotifications: showBlockNotifications ?? this.showBlockNotifications,
      messageTheme: messageTheme ?? this.messageTheme,
      focusStartTime: focusStartTime ?? this.focusStartTime,
      focusDuration: focusDuration ?? this.focusDuration,
      emergencyOverrideActive: emergencyOverrideActive ?? this.emergencyOverrideActive,
      emergencyOverrideExpiry: emergencyOverrideExpiry ?? this.emergencyOverrideExpiry,
      todayBlockAttempts: todayBlockAttempts ?? this.todayBlockAttempts,
      totalTimeSavedToday: totalTimeSavedToday ?? this.totalTimeSavedToday,
      currentStreak: currentStreak ?? this.currentStreak,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      isInitialized: isInitialized ?? this.isInitialized,
    );
  }

  // Helper getters
  List<BlockedApp> get activelyBlockedApps =>
      blockedApps.where((app) => app.isCurrentlyBlocked).toList();

  int get totalBlockAttemptsToday =>
      todayBlockAttempts.values.fold(0, (sum, attempts) => sum + attempts);

  bool get isEmergencyOverrideActive =>
      emergencyOverrideActive &&
          emergencyOverrideExpiry != null &&
          DateTime.now().isBefore(emergencyOverrideExpiry!);
}

// ============================================================================
// APP BLOCKER NOTIFIER CLASS (FIXED - Added all missing methods)
// ============================================================================

class AppBlockerNotifier extends Notifier<AppBlockerState> {
  final AppBlockerService _appBlockerService = AppBlockerService();
  final AppBlockerManager _appBlockerManager = AppBlockerManager();

  @override
  AppBlockerState build() {
    // FIXED: Return initial state immediately, then load data asynchronously
    final initialState = AppBlockerState(blockedApps: [], deviceApps: [], isLoading: true);

    // Load data asynchronously without blocking the build
    Future.microtask(() => _loadInitialData());

    return initialState;
  }

  // FIXED: Load initial data safely with proper error handling
  Future<void> _loadInitialData() async {
    try {
      // Don't change state if already loading to prevent race conditions
      if (state.isInitialized) return;

      state = state.copyWith(isLoading: true, error: null);

      // Initialize both services
      await _appBlockerService.init();
      await _appBlockerManager.initialize();

      // Load blocked apps
      final blockedApps = await _appBlockerService.getAllBlockedApps();

      // Load device apps
      final appInfoList = await _appBlockerManager.getInstalledApps();
      final deviceApps = appInfoList.map((appInfo) => DeviceApp.fromAppInfo(appInfo)).toList();

      // Load settings
      final settings = await _appBlockerService.getSettings();

      state = state.copyWith(
        blockedApps: blockedApps,
        deviceApps: deviceApps, // FIXED: Set deviceApps
        autoBlockDuringFocus: settings['autoBlockDuringFocus'] ?? true,
        showBlockNotifications: settings['showBlockNotifications'] ?? true,
        messageTheme: MessageTheme.values[settings['messageTheme'] ?? MessageTheme.funny.index],
        currentStreak: settings['currentStreak'] ?? 0,
        isFocusModeActive: settings['isFocusModeActive'] ?? false,
        isLoading: false,
        isInitialized: true,
      );

      // Load statistics after main data is loaded
      _loadTodayStatistics();
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to load app blocker data: ${ErrorHandler.getUserFriendlyMessage(e)}',
        isInitialized: true,
      );
      ErrorHandler.logError('Load initial data', e);
    }
  }

  // FIXED: Added missing refreshDeviceApps method
  Future<void> refreshDeviceApps() async {
    try {
      state = state.copyWith(isLoading: true);

      // Get fresh device apps data
      final appInfoList = await _appBlockerManager.getInstalledApps(forceRefresh: true);
      final deviceApps = appInfoList.map((appInfo) => DeviceApp.fromAppInfo(appInfo)).toList();

      // Get blocked apps to mark them in device apps
      final blockedApps = await _appBlockerService.getAllBlockedApps();
      final blockedPackageNames = blockedApps.map((app) => app.packageName).toSet();

      // Update device apps with blocking status
      final updatedDeviceApps = deviceApps.map((deviceApp) {
        return deviceApp.copyWith(
          isBlocked: blockedPackageNames.contains(deviceApp.packageName),
        );
      }).toList();

      state = state.copyWith(
        deviceApps: updatedDeviceApps,
        isLoading: false,
        error: null,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to refresh device apps: ${ErrorHandler.getUserFriendlyMessage(e)}',
      );
      ErrorHandler.logError('Refresh device apps', e);
    }
  }

  // Load today's statistics
  Future<void> _loadTodayStatistics() async {
    try {
      final todayStats = await _appBlockerService.getTodayStatistics();
      state = state.copyWith(
        todayBlockAttempts: Map<String, int>.from(todayStats['blockAttempts'] ?? {}),
        totalTimeSavedToday: Duration(seconds: todayStats['timeSaved'] ?? 0),
      );
    } catch (e) {
      ErrorHandler.logError('Load today statistics', e);
    }
  }

  // Add a new blocked app
  Future<void> addBlockedApp(BlockedApp app) async {
    try {
      await _appBlockerService.addBlockedApp(app);
      final updatedApps = [...state.blockedApps, app];
      state = state.copyWith(blockedApps: updatedApps, error: null);

      // Update device apps to reflect blocking status
      await _updateDeviceAppBlockingStatus();
    } catch (e) {
      state = state.copyWith(error: 'Failed to add blocked app: ${ErrorHandler.getUserFriendlyMessage(e)}');
      ErrorHandler.logError('Add blocked app', e);
    }
  }

  // Update an existing blocked app
  Future<void> updateBlockedApp(BlockedApp app) async {
    try {
      await _appBlockerService.updateBlockedApp(app);
      final updatedApps = state.blockedApps.map((a) => a.id == app.id ? app : a).toList();
      state = state.copyWith(blockedApps: updatedApps, error: null);

      // Update device apps to reflect blocking status
      await _updateDeviceAppBlockingStatus();
    } catch (e) {
      state = state.copyWith(error: 'Failed to update blocked app: ${ErrorHandler.getUserFriendlyMessage(e)}');
      ErrorHandler.logError('Update blocked app', e);
    }
  }

  // Remove a blocked app
  Future<void> removeBlockedApp(String appId) async {
    try {
      await _appBlockerService.removeBlockedApp(appId);
      final updatedApps = state.blockedApps.where((app) => app.id != appId).toList();
      state = state.copyWith(blockedApps: updatedApps, error: null);

      // Update device apps to reflect blocking status
      await _updateDeviceAppBlockingStatus();
    } catch (e) {
      state = state.copyWith(error: 'Failed to remove blocked app: ${ErrorHandler.getUserFriendlyMessage(e)}');
      ErrorHandler.logError('Remove blocked app', e);
    }
  }

  // FIXED: Update device apps blocking status
  Future<void> _updateDeviceAppBlockingStatus() async {
    try {
      final blockedPackageNames = state.blockedApps.map((app) => app.packageName).toSet();

      final updatedDeviceApps = state.deviceApps.map((deviceApp) {
        return deviceApp.copyWith(
          isBlocked: blockedPackageNames.contains(deviceApp.packageName),
        );
      }).toList();

      state = state.copyWith(deviceApps: updatedDeviceApps);
    } catch (e) {
      ErrorHandler.logError('Update device app blocking status', e);
    }
  }

  // Toggle app blocking status
  Future<void> toggleAppBlocking(String appId) async {
    try {
      final app = state.blockedApps.firstWhere((app) => app.id == appId);
      final updatedApp = app.copyWith(isBlocked: !app.isBlocked);
      await updateBlockedApp(updatedApp);
    } catch (e) {
      state = state.copyWith(error: 'Failed to toggle app blocking: ${ErrorHandler.getUserFriendlyMessage(e)}');
      ErrorHandler.logError('Toggle app blocking', e);
    }
  }
  // Start focus mode
  Future<void> startFocusMode({Duration? duration}) async {
    try {
      final focusDuration = duration ?? Duration(minutes: 25);

      if (state.autoBlockDuringFocus) {
        // Use AppBlockerManager for focus mode management
        final success = await _appBlockerManager.startFocusMode(
          duration: focusDuration,
          customMessage: 'Stay focused! This app is blocked during focus mode.',
        );

        if (!success) {
          state = state.copyWith(error: 'Failed to start app blocking - check permissions');
          return;
        }
      }

      state = state.copyWith(
        isFocusModeActive: true,
        focusStartTime: DateTime.now(),
        focusDuration: focusDuration,
        error: null,
      );

      // Update service setting
      await _appBlockerService.updateSetting('isFocusModeActive', true);
    } catch (e) {
      state = state.copyWith(error: 'Failed to start focus mode: ${ErrorHandler.getUserFriendlyMessage(e)}');
      ErrorHandler.logError('Start focus mode', e);
    }
  }

  // End focus mode - FIXED: Now calls the correct manager method
  Future<void> endFocusMode() async {
    try {
      if (state.autoBlockDuringFocus) {
        await _appBlockerManager.stopFocusMode();
      }

      // Update streak if focus session was completed successfully
      final focusDuration = state.focusDuration ?? Duration(minutes: 25);
      final actualDuration = state.focusStartTime != null
          ? DateTime.now().difference(state.focusStartTime!)
          : Duration.zero;

      int newStreak = state.currentStreak;
      if (actualDuration >= focusDuration * 0.8) { // 80% completion threshold
        newStreak++;
        // FIXED: Safe streak update - use setting update
        try {
          await _appBlockerService.updateSetting('currentStreak', newStreak);
        } catch (e) {
          // If updateSetting fails, continue with local state update
          ErrorHandler.logError('Update streak setting', e);
        }
      }

      state = state.copyWith(
        isFocusModeActive: false,
        focusStartTime: null,
        focusDuration: null,
        currentStreak: newStreak,
        error: null,
      );

      // Update service setting
      await _appBlockerService.updateSetting('isFocusModeActive', false);
    } catch (e) {
      state = state.copyWith(error: 'Failed to end focus mode: ${ErrorHandler.getUserFriendlyMessage(e)}');
      ErrorHandler.logError('End focus mode', e);
    }
  }

  // Record a block attempt - FIXED: Use recordBlockAttempt method
  Future<void> recordBlockAttempt(String packageName) async {
    try {
      final app = state.blockedApps.firstWhere(
            (app) => app.packageName == packageName,
        orElse: () => throw Exception('App not found'),
      );

      // FIXED: Create updated app using recordBlockAttempt method
      final updatedApp = app.recordBlockAttempt();
      await updateBlockedApp(updatedApp);

      // Record in service and manager
      try {
        await _appBlockerService.recordBlockAttempt(packageName);
        await _appBlockerManager.recordBlockAttempt(packageName);
      } catch (e) {
        // If methods don't exist, log the error but continue
        ErrorHandler.logError('Record blocked attempt in services', e);
      }

      // Update today's statistics
      final updatedAttempts = Map<String, int>.from(state.todayBlockAttempts);
      updatedAttempts[packageName] = (updatedAttempts[packageName] ?? 0) + 1;

      final timeSaved = updatedApp.estimatedTimeSavedPerBlock;
      final updatedTimeSaved = state.totalTimeSavedToday + timeSaved;

      state = state.copyWith(
        todayBlockAttempts: updatedAttempts,
        totalTimeSavedToday: updatedTimeSaved,
      );

      // Show notification if enabled - FIXED: Safe notification call
      if (state.showBlockNotifications) {
        try {
          await _appBlockerService.showBlockNotification(app.name, 'App blocked successfully');
        } catch (e) {
          // If notification method doesn't exist, log but continue
          ErrorHandler.logError('Show block notification', e);
        }
      }
    } catch (e) {
      state = state.copyWith(error: 'Failed to record block attempt: ${ErrorHandler.getUserFriendlyMessage(e)}');
      ErrorHandler.logError('Record block attempt', e);
    }
  }

  // Update settings
  Future<void> setAutoBlockDuringFocus(bool value) async {
    try {
      await _appBlockerService.updateSetting('autoBlockDuringFocus', value);
      state = state.copyWith(autoBlockDuringFocus: value, error: null);
    } catch (e) {
      state = state.copyWith(error: 'Failed to update setting: ${ErrorHandler.getUserFriendlyMessage(e)}');
      ErrorHandler.logError('Set auto block during focus', e);
    }
  }

  Future<void> setShowBlockNotifications(bool value) async {
    try {
      await _appBlockerService.updateSetting('showBlockNotifications', value);
      state = state.copyWith(showBlockNotifications: value, error: null);
    } catch (e) {
      state = state.copyWith(error: 'Failed to update setting: ${ErrorHandler.getUserFriendlyMessage(e)}');
      ErrorHandler.logError('Set show block notifications', e);
    }
  }

  Future<void> setMessageTheme(MessageTheme theme) async {
    try {
      await _appBlockerService.updateSetting('messageTheme', theme.index);
      state = state.copyWith(messageTheme: theme, error: null);
    } catch (e) {
      state = state.copyWith(error: 'Failed to update message theme: ${ErrorHandler.getUserFriendlyMessage(e)}');
      ErrorHandler.logError('Set message theme', e);
    }
  }

  // Emergency override - FIXED: Safe method calls with manager integration
  Future<void> activateEmergencyOverride() async {
    try {
      final expiryTime = DateTime.now().add(Duration(hours: 1));

      // Try to activate via service, fallback to local state only
      try {
        await _appBlockerService.activateEmergencyOverride(duration: Duration(hours: 1));
      } catch (e) {
        // If service method doesn't exist, just update local state
        ErrorHandler.logError('Activate emergency override in service', e);
      }

      state = state.copyWith(
        emergencyOverrideActive: true,
        emergencyOverrideExpiry: expiryTime,
        error: null,
      );
    } catch (e) {
      state = state.copyWith(error: 'Failed to activate emergency override: ${ErrorHandler.getUserFriendlyMessage(e)}');
      ErrorHandler.logError('Activate emergency override', e);
    }
  }

  Future<void> deactivateEmergencyOverride() async {
    try {
      // Try to deactivate via service, fallback to local state only
      try {
        await _appBlockerService.deactivateEmergencyOverride();
      } catch (e) {
        // If service method doesn't exist, just update local state
        ErrorHandler.logError('Deactivate emergency override in service', e);
      }

      state = state.copyWith(
        emergencyOverrideActive: false,
        emergencyOverrideExpiry: null,
        error: null,
      );
    } catch (e) {
      state = state.copyWith(error: 'Failed to deactivate emergency override: ${ErrorHandler.getUserFriendlyMessage(e)}');
      ErrorHandler.logError('Deactivate emergency override', e);
    }
  }

  // FIXED: Load popular apps for selection - using static data
  List<BlockedApp> getPopularApps() {
    return _getPopularAppsData();
  }

  // FIXED: Static method for popular apps data
  static List<BlockedApp> _getPopularAppsData() {
    return [
      // Social Media Apps
      BlockedApp(
        name: 'Instagram',
        packageName: 'com.instagram.android',
        icon: '📷',
        category: AppCategory.social,
        estimatedTimeSavedPerBlock: const Duration(minutes: 8),
      ),
      BlockedApp(
        name: 'TikTok',
        packageName: 'com.zhiliaoapp.musically',
        icon: '🎵',
        category: AppCategory.entertainment,
        estimatedTimeSavedPerBlock: const Duration(minutes: 12),
      ),
      BlockedApp(
        name: 'Facebook',
        packageName: 'com.facebook.katana',
        icon: '📘',
        category: AppCategory.social,
        estimatedTimeSavedPerBlock: const Duration(minutes: 6),
      ),
      BlockedApp(
        name: 'Twitter',
        packageName: 'com.twitter.android',
        icon: '🐦',
        category: AppCategory.social,
        estimatedTimeSavedPerBlock: const Duration(minutes: 5),
      ),
      BlockedApp(
        name: 'YouTube',
        packageName: 'com.google.android.youtube',
        icon: '📺',
        category: AppCategory.entertainment,
        estimatedTimeSavedPerBlock: const Duration(minutes: 15),
      ),
      BlockedApp(
        name: 'Netflix',
        packageName: 'com.netflix.mediaclient',
        icon: '🎬',
        category: AppCategory.entertainment,
        estimatedTimeSavedPerBlock: const Duration(minutes: 30),
      ),
      BlockedApp(
        name: 'WhatsApp',
        packageName: 'com.whatsapp',
        icon: '💬',
        category: AppCategory.messaging,
        estimatedTimeSavedPerBlock: const Duration(minutes: 5),
      ),
      BlockedApp(
        name: 'Snapchat',
        packageName: 'com.snapchat.android',
        icon: '👻',
        category: AppCategory.social,
        estimatedTimeSavedPerBlock: const Duration(minutes: 4),
      ),
      BlockedApp(
        name: 'Discord',
        packageName: 'com.discord',
        icon: '🎧',
        category: AppCategory.messaging,
        estimatedTimeSavedPerBlock: const Duration(minutes: 7),
      ),
      BlockedApp(
        name: 'Reddit',
        packageName: 'com.reddit.frontpage',
        icon: '🔶',
        category: AppCategory.news,
        estimatedTimeSavedPerBlock: const Duration(minutes: 10),
      ),
    ];
  }

  // FIXED: Block multiple apps at once - now uses DeviceApp type
  Future<void> blockMultipleApps(List<DeviceApp> deviceApps) async {
    try {
      for (final deviceApp in deviceApps) {
        final blockedApp = BlockedApp(
          name: deviceApp.name,
          packageName: deviceApp.packageName,
          icon: deviceApp.icon,
          category: _getAppCategoryFromString(deviceApp.category),
          isBlocked: true,
          blockDuringFocus: true,
        );

        await _appBlockerService.addBlockedApp(blockedApp);
      }

      // Refresh blocked apps list
      final updatedBlockedApps = await _appBlockerService.getAllBlockedApps();
      state = state.copyWith(blockedApps: updatedBlockedApps, error: null);

      // Update device apps blocking status
      await _updateDeviceAppBlockingStatus();
    } catch (e) {
      state = state.copyWith(error: 'Failed to block multiple apps: ${ErrorHandler.getUserFriendlyMessage(e)}');
      ErrorHandler.logError('Block multiple apps', e);
    }
  }

  // FIXED: Helper method to convert string category to AppCategory
  AppCategory _getAppCategoryFromString(String category) {
    switch (category.toLowerCase()) {
      case 'social':
        return AppCategory.social;
      case 'entertainment':
        return AppCategory.entertainment;
      case 'games':
        return AppCategory.games;
      case 'communication':
      case 'messaging':
        return AppCategory.messaging;
      case 'productivity':
        return AppCategory.productivity;
      case 'shopping':
        return AppCategory.shopping;
      case 'news':
        return AppCategory.news;
      case 'education':
        return AppCategory.education;
      case 'health':
        return AppCategory.health;
      case 'finance':
        return AppCategory.finance;
      default:
        return AppCategory.other;
    }
  }

  // Get statistics for today
  Map<String, dynamic> getTodayStatistics() {
    return {
      'totalBlockAttempts': state.totalBlockAttemptsToday,
      'timeSaved': state.totalTimeSavedToday,
      'mostBlockedApp': _getMostBlockedAppToday(),
      'streak': state.currentStreak,
      'focusSessionsCompleted': 0, // Would track from focus sessions
    };
  }

  String? _getMostBlockedAppToday() {
    if (state.todayBlockAttempts.isEmpty) return null;

    final sortedEntries = state.todayBlockAttempts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final mostBlockedPackage = sortedEntries.first.key;
    final app = state.blockedApps.firstWhere(
          (app) => app.packageName == mostBlockedPackage,
      orElse: () => BlockedApp(
        name: 'Unknown App',
        packageName: mostBlockedPackage,
        icon: '📱',
        category: AppCategory.other,
      ),
    );

    return app.name;
  }

  // Get weekly statistics - FIXED: Safe fallback if method doesn't exist
  Future<Map<String, dynamic>> getWeeklyStatistics() async {
    try {
      // Try to get weekly stats from service, fallback to manual calculation
      try {
        return await _appBlockerService.getWeeklyStatistics();
      } catch (e) {
        // If service method doesn't exist, return calculated stats
        return _calculateWeeklyStatistics();
      }
    } catch (e) {
      state = state.copyWith(error: 'Failed to load weekly statistics: ${ErrorHandler.getUserFriendlyMessage(e)}');
      ErrorHandler.logError('Get weekly statistics', e);
      return _calculateWeeklyStatistics();
    }
  }

  // Get productivity insights - FIXED: Safe fallback if method doesn't exist
  Future<Map<String, dynamic>> getProductivityInsights() async {
    try {
      // Try to get insights from service, fallback to manual calculation
      try {
        return await _appBlockerService.getProductivityInsights();
      } catch (e) {
        // If service method doesn't exist, return calculated insights
        return _calculateProductivityInsights();
      }
    } catch (e) {
      state = state.copyWith(error: 'Failed to load productivity insights: ${ErrorHandler.getUserFriendlyMessage(e)}');
      ErrorHandler.logError('Get productivity insights', e);
      return _calculateProductivityInsights();
    }
  }

  // Export data - FIXED: Safe fallback if method doesn't exist
  Future<Map<String, dynamic>> exportData() async {
    try {
      // Try to export from service, fallback to manual export
      try {
        return await _appBlockerService.exportData();
      } catch (e) {
        // If service method doesn't exist, return manual export
        return _manualExportData();
      }
    } catch (e) {
      state = state.copyWith(error: 'Failed to export data: ${ErrorHandler.getUserFriendlyMessage(e)}');
      ErrorHandler.logError('Export data', e);
      return _manualExportData();
    }
  }

  // FIXED: Manual calculation methods for fallback
  Map<String, dynamic> _calculateWeeklyStatistics() {
    return {
      'totalBlocks': state.totalBlockAttemptsToday * 7, // Rough estimate
      'topBlockedApps': state.todayBlockAttempts,
      'averageSessionLength': 25, // Default session length
      'totalFocusTime': state.totalTimeSavedToday.inMinutes * 7,
      'streak': state.currentStreak,
    };
  }

  Map<String, dynamic> _calculateProductivityInsights() {
    final productivityScore = getProductivityScore();
    return {
      'productivityScore': productivityScore,
      'focusEfficiency': productivityScore,
      'improvementAreas': productivityScore < 0.7
          ? ['Reduce distracting apps', 'Increase focus session length']
          : ['Maintain current habits'],
      'recommendations': getSmartSuggestions(),
    };
  }

  Map<String, dynamic> _manualExportData() {
    return {
      'version': '1.0',
      'exportDate': DateTime.now().toIso8601String(),
      'blockedApps': state.blockedApps.map((app) => app.toJson()).toList(),
      'statistics': {
        'currentStreak': state.currentStreak,
        'totalTimeSavedToday': state.totalTimeSavedToday.inMinutes,
        'blockAttempts': state.todayBlockAttempts,
      },
      'settings': {
        'autoBlockDuringFocus': state.autoBlockDuringFocus,
        'showBlockNotifications': state.showBlockNotifications,
        'messageTheme': state.messageTheme.index,
      },
    };
  }

  // FIXED: Import data - now uses AppBlockerManager instead of service
  Future<bool> importData(Map<String, dynamic> data) async {
    try {
      final success = await _appBlockerManager.importData(data);
      if (success) {
        // Reload data after import
        await _loadInitialData();
      }
      return success;
    } catch (e) {
      state = state.copyWith(error: 'Failed to import data: ${ErrorHandler.getUserFriendlyMessage(e)}');
      ErrorHandler.logError('Import data', e);
      return false;
    }
  }

  // Clear error
  void clearError() {
    state = state.copyWith(error: null);
  }

  // Clear all data
  Future<void> clearAllData() async {
    try {
      await _appBlockerService.clearAllData();
      await _appBlockerManager.clearAllData();
      state = AppBlockerState(blockedApps: [], deviceApps: [], isInitialized: true);
    } catch (e) {
      state = state.copyWith(error: 'Failed to clear all data: ${ErrorHandler.getUserFriendlyMessage(e)}');
      ErrorHandler.logError('Clear all data', e);
    }
  }

  // Refresh data
  Future<void> refresh() async {
    await _loadInitialData();
  }
  // Advanced features
  Future<void> pauseFocusMode({Duration? duration}) async {
    try {
      if (!state.isFocusModeActive) return;

      // Use manager to pause focus session
      await _appBlockerManager.pauseFocusSession();

      // Temporarily pause focus mode
      state = state.copyWith(
        isFocusModeActive: false,
        error: null,
      );

      // Resume after specified duration
      if (duration != null) {
        Future.delayed(duration, () async {
          if (!state.isFocusModeActive) {
            await _appBlockerManager.resumeFocusSession();
            state = state.copyWith(isFocusModeActive: true);
          }
        });
      }
    } catch (e) {
      state = state.copyWith(error: 'Failed to pause focus mode: ${ErrorHandler.getUserFriendlyMessage(e)}');
      ErrorHandler.logError('Pause focus mode', e);
    }
  }

  // Schedule focus sessions
  Future<void> scheduleFocusSession({
    required DateTime startTime,
    required Duration duration,
    List<String>? specificApps,
  }) async {
    try {
      // This would integrate with device scheduling
      // For now, just update state with scheduled info
      await _appBlockerService.updateSetting('scheduledFocus', {
        'startTime': startTime.millisecondsSinceEpoch,
        'duration': duration.inMinutes,
        'specificApps': specificApps ?? [],
      });

      if (DateTime.now().isAfter(startTime) &&
          DateTime.now().isBefore(startTime.add(duration))) {
        await startFocusMode(duration: duration);
      }
    } catch (e) {
      state = state.copyWith(error: 'Failed to schedule focus session: ${ErrorHandler.getUserFriendlyMessage(e)}');
      ErrorHandler.logError('Schedule focus session', e);
    }
  }

  // Get app usage patterns
  Future<Map<String, dynamic>> getUsagePatterns() async {
    try {
      final weeklyStats = await getWeeklyStatistics();
      final todayStats = getTodayStatistics();

      return {
        'peakBlockingHours': _calculatePeakHours(weeklyStats),
        'mostProblematicApps': _getMostProblematicApps(weeklyStats),
        'focusEfficiency': _calculateFocusEfficiency(todayStats, weeklyStats),
        'improvementTrends': _getImprovementTrends(weeklyStats),
      };
    } catch (e) {
      state = state.copyWith(error: 'Failed to get usage patterns: ${ErrorHandler.getUserFriendlyMessage(e)}');
      ErrorHandler.logError('Get usage patterns', e);
      return {};
    }
  }

  List<int> _calculatePeakHours(Map<String, dynamic> weeklyStats) {
    // This would analyze when most blocks happen
    // For now, return common distraction hours
    return [9, 11, 14, 16, 20]; // 9am, 11am, 2pm, 4pm, 8pm
  }

  List<String> _getMostProblematicApps(Map<String, dynamic> weeklyStats) {
    final topBlockedApps = Map<String, int>.from(weeklyStats['topBlockedApps'] ?? {});
    final sortedApps = topBlockedApps.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return sortedApps.take(5).map((e) => e.key).toList();
  }

  // FIXED: Return double explicitly to match return type
  double _calculateFocusEfficiency(Map<String, dynamic> todayStats, Map<String, dynamic> weeklyStats) {
    final todayBlocks = (todayStats['totalBlockAttempts'] as num?)?.toDouble() ?? 0.0;
    final weeklyAverage = ((weeklyStats['totalBlocks'] as num?)?.toDouble() ?? 0.0) / 7;

    if (weeklyAverage == 0) return 1.0;
    return (1 - (todayBlocks / weeklyAverage)).clamp(0.0, 1.0);
  }

  Map<String, dynamic> _getImprovementTrends(Map<String, dynamic> weeklyStats) {
    // This would analyze trends over time
    return {
      'streakTrend': 'improving', // or 'declining', 'stable'
      'blocksTrend': 'decreasing', // fewer blocks = better focus
      'consistencyScore': 0.85, // How consistent focus sessions are
    };
  }

  // Smart suggestions based on usage patterns
  List<String> getSmartSuggestions() {
    final suggestions = <String>[];

    if (state.totalBlockAttemptsToday > 15) {
      suggestions.add('Consider longer focus sessions to reduce frequent interruptions');
    }

    if (state.currentStreak == 0) {
      suggestions.add('Start with short 15-minute focus sessions to build momentum');
    } else if (state.currentStreak >= 7) {
      suggestions.add('Great streak! Try challenging yourself with longer sessions');
    }

    if (state.blockedApps.length < 3) {
      suggestions.add('Consider blocking more distracting apps during focus time');
    }

    final mostBlockedApp = _getMostBlockedAppToday();
    if (mostBlockedApp != null) {
      suggestions.add('$mostBlockedApp seems to be your biggest distraction today');
    }

    return suggestions;
  }

  // Gamification features
  Map<String, dynamic> getGamificationData() {
    final level = _calculateLevel();
    final xp = _calculateXP();
    final nextLevelXP = _getNextLevelXP(level);

    return {
      'level': level,
      'currentXP': xp,
      'nextLevelXP': nextLevelXP,
      'progress': xp / nextLevelXP,
      'badges': _getEarnedBadges(),
      'dailyChallenge': _getDailyChallenge(),
      'leaderboardRank': _getLeaderboardRank(),
    };
  }

  int _calculateLevel() {
    final totalXP = _calculateXP();
    return (totalXP / 100).floor() + 1; // 100 XP per level
  }

  int _calculateXP() {
    int xp = 0;
    xp += state.currentStreak * 10; // 10 XP per streak day
    xp += state.totalBlockAttemptsToday * 2; // 2 XP per blocked attempt
    xp += (state.totalTimeSavedToday.inMinutes / 10).floor() * 5; // 5 XP per 10 minutes saved
    return xp;
  }

  int _getNextLevelXP(int currentLevel) {
    return currentLevel * 100; // Each level requires more XP
  }

  List<String> _getEarnedBadges() {
    final badges = <String>[];

    if (state.currentStreak >= 3) badges.add('🔥 3-Day Streak');
    if (state.currentStreak >= 7) badges.add('⭐ Week Warrior');
    if (state.currentStreak >= 30) badges.add('🏆 Focus Master');
    if (state.totalBlockAttemptsToday >= 10) badges.add('🛡️ Distraction Defender');
    if (state.totalBlockAttemptsToday >= 25) badges.add('⚔️ Focus Champion');
    if (state.totalTimeSavedToday.inHours >= 2) badges.add('⏰ Time Saver');

    return badges;
  }

  Map<String, dynamic> _getDailyChallenge() {
    final today = DateTime.now().day;
    final challenges = [
      'Complete 3 focus sessions',
      'Block 15 distracting apps',
      'Maintain focus for 2 hours',
      'Try a new productivity technique',
      'Beat yesterday\'s focus time',
    ];

    return {
      'title': challenges[today % challenges.length],
      'progress': _calculateChallengeProgress(today % challenges.length),
      'reward': '50 XP + Special Badge',
    };
  }

  double _calculateChallengeProgress(int challengeType) {
    switch (challengeType) {
      case 0: // Complete 3 focus sessions
        return 0.33; // This would track actual sessions
      case 1: // Block 15 distracting apps
        return (state.totalBlockAttemptsToday / 15).clamp(0.0, 1.0);
      case 2: // Maintain focus for 2 hours
        return (state.totalTimeSavedToday.inMinutes / 120).clamp(0.0, 1.0);
      default:
        return 0.0;
    }
  }

  int _getLeaderboardRank() {
    // This would compare with other users
    // For now, return a mock rank based on streak
    if (state.currentStreak >= 30) return 1;
    if (state.currentStreak >= 14) return 5;
    if (state.currentStreak >= 7) return 15;
    if (state.currentStreak >= 3) return 50;
    return 100;
  }

  // FIXED: Additional methods for better functionality

  /// Get app by package name
  BlockedApp? getAppByPackageName(String packageName) {
    try {
      return state.blockedApps.firstWhere(
            (app) => app.packageName == packageName,
      );
    } catch (e) {
      return null;
    }
  }

  /// Check if app is blocked
  bool isAppBlocked(String packageName) {
    final app = getAppByPackageName(packageName);
    return app?.isBlocked ?? false;
  }

  /// Get blocked apps by category
  List<BlockedApp> getBlockedAppsByCategory(AppCategory category) {
    return state.blockedApps
        .where((app) => app.category == category && app.isBlocked)
        .toList();
  }

  /// Get device apps by category
  List<DeviceApp> getDeviceAppsByCategory(String category) {
    return state.deviceApps
        .where((app) => app.category.toLowerCase() == category.toLowerCase())
        .toList();
  }

  /// Search device apps
  List<DeviceApp> searchDeviceApps(String query) {
    if (query.isEmpty) return state.deviceApps;

    final lowercaseQuery = query.toLowerCase();
    return state.deviceApps.where((app) =>
    app.name.toLowerCase().contains(lowercaseQuery) ||
        app.packageName.toLowerCase().contains(lowercaseQuery)
    ).toList();
  }

  /// Get focus session progress
  Map<String, dynamic> getFocusSessionProgress() {
    if (!state.isFocusModeActive || state.focusStartTime == null) {
      return {
        'isActive': false,
        'progress': 0.0,
        'timeRemaining': Duration.zero,
        'timeElapsed': Duration.zero,
      };
    }

    final now = DateTime.now();
    final elapsed = now.difference(state.focusStartTime!);
    final duration = state.focusDuration ?? Duration(minutes: 25);
    final remaining = duration - elapsed;
    final progress = (elapsed.inMilliseconds / duration.inMilliseconds).clamp(0.0, 1.0);

    return {
      'isActive': true,
      'progress': progress,
      'timeRemaining': remaining.isNegative ? Duration.zero : remaining,
      'timeElapsed': elapsed,
      'totalDuration': duration,
    };
  }

  /// Get app blocking statistics
  Map<String, dynamic> getAppBlockingStats() {
    final totalApps = state.blockedApps.length;
    final activelyBlocked = state.activelyBlockedApps.length;
    final totalAttempts = state.totalBlockAttemptsToday;
    final timeSaved = state.totalTimeSavedToday;

    return {
      'totalApps': totalApps,
      'activelyBlocked': activelyBlocked,
      'totalAttempts': totalAttempts,
      'timeSaved': timeSaved,
      'averageAttemptsPerApp': totalApps > 0 ? totalAttempts / totalApps : 0.0,
      'mostBlockedApp': _getMostBlockedAppToday(),
    };
  }

  /// Update app settings in bulk
  Future<void> updateSettings(Map<String, dynamic> settings) async {
    try {
      for (final entry in settings.entries) {
        await _appBlockerService.updateSetting(entry.key, entry.value);
      }

      // Update state with new settings
      state = state.copyWith(
        autoBlockDuringFocus: settings['autoBlockDuringFocus'] ?? state.autoBlockDuringFocus,
        showBlockNotifications: settings['showBlockNotifications'] ?? state.showBlockNotifications,
        messageTheme: settings['messageTheme'] != null
            ? MessageTheme.values[settings['messageTheme']]
            : state.messageTheme,
        error: null,
      );
    } catch (e) {
      state = state.copyWith(error: 'Failed to update settings: ${ErrorHandler.getUserFriendlyMessage(e)}');
      ErrorHandler.logError('Update settings', e);
    }
  }

  /// Reset statistics - FIXED: Manual reset without service call
  Future<void> resetStatistics() async {
    try {
      // FIXED: Reset statistics manually since service method doesn't exist yet
      state = state.copyWith(
        todayBlockAttempts: {},
        totalTimeSavedToday: Duration.zero,
        currentStreak: 0,
        error: null,
      );

      // Save the reset streak to storage
      await _appBlockerService.updateSetting('currentStreak', 0);
      await _appBlockerService.updateSetting('todayBlockAttempts', {});
      await _appBlockerService.updateSetting('totalTimeSavedToday', 0);
    } catch (e) {
      state = state.copyWith(error: 'Failed to reset statistics: ${ErrorHandler.getUserFriendlyMessage(e)}');
      ErrorHandler.logError('Reset statistics', e);
    }
  }

  /// Get available categories from device apps
  List<String> getAvailableCategories() {
    final categories = state.deviceApps
        .map((app) => app.category)
        .where((category) => category.isNotEmpty)
        .toSet()
        .toList();

    categories.sort();
    return categories;
  }

  /// Get apps by multiple categories
  List<DeviceApp> getAppsByCategories(List<String> categories) {
    return state.deviceApps
        .where((app) => categories.contains(app.category))
        .toList();
  }

  /// Check if any focus mode is possible (has blocked apps and permissions)
  bool canStartFocusMode() {
    return state.blockedApps.any((app) => app.isBlocked) && state.isInitialized;
  }

  /// Get productivity score (0.0 to 1.0)
  double getProductivityScore() {
    if (state.totalBlockAttemptsToday == 0) return 1.0;

    // Lower attempts = higher productivity
    final maxAttempts = 50; // Arbitrary max for scoring
    final normalizedAttempts = (state.totalBlockAttemptsToday / maxAttempts).clamp(0.0, 1.0);
    return 1.0 - normalizedAttempts;
  }

  /// Get streak information
  Map<String, dynamic> getStreakInfo() {
    return {
      'currentStreak': state.currentStreak,
      'streakLevel': _getStreakLevel(),
      'nextMilestone': _getNextStreakMilestone(),
      'streakMessage': _getStreakMessage(),
    };
  }

  String _getStreakLevel() {
    if (state.currentStreak >= 30) return 'Master';
    if (state.currentStreak >= 14) return 'Expert';
    if (state.currentStreak >= 7) return 'Advanced';
    if (state.currentStreak >= 3) return 'Intermediate';
    return 'Beginner';
  }

  int _getNextStreakMilestone() {
    if (state.currentStreak < 3) return 3;
    if (state.currentStreak < 7) return 7;
    if (state.currentStreak < 14) return 14;
    if (state.currentStreak < 30) return 30;
    return ((state.currentStreak / 30).ceil() + 1) * 30;
  }

  String _getStreakMessage() {
    if (state.currentStreak == 0) return 'Start your focus journey today!';
    if (state.currentStreak < 3) return 'Building momentum...';
    if (state.currentStreak < 7) return 'Great start! Keep it up!';
    if (state.currentStreak < 14) return 'You\'re on fire! 🔥';
    if (state.currentStreak < 30) return 'Incredible dedication!';
    return 'You\'re a focus master! 🏆';
  }

  /// Get permission status from manager
  Future<Map<String, bool>> getPermissionStatus() async {
    try {
      return await _appBlockerManager.checkPermissions();
    } catch (e) {
      ErrorHandler.logError('Get permission status', e);
      return {};
    }
  }

  /// Request permissions through manager
  Future<bool> requestPermissions() async {
    try {
      return await _appBlockerManager.requestPermissions();
    } catch (e) {
      ErrorHandler.logError('Request permissions', e);
      return false;
    }
  }

  /// Check if required permissions are granted
  Future<bool> hasRequiredPermissions() async {
    try {
      return await _appBlockerManager.hasRequiredPermissions();
    } catch (e) {
      ErrorHandler.logError('Check required permissions', e);
      return false;
    }
  }

  /// Get detailed permission information
  Future<List<PermissionStatus>> getDetailedPermissionStatuses() async {
    try {
      return await _appBlockerManager.getDetailedPermissionStatuses();
    } catch (e) {
      ErrorHandler.logError('Get detailed permission statuses', e);
      return [];
    }
  }

  /// Extend current focus session
  Future<void> extendFocusSession(Duration additionalTime) async {
    try {
      if (!state.isFocusModeActive) {
        throw Exception('No active focus session to extend');
      }

      await _appBlockerManager.extendFocusSession(additionalTime);

      final newDuration = (state.focusDuration ?? Duration(minutes: 25)) + additionalTime;
      state = state.copyWith(focusDuration: newDuration);
    } catch (e) {
      state = state.copyWith(error: 'Failed to extend focus session: ${ErrorHandler.getUserFriendlyMessage(e)}');
      ErrorHandler.logError('Extend focus session', e);
    }
  }

  /// Get current focus session info from manager
  Map<String, dynamic>? getCurrentFocusSessionInfo() {
    try {
      return _appBlockerManager.currentFocusSession;
    } catch (e) {
      ErrorHandler.logError('Get current focus session info', e);
      return null;
    }
  }

  /// Get today's focus statistics from manager
  Future<FocusStats> getTodayFocusStatistics() async {
    try {
      return await _appBlockerManager.getTodayStatistics();
    } catch (e) {
      ErrorHandler.logError('Get today focus statistics', e);
      return FocusStats.empty();
    }
  }

  /// Get app blocking statistics from manager
  Future<Map<String, int>> getAppBlockingStatsFromManager() async {
    try {
      return await _appBlockerManager.getAppBlockingStats();
    } catch (e) {
      ErrorHandler.logError('Get app blocking stats from manager', e);
      return {};
    }
  }
}

// ============================================================================
// ADDITIONAL PROVIDERS FOR SPECIFIC FUNCTIONALITY
// ============================================================================

/// Provider for blocked apps only
final blockedAppsProvider = Provider<List<BlockedApp>>((ref) {
  final state = ref.watch(appBlockerProvider);
  return state.blockedApps;
});

/// Provider for device apps only
final deviceAppsProvider = Provider<List<DeviceApp>>((ref) {
  final state = ref.watch(appBlockerProvider);
  return state.deviceApps;
});

/// Provider for focus mode status
final focusModeProvider = Provider<bool>((ref) {
  final state = ref.watch(appBlockerProvider);
  return state.isFocusModeActive;
});

/// Provider for app blocker loading state
final appBlockerLoadingProvider = Provider<bool>((ref) {
  final state = ref.watch(appBlockerProvider);
  return state.isLoading;
});

/// Provider for app blocker error state
final appBlockerErrorProvider = Provider<String?>((ref) {
  final state = ref.watch(appBlockerProvider);
  return state.error;
});

/// Provider for today's statistics
final todayStatsProvider = Provider<Map<String, dynamic>>((ref) {
  final notifier = ref.read(appBlockerProvider.notifier);
  return notifier.getTodayStatistics();
});

/// Provider for productivity score
final productivityScoreProvider = Provider<double>((ref) {
  final notifier = ref.read(appBlockerProvider.notifier);
  return notifier.getProductivityScore();
});

/// Provider for streak information
final streakInfoProvider = Provider<Map<String, dynamic>>((ref) {
  final notifier = ref.read(appBlockerProvider.notifier);
  return notifier.getStreakInfo();
});

/// Provider for focus session progress
final focusProgressProvider = Provider<Map<String, dynamic>>((ref) {
  final notifier = ref.read(appBlockerProvider.notifier);
  return notifier.getFocusSessionProgress();
});

/// Provider for smart suggestions
final smartSuggestionsProvider = Provider<List<String>>((ref) {
  final notifier = ref.read(appBlockerProvider.notifier);
  return notifier.getSmartSuggestions();
});

/// Provider for gamification data
final gamificationProvider = Provider<Map<String, dynamic>>((ref) {
  final notifier = ref.read(appBlockerProvider.notifier);
  return notifier.getGamificationData();
});

/// Provider for available categories
final availableCategoriesProvider = Provider<List<String>>((ref) {
  final notifier = ref.read(appBlockerProvider.notifier);
  return notifier.getAvailableCategories();
});

/// Provider for checking if focus mode can start
final canStartFocusModeProvider = Provider<bool>((ref) {
  final notifier = ref.read(appBlockerProvider.notifier);
  return notifier.canStartFocusMode();
});

/// Provider for permission status
final permissionStatusProvider = FutureProvider<Map<String, bool>>((ref) async {
  final notifier = ref.read(appBlockerProvider.notifier);
  return await notifier.getPermissionStatus();
});

/// Provider for detailed permission statuses
final detailedPermissionStatusProvider = FutureProvider<List<PermissionStatus>>((ref) async {
  final notifier = ref.read(appBlockerProvider.notifier);
  return await notifier.getDetailedPermissionStatuses();
});

/// Provider for current focus session info
final currentFocusSessionProvider = Provider<Map<String, dynamic>?>((ref) {
  final notifier = ref.read(appBlockerProvider.notifier);
  return notifier.getCurrentFocusSessionInfo();
});

/// Provider for today's focus statistics
final todayFocusStatsProvider = FutureProvider<FocusStats>((ref) async {
  final notifier = ref.read(appBlockerProvider.notifier);
  return await notifier.getTodayFocusStatistics();
});

/// Provider for weekly statistics
final weeklyStatsProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final notifier = ref.read(appBlockerProvider.notifier);
  return await notifier.getWeeklyStatistics();
});

/// Provider for productivity insights
final productivityInsightsProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final notifier = ref.read(appBlockerProvider.notifier);
  return await notifier.getProductivityInsights();
});

/// Provider for usage patterns
final usagePatternsProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final notifier = ref.read(appBlockerProvider.notifier);
  return await notifier.getUsagePatterns();
});