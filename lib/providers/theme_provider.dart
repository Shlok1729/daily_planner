import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

// ============================================================================
// THEME PROVIDER (COMPLETE - ALL ORIGINAL FEATURES WITH SHAREDPREFERENCES)
// ============================================================================

/// Global theme provider that manages dark/light mode switching
/// FIXED: Uses SharedPreferences instead of Hive but maintains ALL original functionality
final themeProvider = NotifierProvider<ThemeNotifier, bool>(() {
  return ThemeNotifier();
});

/// Theme notifier that manages theme state persistence
/// COMPLETE: All original features preserved, just replaced Hive with SharedPreferences
class ThemeNotifier extends Notifier<bool> {
  static const String _boxName = 'settings';
  static const String _themeKey = 'isDarkMode';

  SharedPreferences? _prefs;
  bool _isInitialized = false;
  bool _isLoading = true;

  @override
  bool build() {
    // FIXED: Initialize theme loading asynchronously without blocking UI
    _initializeThemeAsync();

    // Return system default while loading to prevent restart
    return _getSystemThemePreference();
  }

  /// FIXED: Initialize theme loading asynchronously to prevent app restart
  Future<void> _initializeThemeAsync() async {
    if (_isInitialized) return;

    try {
      // Use microtask to avoid blocking the UI thread
      await Future.microtask(() async {
        await _loadThemeFromStorage();
        _isInitialized = true;
        _isLoading = false;
      });
    } catch (e) {
      if (kDebugMode) {
        print('⚠️ Theme initialization failed: $e');
      }
      // Fall back to system preference without restart
      _setThemeWithoutRestart(_getSystemThemePreference());
      _isInitialized = true;
      _isLoading = false;
    }
  }

