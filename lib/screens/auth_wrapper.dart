import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:daily_planner/screens/onboarding_screen.dart';
import 'package:daily_planner/screens/permission_screen.dart';
import 'package:daily_planner/screens/login_screen.dart';
import 'package:daily_planner/screens/main_navigation_screen.dart';
import 'package:daily_planner/providers/app_blocker_provider.dart';
import 'package:daily_planner/config/environment_config.dart';

/// FIXED: AuthWrapper with non-blocking initialization
class AuthWrapper extends ConsumerStatefulWidget {
  const AuthWrapper({Key? key}) : super(key: key);

  @override
  _AuthWrapperState createState() => _AuthWrapperState();
}

class _AuthWrapperState extends ConsumerState<AuthWrapper> {
  bool _isLoading = true;
  Widget? _targetScreen;

  @override
  void initState() {
    super.initState();
    // CRITICAL: Initialize without blocking the UI
    _initializeAppFlow();
  }

  /// CRITICAL: Non-blocking initialization with timeout protection
  Future<void> _initializeAppFlow() async {
    try {
      // Add timeout protection to prevent infinite loading
      await Future.any([
        _determineTargetScreenSafely(),
        Future.delayed(const Duration(seconds: 5), () {
          throw TimeoutException('Initialization timeout');
        }),
      ]);
    } catch (e) {
      debugPrint('⚠️ AuthWrapper initialization error: $e');
      // Force navigation to prevent infinite loading
      _setTargetScreen(const MainNavigationScreen());
    }
  }

  /// CRITICAL: Safe target screen determination with minimal blocking
  Future<void> _determineTargetScreenSafely() async {
    try {
      // STEP 1: Quick check - try to get SharedPreferences instance
      SharedPreferences? prefs;
      try {
        prefs = await SharedPreferences.getInstance()
            .timeout(const Duration(seconds: 2));
      } catch (e) {
        debugPrint('⚠️ SharedPreferences timeout, using defaults');
        // If SharedPreferences fails, assume first launch
        _setTargetScreen(const OnboardingScreen());
        return;
      }

      // STEP 2: Quick preference checks with defaults
      final isFirstLaunch = prefs.getBool('first_launch') ?? true;
      final onboardingCompleted = prefs.getBool('onboarding_completed') ?? false;
      final isLoggedIn = prefs.getBool('user_logged_in') ?? false;

      // STEP 3: Quick decision tree (no heavy operations)
      if (isFirstLaunch || !onboardingCompleted) {
        _setTargetScreen(const OnboardingScreen());
        return;
      }

      if (!isLoggedIn) {
        _setTargetScreen(const LoginScreen());
        return;
      }

      // STEP 4: Skip heavy app blocker initialization for now
      // This can be done later in the background after the main screen loads
      _setTargetScreen(const MainNavigationScreen());

      // STEP 5: Initialize app blocker in background (non-blocking)
      _initializeAppBlockerInBackground();

    } catch (e) {
      debugPrint('⚠️ Error in target screen determination: $e');
      // Safe fallback - go to main screen
      _setTargetScreen(const MainNavigationScreen());
    }
  }

  /// Initialize app blocker in background after main screen loads
  void _initializeAppBlockerInBackground() {
    Future.microtask(() async {
      try {
        // Only do this if environment config allows it
        bool appBlockingEnabled = false;
        try {
          appBlockingEnabled = EnvironmentConfig.enableAppBlocking;
        } catch (e) {
          debugPrint('⚠️ EnvironmentConfig not available: $e');
          return;
        }

        if (appBlockingEnabled) {
          try {
            final appBlockerManager = ref.read(appBlockerManagerProvider);
            await appBlockerManager.initialize();
            debugPrint('✅ App blocker initialized in background');
          } catch (e) {
            debugPrint('⚠️ App blocker background initialization failed: $e');
            // This is non-critical, app can work without it
          }
        }
      } catch (e) {
        debugPrint('⚠️ Background initialization error: $e');
        // Non-critical, don't affect main app flow
      }
    });
  }

  /// Set target screen and update loading state
  void _setTargetScreen(Widget screen) {
    if (mounted) {
      setState(() {
        _targetScreen = screen;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Show minimal loading screen while determining target
    if (_isLoading) {
      return Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(
                  Theme.of(context).colorScheme.primary,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Starting Daily Planner...',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Return the determined target screen
    return _targetScreen ?? const MainNavigationScreen();
  }
}

/// Navigation flow helper methods (SIMPLIFIED)
class NavigationFlow {
  /// Complete onboarding flow
  static Future<void> completeOnboarding(BuildContext context) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('first_launch', false);
      await prefs.setBool('onboarding_completed', true);

      // Navigate to login screen after onboarding
      _navigateToScreen(context, const LoginScreen());
    } catch (e) {
      debugPrint('⚠️ Error completing onboarding: $e');
      // Fallback navigation
      _navigateToScreen(context, const MainNavigationScreen());
    }
  }

  /// Complete permissions setup
  static Future<void> completePermissions(BuildContext context) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final isLoggedIn = prefs.getBool('user_logged_in') ?? false;

      if (!isLoggedIn) {
        _navigateToScreen(context, const LoginScreen());
      } else {
        _navigateToScreen(context, const MainNavigationScreen());
      }
    } catch (e) {
      debugPrint('⚠️ Error completing permissions: $e');
      _navigateToScreen(context, const MainNavigationScreen());
    }
  }

  /// Complete login flow
  static Future<void> completeLogin(BuildContext context) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('user_logged_in', true);

      _navigateToScreen(context, const MainNavigationScreen());
    } catch (e) {
      debugPrint('⚠️ Error completing login: $e');
      _navigateToScreen(context, const MainNavigationScreen());
    }
  }

  /// Reset app to initial state
  static Future<void> resetApp(BuildContext context) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();

      _navigateToScreen(context, const OnboardingScreen());
    } catch (e) {
      debugPrint('⚠️ Error resetting app: $e');
      _navigateToScreen(context, const OnboardingScreen());
    }
  }

  /// Get current app state for debugging
  static Future<Map<String, dynamic>> getAppState() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      return {
        'first_launch': prefs.getBool('first_launch') ?? true,
        'onboarding_completed': prefs.getBool('onboarding_completed') ?? false,
        'user_logged_in': prefs.getBool('user_logged_in') ?? false,
        'timestamp': DateTime.now().toIso8601String(),
      };
    } catch (e) {
      debugPrint('⚠️ Error getting app state: $e');
      return {
        'first_launch': true,
        'onboarding_completed': false,
        'user_logged_in': false,
        'error': e.toString(),
      };
    }
  }

  /// Navigate to screen and clear navigation stack
  static void _navigateToScreen(BuildContext context, Widget screen) {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => screen),
          (route) => false,
    );
  }

  /// Navigate to screen without clearing stack
  static void navigateToScreen(BuildContext context, Widget screen) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => screen),
    );
  }

  /// Check if user has completed full onboarding flow
  static Future<bool> hasCompletedFullOnboarding() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final onboardingCompleted = prefs.getBool('onboarding_completed') ?? false;
      final isLoggedIn = prefs.getBool('user_logged_in') ?? false;
      return onboardingCompleted && isLoggedIn;
    } catch (e) {
      debugPrint('⚠️ Error checking onboarding status: $e');
      return false;
    }
  }
}

/// Timeout exception for initialization
class TimeoutException implements Exception {
  final String message;
  TimeoutException(this.message);

  @override
  String toString() => 'TimeoutException: $message';
}