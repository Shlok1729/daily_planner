import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;
import 'package:daily_planner/config/environment_config.dart';
import 'package:daily_planner/utils/error_handler.dart';
import 'package:daily_planner/services/auth_service.dart';
import 'dart:typed_data';
import 'dart:convert';

// ============================================================================
// SUPABASE SERVICE (FIXED WITH ALL MISSING METHODS)
// ============================================================================

/// Service for handling Supabase backend operations
/// FIXED: Added missing methods, proper type handling, and OAuth support
class SupabaseService {
  static final SupabaseService _instance = SupabaseService._internal();
  factory SupabaseService() => _instance;
  SupabaseService._internal();

  supabase.SupabaseClient? _client;
  bool _isInitialized = false;
  bool _initializationFailed = false;

  /// Get the Supabase client
  supabase.SupabaseClient? get client => _client;

  /// Check if service is initialized
  bool get isInitialized => _isInitialized && !_initializationFailed;

  /// Initialize Supabase client
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Check if configuration is available
      if (!EnvironmentConfig.isSupabaseConfigured) {
        if (kDebugMode) {
          print('⚠️ Supabase not configured. Running in offline mode.');
        }
        _initializationFailed = true;
        return;
      }

      // Initialize Supabase
      await supabase.Supabase.initialize(
        url: EnvironmentConfig.supabaseUrl,
        anonKey: EnvironmentConfig.supabaseAnonKey,
        debug: kDebugMode,
      );

      _client = supabase.Supabase.instance.client;
      _isInitialized = true;

