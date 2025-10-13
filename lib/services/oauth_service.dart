import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import 'package:crypto/crypto.dart';
import 'dart:math';
import 'package:daily_planner/models/user_model.dart';
import 'package:daily_planner/utils/error_handler.dart';

// ============================================================================
// DEEP LINK HANDLER - REPLACEMENT FOR UNI_LINKS
// ============================================================================

/// Custom deep link handler to replace uni_links dependency
/// This maintains the same API as uni_links but uses platform channels
class DeepLinkHandler {
  static const MethodChannel _channel = MethodChannel('com.daily_planner/deep_links');
  static Stream<String?>? _linkStream;

  /// Get stream of incoming deep links (replacement for uni_links linkStream)
  static Stream<String?> get linkStream {
    _linkStream ??= _createLinkStream();
    return _linkStream!;
  }

  /// Create stream for incoming deep links
  static Stream<String?> _createLinkStream() {
    return const EventChannel('com.daily_planner/deep_links_stream')
        .receiveBroadcastStream()
        .map((dynamic link) => link as String?);
  }

  /// Get initial link (if app was opened via deep link)
  static Future<String?> getInitialLink() async {
    try {
      return await _channel.invokeMethod<String>('getInitialLink');
    } catch (e) {
      if (kDebugMode) {
        print('Failed to get initial link: $e');
      }
      return null;
    }
  }
}

// ============================================================================
// OAUTH CONFIGURATION - FIXED: ONLY GOOGLE
// ============================================================================

/// OAuth provider types - FIXED: Only Google supported
enum OAuthProvider { google }

/// OAuth configuration class
class OAuthConfig {
  final String clientId;
  final String? clientSecret;
  final List<String> scopes;
  final String redirectUri;
  final String authorizationEndpoint;
  final String tokenEndpoint;

  const OAuthConfig({
    required this.clientId,
    this.clientSecret,
    required this.scopes,
    required this.redirectUri,
    required this.authorizationEndpoint,
    required this.tokenEndpoint,
  });

  // FIXED: Only Google provider configuration
  static const Map<OAuthProvider, OAuthConfig> _configs = {
    OAuthProvider.google: OAuthConfig(
      clientId: '595435556740-mqk3g3ctu3bg4825ubqjsvcuubkjr97s.apps.googleusercontent.com',
      scopes: ['openid', 'email', 'profile'],
      redirectUri: 'com.googleusercontent.apps.595435556740-at7kldv5vt96sthvmb4jrt3s5t40bikh:/oauth/google',
      authorizationEndpoint: 'https://accounts.google.com/o/oauth2/v2/auth',
      tokenEndpoint: 'https://oauth2.googleapis.com/token',
    ),
  };

  /// Get configuration for a provider
  static OAuthConfig getConfig(OAuthProvider provider) {
    final config = _configs[provider];
    if (config == null) {
      throw ArgumentError('OAuth provider $provider is not configured');
    }
    return config;
  }

