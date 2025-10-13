import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart'; // ADD THIS IMPORT

/// Configuration for environment-specific settings
/// Provides centralized access to API keys, URLs, and other environment variables
class EnvironmentConfig {
  // Private constructor to prevent instantiation
  EnvironmentConfig._();

  // ============================================================================
  // INITIALIZATION FLAGS
  // ============================================================================

  static bool _isInitialized = false;
  static String? _initializationError;

  // ============================================================================
  // ENVIRONMENT CONFIGURATION
  // ============================================================================

  /// Current environment (debug, release, profile)
  static String get environment {
    if (kDebugMode) return 'debug';
    if (kProfileMode) return 'profile';
    return 'release';
  }

  /// Whether the app is running in development mode
  static bool get isDevelopment => kDebugMode;

  /// Whether the app is running in production mode
  static bool get isProduction => kReleaseMode;

  // ============================================================================
  // API CONFIGURATION (UPDATED TO USE DOTENV)
  // ============================================================================

  /// Groq API configuration - FIXED: Use dotenv first, then fallback
  static String get groqApiKey {
    return dotenv.env['GROQ_API_KEY'] ??
        const String.fromEnvironment('GROQ_API_KEY', defaultValue: 'your_groq_api_key_here');
  }

  static String get groqBaseUrl {
    return dotenv.env['GROQ_BASE_URL'] ??
        const String.fromEnvironment('GROQ_BASE_URL', defaultValue: 'https://api.groq.com/openai/v1');
  }

  static String get groqModel {
    return dotenv.env['GROQ_MODEL'] ??
        const String.fromEnvironment('GROQ_MODEL', defaultValue: 'llama3-70b-8192');
  }

  /// Supabase configuration - FIXED: Use dotenv first, then fallback
  static String get supabaseUrl {
    return dotenv.env['SUPABASE_URL'] ??
        const String.fromEnvironment('SUPABASE_URL', defaultValue: 'your_supabase_url_here');
  }

  static String get supabaseAnonKey {
    return dotenv.env['SUPABASE_ANON_KEY'] ??
        const String.fromEnvironment('SUPABASE_ANON_KEY', defaultValue: 'your_supabase_anon_key_here');
  }

  // ============================================================================
  // OAUTH CONFIGURATION (UPDATED TO USE DOTENV)
  // ============================================================================

  /// Google OAuth Client ID
  static String get googleClientId {
    return dotenv.env['GOOGLE_CLIENT_ID'] ??
        const String.fromEnvironment('GOOGLE_CLIENT_ID', defaultValue: 'your_google_client_id.googleusercontent.com');
  }

  /// Apple OAuth Client ID
  static String get appleClientId {
    return dotenv.env['APPLE_CLIENT_ID'] ??
        const String.fromEnvironment('APPLE_CLIENT_ID', defaultValue: 'com.example.daily_planner');
  }

  /// Facebook OAuth App ID
  static String get facebookAppId {
    return dotenv.env['FACEBOOK_CLIENT_ID'] ?? // Note: using FACEBOOK_CLIENT_ID from .env
        const String.fromEnvironment('FACEBOOK_APP_ID', defaultValue: 'your_facebook_app_id');
  }

  /// GitHub OAuth Client ID
  static String get githubClientId {
    return dotenv.env['GITHUB_CLIENT_ID'] ??
        const String.fromEnvironment('GITHUB_CLIENT_ID', defaultValue: 'your_github_client_id');
  }

  // ============================================================================
  // APP CONFIGURATION (UPDATED TO USE DOTENV)
  // ============================================================================

  /// Application name
  static String get appName {
    return dotenv.env['APP_NAME'] ??
        const String.fromEnvironment('APP_NAME', defaultValue: 'Daily Planner');
  }

  /// Application version
  static String get appVersion {
    return dotenv.env['APP_VERSION'] ??
        const String.fromEnvironment('APP_VERSION', defaultValue: '1.0.0');
  }

  /// Application package name
  static String get packageName {
    return dotenv.env['PACKAGE_NAME'] ??
        const String.fromEnvironment('PACKAGE_NAME', defaultValue: 'com.example.daily_planner');
  }

