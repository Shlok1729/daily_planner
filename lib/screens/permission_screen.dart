import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:daily_planner/providers/app_blocker_provider.dart';
import 'package:daily_planner/screens/home_screen.dart';
import 'package:daily_planner/screens/main_navigation_screen.dart';
import 'package:daily_planner/utils/error_handler.dart';
import 'package:daily_planner/config/environment_config.dart';
import 'package:daily_planner/utils/app_blocker_manager.dart';
import 'dart:io';

// FIXED: Use alias to avoid naming conflict with permission_handler
import 'package:permission_handler/permission_handler.dart' as ph;

class PermissionScreen extends ConsumerStatefulWidget {
  const PermissionScreen({Key? key}) : super(key: key);

  @override
  _PermissionScreenState createState() => _PermissionScreenState();
}

class _PermissionScreenState extends ConsumerState<PermissionScreen>
    with WidgetsBindingObserver {
  bool _isLoading = false;
  bool _isCheckingPermissions = false;
  Map<String, bool> _permissions = {
    'usageStats': false,
    'overlay': false,
    'notification': false,
  };

  // FIXED: Use permission_handler's PermissionStatus with alias
  Map<String, ph.PermissionStatus> _detailedPermissions = {};
  String? _errorMessage;
  int _permissionCheckAttempts = 0;
  static const int _maxCheckAttempts = 3;

  // FIXED: Create AppBlockerManager instance directly
  late final AppBlockerManager _appBlockerManager;

  @override
  void initState() {
    super.initState();
    // FIXED: Initialize AppBlockerManager directly
    _appBlockerManager = AppBlockerManager();
    WidgetsBinding.instance.addObserver(this);
    _initializePermissionCheck();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    // When user returns from settings, recheck permissions
    if (state == AppLifecycleState.resumed && !_isCheckingPermissions) {
      _checkPermissions(showLoading: false);
    }
  }

  Future<void> _initializePermissionCheck() async {
    // Small delay to ensure UI is ready
    await Future.delayed(const Duration(milliseconds: 300));
    await _checkPermissions();
  }

  Future<void> _checkPermissions({bool showLoading = true}) async {
    if (_isCheckingPermissions) return;

    setState(() {
      _isCheckingPermissions = true;
      if (showLoading) _isLoading = true;
      _errorMessage = null;
    });

    try {
      // FIXED: Use direct instance instead of provider
      if (!_appBlockerManager.isSupported) {
        // Platform not supported - skip to main app
        _navigateToMain();
        return;
      }

      // Check app blocker specific permissions
      final appBlockerPermissions = await _checkAppBlockerPermissions();

      // Check standard Android permissions
      final standardPermissions = await _checkStandardPermissions();

      // Combine results
      final combinedPermissions = <String, bool>{
        ...appBlockerPermissions,
        ...standardPermissions,
      };

      setState(() {
        _permissions = combinedPermissions;
        _isLoading = false;
        _isCheckingPermissions = false;
      });

    } catch (e) {
      setState(() {
        _errorMessage = ErrorHandler.getUserFriendlyMessage(e);
        _isLoading = false;
        _isCheckingPermissions = false;
      });

      ErrorHandler.logError('Permission Check Error', e);
    }
  }

  Future<Map<String, bool>> _checkAppBlockerPermissions() async {
    try {
      // FIXED: Use direct instance
      final permissions = await _appBlockerManager.checkPermissions();

      // Ensure we have the expected keys
      return {
        'usageStats': permissions['usageStats'] ?? false,
        'overlay': permissions['overlay'] ?? false,
        'notification': permissions['notification'] ?? false,
      };
    } catch (e) {
      ErrorHandler.logError('App Blocker Permission Check Error', e);
      return {
        'usageStats': false,
        'overlay': false,
        'notification': false,
      };
    }
  }

  Future<Map<String, bool>> _checkStandardPermissions() async {
    final permissions = <String, bool>{};

    try {
      // Check notification permission (Android 13+)
      if (Platform.isAndroid) {
        final notificationStatus = await ph.Permission.notification.status;
        permissions['notification'] = notificationStatus.isGranted;
        _detailedPermissions['notification'] = notificationStatus;
      }

      // Check other permissions that can be checked via permission_handler
      final storageStatus = await ph.Permission.storage.status;
      _detailedPermissions['storage'] = storageStatus;

    } catch (e) {
      ErrorHandler.logError('Standard Permission Check Error', e);
    }

    return permissions;
  }

  Future<void> _requestPermissions() async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await _requestAppBlockerPermissions();
      await _requestStandardPermissions();

      // Wait for user to potentially grant permissions
      await Future.delayed(const Duration(seconds: 2));

      // Recheck permissions
      await _checkPermissions(showLoading: false);

      // Show feedback based on results
      _showPermissionFeedback();

    } catch (e) {
      setState(() {
        _errorMessage = ErrorHandler.getUserFriendlyMessage(e);
        _isLoading = false;
      });

      _showErrorSnackbar('Failed to request permissions: ${e.toString()}');
    }
  }

  Future<void> _requestAppBlockerPermissions() async {
    try {
      // FIXED: Use direct instance
      await _appBlockerManager.requestPermissions();
    } catch (e) {
      ErrorHandler.logError('App Blocker Permission Request Error', e);
      rethrow;
    }
  }

  Future<void> _requestStandardPermissions() async {
    try {
      // Request notification permission
      if (Platform.isAndroid && !(_permissions['notification'] ?? false)) {
        await ph.Permission.notification.request();
      }

      // Request other permissions as needed
      if (!(_detailedPermissions['storage']?.isGranted ?? false)) {
        await ph.Permission.storage.request();
      }

    } catch (e) {
      ErrorHandler.logError('Standard Permission Request Error', e);
    }
  }

  void _showPermissionFeedback() {
    if (_allPermissionsGranted) {
      _showSuccessSnackbar('All permissions granted successfully!');
      // Auto-navigate after a short delay
      Future.delayed(const Duration(seconds: 1), _navigateToMain);
    } else {
      final missingPermissions = _getMissingPermissions();
      _showWarningSnackbar('Still missing: ${missingPermissions.join(', ')}');
    }
  }

  List<String> _getMissingPermissions() {
    final missing = <String>[];
    _permissions.forEach((key, granted) {
      if (!granted) {
        switch (key) {
          case 'usageStats':
            missing.add('Usage Stats');
            break;
          case 'overlay':
            missing.add('Overlay');
            break;
          case 'notification':
            missing.add('Notifications');
            break;
        }
      }
    });
    return missing;
  }

  // FIXED: Use permission_handler's openAppSettings method directly
  Future<void> _openAppSettings() async {
    try {
      // Use permission_handler's openAppSettings method directly
      await ph.openAppSettings();
    } catch (e) {
      _showErrorSnackbar('Could not open app settings');
    }
  }

  Future<void> _openSpecificPermissionSettings() async {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => _buildPermissionSettingsSheet(),
    );
  }

  Widget _buildPermissionSettingsSheet() {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Icon(Icons.settings, color: Colors.blue),
              const SizedBox(width: 12),
              const Text(
                'Permission Settings',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 20),

          if (!(_permissions['usageStats'] ?? false))
            _buildSettingsAction(
              'Usage Stats Permission',
              'Required to monitor app usage',
              Icons.bar_chart,
                  () => _openUsageStatsSettings(),
            ),

          if (!(_permissions['overlay'] ?? false))
            _buildSettingsAction(
              'Overlay Permission',
              'Required to show blocking screen',
              Icons.layers,
                  () => _openOverlaySettings(),
            ),

          if (!(_permissions['notification'] ?? false))
            _buildSettingsAction(
              'Notification Permission',
              'Required for focus mode alerts',
              Icons.notifications,
                  () => _openNotificationSettings(),
            ),

          const SizedBox(height: 20),

          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Close'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    _checkPermissions();
                  },
                  child: const Text('Recheck'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsAction(String title, String description, IconData icon, VoidCallback onTap) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Icon(icon, color: Colors.orange),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(description),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: onTap,
      ),
    );
  }

  Future<void> _openUsageStatsSettings() async {
    try {
      // FIXED: Use permission_handler to open settings
      await ph.openAppSettings();
    } catch (e) {
      _showErrorSnackbar('Could not open usage stats settings');
    }
  }

  Future<void> _openOverlaySettings() async {
    try {
      // FIXED: Handle overlay permission properly
      if (Platform.isAndroid) {
        await ph.Permission.systemAlertWindow.request();
      } else {
        await ph.openAppSettings();
      }
    } catch (e) {
      _showErrorSnackbar('Could not open overlay settings');
    }
  }

  Future<void> _openNotificationSettings() async {
    try {
      await ph.Permission.notification.request();
    } catch (e) {
      _showErrorSnackbar('Could not open notification settings');
    }
  }

  void _navigateToMain() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (context) => const MainNavigationScreen(),
      ),
    );
  }

  void _skipPermissions() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.warning, color: Colors.orange),
            SizedBox(width: 8),
            Text('Skip Permissions?'),
          ],
        ),
        content: const Text(
          'App blocking features will not work without these permissions. You can enable them later in Settings.\n\nAre you sure you want to continue?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Go Back'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _navigateToMain();
            },
            child: const Text('Continue Anyway'),
          ),
        ],
      ),
    );
  }

  bool get _allPermissionsGranted =>
      _permissions.values.every((granted) => granted);

  bool get _hasAnyPermissions =>
      _permissions.values.any((granted) => granted);

  void _showSuccessSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void _showWarningSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.warning, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.orange,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 4),
      ),
    );
  }

  void _showErrorSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 5),
        action: SnackBarAction(
          label: 'Retry',
          textColor: Colors.white,
          onPressed: _checkPermissions,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              _buildHeader(),

              const SizedBox(height: 24),

              // Main content
              Expanded(
                child: _isLoading
                    ? _buildLoadingState()
                    : _errorMessage != null
                    ? _buildErrorState()
                    : _buildPermissionsContent(),
              ),

              // Bottom buttons
              _buildBottomButtons(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Icon(
            Icons.security,
            size: 48,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'App Permissions',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          'Grant permissions to enable powerful focus mode and app blocking features',
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            color: Colors.grey[600],
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text('Checking permissions...'),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 64,
            color: Colors.red[400],
          ),
          const SizedBox(height: 16),
          Text(
            'Permission Check Failed',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _errorMessage!,
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey[600]),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _checkPermissions,
            icon: const Icon(Icons.refresh),
            label: const Text('Try Again'),
          ),
        ],
      ),
    );
  }

  Widget _buildPermissionsContent() {
    return SingleChildScrollView(
      child: Column(
        children: [
          // Permission status summary
          _buildPermissionSummary(),

          const SizedBox(height: 32),

          // Individual permission items
          _buildPermissionItem(
            'Usage Stats Access',
            'Monitor which apps you use to enable intelligent blocking',
            Icons.analytics,
            _permissions['usageStats'] ?? false,
            isRequired: true,
          ),

          _buildPermissionItem(
            'Display Over Other Apps',
            'Show the focus lock screen when you try to open blocked apps',
            Icons.layers,
            _permissions['overlay'] ?? false,
            isRequired: true,
          ),

          _buildPermissionItem(
            'Notifications',
            'Send focus mode alerts and productivity reminders',
            Icons.notifications,
            _permissions['notification'] ?? false,
            isRequired: false,
          ),

          if (!_allPermissionsGranted) ...[
            const SizedBox(height: 24),
            _buildPermissionHelp(),
          ],
        ],
      ),
    );
  }

  Widget _buildPermissionSummary() {
    final grantedCount = _permissions.values.where((granted) => granted).length;
    final totalCount = _permissions.length;
    final progress = grantedCount / totalCount;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Permission Status',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '$grantedCount of $totalCount permissions granted',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _allPermissionsGranted
                        ? Colors.green.withOpacity(0.1)
                        : Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    _allPermissionsGranted ? 'Complete' : 'Incomplete',
                    style: TextStyle(
                      color: _allPermissionsGranted ? Colors.green : Colors.orange,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            LinearProgressIndicator(
              value: progress,
              backgroundColor: Colors.grey[300],
              valueColor: AlwaysStoppedAnimation<Color>(
                _allPermissionsGranted ? Colors.green : Colors.orange,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPermissionItem(
      String title,
      String description,
      IconData icon,
      bool isGranted, {
        bool isRequired = true,
      }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: isGranted
                    ? Colors.green.withOpacity(0.1)
                    : Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                isGranted ? Icons.check_circle : icon,
                color: isGranted ? Colors.green : Colors.orange,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      if (isRequired) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.red.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text(
                            'Required',
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.red,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPermissionHelp() {
    return Card(
      color: Colors.blue.withOpacity(0.1),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.info, color: Colors.blue),
                SizedBox(width: 8),
                Text(
                  'Need Help?',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.blue,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Text(
              'If permissions don\'t grant automatically, we\'ll guide you through the settings.',
            ),
            const SizedBox(height: 12),
            TextButton.icon(
              onPressed: _openSpecificPermissionSettings,
              icon: const Icon(Icons.settings),
              label: const Text('Open Permission Settings'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomButtons() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (_allPermissionsGranted)
          ElevatedButton.icon(
            onPressed: _navigateToMain,
            icon: const Icon(Icons.check_circle),
            label: const Text('Continue to App'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          )
        else ...[
          ElevatedButton.icon(
            onPressed: _isLoading ? null : _requestPermissions,
            icon: _isLoading
                ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
                : const Icon(Icons.security),
            label: Text(_isLoading ? 'Requesting...' : 'Grant Permissions'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: _isLoading ? null : _skipPermissions,
            icon: const Icon(Icons.skip_next),
            label: const Text('Continue Without Permissions'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],

        if (_hasAnyPermissions && !_allPermissionsGranted) ...[
          const SizedBox(height: 8),
          TextButton.icon(
            onPressed: _checkPermissions,
            icon: const Icon(Icons.refresh),
            label: const Text('Recheck Permissions'),
          ),
        ],
      ],
    );
  }
}