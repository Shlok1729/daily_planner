import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:daily_planner/services/auth_service.dart';
import 'package:daily_planner/models/user_model.dart';
import 'package:daily_planner/utils/auth_utils.dart';
import 'package:flutter/foundation.dart';

/// Authentication state class
class AuthState {
  final User? user;
  final bool isSignedIn;
  final bool isLoading;
  final String? error;
  final bool isInitialized;

  const AuthState({
    this.user,
    this.isSignedIn = false,
    this.isLoading = false,
    this.error,
    this.isInitialized = false,
  });

  AuthState copyWith({
    User? user,
    bool? isSignedIn,
    bool? isLoading,
    String? error,
    bool? isInitialized,
  }) {
    return AuthState(
      user: user ?? this.user,
      isSignedIn: isSignedIn ?? this.isSignedIn,
      isLoading: isLoading ?? this.isLoading,
      error: error, // Allow null to clear error
      isInitialized: isInitialized ?? this.isInitialized,
    );
  }

  // Convenience getters
  bool get hasUser => user != null;
  bool get isGuest => user?.metadata['is_guest'] == true;
  bool get isAuthenticated => isSignedIn && !isGuest;
  String get displayName => user?.displayName ?? 'User';
  String? get email => user?.email;
  String? get photoUrl => user?.photoURL;

  // Added profile getter for backward compatibility
  User? get profile => user;
}

/// Auth notifier for managing authentication state
class AuthNotifier extends Notifier<AuthState> {
  final AuthService _authService = AuthService();

  @override
  AuthState build() {
    // Initialize auth service and load user
    _initializeAuth();
    return const AuthState(isLoading: true);
  }

  /// Initialize authentication service
  Future<void> _initializeAuth() async {
    try {
      await _authService.initialize();

      // Check for existing user session
      final currentUser = _authService.currentUser;
      final isSessionValid = await _authService.isSessionValid();

      if (currentUser != null && isSessionValid) {
        state = AuthState(
          user: currentUser,
          isSignedIn: true,
          isInitialized: true,
        );
      } else {
        state = const AuthState(isInitialized: true);
      }

      if (kDebugMode) {
        print('✅ Auth initialized - User: ${currentUser?.email ?? 'None'}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Auth initialization failed: $e');
      }
      state = AuthState(
        error: 'Failed to initialize authentication',
        isInitialized: true,
      );
    }
  }

  /// Sign up with email and password
  Future<OAuthResult> signUpWithEmail({
    required String email,
    required String password,
    String? name,
  }) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final result = await _authService.signUpWithEmailAndPassword(
        email: email,
        password: password,
        name: name,
      );

      if (result.success && result.user != null) {
        state = AuthState(
          user: result.user,
          isSignedIn: true,
          isInitialized: true,
        );

        if (kDebugMode) {
          print('✅ User signed up successfully: ${result.user!.email}');
        }
      } else {
        state = state.copyWith(
          isLoading: false,
          error: result.error ?? 'Sign-up failed',
        );
      }

