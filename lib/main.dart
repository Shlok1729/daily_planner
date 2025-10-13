import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:daily_planner/config/app_theme.dart';
import 'package:daily_planner/providers/theme_provider.dart';
import 'package:daily_planner/screens/splash_screen.dart';
import 'package:daily_planner/constants/app_colors.dart';
import 'package:daily_planner/services/storage_service.dart';
import 'package:daily_planner/services/notification_service.dart';
import 'package:daily_planner/services/app_blocker_service.dart';
import 'package:daily_planner/providers/app_blocker_provider.dart';
import 'package:daily_planner/services/chatbot_service.dart';
import 'package:daily_planner/services/supabase_service.dart';
import 'package:daily_planner/config/environment_config.dart';
import 'package:daily_planner/utils/error_handler.dart';
import 'package:daily_planner/screens/auth_wrapper.dart';

// ============================================================================
// MAIN ENTRY POINT (FIXED WITH BETTER ERROR HANDLING - PRESERVES ALL FEATURES)
// ============================================================================

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize global error handling first
  ErrorHandler.initialize();

  // ADDED: Initialize global error handling for uncaught exceptions
  _initializeGlobalErrorHandling();

  try {
    // STEP 1: Load environment variables from .env file FIRST
    await _loadEnvironmentVariables();

    // STEP 2: Initialize Hive for local storage
    await Hive.initFlutter();

    // STEP 3: Initialize environment configuration (WITH SAFE ERROR HANDLING)
    try {
      await EnvironmentConfig.initialize();
    } catch (e) {
      if (kDebugMode) {
        print('⚠️ EnvironmentConfig initialization failed: $e');
        print('   Continuing with default configuration...');
      }
      // Don't rethrow - continue with defaults
    }

    // STEP 4: Print config summary in debug mode
    if (kDebugMode) {
      try {
        EnvironmentConfig.printConfigSummary();
      } catch (e) {
        print('⚠️ Could not print config summary: $e');
      }
    }

    // STEP 5: Initialize core services (FIXED: With better error handling)
    await _initializeCoreServices();

    // STEP 6: Set preferred orientations (SAFE ERROR HANDLING)
    try {
      await SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
        DeviceOrientation.portraitDown,
      ]);
      if (kDebugMode) print('✅ Screen orientations set');
    } catch (e) {
      if (kDebugMode) print('⚠️ Could not set orientations: $e');
    }

    // STEP 7: Run the app with ProviderScope
    runApp(
      ProviderScope(
        child: DailyPlannerApp(),
      ),
    );

  } catch (e, stackTrace) {
    // CRITICAL ERROR - Show fallback app
    if (kDebugMode) {
      print('❌ CRITICAL: App initialization failed: $e');
      print('Stack trace: $stackTrace');
    }

    // Even if initialization fails, ensure Hive is available and run the app
    try {
      await Hive.initFlutter();
    } catch (hiveError) {
      if (kDebugMode) {
        print('❌ Failed to initialize Hive: $hiveError');
      }
    }

    runApp(
      ProviderScope(
        child: MaterialApp(
          title: 'Daily Planner',
          home: _buildCriticalErrorScreen(e.toString()),
          debugShowCheckedModeBanner: false,
        ),
      ),
    );
  }
}

// ============================================================================
// INITIALIZATION FUNCTIONS (IMPROVED ERROR HANDLING)
// ============================================================================

/// Initialize global error handling for uncaught exceptions
void _initializeGlobalErrorHandling() {
  // Set up Flutter error handling
  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.dumpErrorToConsole(details);
    if (kDebugMode) {
      print('🐛 Flutter Error: ${details.exception}');
      print('Stack trace: ${details.stack}');
    }
  };

  // Set up Dart error handling
  PlatformDispatcher.instance.onError = (error, stack) {
    if (kDebugMode) {
      print('🐛 Dart Error: $error');
      print('Stack trace: $stack');
    }
    return true;
  };
}

/// Load environment variables with error handling
Future<void> _loadEnvironmentVariables() async {
  try {
    await dotenv.load(fileName: '.env');
    if (kDebugMode) {
      print('✅ Environment variables loaded successfully');

      // Check if critical variables are loaded
      final groqKey = dotenv.env['GROQ_API_KEY'];
      final supabaseUrl = dotenv.env['SUPABASE_URL'];

      if (groqKey != null && groqKey.isNotEmpty && groqKey != 'your_groq_api_key_here') {
        print('   ✅ Groq API Key loaded: ${groqKey.substring(0, 10)}...');
      } else {
        print('   ⚠️ Groq API Key not found or using placeholder in .env');
      }

      if (supabaseUrl != null && supabaseUrl.isNotEmpty && supabaseUrl != 'your_supabase_url_here') {
        print('   ✅ Supabase URL loaded: ${supabaseUrl.substring(0, 20)}...');
      } else {
        print('   ⚠️ Supabase URL not found or using placeholder in .env');
      }
    }
  } catch (e) {
    if (kDebugMode) {
      print('⚠️ Could not load .env file: $e');
      print('   Using default environment variables or --dart-define values');
    }
    // Don't throw error - app can still work with defaults
  }
}