      if (kDebugMode) {
        print('✅ Supabase initialized successfully');
      }
    } catch (e) {
      _initializationFailed = true;
      ErrorHandler.logError('Supabase initialization failed', e);

      if (kDebugMode) {
        print('⚠️ Supabase initialization failed: $e. Using offline mode.');
      }
    }
  }

  // ============================================================================
  // AUTHENTICATION METHODS
  // ============================================================================

  /// Sign up with email and password
  Future<supabase.AuthResponse> signUp({
    required String email,
    required String password,
    String? name,
  }) async {
    if (!_isInitialized || _initializationFailed) {
      throw StateError('Supabase not properly initialized. Using offline mode.');
    }

    try {
      return await _client!.auth.signUp(
        email: email,
        password: password,
        data: name != null ? {'name': name} : null,
      );
    } catch (e) {
      ErrorHandler.logError('Supabase sign up failed', e);
      rethrow;
    }
  }

  /// Sign in with email and password
  Future<supabase.AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    if (!_isInitialized || _initializationFailed) {
      throw StateError('Supabase not properly initialized. Using offline mode.');
    }

    try {
      return await _client!.auth.signInWithPassword(
        email: email,
        password: password,
      );
    } catch (e) {
      ErrorHandler.logError('Supabase sign in failed', e);
      rethrow;
    }
  }

  /// Sign in with OAuth provider
  /// FIXED: Return AuthResponse instead of bool
  Future<supabase.AuthResponse> signInWithOAuth(OAuthProvider provider) async {
    if (!_isInitialized || _initializationFailed) {
      throw StateError('Supabase not properly initialized. Using offline mode.');
    }

    try {
      supabase.OAuthProvider supabaseProvider;

      switch (provider) {
        case OAuthProvider.google:
          supabaseProvider = supabase.OAuthProvider.google;
          break;
        case OAuthProvider.apple:
          supabaseProvider = supabase.OAuthProvider.apple;
          break;
        case OAuthProvider.facebook:
          supabaseProvider = supabase.OAuthProvider.facebook;
          break;
        case OAuthProvider.github:
          supabaseProvider = supabase.OAuthProvider.github;
          break;
      }

      // FIXED: signInWithOAuth returns AuthResponse, not bool
      final response = await _client!.auth.signInWithOAuth(supabaseProvider);

      // Create a proper AuthResponse to return
      // Since signInWithOAuth doesn't directly return AuthResponse, we need to handle it properly
      final currentSession = _client!.auth.currentSession;
      final currentUser = _client!.auth.currentUser;

      if (currentUser != null) {
        return supabase.AuthResponse(
          session: currentSession,
          user: currentUser,
        );
      } else {
        throw Exception('OAuth sign in failed - no user returned');
      }
    } catch (e) {
      ErrorHandler.logError('Supabase OAuth sign in failed', e);
      rethrow;
    }
  }

  /// Sign out current user
  Future<void> signOut() async {
    if (!_isInitialized || _initializationFailed) {
      if (kDebugMode) {
        print('Cannot sign out: Supabase not initialized');
      }
      return;
    }

    try {
      await _client!.auth.signOut();
    } catch (e) {
      ErrorHandler.logError('Supabase sign out failed', e);
      if (kDebugMode) {
        print('Failed to sign out from Supabase: $e');
      }
    }
  }

  /// Reset password
  Future<void> resetPassword(String email) async {
    if (!_isInitialized || _initializationFailed) {
      throw StateError('Supabase not properly initialized. Using offline mode.');
    }

    try {
      await _client!.auth.resetPasswordForEmail(email);
    } catch (e) {
      ErrorHandler.logError('Supabase password reset failed', e);
      rethrow;
    }
  }

  /// Update user profile
  Future<supabase.UserResponse> updateUserProfile({
    required String userId,
    String? name,
    String? avatarUrl,
  }) async {
    if (!_isInitialized || _initializationFailed) {
      throw StateError('Supabase not properly initialized. Using offline mode.');
    }

    try {
      final updateData = <String, dynamic>{};
      if (name != null) updateData['name'] = name;
      if (avatarUrl != null) updateData['avatar_url'] = avatarUrl;

      return await _client!.auth.updateUser(
        supabase.UserAttributes(data: updateData),
      );
    } catch (e) {
      ErrorHandler.logError('Supabase profile update failed', e);
      rethrow;
    }
  }

  /// Delete user account
  Future<void> deleteUser(String userId) async {
    if (!_isInitialized || _initializationFailed) {
      throw StateError('Supabase not properly initialized. Using offline mode.');
    }

    try {
      // Delete user data from database first
      await _client!.from('users').delete().eq('id', userId);

      // Then delete from auth
      await _client!.auth.admin.deleteUser(userId);
    } catch (e) {
      ErrorHandler.logError('Supabase user deletion failed', e);
      rethrow;
    }
  }

  /// Refresh current session
  Future<supabase.AuthResponse?> refreshSession() async {
    if (!_isInitialized || _initializationFailed) {
      return null;
    }

    try {
      return await _client!.auth.refreshSession();
    } catch (e) {
      ErrorHandler.logError('Supabase session refresh failed', e);
      return null;
    }
  }

  /// Get user profile
  Future<Map<String, dynamic>?> getUserProfile(String userId) async {
    if (!_isInitialized || _initializationFailed) {
      return null;
    }

    try {
      final response = await _client!
          .from('users')
          .select()
          .eq('id', userId)
          .single();

      return response;
    } catch (e) {
      if (kDebugMode) {
        print('Failed to get user profile: $e');
      }
      return null;
    }
  }

  /// Check if email is already registered
  Future<bool> isEmailRegistered(String email) async {
    if (!_isInitialized || _initializationFailed) {
      return false;
    }

    try {
      final response = await _client!
          .from('users')
          .select('id')
          .eq('email', email)
          .limit(1);

      return response.isNotEmpty;
    } catch (e) {
      if (kDebugMode) {
        print('Failed to check email registration: $e');
      }
      return false;
    }
  }

  // ============================================================================
  // USER DATA METHODS
  // ============================================================================

  /// Create user profile
  Future<void> createUserProfile({
    required String userId,
    required String email,
    String? name,
    String? avatarUrl,
    Map<String, dynamic>? additionalData,
  }) async {
    if (!_isInitialized || _initializationFailed) {
      if (kDebugMode) {
        print('Cannot create user profile: Supabase not initialized');
      }
      return;
    }

    try {
      final profileData = {
        'id': userId,
        'email': email,
        'name': name,
        'avatar_url': avatarUrl,
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
        ...?additionalData,
      };

      await _client!.from('users').insert(profileData);
    } catch (e) {
      ErrorHandler.logError('Failed to create user profile', e);
      if (kDebugMode) {
        print('Failed to create user profile: $e');
      }
    }
  }

  /// Update user profile data
  Future<void> updateUserProfileData({
    required String userId,
    Map<String, dynamic>? data,
  }) async {
    if (!_isInitialized || _initializationFailed) {
      if (kDebugMode) {
        print('Cannot update user profile: Supabase not initialized');
      }
      return;
    }

    try {
      final updateData = {
        ...?data,
        'updated_at': DateTime.now().toIso8601String(),
      };

      await _client!.from('users').update(updateData).eq('id', userId);
    } catch (e) {
      if (kDebugMode) {
        print('Failed to update user profile: $e');
      }
    }
  }

  // ============================================================================
  // TASK METHODS
  // ============================================================================

  /// Save user task
  Future<void> saveUserTask({
    required String userId,
    required Map<String, dynamic> taskData,
  }) async {
    if (!_isInitialized || _initializationFailed) {
      if (kDebugMode) {
        print('Cannot save task: Supabase not initialized');
      }
      return;
    }

    try {
      final task = {
        'user_id': userId,
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
        ...taskData,
      };

      await _client!.from('tasks').insert(task);
    } catch (e) {
      if (kDebugMode) {
        print('Failed to save task: $e');
      }
    }
  }

  /// Get user tasks
  Future<List<Map<String, dynamic>>> getUserTasks(String userId) async {
    if (!_isInitialized || _initializationFailed) {
      if (kDebugMode) {
        print('Cannot get tasks: Supabase not initialized');
      }
      return [];
    }

    try {
      final response = await _client!
          .from('tasks')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      if (kDebugMode) {
        print('Failed to get tasks: $e');
      }
      return [];
    }
  }

  /// Update user task
  Future<void> updateUserTask({
    required String taskId,
    required Map<String, dynamic> updates,
  }) async {
    if (!_isInitialized || _initializationFailed) {
      if (kDebugMode) {
        print('Cannot update task: Supabase not initialized');
      }
      return;
    }

    try {
      final updateData = {
        ...updates,
        'updated_at': DateTime.now().toIso8601String(),
      };

      await _client!.from('tasks').update(updateData).eq('id', taskId);
    } catch (e) {
      if (kDebugMode) {
        print('Failed to update task: $e');
      }
    }
  }

  /// Delete user task
  Future<void> deleteUserTask(String taskId) async {
    if (!_isInitialized || _initializationFailed) {
      if (kDebugMode) {
        print('Cannot delete task: Supabase not initialized');
      }
      return;
    }

    try {
      await _client!.from('tasks').delete().eq('id', taskId);
    } catch (e) {
      if (kDebugMode) {
        print('Failed to delete task: $e');
      }
    }
  }

  // ============================================================================
  // FOCUS SESSION METHODS
  // ============================================================================

  /// Save focus session
  Future<void> saveFocusSession({
    required String userId,
    required Map<String, dynamic> sessionData,
  }) async {
    if (!_isInitialized || _initializationFailed) {
      if (kDebugMode) {
        print('Cannot save focus session: Supabase not initialized');
      }
      return;
    }

    try {
      final session = {
        'user_id': userId,
        'created_at': DateTime.now().toIso8601String(),
        ...sessionData,
      };

      await _client!.from('focus_sessions').insert(session);
    } catch (e) {
      if (kDebugMode) {
        print('Failed to save focus session: $e');
      }
    }
  }

  /// Get user focus sessions
  Future<List<Map<String, dynamic>>> getUserFocusSessions(String userId) async {
    if (!_isInitialized || _initializationFailed) {
      if (kDebugMode) {
        print('Cannot get focus sessions: Supabase not initialized');
      }
      return [];
    }

    try {
      final response = await _client!
          .from('focus_sessions')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      if (kDebugMode) {
        print('Failed to get user focus sessions: $e');
      }
      return [];
    }
  }

  // ============================================================================
  // SETTINGS AND STATS METHODS
  // ============================================================================

  /// Update user settings
  Future<void> updateUserSettings({
    required String userId,
    required Map<String, dynamic> settings,
  }) async {
    if (!_isInitialized || _initializationFailed) {
      if (kDebugMode) {
        print('Cannot update user settings: Supabase not initialized');
      }
      return;
    }

    try {
      await _client!.from('users').update({
        'settings': settings,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', userId);
    } catch (e) {
      if (kDebugMode) {
        print('Failed to update user settings: $e');
      }
    }
  }

  /// Update user stats
  Future<void> updateUserStats({
    required String userId,
    required Map<String, dynamic> stats,
  }) async {
    if (!_isInitialized || _initializationFailed) {
      if (kDebugMode) {
        print('Cannot update user stats: Supabase not initialized');
      }
      return;
    }

    try {
      await _client!.from('users').update({
        'stats': stats,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', userId);
    } catch (e) {
      if (kDebugMode) {
        print('Failed to update user stats: $e');
      }
    }
  }

  // ============================================================================
  // FILE UPLOAD METHODS
  // ============================================================================

  /// Upload file to storage
  Future<String?> uploadFile({
    required String bucketName,
    required String fileName,
    required Uint8List fileBytes,
    String? mimeType,
  }) async {
    if (!_isInitialized || _initializationFailed) {
      if (kDebugMode) {
        print('Cannot upload file: Supabase not initialized');
      }
      return null;
    }

    try {
      await _client!.storage.from(bucketName).uploadBinary(
        fileName,
        fileBytes,
        fileOptions: supabase.FileOptions(
          contentType: mimeType,
          cacheControl: '3600',
        ),
      );

      // Get public URL
      final publicUrl = _client!.storage.from(bucketName).getPublicUrl(fileName);
      return publicUrl;
    } catch (e) {
      if (kDebugMode) {
        print('Failed to upload file: $e');
      }
      return null;
    }
  }

  /// Delete file from storage
  Future<bool> deleteFile({
    required String bucketName,
    required String fileName,
  }) async {
    if (!_isInitialized || _initializationFailed) {
      if (kDebugMode) {
        print('Cannot delete file: Supabase not initialized');
      }
      return false;
    }

    try {
      await _client!.storage.from(bucketName).remove([fileName]);
      return true;
    } catch (e) {
      if (kDebugMode) {
        print('Failed to delete file: $e');
      }
      return false;
    }
  }

  // ============================================================================
  // REAL-TIME SUBSCRIPTIONS
  // ============================================================================

  /// Subscribe to user data changes
  supabase.RealtimeChannel? subscribeToUserData({
    required String userId,
    required void Function(Map<String, dynamic>) onUpdate,
  }) {
    if (!_isInitialized || _initializationFailed) {
      if (kDebugMode) {
        print('Cannot subscribe: Supabase not initialized');
      }
      return null;
    }

    try {
      return _client!
          .channel('user_data_$userId')
          .onPostgresChanges(
        event: supabase.PostgresChangeEvent.all,
        schema: 'public',
        table: 'users',
        filter: supabase.PostgresChangeFilter(
          type: supabase.PostgresChangeFilterType.eq,
          column: 'id',
          value: userId,
        ),
        callback: (payload) {
          onUpdate(payload.newRecord);
        },
      )
          .subscribe();
    } catch (e) {
      if (kDebugMode) {
        print('Failed to subscribe to user data: $e');
      }
      return null;
    }
  }

  /// Subscribe to task changes
  supabase.RealtimeChannel? subscribeToTasks({
    required String userId,
    required void Function(Map<String, dynamic>) onUpdate,
  }) {
    if (!_isInitialized || _initializationFailed) {
      if (kDebugMode) {
        print('Cannot subscribe: Supabase not initialized');
      }
      return null;
    }

    try {
      return _client!
          .channel('tasks_$userId')
          .onPostgresChanges(
        event: supabase.PostgresChangeEvent.all,
        schema: 'public',
        table: 'tasks',
        filter: supabase.PostgresChangeFilter(
          type: supabase.PostgresChangeFilterType.eq,
          column: 'user_id',
          value: userId,
        ),
        callback: (payload) {
          onUpdate(payload.newRecord);
        },
      )
          .subscribe();
    } catch (e) {
      if (kDebugMode) {
        print('Failed to subscribe to tasks: $e');
      }
      return null;
    }
  }

  // ============================================================================
  // ANALYTICS AND REPORTING
  // ============================================================================

  /// Get user analytics data
  Future<Map<String, dynamic>> getUserAnalytics({
    required String userId,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    if (!_isInitialized || _initializationFailed) {
      return {};
    }

    try {
      final start = startDate ?? DateTime.now().subtract(const Duration(days: 30));
      final end = endDate ?? DateTime.now();

      // Get tasks completed
      final tasksResponse = await _client!
          .from('tasks')
          .select('id, completed_at')
          .eq('user_id', userId)
          .gte('completed_at', start.toIso8601String())
          .lte('completed_at', end.toIso8601String());

      // Get focus sessions
      final focusResponse = await _client!
          .from('focus_sessions')
          .select('id, duration, created_at')
          .eq('user_id', userId)
          .gte('created_at', start.toIso8601String())
          .lte('created_at', end.toIso8601String());

      final tasks = List<Map<String, dynamic>>.from(tasksResponse);
      final focusSessions = List<Map<String, dynamic>>.from(focusResponse);

      return {
        'tasks_completed': tasks.length,
        'focus_sessions': focusSessions.length,
        'total_focus_time': focusSessions.fold<int>(
          0,
              (sum, session) => sum + (session['duration'] as int? ?? 0),
        ),
        'date_range': {
          'start': start.toIso8601String(),
          'end': end.toIso8601String(),
        },
      };
    } catch (e) {
      if (kDebugMode) {
        print('Failed to get user analytics: $e');
      }
      return {};
    }
  }

  // ============================================================================
  // UTILITY METHODS
  // ============================================================================

  /// Check service health
  Future<bool> checkHealth() async {
    if (!_isInitialized || _initializationFailed) {
      return false;
    }

    try {
      // Simple query to check if service is responsive
      await _client!.from('users').select('id').limit(1);
      return true;
    } catch (e) {
      if (kDebugMode) {
        print('Supabase health check failed: $e');
      }
      return false;
    }
  }

  /// Get service status
  Map<String, dynamic> getStatus() {
    return {
      'initialized': _isInitialized,
      'initialization_failed': _initializationFailed,
      'configured': EnvironmentConfig.isSupabaseConfigured,
      'client_available': _client != null,
      'url': EnvironmentConfig.supabaseUrl,
    };
  }

  /// Reset service state (for testing)
  void reset() {
    _isInitialized = false;
    _initializationFailed = false;
    _client = null;
  }
}