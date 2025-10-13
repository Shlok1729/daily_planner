import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:daily_planner/services/supabase_service.dart';
import 'package:daily_planner/models/user_model.dart';
import 'package:daily_planner/utils/auth_utils.dart';
import 'package:daily_planner/utils/error_handler.dart';
import 'dart:io';

/// OAuth provider types
enum OAuthProvider { google, apple, facebook, github }

/// OAuth authentication result
class OAuthResult {
  final bool success;
  final User? user;
  final String? error;
  final String? accessToken;
  final String? refreshToken;

  const OAuthResult({
    required this.success,
    this.user,
    this.error,
    this.accessToken,
    this.refreshToken,
  });

  factory OAuthResult.success(User user, {String? accessToken, String? refreshToken}) {
    return OAuthResult(
      success: true,
      user: user,
      accessToken: accessToken,
      refreshToken: refreshToken,
    );
  }

  factory OAuthResult.failure(String error) {
    return OAuthResult(
      success: false,
      error: error,
    );
  }
}

/// OAuth configuration class
class OAuthConfig {
  final String clientId;
  final String? clientSecret;
  final List<String> scopes;
  final String? redirectUrl;

  const OAuthConfig({
    required this.clientId,
    this.clientSecret,
    this.scopes = const [],
    this.redirectUrl,
  });
}