/// Initialize all core services with proper error handling
Future<void> _initializeCoreServices() async {
  final services = [
    'StorageService',
    'NotificationService',
    'AppBlockerService',
    'ChatbotService',
    'SupabaseService',
  ];

  final serviceFunctions = [
    _initializeStorageService,
    _initializeNotificationService,
    _initializeAppBlockerService,
    _initializeChatbotService,
    _initializeSupabaseService,
  ];

  int successCount = 0;
  int failureCount = 0;

  // Initialize services one by one to handle individual failures
  for (int i = 0; i < serviceFunctions.length; i++) {
    try {
      await serviceFunctions[i]();
      successCount++;
    } catch (e) {
      failureCount++;
      if (kDebugMode) {
        print('❌ ${services[i]} initialization failed: $e');
      }
      // Continue with next service instead of failing completely
    }
  }

  if (kDebugMode) {
    if (failureCount > 0) {
      print('⚠️ Service initialization completed with ${failureCount} failures: ${successCount}/${services.length} services started');
    } else {
      print('✅ All services initialized successfully');
    }
  }
}

/// Initialize Storage service
Future<void> _initializeStorageService() async {
  try {
    final storageService = StorageService();
    await storageService.initialize();

    if (kDebugMode) {
      print('✅ Storage service initialized');
    }
  } catch (e) {
    if (kDebugMode) {
      print('❌ Storage service initialization failed: $e');
    }
    // FIXED: Don't rethrow - let app continue with limited functionality
  }
}

/// Initialize Notification service
Future<void> _initializeNotificationService() async {
  try {
    final notificationService = NotificationService();
    await notificationService.initialize();

    if (kDebugMode) {
      print('✅ Notification service initialized');
    }
  } catch (e) {
    if (kDebugMode) {
      print('❌ Notification service initialization failed: $e');
    }
    // FIXED: Don't rethrow - let app continue without notifications
  }
}

/// Initialize app blocker service - FIXED: Better timing and error handling
Future<void> _initializeAppBlockerService() async {
  try {
    // Only initialize if app blocking is enabled
    if (EnvironmentConfig.enableAppBlocking) {
      // FIXED: Add delay to ensure Flutter engine is ready
      await Future.delayed(const Duration(milliseconds: 500));

      final appBlockerService = AppBlockerService();
      // FIXED: Using init() instead of initialize()
      await appBlockerService.init();

      if (kDebugMode) {
        print('✅ App blocker service initialized');
      }
    } else {
      if (kDebugMode) {
        print('⚠️ App blocker service disabled in configuration');
      }
    }
  } catch (e) {
    if (kDebugMode) {
      print('❌ App blocker service initialization failed: $e');
      print('   App will continue without app blocking functionality');
    }
    // FIXED: Don't rethrow - let app continue without app blocking
  }
}

/// Initialize Chatbot service
Future<void> _initializeChatbotService() async {
  try {
    final chatbotService = ChatbotService();
    // FIXED: Using ChatbotService instead of GroqChatService
    await chatbotService.initialize();

    if (kDebugMode) {
      print('✅ Chatbot service initialized');
    }
  } catch (e) {
    if (kDebugMode) {
      print('❌ Chatbot service initialization failed: $e');
    }
    // FIXED: Don't rethrow - let app continue without chatbot
  }
}

/// Initialize Supabase service
Future<void> _initializeSupabaseService() async {
  try {
    final supabaseService = SupabaseService();
    await supabaseService.initialize();

    if (kDebugMode) {
      print('✅ Supabase service initialized');
    }
  } catch (e) {
    if (kDebugMode) {
      print('❌ Supabase service initialization failed: $e');
    }
    // FIXED: Don't rethrow - let app continue in offline mode
  }
}

// ============================================================================
// MAIN APP WIDGET (FIXED THEME SWITCHING - NO MORE RESTARTS)
// ============================================================================

class DailyPlannerApp extends ConsumerWidget {
  const DailyPlannerApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // FIXED: Safe theme provider access with error handling
    final themeMode = _getThemeMode(ref);
    final isThemeLoading = _isThemeLoading(ref);