  /// Check if provider is configured with real credentials
  static bool isConfigured(OAuthProvider provider) {
    try {
      final config = getConfig(provider);
      return !config.clientId.contains('your-') &&
          config.clientId.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  /// Get available configured providers - FIXED: Only Google
  static List<OAuthProvider> get availableProviders {
    return [OAuthProvider.google]; // Only Google is supported
  }
}

// ============================================================================
// OAUTH RESULT CLASSES
// ============================================================================

/// OAuth authentication result
class OAuthResult {
  final bool success;
  final User? user;
  final String? error;
  final String? accessToken;
  final String? refreshToken;
  final DateTime? expiresAt;

  const OAuthResult({
    required this.success,
    this.user,
    this.error,
    this.accessToken,
    this.refreshToken,
    this.expiresAt,
  });

  factory OAuthResult.success(
      User user, {
        String? accessToken,
        String? refreshToken,
        DateTime? expiresAt,
      }) {
    return OAuthResult(
      success: true,
      user: user,
      accessToken: accessToken,
      refreshToken: refreshToken,
      expiresAt: expiresAt,
    );
  }

  factory OAuthResult.failure(String error) {
    return OAuthResult(
      success: false,
      error: error,
    );
  }

  @override
  String toString() {
    return 'OAuthResult(success: $success, error: $error, user: ${user?.email})';
  }
}

/// OAuth token response
class OAuthTokenResponse {
  final String accessToken;
  final String? refreshToken;
  final int? expiresIn;
  final String tokenType;
  final String? scope;

  OAuthTokenResponse({
    required this.accessToken,
    this.refreshToken,
    this.expiresIn,
    this.tokenType = 'Bearer',
    this.scope,
  });

  factory OAuthTokenResponse.fromJson(Map<String, dynamic> json) {
    return OAuthTokenResponse(
      accessToken: json['access_token'] as String,
      refreshToken: json['refresh_token'] as String?,
      expiresIn: json['expires_in'] as int?,
      tokenType: json['token_type'] as String? ?? 'Bearer',
      scope: json['scope'] as String?,
    );
  }

  DateTime? get expiresAt {
    if (expiresIn == null) return null;
    return DateTime.now().add(Duration(seconds: expiresIn!));
  }
}

// ============================================================================
// OAUTH SERVICE IMPLEMENTATION - FIXED: GOOGLE ONLY
// ============================================================================

/// Production OAuth service with Google authentication only
/// FIXED: Removed Facebook, GitHub, and Apple - only Google is supported
class OAuthService {
  static final OAuthService _instance = OAuthService._internal();
  factory OAuthService() => _instance;
  OAuthService._internal();

  static const MethodChannel _channel = MethodChannel('com.daily_planner/oauth');

  bool _isInitialized = false;
  String? _currentState;
  String? _codeVerifier;

  // ============================================================================
  // INITIALIZATION
  // ============================================================================

  /// Initialize OAuth service
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Setup method channel for native OAuth calls
      _channel.setMethodCallHandler(_handleMethodCall);

      // Initialize native OAuth module if available
      try {
        await _channel.invokeMethod('initialize', {
          'providers': ['google'], // Only Google is supported
        });
      } catch (e) {
        // Native initialization failed - continue with web-based OAuth
        if (kDebugMode) {
          print('⚠️ Native OAuth not available, using web-based authentication');
        }
      }

      _isInitialized = true;

      if (kDebugMode) {
        print('✅ OAuth service initialized (Google only)');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ OAuth service initialization failed: $e');
      }
      rethrow;
    }
  }

  /// Handle method calls from native platform
  Future<dynamic> _handleMethodCall(MethodCall call) async {
    switch (call.method) {
      case 'onOAuthResult':
        return _handleOAuthResult(call.arguments);
      case 'onOAuthError':
        return _handleOAuthError(call.arguments);
      default:
        if (kDebugMode) {
          print('⚠️ Unknown OAuth method call: ${call.method}');
        }
    }
  }

  // ============================================================================
  // MAIN AUTHENTICATION METHODS - FIXED: GOOGLE ONLY
  // ============================================================================

  /// Sign in with Google - The only supported provider
  Future<OAuthResult> signInWithGoogle() async {
    if (!_isInitialized) await initialize();

    if (!OAuthConfig.isConfigured(OAuthProvider.google)) {
      return OAuthResult.failure('Google OAuth is not configured');
    }

    try {
      if (kDebugMode) {
        print('🔑 Starting Google OAuth authentication...');
      }

      // Try native implementation first (for better UX)
      if (Platform.isAndroid || Platform.isIOS) {
        try {
          final result = await _signInWithNative(OAuthProvider.google);
          if (result.success) return result;
        } catch (e) {
          if (kDebugMode) {
            print('⚠️ Native Google OAuth failed, falling back to web: $e');
          }
        }
      }

      // Fallback to web-based OAuth
      return await _signInWithWeb(OAuthProvider.google);

    } catch (e) {
      if (kDebugMode) {
        print('❌ Google OAuth failed: $e');
      }
      return OAuthResult.failure('Google sign-in failed: ${e.toString()}');
    }
  }

  /// REMOVED: Facebook, GitHub, and Apple sign-in methods as requested

  // ============================================================================
  // NATIVE OAUTH IMPLEMENTATION
  // ============================================================================

  /// Native OAuth implementation (uses platform channels)
  Future<OAuthResult> _signInWithNative(OAuthProvider provider) async {
    try {
      final result = await _channel.invokeMethod('signInWithGoogle'); // Only Google
      return _processNativeOAuthResult(result, provider);
    } catch (e) {
      throw Exception('Native OAuth failed: $e');
    }
  }

