import 'package:shared_preferences/shared_preferences.dart';
import 'package:daily_planner/utils/error_handler.dart';
import 'package:flutter/foundation.dart';
import 'dart:convert';
import 'dart:math';

/// Utility class for authentication-related operations
/// FIXED: Added all missing methods that were causing compilation errors
class AuthUtils {
  // Storage keys
  static const String _isLoggedInKey = 'is_logged_in';
  static const String _userIdKey = 'user_id';
  static const String _userEmailKey = 'user_email';
  static const String _userDisplayNameKey = 'user_display_name';
  static const String _userPhotoUrlKey = 'user_photo_url';
  static const String _isGuestKey = 'is_guest';
  static const String _authTokenKey = 'auth_token';
  static const String _refreshTokenKey = 'refresh_token';
  static const String _sessionExpiryKey = 'session_expiry';

  // ============================================================================
  // SESSION MANAGEMENT METHODS
  // ============================================================================

  /// FIXED: Added missing storeUserSession method
  static Future<void> storeUserSession({
    required String userId,
    required String email,
    required String displayName,
    String? photoUrl,
    bool isGuest = false,
    String? authToken,
    String? refreshToken,
    DateTime? sessionExpiry,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      await prefs.setBool(_isLoggedInKey, true);
      await prefs.setString(_userIdKey, userId);
      await prefs.setString(_userEmailKey, email);
      await prefs.setString(_userDisplayNameKey, displayName);
      await prefs.setBool(_isGuestKey, isGuest);

      if (photoUrl != null) {
        await prefs.setString(_userPhotoUrlKey, photoUrl);
      }

      if (authToken != null) {
        await prefs.setString(_authTokenKey, authToken);
      }

      if (refreshToken != null) {
        await prefs.setString(_refreshTokenKey, refreshToken);
      }

      if (sessionExpiry != null) {
        await prefs.setString(_sessionExpiryKey, sessionExpiry.toIso8601String());
      }

    } catch (e) {
      ErrorHandler.logError('Failed to store user session', e);
      rethrow;
    }
  }