/// Main authentication service with OAuth support
class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  final SupabaseService _supabaseService = SupabaseService();

  // OAuth configurations (placeholder values)
  static const Map<OAuthProvider, OAuthConfig> _oauthConfigs = {
    OAuthProvider.google: OAuthConfig(
      clientId: 'your-google-client-id.googleusercontent.com',
      scopes: ['openid', 'email', 'profile'],
    ),
    OAuthProvider.apple: OAuthConfig(
      clientId: 'com.example.daily_planner',
      scopes: ['email', 'name'],
    ),
    OAuthProvider.facebook: OAuthConfig(
      clientId: 'your-facebook-app-id',
      scopes: ['email', 'public_profile'],
    ),
    OAuthProvider.github: OAuthConfig(
      clientId: 'your-github-client-id',
      scopes: ['user:email'],
    ),
  };

  bool _isInitialized = false;
  User? _currentUser;

  /// Initialize the auth service
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Initialize Supabase service
      await _supabaseService.initialize();

      // Check for existing user session
      await _loadStoredUser();

      _isInitialized = true;

      if (kDebugMode) {
        print('✅ AuthService initialized successfully');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ AuthService initialization failed: $e');
      }
      // Continue without throwing - allow app to work offline
      _isInitialized = true;
    }
  }

  /// Load stored user from local storage
  Future<void> _loadStoredUser() async {
    try {
      final isLoggedIn = await AuthUtils.isUserLoggedIn();
      if (!isLoggedIn) return;

      final userId = await AuthUtils.getUserId();
      final email = await AuthUtils.getUserEmail();
      final name = await AuthUtils.getUserDisplayName();

      if (userId != null && email != null) {
        // FIXED: Create User directly instead of using AppUser.User
        _currentUser = User(
          id: userId,
          email: email,
          displayName: name ?? 'User',
          photoURL: null,
          metadata: {'is_guest': false},
          // Added missing required createdAt parameter
          createdAt: DateTime.now(),
        );
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error loading stored user: $e');
      }
    }
  }

  /// Get current authenticated user
  User? get currentUser => _currentUser;

  /// Check if user is authenticated
  bool get isAuthenticated => _currentUser != null && !(_currentUser!.metadata['is_guest'] == true);

  /// Check if session is valid
  Future<bool> isSessionValid() async {
    if (_currentUser == null) return false;

    try {
      // Check if user still exists in storage
      final isLoggedIn = await AuthUtils.isUserLoggedIn();
      return isLoggedIn;
    } catch (e) {
      if (kDebugMode) {
        print('Error checking session validity: $e');
      }
      return false;
    }
  }

  /// Check if OAuth provider is available on current platform
  bool isOAuthProviderAvailable(OAuthProvider provider) {
    switch (provider) {
      case OAuthProvider.google:
        return true; // Available on all platforms
      case OAuthProvider.apple:
        return Platform.isIOS || Platform.isMacOS; // Apple Sign-In only on Apple platforms
      case OAuthProvider.facebook:
        return true; // Available on all platforms
      case OAuthProvider.github:
        return true; // Available on all platforms
    }
  }

  /// Get OAuth provider display name
  String getProviderDisplayName(OAuthProvider provider) {
    switch (provider) {
      case OAuthProvider.google:
        return 'Google';
      case OAuthProvider.apple:
        return 'Apple';
      case OAuthProvider.facebook:
        return 'Facebook';
      case OAuthProvider.github:
        return 'GitHub';
    }
  }

  /// Get OAuth provider icon name
  String getProviderIconName(OAuthProvider provider) {
    switch (provider) {
      case OAuthProvider.google:
        return 'google';
      case OAuthProvider.apple:
        return 'apple';
      case OAuthProvider.facebook:
        return 'facebook';
      case OAuthProvider.github:
        return 'github';
    }
  }

  /// Sign in with email and password
  Future<OAuthResult> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      if (!_isInitialized) await initialize();

      // Validate input
      if (!AuthUtils.isValidEmail(email)) {
        return OAuthResult.failure('Please enter a valid email address');
      }

      final passwordError = AuthUtils.validatePassword(password);
      if (passwordError != null) {
        return OAuthResult.failure(passwordError);
      }

      // Try Supabase authentication first
      try {
        final response = await _supabaseService.signIn(
          email: email,
          password: password,
        );

        if (response.user != null) {
          // FIXED: Create User directly instead of using AppUser.User
          final user = User(
            id: response.user!.id,
            email: response.user!.email ?? email,
            displayName: response.user!.userMetadata?['name'] ?? 'User',
            photoURL: response.user!.userMetadata?['avatar_url'],
            metadata: {'is_guest': false},
            createdAt: DateTime.tryParse(response.user!.createdAt) ?? DateTime.now(),
          );

          await _storeUserSession(user);
          _currentUser = user;

          if (kDebugMode) {
            print('✅ User signed in with Supabase: ${user.email}');
          }

          return OAuthResult.success(user);
        }
      } catch (supabaseError) {
        if (kDebugMode) {
          print('Supabase sign-in failed: $supabaseError');
        }
        // Fall through to offline mode
      }

      // Offline mode - store user locally
      // FIXED: Create User directly instead of using AppUser.User
      final user = User(
        id: 'offline_${email.hashCode}',
        email: email,
        displayName: 'User',
        photoURL: null,
        metadata: {'is_guest': false},
        createdAt: DateTime.now(),
      );

      await _storeUserSession(user);
      _currentUser = user;

      if (kDebugMode) {
        print('✅ User signed in offline: ${user.email}');
      }

      return OAuthResult.success(user);
    } catch (e) {
      ErrorHandler.logError('Sign-in failed', e);
      return OAuthResult.failure('Sign-in failed: ${e.toString()}');
    }
  }

  /// Sign up with email and password
  Future<OAuthResult> signUpWithEmailAndPassword({
    required String email,
    required String password,
    String? name,
  }) async {
    try {
      if (!_isInitialized) await initialize();

      // Validate input
      if (!AuthUtils.isValidEmail(email)) {
        return OAuthResult.failure('Please enter a valid email address');
      }

      final passwordError = AuthUtils.validatePassword(password);
      if (passwordError != null) {
        return OAuthResult.failure(passwordError);
      }

      // Try Supabase authentication first
      try {
        final response = await _supabaseService.signUp(
          email: email,
          password: password,
          name: name,
        );

        if (response.user != null) {
          // FIXED: Create User directly instead of using AppUser.User
          final user = User(
            id: response.user!.id,
            email: response.user!.email ?? email,
            displayName: name ?? response.user!.userMetadata?['name'] ?? 'User',
            photoURL: response.user!.userMetadata?['avatar_url'],
            metadata: {'is_guest': false},
            createdAt: DateTime.tryParse(response.user!.createdAt) ?? DateTime.now(),
          );

          await _storeUserSession(user);
          _currentUser = user;

          if (kDebugMode) {
            print('✅ User signed up with Supabase: ${user.email}');
          }

          return OAuthResult.success(user);
        }
      } catch (supabaseError) {
        if (kDebugMode) {
          print('Supabase sign-up failed: $supabaseError');
        }
        // Fall through to offline mode
      }

      // Offline mode - store user locally
      // FIXED: Create User directly instead of using AppUser.User
      final user = User(
        id: 'offline_${email.hashCode}',
        email: email,
        displayName: name ?? 'User',
        photoURL: null,
        metadata: {'is_guest': false},
        createdAt: DateTime.now(),
      );

      await _storeUserSession(user);
      _currentUser = user;

      if (kDebugMode) {
        print('✅ User signed up offline: ${user.email}');
      }

      return OAuthResult.success(user);
    } catch (e) {
      ErrorHandler.logError('Sign-up failed', e);
      return OAuthResult.failure('Sign-up failed: ${e.toString()}');
    }
  }

  /// Sign in with OAuth provider
  Future<OAuthResult> signInWithOAuth(OAuthProvider provider) async {
    try {
      if (!_isInitialized) await initialize();

      if (!isOAuthProviderAvailable(provider)) {
        return OAuthResult.failure('${getProviderDisplayName(provider)} sign-in is not available on this platform');
      }

      // Try Supabase OAuth
      try {
        final response = await _supabaseService.signInWithOAuth(provider);

        if (response.user != null) {
          // FIXED: Create User directly instead of using AppUser.User
          final user = User(
            id: response.user!.id,
            email: response.user!.email ?? '',
            displayName: response.user!.userMetadata?['name'] ?? response.user!.userMetadata?['full_name'] ?? 'User',
            photoURL: response.user!.userMetadata?['avatar_url'] ?? response.user!.userMetadata?['picture'],
            metadata: {'is_guest': false},
            createdAt: DateTime.tryParse(response.user!.createdAt) ?? DateTime.now(),
          );

          await _storeUserSession(user);
          _currentUser = user;

          if (kDebugMode) {
            print('✅ User signed in with ${getProviderDisplayName(provider)}: ${user.email}');
          }

          return OAuthResult.success(user);
        }
      } catch (oauthError) {
        if (kDebugMode) {
          print('OAuth sign-in failed: $oauthError');
        }
      }

      return OAuthResult.failure('${getProviderDisplayName(provider)} sign-in failed');
    } catch (e) {
      ErrorHandler.logError('OAuth sign-in failed', e);
      return OAuthResult.failure('OAuth sign-in failed: ${e.toString()}');
    }
  }

  /// Sign in as guest
  Future<OAuthResult> signInAsGuest() async {
    try {
      // FIXED: Create User directly instead of using AppUser.User
      final user = User(
        id: 'guest_${DateTime.now().millisecondsSinceEpoch}',
        email: 'guest@example.com',
        displayName: 'Guest User',
        photoURL: null,
        metadata: {'is_guest': true},
        createdAt: DateTime.now(),
      );

      await _storeUserSession(user);
      _currentUser = user;

      if (kDebugMode) {
        print('✅ User signed in as guest');
      }

      return OAuthResult.success(user);
    } catch (e) {
      ErrorHandler.logError('Guest sign-in failed', e);
      return OAuthResult.failure('Guest sign-in failed: ${e.toString()}');
    }
  }

  /// Sign out current user
  Future<void> signOut() async {
    try {
      // Sign out from Supabase if connected
      if (_supabaseService.isInitialized) {
        await _supabaseService.signOut();
      }

      // Clear local session
      await AuthUtils.clearUserSession();
      _currentUser = null;

      if (kDebugMode) {
        print('✅ User signed out successfully');
      }
    } catch (e) {
      ErrorHandler.logError('Sign-out failed', e);
      if (kDebugMode) {
        print('❌ Sign-out failed: $e');
      }
    }
  }

  /// Reset password
  Future<bool> resetPassword(String email) async {
    try {
      if (!AuthUtils.isValidEmail(email)) {
        return false;
      }

      // Try Supabase password reset
      if (_supabaseService.isInitialized) {
        await _supabaseService.resetPassword(email);
        return true;
      }

      return false;
    } catch (e) {
      ErrorHandler.logError('Password reset failed', e);
      return false;
    }
  }

  /// Update user profile
  Future<bool> updateProfile({
    String? name,
    String? photoUrl,
  }) async {
    try {
      if (_currentUser == null) return false;

      final updatedUser = _currentUser!.copyWith(
        displayName: name,
        photoURL: photoUrl,
      );

      // Update in Supabase if connected
      if (_supabaseService.isInitialized) {
        await _supabaseService.updateUserProfile(
          userId: _currentUser!.id,
          name: name,
          avatarUrl: photoUrl,
        );
      }

      // Update locally
      await _storeUserSession(updatedUser);
      _currentUser = updatedUser;

      if (kDebugMode) {
        print('✅ User profile updated');
      }

      return true;
    } catch (e) {
      ErrorHandler.logError('Profile update failed', e);
      return false;
    }
  }

  /// Delete user account
  Future<bool> deleteUser() async {
    try {
      if (_currentUser == null) return false;

      // Delete from Supabase if connected
      if (_supabaseService.isInitialized) {
        await _supabaseService.deleteUser(_currentUser!.id);
      }

      // Clear local session
      await AuthUtils.clearUserSession();
      _currentUser = null;

      if (kDebugMode) {
        print('✅ User account deleted');
      }

      return true;
    } catch (e) {
      ErrorHandler.logError('Account deletion failed', e);
      return false;
    }
  }

  /// Store user session locally
  Future<void> _storeUserSession(User user) async {
    await AuthUtils.storeUserSession(
      userId: user.id,
      email: user.email ?? '',
      displayName: user.displayName ?? '',
      photoUrl: user.photoURL,
      isGuest: user.metadata['is_guest'] == true,
    );
  }

  /// Get user profile from storage/server
  Future<User?> getUserProfile(String userId) async {
    try {
      if (_supabaseService.isInitialized) {
        final userData = await _supabaseService.getUserProfile(userId);
        if (userData != null) {
          return User.fromJson(userData);
        }
      }
      return null;
    } catch (e) {
      ErrorHandler.logError('Failed to get user profile', e);
      return null;
    }
  }

  /// Check if email is already registered
  Future<bool> isEmailRegistered(String email) async {
    try {
      if (_supabaseService.isInitialized) {
        return await _supabaseService.isEmailRegistered(email);
      }
      return false;
    } catch (e) {
      if (kDebugMode) {
        print('Failed to check email registration: $e');
      }
      return false;
    }
  }

  /// Refresh current user session
  Future<void> refreshSession() async {
    try {
      if (_supabaseService.isInitialized) {
        final session = await _supabaseService.refreshSession();
        if (session?.user != null) {
          _currentUser = User.fromJson(session!.user!.toJson());
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('Failed to refresh session: $e');
      }
    }
  }
}