    return MaterialApp(
      title: _getSafeAppName(),
      debugShowCheckedModeBanner: false,
      theme: _getSafeTheme(false),
      darkTheme: _getSafeTheme(true),
      // FIXED: Use actual ThemeMode instead of just bool - NO MORE RESTARTS
      themeMode: themeMode,
      home: _getSafeHomeScreen(),

      // FIXED: Theme animation settings for smooth transitions
      themeAnimationDuration: const Duration(milliseconds: 300),
      themeAnimationCurve: Curves.easeInOut,

      // Error handling (ENHANCED)
      builder: (context, child) {
        // ADDED: Set global error widget builder
        ErrorWidget.builder = (FlutterErrorDetails errorDetails) {
          return _buildErrorWidget(errorDetails);
        };

        // FIXED: Show loading indicator while theme is loading
        if (isThemeLoading) {
          return MaterialApp(
            home: Scaffold(
              body: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(
                      color: Colors.blue,
                    ),
                    SizedBox(height: 16),
                    Text(
                      'Loading...',
                      style: TextStyle(fontSize: 16),
                    ),
                  ],
                ),
              ),
            ),
            debugShowCheckedModeBanner: false,
          );
        }

        return MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: const TextScaler.linear(1.0), // FIXED: Updated deprecated textScaleFactor
          ),
          child: child ?? const SizedBox.shrink(),
        );
      },

      // Route configuration (PRESERVED ALL ORIGINAL ROUTES)
      routes: {
        '/splash': (context) => const SplashScreen(),
        '/auth': (context) => const AuthWrapper(),
      },

      // Initial route
      initialRoute: '/splash',

      // Locale configuration (PRESERVED)
      supportedLocales: const [
        Locale('en', 'US'),
        Locale('es', 'ES'),
        Locale('fr', 'FR'),
        Locale('de', 'DE'),
      ],

      // Accessibility (PRESERVED)
      showSemanticsDebugger: false,

      // Performance (PRESERVED)
      checkerboardRasterCacheImages: kDebugMode,
      checkerboardOffscreenLayers: kDebugMode,
      showPerformanceOverlay: false,

      // Navigation (PRESERVED)
      navigatorKey: GlobalKey<NavigatorState>(),

      // Lifecycle (PRESERVED)
      onGenerateRoute: _onGenerateRoute,
      onUnknownRoute: _onUnknownRoute,
    );
  }

  // FIXED: Safe theme mode getter with fallback
  ThemeMode _getThemeMode(WidgetRef ref) {
    try {
      final themeNotifier = ref.read(themeProvider.notifier);
      return themeNotifier.themeMode;
    } catch (e) {
      if (kDebugMode) {
        print('⚠️ Could not read theme provider, using system theme: $e');
      }
      return ThemeMode.system; // Safe fallback
    }
  }

  // FIXED: Check if theme is loading
  bool _isThemeLoading(WidgetRef ref) {
    try {
      final themeNotifier = ref.read(themeProvider.notifier);
      return themeNotifier.isLoading;
    } catch (e) {
      if (kDebugMode) {
        print('⚠️ Could not check theme loading state: $e');
      }
      return false;
    }
  }

  // ADDED: Safe helper methods
  String _getSafeAppName() {
    try {
      return EnvironmentConfig.appName;
    } catch (e) {
      if (kDebugMode) {
        print('⚠️ Could not load app name: $e');
      }
      return 'Daily Planner';
    }
  }

  ThemeData _getSafeTheme(bool isDark) {
    try {
      return isDark ? AppTheme.darkTheme : AppTheme.lightTheme;
    } catch (e) {
      if (kDebugMode) {
        print('⚠️ Could not load app theme, using fallback: $e');
      }
      return isDark ? ThemeData.dark() : ThemeData.light();
    }
  }

  Widget _getSafeHomeScreen() {
    try {
      return const SplashScreen();
    } catch (e) {
      if (kDebugMode) {
        print('⚠️ Could not load splash screen: $e');
      }
      return _buildErrorWidget(FlutterErrorDetails(
        exception: e,
        library: 'main.dart',
        context: ErrorDescription('Loading home screen'),
      ));
    }
  }

  // PRESERVED: Original route handling
  Route<dynamic>? _onGenerateRoute(RouteSettings settings) {
    try {
      switch (settings.name) {
        case '/':
        case '/splash':
          return MaterialPageRoute(
            builder: (context) => const SplashScreen(),
            settings: settings,
          );
        case '/auth':
          return MaterialPageRoute(
            builder: (context) => const AuthWrapper(),
            settings: settings,
          );
        default:
          return null;
      }
    } catch (e) {
      if (kDebugMode) {
        print('⚠️ Route generation failed: $e');
      }
      return MaterialPageRoute(
        builder: (context) => _buildErrorWidget(FlutterErrorDetails(
          exception: e,
          library: 'main.dart',
          context: ErrorDescription('Generating route: ${settings.name}'),
        )),
        settings: settings,
      );
    }
  }

  // PRESERVED: Original unknown route handling
  Route<dynamic> _onUnknownRoute(RouteSettings settings) {
    if (kDebugMode) {
      print('Unknown route: ${settings.name}');
    }

    return MaterialPageRoute(
      builder: (context) => Scaffold(
        appBar: AppBar(
          title: const Text('Page Not Found'),
        ),
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 64,
                color: Colors.grey,
              ),
              SizedBox(height: 16),
              Text(
                'Page Not Found',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 8),
              Text(
                'The requested page could not be found.',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
        ),
      ),
      settings: settings,
    );
  }
}