      return result;
    } catch (e) {
      final errorMessage = 'Sign-up failed: ${e.toString()}';
      state = state.copyWith(
        isLoading: false,
        error: errorMessage,
      );

      if (kDebugMode) {
        print('❌ Sign-up error: $e');
      }

      return OAuthResult.failure(errorMessage);
    }
  }

  /// Sign in with email and password
  Future<OAuthResult> signInWithEmail({
    required String email,
    required String password,
  }) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final result = await _authService.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (result.success && result.user != null) {
        state = AuthState(
          user: result.user,
          isSignedIn: true,
          isInitialized: true,
        );

        if (kDebugMode) {
          print('✅ User signed in successfully: ${result.user!.email}');
        }
      } else {
        state = state.copyWith(
          isLoading: false,
          error: result.error ?? 'Sign-in failed',
        );
      }

      return result;
    } catch (e) {
      final errorMessage = 'Sign-in failed: ${e.toString()}';
      state = state.copyWith(
        isLoading: false,
        error: errorMessage,
      );

      if (kDebugMode) {
        print('❌ Sign-in error: $e');
      }

      return OAuthResult.failure(errorMessage);
    }
  }

  /// Sign in with OAuth provider
  Future<OAuthResult> signInWithOAuth(OAuthProvider provider) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final result = await _authService.signInWithOAuth(provider);

      if (result.success && result.user != null) {
        state = AuthState(
          user: result.user,
          isSignedIn: true,
          isInitialized: true,
        );

        if (kDebugMode) {
          print('✅ User signed in with OAuth: ${result.user!.email}');
        }
      } else {
        state = state.copyWith(
          isLoading: false,
          error: result.error ?? 'OAuth sign-in failed',
        );
      }

      return result;
    } catch (e) {
      final errorMessage = 'OAuth sign-in failed: ${e.toString()}';
      state = state.copyWith(
        isLoading: false,
        error: errorMessage,
      );

      if (kDebugMode) {
        print('❌ OAuth sign-in error: $e');
      }

      return OAuthResult.failure(errorMessage);
    }
  }

  /// Sign in as guest
  Future<OAuthResult> signInAsGuest() async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final result = await _authService.signInAsGuest();

      if (result.success && result.user != null) {
        state = AuthState(
          user: result.user,
          isSignedIn: true,
          isInitialized: true,
        );

        if (kDebugMode) {
          print('✅ User signed in as guest');
        }
      } else {
        state = state.copyWith(
          isLoading: false,
          error: result.error ?? 'Guest sign-in failed',
        );
      }

      return result;
    } catch (e) {
      final errorMessage = 'Guest sign-in failed: ${e.toString()}';
      state = state.copyWith(
        isLoading: false,
        error: errorMessage,
      );

      if (kDebugMode) {
        print('❌ Guest sign-in error: $e');
      }

      return OAuthResult.failure(errorMessage);
    }
  }

  /// Sign out current user
  Future<void> signOut() async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      await _authService.signOut();

      state = const AuthState(isInitialized: true);

      if (kDebugMode) {
        print('✅ User signed out successfully');
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Sign-out failed: ${e.toString()}',
      );

      if (kDebugMode) {
        print('❌ Sign-out error: $e');
      }
    }
  }

  /// Reset password
  Future<bool> resetPassword(String email) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final success = await _authService.resetPassword(email);

      state = state.copyWith(
        isLoading: false,
        error: success ? null : 'Failed to send password reset email',
      );

      return success;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Password reset failed: ${e.toString()}',
      );

      if (kDebugMode) {
        print('❌ Password reset error: $e');
      }

      return false;
    }
  }

  /// Update user profile
  Future<bool> updateProfile({
    String? name,
    String? photoUrl,
  }) async {
    if (state.user == null) return false;

    state = state.copyWith(isLoading: true, error: null);

    try {
      final success = await _authService.updateProfile(
        name: name,
        photoUrl: photoUrl,
      );

      if (success) {
        // Update local state with new user data
        final updatedUser = state.user!.copyWith(
          displayName: name,
          photoURL: photoUrl,
        );

        state = state.copyWith(
          user: updatedUser,
          isLoading: false,
        );

        if (kDebugMode) {
          print('✅ Profile updated successfully');
        }
      } else {
        state = state.copyWith(
          isLoading: false,
          error: 'Failed to update profile',
        );
      }

      return success;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Profile update failed: ${e.toString()}',
      );

      if (kDebugMode) {
        print('❌ Profile update error: $e');
      }

      return false;
    }
  }

  /// Delete user account
  Future<bool> deleteAccount() async {
    if (state.user == null) return false;

    state = state.copyWith(isLoading: true, error: null);

    try {
      final success = await _authService.deleteUser();

      if (success) {
        state = const AuthState(isInitialized: true);

        if (kDebugMode) {
          print('✅ Account deleted successfully');
        }
      } else {
        state = state.copyWith(
          isLoading: false,
          error: 'Failed to delete account',
        );
      }

      return success;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Account deletion failed: ${e.toString()}',
      );

      if (kDebugMode) {
        print('❌ Account deletion error: $e');
      }

      return false;
    }
  }

  /// Clear any error state
  void clearError() {
    state = state.copyWith(error: null);
  }

  /// Refresh current session
  Future<void> refreshSession() async {
    try {
      await _authService.refreshSession();

      // Update state with current user
      final currentUser = _authService.currentUser;
      if (currentUser != null) {
        state = state.copyWith(user: currentUser);
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Session refresh error: $e');
      }
    }
  }

  /// Check if email is already registered
  Future<bool> isEmailRegistered(String email) async {
    try {
      return await _authService.isEmailRegistered(email);
    } catch (e) {
      if (kDebugMode) {
        print('❌ Email check error: $e');
      }
      return false;
    }
  }

  /// Get available OAuth providers for current platform
  List<OAuthProvider> getAvailableOAuthProviders() {
    return OAuthProvider.values.where((provider) {
      return _authService.isOAuthProviderAvailable(provider);
    }).toList();
  }

  /// Get OAuth provider display name
  String getOAuthProviderDisplayName(OAuthProvider provider) {
    return _authService.getProviderDisplayName(provider);
  }

  /// Get OAuth provider icon name
  String getOAuthProviderIconName(OAuthProvider provider) {
    return _authService.getProviderIconName(provider);
  }
}

/// Provider for authentication state
final authProvider = NotifierProvider<AuthNotifier, AuthState>(() {
  return AuthNotifier();
});

/// Provider for current user (convenience)
final currentUserProvider = Provider<User?>((ref) {
  return ref.watch(authProvider).user;
});

/// Provider for authentication status (convenience)
final isAuthenticatedProvider = Provider<bool>((ref) {
  return ref.watch(authProvider).isAuthenticated;
});

/// Provider for loading status (convenience)
final authLoadingProvider = Provider<bool>((ref) {
  return ref.watch(authProvider).isLoading;
});

/// Provider for error status (convenience)
final authErrorProvider = Provider<String?>((ref) {
  return ref.watch(authProvider).error;
});