  // ============================================================================
  // FEATURE FLAGS (UPDATED TO USE DOTENV)
  // ============================================================================

  /// Whether to enable app blocking functionality
  static bool get enableAppBlocking {
    final envValue = dotenv.env['ENABLE_APP_BLOCKING'];
    if (envValue != null) {
      return envValue.toLowerCase() == 'true';
    }
    return const bool.fromEnvironment('ENABLE_APP_BLOCKING', defaultValue: true);
  }

  /// Whether to enable crash reporting
  static bool get enableCrashReporting {
    final envValue = dotenv.env['ENABLE_CRASH_REPORTING'];
    if (envValue != null) {
      return envValue.toLowerCase() == 'true';
    }
    return const bool.fromEnvironment('ENABLE_CRASH_REPORTING', defaultValue: !kDebugMode);
  }

  /// Whether to enable analytics
  static bool get enableAnalytics {
    final envValue = dotenv.env['ENABLE_ANALYTICS'];
    if (envValue != null) {
      return envValue.toLowerCase() == 'true';
    }
    return const bool.fromEnvironment('ENABLE_ANALYTICS', defaultValue: !kDebugMode);
  }

  /// Whether to enable debug logging
  static bool get enableLogging {
    final envValue = dotenv.env['ENABLE_LOGGING'];
    if (envValue != null) {
      return envValue.toLowerCase() == 'true';
    }
    return const bool.fromEnvironment('ENABLE_LOGGING', defaultValue: kDebugMode);
  }

  /// Whether to enable beta features
  static bool get enableBetaFeatures {
    final envValue = dotenv.env['ENABLE_BETA_FEATURES'];
    if (envValue != null) {
      return envValue.toLowerCase() == 'true';
    }
    return const bool.fromEnvironment('ENABLE_BETA_FEATURES', defaultValue: kDebugMode);
  }

  // ============================================================================
  // TIMEOUT CONFIGURATION (UPDATED TO USE DOTENV)
  // ============================================================================

  /// Default timeout for API requests (in seconds)
  static int get defaultTimeoutSeconds {
    final envValue = dotenv.env['DEFAULT_TIMEOUT_SECONDS'];
    if (envValue != null) {
      return int.tryParse(envValue) ?? 30;
    }
    return const int.fromEnvironment('DEFAULT_TIMEOUT_SECONDS', defaultValue: 30);
  }

  /// Timeout for image uploads (in seconds)
  static int get imageUploadTimeoutSeconds {
    final envValue = dotenv.env['IMAGE_UPLOAD_TIMEOUT_SECONDS'];
    if (envValue != null) {
      return int.tryParse(envValue) ?? 60;
    }
    return const int.fromEnvironment('IMAGE_UPLOAD_TIMEOUT_SECONDS', defaultValue: 60);
  }

  /// Timeout for file downloads (in seconds)
  static int get fileDownloadTimeoutSeconds {
    final envValue = dotenv.env['FILE_DOWNLOAD_TIMEOUT_SECONDS'];
    if (envValue != null) {
      return int.tryParse(envValue) ?? 120;
    }
    return const int.fromEnvironment('FILE_DOWNLOAD_TIMEOUT_SECONDS', defaultValue: 120);
  }

  // ============================================================================
  // CACHE CONFIGURATION (UPDATED TO USE DOTENV)
  // ============================================================================

  /// Cache size limit in MB
  static int get cacheSizeLimitMB {
    final envValue = dotenv.env['CACHE_SIZE_LIMIT_MB'];
    if (envValue != null) {
      return int.tryParse(envValue) ?? 100;
    }
    return const int.fromEnvironment('CACHE_SIZE_LIMIT_MB', defaultValue: 100);
  }

  /// Cache expiry time in hours
  static int get cacheExpiryHours {
    final envValue = dotenv.env['CACHE_EXPIRY_HOURS'];
    if (envValue != null) {
      return int.tryParse(envValue) ?? 24;
    }
    return const int.fromEnvironment('CACHE_EXPIRY_HOURS', defaultValue: 24);
  }