  /// Load theme preference from SharedPreferences (replacing Hive)
  Future<void> _loadThemeFromStorage() async {
    try {
      // FIXED: Better SharedPreferences handling with null safety
      _prefs ??= await SharedPreferences.getInstance();

      if (_prefs != null) {
        final savedTheme = _prefs!.getBool(_themeKey);

        if (savedTheme != null) {
          // Found saved theme preference
          _setThemeWithoutRestart(savedTheme);

          if (kDebugMode) {
            print('✅ Theme loaded from storage: ${savedTheme ? 'Dark' : 'Light'}');
          }
        } else {
          // First time - use system default and save it
          final systemDefault = _getSystemThemePreference();
          await _saveThemeToStorage(systemDefault);

          _setThemeWithoutRestart(systemDefault);

          if (kDebugMode) {
            print('✅ First time theme setup: ${systemDefault ? 'Dark' : 'Light'}');
          }
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('⚠️ Failed to load theme from storage: $e');
      }

      // Fallback to system theme
      final systemDefault = _getSystemThemePreference();
      _setThemeWithoutRestart(systemDefault);
    }
  }

  /// Save theme preference to SharedPreferences (replacing Hive)
  Future<void> _saveThemeToStorage(bool isDarkMode) async {
    try {
      _prefs ??= await SharedPreferences.getInstance();

      if (_prefs != null) {
        await _prefs!.setBool(_themeKey, isDarkMode);

        if (kDebugMode) {
          print('✅ Theme saved to storage: ${isDarkMode ? 'Dark' : 'Light'}');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('⚠️ Failed to save theme to storage: $e');
      }
    }
  }

  /// FIXED: Set theme without causing app restart
  void _setThemeWithoutRestart(bool isDarkMode) {
    if (state != isDarkMode) {
      state = isDarkMode;
    }
  }

  /// Get system theme preference safely
  bool _getSystemThemePreference() {
    try {
      final brightness = SchedulerBinding.instance.platformDispatcher.platformBrightness;
      return brightness == Brightness.dark;
    } catch (e) {
      if (kDebugMode) {
        print('⚠️ Error getting system theme preference: $e');
      }
      return false; // Default to light mode
    }
  }

  /// Toggle theme mode (user action)
  Future<void> toggleTheme() async {
    try {
      final newTheme = !state;
      state = newTheme;
      await _saveThemeToStorage(newTheme);

      if (kDebugMode) {
        print('✅ Theme toggled to: ${newTheme ? 'Dark' : 'Light'}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('⚠️ Error toggling theme: $e');
      }
    }
  }

  /// Set specific theme mode (programmatic)
  Future<void> setTheme(bool isDarkMode) async {
    try {
      if (state != isDarkMode) {
        state = isDarkMode;
        await _saveThemeToStorage(isDarkMode);

        if (kDebugMode) {
          print('✅ Theme set to: ${isDarkMode ? 'Dark' : 'Light'}');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('⚠️ Error setting theme: $e');
      }
    }
  }

  /// Sync with system theme
  Future<void> syncWithSystemTheme() async {
    try {
      final systemTheme = _getSystemThemePreference();
      if (state != systemTheme) {
        state = systemTheme;
        await _saveThemeToStorage(systemTheme);

        if (kDebugMode) {
          print('✅ Theme synced with system: ${systemTheme ? 'Dark' : 'Light'}');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('⚠️ Error syncing with system theme: $e');
      }
    }
  }

  /// Get theme description
  String get themeDescription {
    return state ? 'Dark Mode' : 'Light Mode';
  }

  /// Check if theme is initialized
  bool get isInitialized => _isInitialized;

  /// Check if theme is currently loading
  bool get isLoading => _isLoading;

  /// FIXED: Get theme mode for MaterialApp
  ThemeMode get themeMode {
    if (_isLoading) return ThemeMode.system; // Use system while loading
    return state ? ThemeMode.dark : ThemeMode.light;
  }

  /// Clean up resources when provider is disposed
  void dispose() {
    try {
      // SharedPreferences doesn't need explicit closing like Hive
      _prefs = null;

      if (kDebugMode) {
        print('✅ ThemeNotifier disposed');
      }
    } catch (e) {
      if (kDebugMode) {
        print('⚠️ Error disposing ThemeNotifier: $e');
      }
    }
  }
}

// ============================================================================
// THEME ANIMATION AND TRANSITION PROVIDERS
// ============================================================================

/// Provider for theme transition duration
final themeTransitionProvider = Provider<Duration>((ref) {
  return const Duration(milliseconds: 200); // Faster transition
});

/// Provider for checking if theme is currently transitioning
final themeTransitioningProvider = StateProvider<bool>((ref) {
  return false;
});

/// Provider for theme animation curve
final themeAnimationCurveProvider = Provider<Curve>((ref) {
  return Curves.easeInOut;
});

/// FIXED: Smooth theme transition helper without restart
class ThemeTransitionHelper {
  /// FIXED: Smoothly transition theme with animation (no restart)
  static Future<void> transitionTheme(WidgetRef ref) async {
    final transitioningNotifier = ref.read(themeTransitioningProvider.notifier);
    final duration = ref.read(themeTransitionProvider);
    final themeNotifier = ref.read(themeProvider.notifier);

    try {
      // Mark as transitioning for visual feedback
      transitioningNotifier.state = true;

      // FIXED: Toggle theme without restart
      await themeNotifier.toggleTheme();

      // Wait for transition animation
      await Future.delayed(duration);

    } finally {
      // Mark transition complete
      transitioningNotifier.state = false;
    }
  }

  /// FIXED: Animate theme change with custom duration
  static Future<void> animatedThemeChange(
      WidgetRef ref, {
        Duration? duration,
        bool? isDarkMode,
      }) async {
    final transitioningNotifier = ref.read(themeTransitioningProvider.notifier);
    // FIXED: Handle nullable Duration properly
    final animationDuration = duration ?? ref.read(themeTransitionProvider);
    final themeNotifier = ref.read(themeProvider.notifier);

    try {
      transitioningNotifier.state = true;

      if (isDarkMode != null) {
        await themeNotifier.setTheme(isDarkMode);
      } else {
        await themeNotifier.toggleTheme();
      }

      // FIXED: Duration is already non-nullable from the null check above
      await Future.delayed(animationDuration!);

    } finally {
      transitioningNotifier.state = false;
    }
  }

  /// Get theme transition status
  static bool isTransitioning(WidgetRef ref) {
    return ref.watch(themeTransitioningProvider);
  }

  /// Get theme transition duration
  static Duration getTransitionDuration(WidgetRef ref) {
    return ref.read(themeTransitionProvider);
  }

  /// Get theme animation curve
  static Curve getAnimationCurve(WidgetRef ref) {
    return ref.read(themeAnimationCurveProvider);
  }
}

// ============================================================================
// ADDITIONAL THEME PROVIDERS
// ============================================================================

/// Provider for theme status with all information
final themeStatusProvider = Provider<Map<String, dynamic>>((ref) {
  final isDarkMode = ref.watch(themeProvider);
  final isTransitioning = ref.watch(themeTransitioningProvider);
  final themeNotifier = ref.read(themeProvider.notifier);

  return {
    'isDarkMode': isDarkMode,
    'isLightMode': !isDarkMode,
    'themeDescription': themeNotifier.themeDescription,
    'isInitialized': themeNotifier.isInitialized,
    'isLoading': themeNotifier.isLoading,
    'isTransitioning': isTransitioning,
    'themeMode': themeNotifier.themeMode,
  };
});

/// FIXED: Provider for theme state with better error handling
final safeThemeProvider = Provider<bool>((ref) {
  try {
    return ref.watch(themeProvider);
  } catch (e) {
    if (kDebugMode) {
      print('⚠️ Error reading theme state, falling back to system default: $e');
    }
    // Fallback to system default
    final brightness = SchedulerBinding.instance.platformDispatcher.platformBrightness;
    return brightness == Brightness.dark;
  }
});

/// Provider for theme initialization status
final themeInitializationProvider = Provider<bool>((ref) {
  final themeNotifier = ref.read(themeProvider.notifier);
  return themeNotifier.isInitialized;
});

/// Provider for theme loading status
final themeLoadingProvider = Provider<bool>((ref) {
  final themeNotifier = ref.read(themeProvider.notifier);
  return themeNotifier.isLoading;
});

// ============================================================================
// THEME UTILITIES
// ============================================================================

/// Utility class for theme-related operations
class ThemeUtils {
  /// Get the opposite theme mode
  static bool getOppositeTheme(bool currentTheme) {
    return !currentTheme;
  }

  /// Check if current theme matches system theme
  static bool isSystemTheme(bool currentTheme) {
    try {
      final systemBrightness = SchedulerBinding.instance.platformDispatcher.platformBrightness;
      final systemIsDark = systemBrightness == Brightness.dark;
      return currentTheme == systemIsDark;
    } catch (e) {
      if (kDebugMode) {
        print('⚠️ Error checking system theme: $e');
      }
      return false;
    }
  }

  /// Get current system theme preference
  static bool getSystemThemePreference() {
    try {
      final brightness = SchedulerBinding.instance.platformDispatcher.platformBrightness;
      return brightness == Brightness.dark;
    } catch (e) {
      if (kDebugMode) {
        print('⚠️ Error getting system theme preference: $e');
      }
      return false; // Default to light mode
    }
  }

  /// Get theme icon based on current mode
  static IconData getThemeIcon(bool isDarkMode) {
    return isDarkMode ? Icons.dark_mode : Icons.light_mode;
  }

  /// Get theme switch icon (opposite of current)
  static IconData getThemeSwitchIcon(bool isDarkMode) {
    return isDarkMode ? Icons.light_mode : Icons.dark_mode;
  }

  /// Get theme color based on current mode
  static Color getThemeColor(bool isDarkMode) {
    return isDarkMode ? Colors.amber : Colors.indigo;
  }

  /// Get theme description text
  static String getThemeDescription(bool isDarkMode) {
    return isDarkMode ? 'Dark Mode' : 'Light Mode';
  }

  /// Get theme switch description text
  static String getThemeSwitchDescription(bool isDarkMode) {
    return isDarkMode ? 'Switch to Light Mode' : 'Switch to Dark Mode';
  }

  /// Convert string to theme preference
  static bool? stringToThemePreference(String? value) {
    if (value == null) return null;

    switch (value.toLowerCase()) {
      case 'dark':
      case 'true':
      case '1':
        return true;
      case 'light':
      case 'false':
      case '0':
        return false;
      default:
        return null;
    }
  }

  /// Convert theme preference to string
  static String themePreferenceToString(bool isDarkMode) {
    return isDarkMode ? 'dark' : 'light';
  }
}

// ============================================================================
// THEME LISTENER MIXIN (FIXED)
// ============================================================================

/// FIXED: Mixin for widgets that need to respond to theme changes
mixin ThemeListenerMixin<T extends ConsumerStatefulWidget> on ConsumerState<T> {

  /// Override this method to handle theme changes
  void onThemeChanged(bool isDarkMode) {}

  /// Override this method to handle theme transitions
  void onThemeTransition(bool isTransitioning) {}

  /// Override this method to handle theme initialization
  void onThemeInitialized(bool isInitialized) {}

  /// Override this method to handle theme loading state
  void onThemeLoadingChanged(bool isLoading) {}

  @override
  void initState() {
    super.initState();

    // FIXED: Listen to theme changes with proper error handling
    ref.listenManual(themeProvider, (previous, next) {
      try {
        if (previous != next) {
          onThemeChanged(next);
        }
      } catch (e) {
        if (kDebugMode) {
          print('⚠️ Error in theme change listener: $e');
        }
      }
    });

    // FIXED: Listen to theme transitions with error handling
    ref.listenManual(themeTransitioningProvider, (previous, next) {
      try {
        if (previous != next) {
          onThemeTransition(next);
        }
      } catch (e) {
        if (kDebugMode) {
          print('⚠️ Error in theme transition listener: $e');
        }
      }
    });

    // Listen to theme initialization
    ref.listenManual(themeInitializationProvider, (previous, next) {
      try {
        if (previous != next) {
          onThemeInitialized(next);
        }
      } catch (e) {
        if (kDebugMode) {
          print('⚠️ Error in theme initialization listener: $e');
        }
      }
    });

    // Listen to theme loading state
    ref.listenManual(themeLoadingProvider, (previous, next) {
      try {
        if (previous != next) {
          onThemeLoadingChanged(next);
        }
      } catch (e) {
        if (kDebugMode) {
          print('⚠️ Error in theme loading listener: $e');
        }
      }
    });
  }
}

// ============================================================================
// THEME BUILDER WIDGET
// ============================================================================

/// FIXED: Widget builder that rebuilds when theme changes
class ThemeBuilder extends ConsumerWidget {
  final Widget Function(BuildContext context, bool isDarkMode) builder;
  final Widget? loadingWidget;
  final Widget Function(BuildContext context, String error)? errorBuilder;

  const ThemeBuilder({
    Key? key,
    required this.builder,
    this.loadingWidget,
    this.errorBuilder,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    try {
      final themeStatus = ref.watch(themeStatusProvider);
      final isLoading = themeStatus['isLoading'] as bool;
      final isDarkMode = themeStatus['isDarkMode'] as bool;

      if (isLoading && loadingWidget != null) {
        return loadingWidget!;
      }

      return builder(context, isDarkMode);
    } catch (e) {
      if (kDebugMode) {
        print('⚠️ Error in ThemeBuilder: $e');
      }

      if (errorBuilder != null) {
        return errorBuilder!(context, e.toString());
      }

      // Fallback to system theme
      final systemTheme = ThemeUtils.getSystemThemePreference();
      return builder(context, systemTheme);
    }
  }
}

// ============================================================================
// THEME EXTENSIONS
// ============================================================================

/// Extension on BuildContext for easy theme access
extension ThemeContextExtension on BuildContext {
  /// Get current theme mode safely
  bool get isDarkMode {
    try {
      final container = ProviderScope.containerOf(this);
      return container.read(safeThemeProvider);
    } catch (e) {
      // Fallback to system theme
      return ThemeUtils.getSystemThemePreference();
    }
  }

  /// Get theme description
  String get themeDescription {
    return isDarkMode ? 'Dark Mode' : 'Light Mode';
  }

  /// Get theme icon
  IconData get themeIcon {
    return ThemeUtils.getThemeIcon(isDarkMode);
  }

  /// Get theme color
  Color get themeColor {
    return ThemeUtils.getThemeColor(isDarkMode);
  }

  /// Check if system theme matches current theme
  bool get isSystemTheme {
    return ThemeUtils.isSystemTheme(isDarkMode);
  }
}

// ============================================================================
// THEME CONSTANTS
// ============================================================================

/// Constants for theme-related values
class ThemeConstants {
  static const Duration defaultTransitionDuration = Duration(milliseconds: 200);
  static const Duration fastTransitionDuration = Duration(milliseconds: 100);
  static const Duration slowTransitionDuration = Duration(milliseconds: 400);

  static const Curve defaultCurve = Curves.easeInOut;
  static const Curve fastCurve = Curves.easeOut;
  static const Curve slowCurve = Curves.easeInOutCubic;

  static const String darkModeKey = 'isDarkMode';
  static const String settingsBoxName = 'settings';

  // Default colors
  static const Color defaultDarkBackground = Color(0xFF121212);
  static const Color defaultLightBackground = Color(0xFFFFFFFF);
  static const Color defaultDarkSurface = Color(0xFF1E1E1E);
  static const Color defaultLightSurface = Color(0xFFFAFAFA);
}

// ============================================================================
// THEME INITIALIZATION HELPER
// ============================================================================

/// Helper function to initialize theme system (call in main.dart)
Future<void> initializeThemeSystem() async {
  try {
    // Pre-warm SharedPreferences for faster subsequent access
    await SharedPreferences.getInstance();

    if (kDebugMode) {
      print('✅ Theme system initialized successfully');
    }
  } catch (e) {
    if (kDebugMode) {
      print('⚠️ Theme system initialization warning: $e');
    }
    // Don't throw - this is optimization, not critical
  }
}

// ============================================================================
// THEME ANIMATION WIDGETS
// ============================================================================

/// Animated theme switch button
class AnimatedThemeSwitch extends ConsumerWidget {
  final double size;
  final Duration animationDuration;
  final VoidCallback? onPressed;

  const AnimatedThemeSwitch({
    Key? key,
    this.size = 24.0,
    this.animationDuration = const Duration(milliseconds: 300),
    this.onPressed,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDarkMode = ref.watch(themeProvider);
    final isTransitioning = ref.watch(themeTransitioningProvider);

    return AnimatedSwitcher(
      duration: animationDuration,
      child: IconButton(
        key: ValueKey(isDarkMode),
        onPressed: isTransitioning ? null : (onPressed ?? () {
          ThemeTransitionHelper.transitionTheme(ref);
        }),
        icon: Icon(
          ThemeUtils.getThemeSwitchIcon(isDarkMode),
          size: size,
        ),
        tooltip: ThemeUtils.getThemeSwitchDescription(isDarkMode),
      ),
    );
  }
}

/// Theme-aware animated container
class ThemeAnimatedContainer extends ConsumerWidget {
  final Widget child;
  final Duration duration;
  final Curve curve;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final BoxDecoration? lightDecoration;
  final BoxDecoration? darkDecoration;

  const ThemeAnimatedContainer({
    Key? key,
    required this.child,
    this.duration = const Duration(milliseconds: 200),
    this.curve = Curves.easeInOut,
    this.padding,
    this.margin,
    this.lightDecoration,
    this.darkDecoration,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDarkMode = ref.watch(themeProvider);

    return AnimatedContainer(
      duration: duration,
      curve: curve,
      padding: padding,
      margin: margin,
      decoration: isDarkMode ? darkDecoration : lightDecoration,
      child: child,
    );
  }
}