  /// Process native OAuth result
  OAuthResult _processNativeOAuthResult(Map<dynamic, dynamic>? result, OAuthProvider provider) {
    try {
      if (result == null) {
        return OAuthResult.failure('No result from native OAuth');
      }

      final success = result['success'] as bool? ?? false;
      if (!success) {
        final error = result['error'] as String? ?? 'Unknown error';
        return OAuthResult.failure(_getErrorMessage(error));
      }

      final userInfo = result['user'] as Map<dynamic, dynamic>? ?? {};
      final tokens = result['tokens'] as Map<dynamic, dynamic>? ?? {};

      final user = _createUserFromNativeResult(userInfo, tokens, provider);

      return OAuthResult.success(
        user,
        accessToken: tokens['access_token'] as String?,
        refreshToken: tokens['refresh_token'] as String?,
        expiresAt: tokens['expires_in'] != null
            ? DateTime.now().add(Duration(seconds: tokens['expires_in']))
            : null,
      );
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error processing native OAuth result: $e');
      }
      return OAuthResult.failure('Failed to process authentication result');
    }
  }

  // ============================================================================
  // WEB OAUTH IMPLEMENTATION - FIXED: Using custom deep link handler
  // ============================================================================

  /// Web-based OAuth implementation for Google
  Future<OAuthResult> _signInWithWeb(OAuthProvider provider) async {
    try {
      final config = OAuthConfig.getConfig(provider);

      // Generate security parameters
      _currentState = _generateSecureState();
      _codeVerifier = _generateCodeVerifier();
      final codeChallenge = _generateCodeChallenge(_codeVerifier!);

      // Build authorization URL
      final authUrl = _buildAuthorizationUrl(config, _currentState!, codeChallenge);

      // Launch OAuth flow
      final authCode = await _launchOAuthFlow(authUrl, config.redirectUri);
      if (authCode == null) {
        return OAuthResult.failure('Authorization cancelled by user');
      }

      // Exchange authorization code for tokens
      final tokenResponse = await _exchangeCodeForTokens(config, authCode, _codeVerifier!);
      if (tokenResponse == null) {
        return OAuthResult.failure('Failed to exchange authorization code for tokens');
      }

      // Get user information
      final userInfo = await _getUserInfo(provider, tokenResponse.accessToken);
      if (userInfo == null) {
        return OAuthResult.failure('Failed to get user information');
      }

      // Create user object
      final user = _createUserFromWebResult(userInfo, tokenResponse, provider);

      return OAuthResult.success(
        user,
        accessToken: tokenResponse.accessToken,
        refreshToken: tokenResponse.refreshToken,
        expiresAt: tokenResponse.expiresAt,
      );

    } catch (e) {
      if (kDebugMode) {
        print('❌ Web OAuth failed for Google: $e');
      }
      return OAuthResult.failure('Google authentication failed: ${e.toString()}');
    }
  }

  /// Build authorization URL with PKCE
  String _buildAuthorizationUrl(OAuthConfig config, String state, String codeChallenge) {
    final params = {
      'client_id': config.clientId,
      'response_type': 'code',
      'scope': config.scopes.join(' '),
      'redirect_uri': config.redirectUri,
      'state': state,
      'code_challenge': codeChallenge,
      'code_challenge_method': 'S256',
    };

    final query = params.entries
        .map((e) => '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value)}')
        .join('&');

    return '${config.authorizationEndpoint}?$query';
  }

  /// Launch OAuth flow in browser and wait for callback
  Future<String?> _launchOAuthFlow(String authUrl, String redirectUri) async {
    try {
      // Launch URL in browser
      final launched = await launchUrl(
        Uri.parse(authUrl),
        mode: LaunchMode.externalApplication,
      );

      if (!launched) {
        throw Exception('Could not launch OAuth URL');
      }

      // Listen for deep link callback - FIXED: Using custom implementation
      return await _listenForCallback(redirectUri);
    } catch (e) {
      if (kDebugMode) {
        print('❌ OAuth flow launch failed: $e');
      }
      return null;
    }
  }

  /// Listen for OAuth callback deep link - FIXED: Using custom deep link handler
  Future<String?> _listenForCallback(String expectedRedirectUri) async {
    try {
      // FIXED: Use custom deep link handler instead of uni_links
      final linkStream = DeepLinkHandler.linkStream;

      await for (final link in linkStream) {
        if (link != null && link.startsWith(expectedRedirectUri)) {
          final uri = Uri.parse(link);

          // Check for error
          final error = uri.queryParameters['error'];
          if (error != null) {
            throw Exception('OAuth error: $error');
          }

          // Validate state parameter
          final returnedState = uri.queryParameters['state'];
          if (returnedState != _currentState) {
            throw Exception('Invalid state parameter');
          }

          // Extract authorization code
          final code = uri.queryParameters['code'];
          if (code == null) {
            throw Exception('No authorization code received');
          }

          return code;
        }
      }

      return null;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Callback listening failed: $e');
      }
      return null;
    }
  }

  /// Exchange authorization code for access tokens
  Future<OAuthTokenResponse?> _exchangeCodeForTokens(
      OAuthConfig config,
      String authCode,
      String codeVerifier,
      ) async {
    try {
      final response = await http.post(
        Uri.parse(config.tokenEndpoint),
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded',
          'Accept': 'application/json',
        },
        body: {
          'client_id': config.clientId,
          'code': authCode,
          'grant_type': 'authorization_code',
          'redirect_uri': config.redirectUri,
          'code_verifier': codeVerifier,
          if (config.clientSecret != null) 'client_secret': config.clientSecret!,
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return OAuthTokenResponse.fromJson(data);
      } else {
        if (kDebugMode) {
          print('❌ Token exchange failed: ${response.statusCode} ${response.body}');
        }
        return null;
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Token exchange error: $e');
      }
      return null;
    }
  }

  /// Get user information from Google API
  Future<Map<String, dynamic>?> _getUserInfo(OAuthProvider provider, String accessToken) async {
    try {
      // Only Google is supported
      const userInfoUrl = 'https://www.googleapis.com/oauth2/v2/userinfo';

      final response = await http.get(
        Uri.parse(userInfoUrl),
        headers: {
          'Authorization': 'Bearer $accessToken',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        if (kDebugMode) {
          print('❌ User info request failed: ${response.statusCode} ${response.body}');
        }
        return null;
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Get user info error: $e');
      }
      return null;
    }
  }

  // ============================================================================
  // USER CREATION METHODS
  // ============================================================================

  /// Create user from native OAuth result
  User _createUserFromNativeResult(
      Map<dynamic, dynamic> userInfo,
      Map<dynamic, dynamic> tokens,
      OAuthProvider provider,
      ) {
    return User(
      id: userInfo['id']?.toString() ?? '',
      email: userInfo['email']?.toString() ?? '',
      displayName: userInfo['name']?.toString() ?? userInfo['displayName']?.toString() ?? '',
      photoURL: userInfo['photoURL']?.toString() ?? userInfo['picture']?.toString(),
      metadata: {
        'provider': 'google', // Only Google
        'access_token': tokens['access_token']?.toString(),
        'refresh_token': tokens['refresh_token']?.toString(),
        'expires_at': tokens['expires_in'] != null
            ? DateTime.now().add(Duration(seconds: tokens['expires_in'])).millisecondsSinceEpoch
            : null,
        ...userInfo.map((key, value) => MapEntry(key.toString(), value)),
      },
      createdAt: DateTime.now(),
    );
  }

  /// Create user from web OAuth result
  User _createUserFromWebResult(
      Map<String, dynamic> userInfo,
      OAuthTokenResponse tokens,
      OAuthProvider provider,
      ) {
    // Only Google is supported
    final userId = userInfo['id'] ?? '';
    final email = userInfo['email'] ?? '';
    final displayName = userInfo['name'] ?? '';
    final photoURL = userInfo['picture'];

    return User(
      id: userId,
      email: email,
      displayName: displayName,
      photoURL: photoURL,
      metadata: {
        'provider': 'google', // Only Google
        'access_token': tokens.accessToken,
        'refresh_token': tokens.refreshToken,
        'expires_at': tokens.expiresAt?.millisecondsSinceEpoch,
        'token_type': tokens.tokenType,
        'scope': tokens.scope,
        ...userInfo,
      },
      createdAt: DateTime.now(),
    );
  }

  // ============================================================================
  // SECURITY HELPERS
  // ============================================================================

  /// Generate secure random state parameter
  String _generateSecureState() {
    final random = Random.secure();
    final values = List<int>.generate(32, (i) => random.nextInt(256));
    return base64UrlEncode(values).replaceAll('=', '');
  }

  /// Generate PKCE code verifier
  String _generateCodeVerifier() {
    final random = Random.secure();
    final values = List<int>.generate(32, (i) => random.nextInt(256));
    return base64UrlEncode(values).replaceAll('=', '');
  }

  /// Generate PKCE code challenge
  String _generateCodeChallenge(String codeVerifier) {
    final bytes = utf8.encode(codeVerifier);
    final digest = sha256.convert(bytes);
    return base64UrlEncode(digest.bytes).replaceAll('=', '');
  }

  // ============================================================================
  // TOKEN MANAGEMENT
  // ============================================================================

  /// Refresh access token using refresh token
  Future<OAuthTokenResponse?> refreshToken(String refreshToken, OAuthProvider provider) async {
    try {
      final config = OAuthConfig.getConfig(provider);

      final response = await http.post(
        Uri.parse(config.tokenEndpoint),
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded',
          'Accept': 'application/json',
        },
        body: {
          'client_id': config.clientId,
          'refresh_token': refreshToken,
          'grant_type': 'refresh_token',
          if (config.clientSecret != null) 'client_secret': config.clientSecret!,
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return OAuthTokenResponse.fromJson(data);
      } else {
        if (kDebugMode) {
          print('❌ Token refresh failed: ${response.statusCode} ${response.body}');
        }
        return null;
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Token refresh error: $e');
      }
      return null;
    }
  }

  /// Validate access token
  Future<bool> validateToken(String accessToken, OAuthProvider provider) async {
    try {
      // Only Google is supported
      final response = await http.get(
        Uri.parse('https://www.googleapis.com/oauth2/v1/tokeninfo?access_token=$accessToken'),
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  /// Revoke access token
  Future<bool> revokeToken(String accessToken, OAuthProvider provider) async {
    try {
      // Only Google is supported
      final response = await http.post(
        Uri.parse('https://oauth2.googleapis.com/revoke?token=$accessToken'),
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  // ============================================================================
  // ERROR HANDLING
  // ============================================================================

  /// Handle OAuth result from method channel
  void _handleOAuthResult(Map<dynamic, dynamic> arguments) {
    if (kDebugMode) {
      print('✅ OAuth result received: Google');
    }
  }

  /// Handle OAuth error from method channel
  void _handleOAuthError(Map<dynamic, dynamic> arguments) {
    if (kDebugMode) {
      print('❌ OAuth error: ${arguments['error']}');
    }
  }

  /// Get user-friendly error message
  String _getErrorMessage(String error) {
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
  // UTILITY METHODS
  // ============================================================================

  /// Check if service is initialized
  bool get isInitialized => _isInitialized;

  /// Get available OAuth providers - FIXED: Only Google
  List<OAuthProvider> get availableProviders => [OAuthProvider.google];

  /// Check if Google OAuth is configured
  bool get isGoogleConfigured => OAuthConfig.isConfigured(OAuthProvider.google);

  /// Sign out (clear tokens)
  Future<void> signOut() async {
    try {
      _currentState = null;
      _codeVerifier = null;

      if (kDebugMode) {
        print('✅ OAuth session cleared');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Sign out error: $e');
      }
    }
  }

  /// Get service status
  Map<String, dynamic> getStatus() {
    return {
      'initialized': _isInitialized,
      'google_configured': isGoogleConfigured,
      'available_providers': ['google'], // Only Google
      'version': '2.0',
    };
  }

  /// Dispose resources
  void dispose() {
    _currentState = null;
    _codeVerifier = null;
    _isInitialized = false;
  }
}

// ============================================================================
// EXTENSION HELPERS
// ============================================================================

extension StringExtension on String {
  String capitalize() {
    return this[0].toUpperCase() + substring(1);
  }
}