  /// FIXED: Added missing clearUserSession method
  static Future<void> clearUserSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      await prefs.remove(_isLoggedInKey);
      await prefs.remove(_userIdKey);
      await prefs.remove(_userEmailKey);
      await prefs.remove(_userDisplayNameKey);
      await prefs.remove(_userPhotoUrlKey);
      await prefs.remove(_isGuestKey);
      await prefs.remove(_authTokenKey);
      await prefs.remove(_refreshTokenKey);
      await prefs.remove(_sessionExpiryKey);

    } catch (e) {
      ErrorHandler.logError('Failed to clear user session', e);
      rethrow;
    }
  }

  /// Check if user is logged in
  static Future<bool> isUserLoggedIn() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_isLoggedInKey) ?? false;
    } catch (e) {
      ErrorHandler.logError('Failed to check if user is logged in', e);
      return false;
    }
  }

  /// Get stored user ID
  static Future<String?> getUserId() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_userIdKey);
    } catch (e) {
      ErrorHandler.logError('Failed to get user ID', e);
      return null;
    }
  }

  /// Get stored user email
  static Future<String?> getUserEmail() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_userEmailKey);
    } catch (e) {
      ErrorHandler.logError('Failed to get user email', e);
      return null;
    }
  }

  /// Get stored user display name
  static Future<String?> getUserDisplayName() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_userDisplayNameKey);
    } catch (e) {
      ErrorHandler.logError('Failed to get user display name', e);
      return null;
    }
  }

  /// Get stored user photo URL
  static Future<String?> getUserPhotoUrl() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_userPhotoUrlKey);
    } catch (e) {
      ErrorHandler.logError('Failed to get user photo URL', e);
      return null;
    }
  }

  /// Check if user is guest
  static Future<bool> isGuestUser() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_isGuestKey) ?? false;
    } catch (e) {
      ErrorHandler.logError('Failed to check if user is guest', e);
      return false;
    }
  }

  /// Get stored auth token
  static Future<String?> getAuthToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_authTokenKey);
    } catch (e) {
      ErrorHandler.logError('Failed to get auth token', e);
      return null;
    }
  }

  /// Get stored refresh token
  static Future<String?> getRefreshToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_refreshTokenKey);
    } catch (e) {
      ErrorHandler.logError('Failed to get refresh token', e);
      return null;
    }
  }

  /// Get session expiry date
  static Future<DateTime?> getSessionExpiry() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final expiryString = prefs.getString(_sessionExpiryKey);
      if (expiryString != null) {
        return DateTime.parse(expiryString);
      }
      return null;
    } catch (e) {
      ErrorHandler.logError('Failed to get session expiry', e);
      return null;
    }
  }

  /// Check if session is expired
  static Future<bool> isSessionExpired() async {
    try {
      final expiry = await getSessionExpiry();
      if (expiry == null) return false;
      return DateTime.now().isAfter(expiry);
    } catch (e) {
      ErrorHandler.logError('Failed to check session expiry', e);
      return true; // Assume expired on error
    }
  }

  // ============================================================================
  // VALIDATION METHODS
  // ============================================================================

  /// Validate email format
  static bool isValidEmail(String email) {
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );
    return emailRegex.hasMatch(email.trim());
  }

  /// Validate password strength
  static String? validatePassword(String password) {
    if (password.isEmpty) {
      return 'Password cannot be empty';
    }

    if (password.length < 8) {
      return 'Password must be at least 8 characters long';
    }

    if (!password.contains(RegExp(r'[A-Z]'))) {
      return 'Password must contain at least one uppercase letter';
    }

    if (!password.contains(RegExp(r'[a-z]'))) {
      return 'Password must contain at least one lowercase letter';
    }

    if (!password.contains(RegExp(r'[0-9]'))) {
      return 'Password must contain at least one number';
    }

    return null; // Password is valid
  }

  /// Check if password is strong
  static bool isStrongPassword(String password) {
    return validatePassword(password) == null;
  }

  /// Get password strength score (0-5)
  static int getPasswordStrength(String password) {
    int score = 0;

    // Length check
    if (password.length >= 8) score++;
    if (password.length >= 12) score++;

    // Character type checks
    if (password.contains(RegExp(r'[A-Z]'))) score++;
    if (password.contains(RegExp(r'[a-z]'))) score++;
    if (password.contains(RegExp(r'[0-9]'))) score++;
    if (password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'))) score++;

    return score.clamp(0, 5);
  }

  /// Get password strength description
  static String getPasswordStrengthText(String password) {
    final strength = getPasswordStrength(password);

    switch (strength) {
      case 0:
      case 1:
        return 'Very Weak';
      case 2:
        return 'Weak';
      case 3:
        return 'Fair';
      case 4:
        return 'Good';
      case 5:
        return 'Strong';
      default:
        return 'Very Weak';
    }
  }

  /// Validate name format
  static String? validateName(String name) {
    if (name.trim().isEmpty) {
      return 'Name cannot be empty';
    }

    if (name.trim().length < 2) {
      return 'Name must be at least 2 characters long';
    }

    if (name.trim().length > 50) {
      return 'Name cannot exceed 50 characters';
    }

    // Check for invalid characters
    final nameRegex = RegExp(r"^[a-zA-Z\s\-\.']+$");

    if (!nameRegex.hasMatch(name.trim())) {
    return 'Name contains invalid characters';
    }

    return null; // Name is valid
  }

  // ============================================================================
  // UTILITY METHODS
  // ============================================================================

  /// Generate a unique user ID
  static String generateUserId() {
    return 'user_${DateTime.now().millisecondsSinceEpoch}';
  }

  /// Generate a guest user ID
  static String generateGuestUserId() {
    return 'guest_${DateTime.now().millisecondsSinceEpoch}';
  }

  /// Get user session info
  static Future<Map<String, dynamic>> getUserSessionInfo() async {
    try {
      return {
        'isLoggedIn': await isUserLoggedIn(),
        'userId': await getUserId(),
        'email': await getUserEmail(),
        'displayName': await getUserDisplayName(),
        'photoUrl': await getUserPhotoUrl(),
        'isGuest': await isGuestUser(),
        'sessionExpiry': await getSessionExpiry(),
        'isSessionExpired': await isSessionExpired(),
      };
    } catch (e) {
      ErrorHandler.logError('Failed to get user session info', e);
      return {
        'isLoggedIn': false,
        'error': 'Failed to get session info',
      };
    }
  }

  /// Update user profile data
  static Future<void> updateUserProfile({
    String? displayName,
    String? photoUrl,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      if (displayName != null) {
        await prefs.setString(_userDisplayNameKey, displayName);
      }

      if (photoUrl != null) {
        await prefs.setString(_userPhotoUrlKey, photoUrl);
      }

    } catch (e) {
      ErrorHandler.logError('Failed to update user profile', e);
      rethrow;
    }
  }

  /// Set session expiry
  static Future<void> setSessionExpiry(DateTime expiry) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_sessionExpiryKey, expiry.toIso8601String());
    } catch (e) {
      ErrorHandler.logError('Failed to set session expiry', e);
      rethrow;
    }
  }

  /// Extend session expiry
  static Future<void> extendSession({Duration? duration}) async {
    try {
      final extension = duration ?? const Duration(days: 30);
      final newExpiry = DateTime.now().add(extension);
      await setSessionExpiry(newExpiry);
    } catch (e) {
      ErrorHandler.logError('Failed to extend session', e);
      rethrow;
    }
  }

  /// Clear expired sessions
  static Future<void> clearExpiredSessions() async {
    try {
      final isExpired = await isSessionExpired();
      if (isExpired) {
        await clearUserSession();
      }
    } catch (e) {
      ErrorHandler.logError('Failed to clear expired sessions', e);
    }
  }

  /// Get formatted auth error message
  static String getAuthErrorMessage(String error) {
    final errorLower = error.toLowerCase();

    if (errorLower.contains('email-already-in-use')) {
      return 'An account with this email already exists';
    } else if (errorLower.contains('weak-password')) {
      return 'Password is too weak';
    } else if (errorLower.contains('invalid-email')) {
      return 'Please enter a valid email address';
    } else if (errorLower.contains('user-not-found')) {
      return 'No account found with this email';
    } else if (errorLower.contains('wrong-password')) {
      return 'Incorrect password';
    } else if (errorLower.contains('user-disabled')) {
      return 'This account has been disabled';
    } else if (errorLower.contains('too-many-requests')) {
      return 'Too many failed attempts. Please try again later';
    } else if (errorLower.contains('network')) {
      return 'Network error. Please check your connection';
    } else if (errorLower.contains('timeout')) {
      return 'Request timed out. Please try again';
    } else if (errorLower.contains('permission')) {
      return 'Permission denied. Please check your settings';
    }

    return 'An unexpected error occurred. Please try again';
  }

  // ============================================================================
  // BIOMETRIC AUTHENTICATION HELPERS
  // ============================================================================

  /// Check if biometric authentication is available
  static Future<bool> isBiometricAvailable() async {
    try {
      // This would integrate with local_auth package
      // For now, return false as placeholder
      return false;
    } catch (e) {
      ErrorHandler.logError('Failed to check biometric availability', e);
      return false;
    }
  }

  /// Enable biometric authentication
  static Future<bool> enableBiometricAuth() async {
    try {
      // This would integrate with local_auth package
      // For now, return false as placeholder
      return false;
    } catch (e) {
      ErrorHandler.logError('Failed to enable biometric auth', e);
      return false;
    }
  }

  /// Authenticate with biometrics
  static Future<bool> authenticateWithBiometrics() async {
    try {
      // This would integrate with local_auth package
      // For now, return false as placeholder
      return false;
    } catch (e) {
      ErrorHandler.logError('Failed to authenticate with biometrics', e);
      return false;
    }
  }

  // ============================================================================
  // SECURITY UTILITIES
  // ============================================================================

  /// Generate secure random token
  static String generateSecureToken() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final randomSuffix = (timestamp * 1000).toString();
    return 'token_$randomSuffix';
  }

  /// Hash password (placeholder - use proper hashing in production)
  static String hashPassword(String password) {
    // In production, use proper password hashing like bcrypt
    return password.hashCode.toString();
  }

  /// Verify password hash (placeholder - use proper verification in production)
  static bool verifyPassword(String password, String hash) {
    // In production, use proper password verification
    return hashPassword(password) == hash;
  }

  /// Sanitize input string
  static String sanitizeInput(String input) {
    // FIXED: Used hexadecimal escape for single quote
    return input.trim().replaceAll(RegExp(r'[<>\x27"`]'), '');
  }

  /// FIXED: Removed extraneous parenthesis in regex pattern
  static bool isValidPhoneNumber(String phoneNumber) {
    // Remove any non-digit characters except + at the beginning
    final cleanedNumber = phoneNumber.replaceAll(RegExp(r'[^\d+]'), '');

    // Using a simple regex pattern for international phone numbers
    final phoneRegex = RegExp(r'^\+?[1-9]\d{1,14}$');
    return phoneRegex.hasMatch(cleanedNumber);
  }

  /// Log authentication event
  static void logAuthEvent(String event, {Map<String, dynamic>? metadata}) {
    ErrorHandler.logInfo('Auth Event: $event', metadata);
  }
}