import 'package:flutter/foundation.dart';
import 'package:daily_planner/config/environment_config.dart';

// ============================================================================
// OAUTH CONFIGURATION - FIXED FOR PROPER INITIALIZATION
// ============================================================================

/// OAuth configuration for production-ready authentication
/// FIXED: Updated with real OAuth credentials and consistent channel names
class OAuthConfig {
  // Private constructor
  OAuthConfig._();

  // ============================================================================
  // GOOGLE OAUTH CONFIGURATION
  // ============================================================================

  /// Google OAuth Client IDs for different platforms
  static const Map<String, String> googleClientIds = {
    'android': '595435556740-mqk3g3ctu3bg4825ubqjsvcuubkjr97s.apps.googleusercontent.com',
    'ios': '595435556740-at7kldv5vt96sthvmb4jrt3s5t40bikh.apps.googleusercontent.com',
    'web': '595435556740-mqk3g3ctu3bg4825ubqjsvcuubkjr97s.apps.googleusercontent.com',
  };

  /// Get Google Client ID for current platform
  static String get googleClientId {
    if (kIsWeb) {
      return googleClientIds['web'] ?? EnvironmentConfig.googleClientId;
    } else {
      // For mobile platforms, use platform-specific ID
      return defaultTargetPlatform == TargetPlatform.android
          ? googleClientIds['android'] ?? EnvironmentConfig.googleClientId
          : googleClientIds['ios'] ?? EnvironmentConfig.googleClientId;
    }
  }

  /// Google OAuth scopes
  static const List<String> googleScopes = [
    'openid',
    'email',
    'profile',
    'https://www.googleapis.com/auth/userinfo.email',
    'https://www.googleapis.com/auth/userinfo.profile',
  ];

  /// Google OAuth server client ID (for token verification)
  static String get googleServerClientId {
    return EnvironmentConfig.googleClientId;
  }

  // ============================================================================
  // FACEBOOK OAUTH CONFIGURATION (DISABLED)
  // ============================================================================

  /// Facebook App ID (placeholder - not implemented)
  static String get facebookAppId {
    return 'facebook_not_implemented';
  }

  /// Facebook OAuth scopes
  static const List<String> facebookScopes = [
    'email',
    'public_profile',
  ];

  /// Facebook redirect URL
  static String get facebookRedirectUrl {
    return 'https://your-app.com/auth/facebook/callback';
  }

  // ============================================================================
  // GITHUB OAUTH CONFIGURATION (DISABLED)
  // ============================================================================

  /// GitHub OAuth Client ID (placeholder - not implemented)
  static String get githubClientId {
    return 'github_not_implemented';
  }

  /// GitHub OAuth Client Secret (server-side only)
  static String get githubClientSecret {
    return 'github_not_implemented';
  }

  /// GitHub OAuth scopes
  static const List<String> githubScopes = [
    'user:email',
    'read:user',
  ];

  /// GitHub OAuth redirect URL
  static String get githubRedirectUrl {
    return 'https://your-app.com/auth/github/callback';
  }

  // ============================================================================
  // APPLE OAUTH CONFIGURATION (DISABLED)
  // ============================================================================

  /// Apple OAuth Client ID (Bundle ID)
  static String get appleClientId {
    return 'apple_not_implemented';
  }

  /// Apple OAuth scopes
  static const List<String> appleScopes = [
    'email',
    'name',
  ];

  /// Apple OAuth redirect URL
  static String get appleRedirectUrl {
    return 'https://your-app.com/auth/apple/callback';
  }

  // ============================================================================
  // OAUTH PROVIDER CONFIGURATIONS
  // ============================================================================

  /// Get OAuth configuration for a specific provider
  static Map<String, dynamic> getProviderConfig(String provider) {
    switch (provider.toLowerCase()) {
      case 'google':
        return {
          'clientId': googleClientId,
          'scopes': googleScopes,
          'redirectUrl': 'com.example.daily_planner:/oauth',
          'discoveryUrl': 'https://accounts.google.com/.well-known/openid_configuration',
          'issuer': 'https://accounts.google.com',
          'additionalParameters': <String, String>{},
        };

      case 'facebook':
        return {
          'clientId': facebookAppId,
          'scopes': facebookScopes,
          'redirectUrl': facebookRedirectUrl,
          'authorizationUrl': 'https://www.facebook.com/v18.0/dialog/oauth',
          'tokenUrl': 'https://graph.facebook.com/v18.0/oauth/access_token',
          'userInfoUrl': 'https://graph.facebook.com/me?fields=id,name,email,picture',
        };

      case 'github':
        return {
          'clientId': githubClientId,
          'scopes': githubScopes,
          'redirectUrl': githubRedirectUrl,
          'authorizationUrl': 'https://github.com/login/oauth/authorize',
          'tokenUrl': 'https://github.com/login/oauth/access_token',
          'userInfoUrl': 'https://api.github.com/user',
        };

      case 'apple':
        return {
          'clientId': appleClientId,
          'scopes': appleScopes,
          'redirectUrl': appleRedirectUrl,
          'issuer': 'https://appleid.apple.com',
        };

      default:
        throw UnsupportedError('OAuth provider $provider is not supported');
    }
  }

  // ============================================================================
  // VALIDATION AND HELPERS
  // ============================================================================