  // ============================================================================
  // VALIDATION HELPERS
  // ============================================================================

  /// Check if Groq API is properly configured
  static bool get isGroqConfigured {
    return groqApiKey != 'your_groq_api_key_here' &&
        groqApiKey.isNotEmpty &&
        groqBaseUrl.isNotEmpty;
  }

  /// Check if Supabase is properly configured
  static bool get isSupabaseConfigured {
    return supabaseUrl != 'your_supabase_url_here' &&
        supabaseUrl.isNotEmpty &&
        supabaseAnonKey != 'your_supabase_anon_key_here' &&
        supabaseAnonKey.isNotEmpty;
  }

  /// Check if Google OAuth is configured
  static bool get isGoogleOAuthConfigured {
    return googleClientId != 'your_google_client_id.googleusercontent.com' &&
        googleClientId.isNotEmpty;
  }

  /// Check if Apple OAuth is configured
  static bool get isAppleOAuthConfigured {
    return appleClientId != 'com.example.daily_planner' &&
        appleClientId.isNotEmpty;
  }

  /// Check if Facebook OAuth is configured
  static bool get isFacebookOAuthConfigured {
    return facebookAppId != 'your_facebook_app_id' &&
        facebookAppId.isNotEmpty;
  }

  /// Check if GitHub OAuth is configured
  static bool get isGitHubOAuthConfigured {
    return githubClientId != 'your_github_client_id' &&
        githubClientId.isNotEmpty;
  }

  // ============================================================================
  // INITIALIZATION METHODS
  // ============================================================================

  /// Initialize environment configuration
  /// This method validates all required environment variables and configurations
  static Future<void> initialize() async {
    if (_isInitialized) {
      if (kDebugMode) {
        print('EnvironmentConfig: Already initialized');
      }
      return;
    }

    try {
      if (kDebugMode) {
        print('EnvironmentConfig: Starting initialization...');
      }

      // Validate critical environment variables
      await _validateConfiguration();

      // Initialize logging if enabled
      if (enableLogging && kDebugMode) {
        _initializeLogging();
      }

      _isInitialized = true;
      _initializationError = null;

      if (kDebugMode) {
        print('EnvironmentConfig: Initialization completed successfully');
        _logConfiguration();
      }
    } catch (e) {
      _initializationError = e.toString();
      if (kDebugMode) {
        print('EnvironmentConfig: Initialization failed: $e');
      }
      rethrow;
    }
  }

  /// Print configuration summary to console (DEBUG ONLY)
  static void printConfigSummary() {
    if (!kDebugMode) return;

    print('\n=== ENVIRONMENT CONFIGURATION SUMMARY ===');
    print('Environment: $environment');
    print('App Name: $appName');
    print('App Version: $appVersion');
    print('Package Name: $packageName');
    print('');
    print('=== API CONFIGURATION ===');
    print('Groq API Configured: $isGroqConfigured');
    if (isGroqConfigured) {
      print('Groq API Key: ${groqApiKey.substring(0, 10)}...');
    }
    print('Groq Base URL: $groqBaseUrl');
    print('Groq Model: $groqModel');
    print('Supabase Configured: $isSupabaseConfigured');
    if (isSupabaseConfigured) {
      print('Supabase URL: ${supabaseUrl.substring(0, supabaseUrl.length.clamp(0, 20))}...');
    }
    print('');
    print('=== OAUTH CONFIGURATION ===');
    print('Google OAuth: $isGoogleOAuthConfigured');
    print('Apple OAuth: $isAppleOAuthConfigured');
    print('Facebook OAuth: $isFacebookOAuthConfigured');
    print('GitHub OAuth: $isGitHubOAuthConfigured');
    print('');
    print('=== FEATURE FLAGS ===');
    print('App Blocking: $enableAppBlocking');
    print('Crash Reporting: $enableCrashReporting');
    print('Analytics: $enableAnalytics');
    print('Logging: $enableLogging');
    print('Beta Features: $enableBetaFeatures');
    print('');
    print('=== TIMEOUTS ===');
    print('Default API Timeout: ${defaultTimeoutSeconds}s');
    print('Image Upload Timeout: ${imageUploadTimeoutSeconds}s');
    print('File Download Timeout: ${fileDownloadTimeoutSeconds}s');
    print('');
    print('=== CACHE SETTINGS ===');
    print('Cache Size Limit: ${cacheSizeLimitMB}MB');
    print('Cache Expiry: ${cacheExpiryHours}h');
    print('==========================================\n');
  }