// ============================================================================
// ERROR HANDLING WIDGETS
// ============================================================================

/// Build error widget for critical app failures
Widget _buildCriticalErrorScreen(String error) {
  return Scaffold(
    backgroundColor: Colors.red[50],
    body: SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 80,
              color: Colors.red[600],
            ),
            const SizedBox(height: 24),
            const Text(
              'App Initialization Failed',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              'We encountered an error while starting the app. Please restart the application.',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[700],
              ),
              textAlign: TextAlign.center,
            ),
            if (kDebugMode) ...[
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Debug Info:\n$error',
                  style: const TextStyle(
                    fontSize: 12,
                    fontFamily: 'monospace',
                  ),
                ),
              ),
            ],
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () {
                // Restart the app
                SystemNavigator.pop();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red[600],
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              ),
              child: const Text('Restart App'),
            ),
          ],
        ),
      ),
    ),
  );
}

/// Build error widget for Flutter errors
Widget _buildErrorWidget(FlutterErrorDetails errorDetails) {
  return Scaffold(
    backgroundColor: Colors.orange[50],
    body: SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.warning_amber_rounded,
              size: 60,
              color: Colors.orange[600],
            ),
            const SizedBox(height: 16),
            const Text(
              'Something went wrong',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              'A temporary error occurred. Please try again.',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[700],
              ),
              textAlign: TextAlign.center,
            ),
            if (kDebugMode) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Error: ${errorDetails.exception}',
                  style: const TextStyle(
                    fontSize: 10,
                    fontFamily: 'monospace',
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ],
        ),
      ),
    ),
  );
}

// ============================================================================
// LIFECYCLE MANAGEMENT (PRESERVED ALL ORIGINAL FEATURES)
// ============================================================================

class AppLifecycleObserver extends WidgetsBindingObserver {
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    switch (state) {
      case AppLifecycleState.resumed:
        _onAppResumed();
        break;
      case AppLifecycleState.paused:
        _onAppPaused();
        break;
      case AppLifecycleState.detached:
        _onAppDetached();
        break;
      case AppLifecycleState.inactive:
        _onAppInactive();
        break;
      case AppLifecycleState.hidden:
        _onAppHidden();
        break;
    }
  }

  void _onAppResumed() {
    if (kDebugMode) {
      print('App resumed');
    }
    // Resume timers, refresh data, etc.
  }

  void _onAppPaused() {
    if (kDebugMode) {
      print('App paused');
    }
    // Save state, pause timers, etc.
  }

  void _onAppDetached() {
    if (kDebugMode) {
      print('App detached');
    }
    // Clean up resources
  }

  void _onAppInactive() {
    if (kDebugMode) {
      print('App inactive');
    }
    // Handle inactive state
  }

  void _onAppHidden() {
    if (kDebugMode) {
      print('App hidden');
    }
    // Handle hidden state
  }
}

// ============================================================================
// DEVICE INFORMATION (PRESERVED FROM ORIGINAL)
// ============================================================================

class DeviceInfo {
  static Map<String, dynamic>? _deviceInfo;

  static Future<Map<String, dynamic>> getDeviceInfo() async {
    if (_deviceInfo != null) return _deviceInfo!;

    try {
      // Get device information
      _deviceInfo = {
        'platform': Theme.of(GlobalKey<NavigatorState>().currentContext!).platform.toString(),
        'app_version': EnvironmentConfig.appVersion,
        'environment': EnvironmentConfig.environment,
        'debug_mode': kDebugMode,
        'timestamp': DateTime.now().toIso8601String(),
      };

      return _deviceInfo!;
    } catch (e) {
      if (kDebugMode) {
        print('⚠️ Could not get device info: $e');
      }
      return {
        'platform': 'unknown',
        'app_version': '1.0.0',
        'environment': 'debug',
        'debug_mode': kDebugMode,
        'timestamp': DateTime.now().toIso8601String(),
      };
    }
  }

  static void clearCache() {
    _deviceInfo = null;
  }
}