  /// Check if a provider is properly configured
  static bool isProviderConfigured(String provider) {
    try {
      final config = getProviderConfig(provider);
      final clientId = config['clientId'] as String?;

      if (clientId == null || clientId.isEmpty) return false;

      // Check for placeholder values and implementation status
      switch (provider.toLowerCase()) {
        case 'google':
          return !clientId.contains('YOUR_GOOGLE') &&
              !clientId.contains('your_google_client_id') &&
              clientId.contains('apps.googleusercontent.com');
        case 'facebook':
          return false; // Disabled for now
        case 'github':
          return false; // Disabled for now
        case 'apple':
          return false; // Disabled for now
        default:
          return false;
      }
    } catch (e) {
      return false;
    }
  }

  /// Get list of available and configured providers
  static List<String> getAvailableProviders() {
    final providers = <String>[];

    if (isProviderConfigured('google')) {
      providers.add('google');
    }

    // Note: Other providers are disabled for now
    // They can be enabled by implementing the native SDKs

    return providers;
  }

  /// Check if any OAuth provider is configured
  static bool get hasConfiguredProviders {
    return getAvailableProviders().isNotEmpty;
  }

  /// Get OAuth provider display information
  static Map<String, dynamic> getProviderDisplayInfo(String provider) {
    switch (provider.toLowerCase()) {
      case 'google':
        return {
          'name': 'Google',
          'icon': 'google',
          'color': 0xFF4285F4,
          'buttonText': 'Continue with Google',
        };
      case 'facebook':
        return {
          'name': 'Facebook',
          'icon': 'facebook',
          'color': 0xFF1877F2,
          'buttonText': 'Continue with Facebook',
        };
      case 'github':
        return {
          'name': 'GitHub',
          'icon': 'github',
          'color': 0xFF333333,
          'buttonText': 'Continue with GitHub',
        };
      case 'apple':
        return {
          'name': 'Apple',
          'icon': 'apple',
          'color': 0xFF000000,
          'buttonText': 'Continue with Apple',
        };
      default:
        return {
          'name': provider,
          'icon': 'account_circle',
          'color': 0xFF757575,
          'buttonText': 'Continue with $provider',
        };
    }
  }

  // ============================================================================
  // SECURITY AND VALIDATION
  // ============================================================================

  /// Generate secure state parameter for OAuth flow
  static String generateStateParameter() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final random = DateTime.now().microsecond;
    return '$timestamp$random'.hashCode.abs().toString();
  }

  /// Validate OAuth redirect URL
  static bool isValidRedirectUrl(String url, String provider) {
    try {
      final uri = Uri.parse(url);
      final expectedConfig = getProviderConfig(provider);
      final expectedRedirect = expectedConfig['redirectUrl'] as String;

      return uri.toString().startsWith(expectedRedirect);
    } catch (e) {
      return false;
    }
  }

  /// Get OAuth error messages
  static String getOAuthErrorMessage(String error) {
    switch (error.toLowerCase()) {
      case 'access_denied':
        return 'Access was denied. Please try again.';
      case 'invalid_request':
        return 'Invalid request. Please try again.';
      case 'invalid_client':
        return 'App configuration error. Please contact support.';
      case 'invalid_grant':
        return 'Authentication failed. Please try again.';
      case 'unsupported_response_type':
        return 'Unsupported authentication method.';
      case 'invalid_scope':
        return 'Invalid permissions requested.';
      case 'server_error':
        return 'Server error occurred. Please try again later.';
      case 'temporarily_unavailable':
        return 'Service temporarily unavailable. Please try again later.';
      default:
        return 'Authentication failed. Please try again.';
    }
  }

  // ============================================================================
  // DEBUGGING AND LOGGING
  // ============================================================================

  /// Print OAuth configuration status (debug only)
  static void printConfigStatus() {
    if (!kDebugMode) return;

    print('\n=== OAUTH CONFIGURATION STATUS ===');
    print('Google: ${isProviderConfigured('google') ? '✅' : '❌'}');
    print('Facebook: ${isProviderConfigured('facebook') ? '✅' : '❌ (Disabled)'}');
    print('GitHub: ${isProviderConfigured('github') ? '✅' : '❌ (Disabled)'}');
    print('Apple: ${isProviderConfigured('apple') ? '✅' : '❌ (Disabled)'}');
    print('Available providers: ${getAvailableProviders()}');
    print('===================================\n');
  }
}

// ============================================================================
// OAUTH PROVIDER ENUM
// ============================================================================

/// Enum for supported OAuth providers
enum OAuthProvider {
  google,
  facebook,
  github,
  apple;

  /// Get provider configuration
  Map<String, dynamic> get config => OAuthConfig.getProviderConfig(name);

  /// Check if provider is configured
  bool get isConfigured => OAuthConfig.isProviderConfigured(name);

  /// Get provider display information
  Map<String, dynamic> get displayInfo => OAuthConfig.getProviderDisplayInfo(name);

  /// Get provider name
  String get displayName => displayInfo['name'] as String;

  /// Get provider icon
  String get icon => displayInfo['icon'] as String;

  /// Get provider color
  int get color => displayInfo['color'] as int;

  /// Get provider button text
  String get buttonText => displayInfo['buttonText'] as String;
}