  /// Validate that all required configuration is present
  static Future<void> _validateConfiguration() async {
    final errors = <String>[];

    // Check for missing critical environment variables in production
    if (isProduction) {
      if (groqApiKey == 'your_groq_api_key_here') {
        errors.add('GROQ_API_KEY is not configured');
      }
      if (supabaseUrl == 'your_supabase_url_here') {
        errors.add('SUPABASE_URL is not configured');
      }
      if (supabaseAnonKey == 'your_supabase_anon_key_here') {
        errors.add('SUPABASE_ANON_KEY is not configured');
      }
    }

    // Validate URL formats
    if (!_isValidUrl(groqBaseUrl)) {
      errors.add('GROQ_BASE_URL is not a valid URL');
    }

    if (supabaseUrl != 'your_supabase_url_here' && !_isValidUrl(supabaseUrl)) {
      errors.add('SUPABASE_URL is not a valid URL');
    }

    if (errors.isNotEmpty) {
      throw ConfigurationException(
        'Environment configuration validation failed:\n${errors.join('\n')}',
      );
    }
  }

  /// Initialize logging configuration
  static void _initializeLogging() {
    if (kDebugMode) {
      print('EnvironmentConfig: Logging enabled for $environment environment');
    }
  }

  /// Log current configuration (debug mode only)
  static void _logConfiguration() {
    if (!kDebugMode) return;

    print('EnvironmentConfig: Current configuration:');
    print('  Environment: $environment');
    print('  App Name: $appName');
    print('  App Version: $appVersion');
    print('  Groq Base URL: $groqBaseUrl');
    print('  Groq Model: $groqModel');
    print('  Supabase URL: ${supabaseUrl.substring(0, 20)}...');
    print('  Timeout: ${defaultTimeoutSeconds}s');
    print('  Logging: $enableLogging');
    print('  Crash Reporting: $enableCrashReporting');
  }

  /// Validate URL format
  static bool _isValidUrl(String url) {
    try {
      final uri = Uri.parse(url);
      return uri.hasScheme && (uri.scheme == 'http' || uri.scheme == 'https');
    } catch (e) {
      return false;
    }
  }

  // ============================================================================
  // GETTERS FOR STATUS
  // ============================================================================

  /// Whether the configuration has been initialized
  static bool get isInitialized => _isInitialized;

  /// Get initialization error if any
  static String? get initializationError => _initializationError;

  /// Get a map of all configuration values (for debugging)
  static Map<String, dynamic> get configurationMap => {
    'environment': environment,
    'app_name': appName,
    'app_version': appVersion,
    'package_name': packageName,
    'groq_configured': isGroqConfigured,
    'supabase_configured': isSupabaseConfigured,
    'google_oauth_configured': isGoogleOAuthConfigured,
    'apple_oauth_configured': isAppleOAuthConfigured,
    'facebook_oauth_configured': isFacebookOAuthConfigured,
    'github_oauth_configured': isGitHubOAuthConfigured,
    'enable_app_blocking': enableAppBlocking,
    'enable_crash_reporting': enableCrashReporting,
    'enable_analytics': enableAnalytics,
    'enable_logging': enableLogging,
    'enable_beta_features': enableBetaFeatures,
    'default_timeout_seconds': defaultTimeoutSeconds,
    'cache_size_limit_mb': cacheSizeLimitMB,
    'cache_expiry_hours': cacheExpiryHours,
  };
}

/// Exception thrown when configuration validation fails
class ConfigurationException implements Exception {
  final String message;

  const ConfigurationException(this.message);

  @override
  String toString() => 'ConfigurationException: $message';
}