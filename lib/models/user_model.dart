import 'package:flutter/foundation.dart';

// ============================================================================
// USER AUTHENTICATION MODELS
// ============================================================================

/// Base User class for authentication
/// This represents the authenticated user from various providers (email, OAuth, etc.)
class User {
  final String id;
  final String? email;
  final String? displayName;
  final String? photoURL;
  final bool emailVerified;
  final Map<String, dynamic> metadata;
  final DateTime createdAt;
  final DateTime? lastSignInAt;
  final String? phoneNumber;
  final List<UserProvider> providers;

  const User({
    required this.id,
    this.email,
    this.displayName,
    this.photoURL,
    this.emailVerified = false,
    this.metadata = const {},
    required this.createdAt,
    this.lastSignInAt,
    this.phoneNumber,
    this.providers = const [],
  });

  /// Create User from JSON (e.g., from Supabase response)
  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] ?? '',
      email: json['email'],
      displayName: json['user_metadata']?['display_name'] ??
          json['user_metadata']?['full_name'] ??
          json['user_metadata']?['name'],
      photoURL: json['user_metadata']?['avatar_url'] ??
          json['user_metadata']?['picture'],
      emailVerified: json['email_confirmed_at'] != null ||
          json['email_verified'] == true,
      metadata: Map<String, dynamic>.from(json['user_metadata'] ?? {}),
      createdAt: DateTime.tryParse(json['created_at'] ?? '') ?? DateTime.now(),
      lastSignInAt: json['last_sign_in_at'] != null
          ? DateTime.tryParse(json['last_sign_in_at'])
          : null,
      phoneNumber: json['phone'],
      providers: _parseProviders(json['identities'] ?? []),
    );
  }

  /// Convert User to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'display_name': displayName,
      'photo_url': photoURL,
      'email_verified': emailVerified,
      'metadata': metadata,
      'created_at': createdAt.toIso8601String(),
      'last_sign_in_at': lastSignInAt?.toIso8601String(),
      'phone_number': phoneNumber,
      'providers': providers.map((p) => p.toJson()).toList(),
    };
  }

  /// Create a copy of User with updated fields
  User copyWith({
    String? id,
    String? email,
    String? displayName,
    String? photoURL,
    bool? emailVerified,
    Map<String, dynamic>? metadata,
    DateTime? createdAt,
    DateTime? lastSignInAt,
    String? phoneNumber,
    List<UserProvider>? providers,
  }) {
    return User(
      id: id ?? this.id,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      photoURL: photoURL ?? this.photoURL,
      emailVerified: emailVerified ?? this.emailVerified,
      metadata: metadata ?? this.metadata,
      createdAt: createdAt ?? this.createdAt,
      lastSignInAt: lastSignInAt ?? this.lastSignInAt,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      providers: providers ?? this.providers,
    );
  }

  /// Get the primary email for the user
  String? get primaryEmail => email;

  /// Get the user's full name
  String? get fullName => displayName;

  /// Get the user's first name
  String? get firstName {
    if (displayName == null) return null;
    final parts = displayName!.split(' ');
    return parts.isNotEmpty ? parts.first : null;
  }

  /// Get the user's last name
  String? get lastName {
    if (displayName == null) return null;
    final parts = displayName!.split(' ');
    return parts.length > 1 ? parts.skip(1).join(' ') : null;
  }

  /// Check if user has a specific provider
  bool hasProvider(String providerId) {
    return providers.any((p) => p.provider == providerId);
  }

  /// Get initials for avatar
  String get initials {
    if (displayName != null && displayName!.isNotEmpty) {
      final parts = displayName!.trim().split(' ');
      if (parts.length >= 2) {
        return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
      } else if (parts.isNotEmpty) {
        return parts.first[0].toUpperCase();
      }
    }
    if (email != null && email!.isNotEmpty) {
      return email![0].toUpperCase();
    }
    return 'U';
  }

  static List<UserProvider> _parseProviders(List<dynamic> identities) {
    return identities.map((identity) {
      return UserProvider.fromJson(Map<String, dynamic>.from(identity));
    }).toList();
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is User && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'User(id: $id, email: $email, displayName: $displayName, emailVerified: $emailVerified)';
  }
}

/// Extended User class with application-specific data
/// This extends the base User with app-specific preferences and data
class AppUser extends User {
  final UserPreferences preferences;
  final UserStats stats;
  final UserSubscription? subscription;
  final DateTime lastActiveAt;
  final String? timezone;
  final String? locale;
  final Map<String, dynamic> appMetadata;

  const AppUser({
    required String id,
    String? email,
    String? displayName,
    String? photoURL,
    bool emailVerified = false,
    Map<String, dynamic> metadata = const {},
    required DateTime createdAt,
    DateTime? lastSignInAt,
    String? phoneNumber,
    List<UserProvider> providers = const [],
    required this.preferences,
    required this.stats,
    this.subscription,
    required this.lastActiveAt,
    this.timezone,
    this.locale,
    this.appMetadata = const {},
  }) : super(
    id: id,
    email: email,
    displayName: displayName,
    photoURL: photoURL,
    emailVerified: emailVerified,
    metadata: metadata,
    createdAt: createdAt,
    lastSignInAt: lastSignInAt,
    phoneNumber: phoneNumber,
    providers: providers,
  );

  /// Create AppUser from base User and additional app data
  factory AppUser.fromUser(
      User user, {
        UserPreferences? preferences,
        UserStats? stats,
        UserSubscription? subscription,
        DateTime? lastActiveAt,
        String? timezone,
        String? locale,
        Map<String, dynamic> appMetadata = const {},
      }) {
    return AppUser(
      id: user.id,
      email: user.email,
      displayName: user.displayName,
      photoURL: user.photoURL,
      emailVerified: user.emailVerified,
      metadata: user.metadata,
      createdAt: user.createdAt,
      lastSignInAt: user.lastSignInAt,
      phoneNumber: user.phoneNumber,
      providers: user.providers,
      preferences: preferences ?? UserPreferences.defaultPreferences(),
      stats: stats ?? UserStats.empty(),
      subscription: subscription,
      lastActiveAt: lastActiveAt ?? DateTime.now(),
      timezone: timezone,
      locale: locale,
      appMetadata: appMetadata,
    );
  }

  /// Create AppUser from JSON
  factory AppUser.fromJson(Map<String, dynamic> json) {
    final baseUser = User.fromJson(json);

    return AppUser(
      id: baseUser.id,
      email: baseUser.email,
      displayName: baseUser.displayName,
      photoURL: baseUser.photoURL,
      emailVerified: baseUser.emailVerified,
      metadata: baseUser.metadata,
      createdAt: baseUser.createdAt,
      lastSignInAt: baseUser.lastSignInAt,
      phoneNumber: baseUser.phoneNumber,
      providers: baseUser.providers,
      preferences: UserPreferences.fromJson(json['preferences'] ?? {}),
      stats: UserStats.fromJson(json['stats'] ?? {}),
      subscription: json['subscription'] != null
          ? UserSubscription.fromJson(json['subscription'])
          : null,
      lastActiveAt: DateTime.tryParse(json['last_active_at'] ?? '') ?? DateTime.now(),
      timezone: json['timezone'],
      locale: json['locale'],
      appMetadata: Map<String, dynamic>.from(json['app_metadata'] ?? {}),
    );
  }

  /// Convert AppUser to JSON
  @override
  Map<String, dynamic> toJson() {
    final json = super.toJson();
    json.addAll({
      'preferences': preferences.toJson(),
      'stats': stats.toJson(),
      'subscription': subscription?.toJson(),
      'last_active_at': lastActiveAt.toIso8601String(),
      'timezone': timezone,
      'locale': locale,
      'app_metadata': appMetadata,
    });
    return json;
  }

  /// Create a copy of AppUser with updated fields
  AppUser copyWith({
    String? id,
    String? email,
    String? displayName,
    String? photoURL,
    bool? emailVerified,
    Map<String, dynamic>? metadata,
    DateTime? createdAt,
    DateTime? lastSignInAt,
    String? phoneNumber,
    List<UserProvider>? providers,
    UserPreferences? preferences,
    UserStats? stats,
    UserSubscription? subscription,
    DateTime? lastActiveAt,
    String? timezone,
    String? locale,
    Map<String, dynamic>? appMetadata,
  }) {
    return AppUser(
      id: id ?? this.id,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      photoURL: photoURL ?? this.photoURL,
      emailVerified: emailVerified ?? this.emailVerified,
      metadata: metadata ?? this.metadata,
      createdAt: createdAt ?? this.createdAt,
      lastSignInAt: lastSignInAt ?? this.lastSignInAt,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      providers: providers ?? this.providers,
      preferences: preferences ?? this.preferences,
      stats: stats ?? this.stats,
      subscription: subscription ?? this.subscription,
      lastActiveAt: lastActiveAt ?? this.lastActiveAt,
      timezone: timezone ?? this.timezone,
      locale: locale ?? this.locale,
      appMetadata: appMetadata ?? this.appMetadata,
    );
  }

  /// Check if user has premium subscription
  bool get isPremium => subscription?.isActive == true;

  /// Check if user is new (created in last 7 days)
  bool get isNewUser => DateTime.now().difference(createdAt).inDays <= 7;

  /// Check if user is active (last active in last 30 days)
  bool get isActive => DateTime.now().difference(lastActiveAt).inDays <= 30;

  @override
  String toString() {
    return 'AppUser(id: $id, email: $email, displayName: $displayName, isPremium: $isPremium, isActive: $isActive)';
  }
}

// ============================================================================
// SUPPORTING CLASSES
// ============================================================================

/// User authentication provider information
class UserProvider {
  final String provider;
  final String providerId;
  final DateTime createdAt;
  final DateTime? lastSignInAt;
  final Map<String, dynamic> metadata;

  const UserProvider({
    required this.provider,
    required this.providerId,
    required this.createdAt,
    this.lastSignInAt,
    this.metadata = const {},
  });

  factory UserProvider.fromJson(Map<String, dynamic> json) {
    return UserProvider(
      provider: json['provider'] ?? '',
      providerId: json['id'] ?? '',
      createdAt: DateTime.tryParse(json['created_at'] ?? '') ?? DateTime.now(),
      lastSignInAt: json['last_sign_in_at'] != null
          ? DateTime.tryParse(json['last_sign_in_at'])
          : null,
      metadata: Map<String, dynamic>.from(json['identity_data'] ?? {}),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'provider': provider,
      'id': providerId,
      'created_at': createdAt.toIso8601String(),
      'last_sign_in_at': lastSignInAt?.toIso8601String(),
      'identity_data': metadata,
    };
  }
}

/// User preferences for app customization
class UserPreferences {
  final String theme; // 'light', 'dark', 'system'
  final bool notificationsEnabled;
  final bool emailNotificationsEnabled;
  final bool pushNotificationsEnabled;
  final String defaultFocusDuration; // '25', '45', '60' minutes
  final String defaultBreakDuration; // '5', '10', '15' minutes
  final bool soundEnabled;
  final String soundType; // 'bell', 'chime', 'nature'
  final int dailyGoalHours; // Default daily focus goal in hours
  final String workdayStart; // HH:mm format
  final String workdayEnd; // HH:mm format
  final List<String> workdays; // ['monday', 'tuesday', ...]
  final String timeFormat; // '12h', '24h'
  final String dateFormat; // 'MM/dd/yyyy', 'dd/MM/yyyy', 'yyyy-MM-dd'
  final bool autoStartBreaks;
  final bool autoStartPomodoros;
  final Map<String, dynamic> customSettings;

  const UserPreferences({
    this.theme = 'system',
    this.notificationsEnabled = true,
    this.emailNotificationsEnabled = true,
    this.pushNotificationsEnabled = true,
    this.defaultFocusDuration = '25',
    this.defaultBreakDuration = '5',
    this.soundEnabled = true,
    this.soundType = 'bell',
    this.dailyGoalHours = 8,
    this.workdayStart = '09:00',
    this.workdayEnd = '17:00',
    this.workdays = const ['monday', 'tuesday', 'wednesday', 'thursday', 'friday'],
    this.timeFormat = '12h',
    this.dateFormat = 'MM/dd/yyyy',
    this.autoStartBreaks = false,
    this.autoStartPomodoros = false,
    this.customSettings = const {},
  });

  factory UserPreferences.defaultPreferences() {
    return const UserPreferences();
  }

  factory UserPreferences.fromJson(Map<String, dynamic> json) {
    return UserPreferences(
      theme: json['theme'] ?? 'system',
      notificationsEnabled: json['notifications_enabled'] ?? true,
      emailNotificationsEnabled: json['email_notifications_enabled'] ?? true,
      pushNotificationsEnabled: json['push_notifications_enabled'] ?? true,
      defaultFocusDuration: json['default_focus_duration'] ?? '25',
      defaultBreakDuration: json['default_break_duration'] ?? '5',
      soundEnabled: json['sound_enabled'] ?? true,
      soundType: json['sound_type'] ?? 'bell',
      dailyGoalHours: json['daily_goal_hours'] ?? 8,
      workdayStart: json['workday_start'] ?? '09:00',
      workdayEnd: json['workday_end'] ?? '17:00',
      workdays: List<String>.from(json['workdays'] ??
          ['monday', 'tuesday', 'wednesday', 'thursday', 'friday']),
      timeFormat: json['time_format'] ?? '12h',
      dateFormat: json['date_format'] ?? 'MM/dd/yyyy',
      autoStartBreaks: json['auto_start_breaks'] ?? false,
      autoStartPomodoros: json['auto_start_pomodoros'] ?? false,
      customSettings: Map<String, dynamic>.from(json['custom_settings'] ?? {}),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'theme': theme,
      'notifications_enabled': notificationsEnabled,
      'email_notifications_enabled': emailNotificationsEnabled,
      'push_notifications_enabled': pushNotificationsEnabled,
      'default_focus_duration': defaultFocusDuration,
      'default_break_duration': defaultBreakDuration,
      'sound_enabled': soundEnabled,
      'sound_type': soundType,
      'daily_goal_hours': dailyGoalHours,
      'workday_start': workdayStart,
      'workday_end': workdayEnd,
      'workdays': workdays,
      'time_format': timeFormat,
      'date_format': dateFormat,
      'auto_start_breaks': autoStartBreaks,
      'auto_start_pomodoros': autoStartPomodoros,
      'custom_settings': customSettings,
    };
  }

  UserPreferences copyWith({
    String? theme,
    bool? notificationsEnabled,
    bool? emailNotificationsEnabled,
    bool? pushNotificationsEnabled,
    String? defaultFocusDuration,
    String? defaultBreakDuration,
    bool? soundEnabled,
    String? soundType,
    int? dailyGoalHours,
    String? workdayStart,
    String? workdayEnd,
    List<String>? workdays,
    String? timeFormat,
    String? dateFormat,
    bool? autoStartBreaks,
    bool? autoStartPomodoros,
    Map<String, dynamic>? customSettings,
  }) {
    return UserPreferences(
      theme: theme ?? this.theme,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      emailNotificationsEnabled: emailNotificationsEnabled ?? this.emailNotificationsEnabled,
      pushNotificationsEnabled: pushNotificationsEnabled ?? this.pushNotificationsEnabled,
      defaultFocusDuration: defaultFocusDuration ?? this.defaultFocusDuration,
      defaultBreakDuration: defaultBreakDuration ?? this.defaultBreakDuration,
      soundEnabled: soundEnabled ?? this.soundEnabled,
      soundType: soundType ?? this.soundType,
      dailyGoalHours: dailyGoalHours ?? this.dailyGoalHours,
      workdayStart: workdayStart ?? this.workdayStart,
      workdayEnd: workdayEnd ?? this.workdayEnd,
      workdays: workdays ?? this.workdays,
      timeFormat: timeFormat ?? this.timeFormat,
      dateFormat: dateFormat ?? this.dateFormat,
      autoStartBreaks: autoStartBreaks ?? this.autoStartBreaks,
      autoStartPomodoros: autoStartPomodoros ?? this.autoStartPomodoros,
      customSettings: customSettings ?? this.customSettings,
    );
  }
}

/// User statistics and achievements
class UserStats {
  final int totalFocusMinutes;
  final int totalSessions;
  final int totalTasksCompleted;
  final int currentStreak;
  final int longestStreak;
  final DateTime? lastSessionDate;
  final Map<String, int> dailyStats; // Date -> minutes focused
  final Map<String, int> weeklyStats; // Week -> minutes focused
  final Map<String, int> monthlyStats; // Month -> minutes focused
  final List<String> achievements;
  final Map<String, dynamic> customStats;

  const UserStats({
    this.totalFocusMinutes = 0,
    this.totalSessions = 0,
    this.totalTasksCompleted = 0,
    this.currentStreak = 0,
    this.longestStreak = 0,
    this.lastSessionDate,
    this.dailyStats = const {},
    this.weeklyStats = const {},
    this.monthlyStats = const {},
    this.achievements = const [],
    this.customStats = const {},
  });

  factory UserStats.empty() {
    return const UserStats();
  }

  factory UserStats.fromJson(Map<String, dynamic> json) {
    return UserStats(
      totalFocusMinutes: json['total_focus_minutes'] ?? 0,
      totalSessions: json['total_sessions'] ?? 0,
      totalTasksCompleted: json['total_tasks_completed'] ?? 0,
      currentStreak: json['current_streak'] ?? 0,
      longestStreak: json['longest_streak'] ?? 0,
      lastSessionDate: json['last_session_date'] != null
          ? DateTime.tryParse(json['last_session_date'])
          : null,
      dailyStats: Map<String, int>.from(json['daily_stats'] ?? {}),
      weeklyStats: Map<String, int>.from(json['weekly_stats'] ?? {}),
      monthlyStats: Map<String, int>.from(json['monthly_stats'] ?? {}),
      achievements: List<String>.from(json['achievements'] ?? []),
      customStats: Map<String, dynamic>.from(json['custom_stats'] ?? {}),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'total_focus_minutes': totalFocusMinutes,
      'total_sessions': totalSessions,
      'total_tasks_completed': totalTasksCompleted,
      'current_streak': currentStreak,
      'longest_streak': longestStreak,
      'last_session_date': lastSessionDate?.toIso8601String(),
      'daily_stats': dailyStats,
      'weekly_stats': weeklyStats,
      'monthly_stats': monthlyStats,
      'achievements': achievements,
      'custom_stats': customStats,
    };
  }

  UserStats copyWith({
    int? totalFocusMinutes,
    int? totalSessions,
    int? totalTasksCompleted,
    int? currentStreak,
    int? longestStreak,
    DateTime? lastSessionDate,
    Map<String, int>? dailyStats,
    Map<String, int>? weeklyStats,
    Map<String, int>? monthlyStats,
    List<String>? achievements,
    Map<String, dynamic>? customStats,
  }) {
    return UserStats(
      totalFocusMinutes: totalFocusMinutes ?? this.totalFocusMinutes,
      totalSessions: totalSessions ?? this.totalSessions,
      totalTasksCompleted: totalTasksCompleted ?? this.totalTasksCompleted,
      currentStreak: currentStreak ?? this.currentStreak,
      longestStreak: longestStreak ?? this.longestStreak,
      lastSessionDate: lastSessionDate ?? this.lastSessionDate,
      dailyStats: dailyStats ?? this.dailyStats,
      weeklyStats: weeklyStats ?? this.weeklyStats,
      monthlyStats: monthlyStats ?? this.monthlyStats,
      achievements: achievements ?? this.achievements,
      customStats: customStats ?? this.customStats,
    );
  }

  /// Get total focus hours
  double get totalFocusHours => totalFocusMinutes / 60.0;

  /// Get average session length in minutes
  double get averageSessionLength =>
      totalSessions > 0 ? totalFocusMinutes / totalSessions : 0.0;

  /// Get focus minutes for today
  int get todayFocusMinutes {
    final today = DateTime.now().toIso8601String().split('T')[0];
    return dailyStats[today] ?? 0;
  }

  /// Get focus minutes for this week
  int get thisWeekFocusMinutes {
    final now = DateTime.now();
    final weekStart = now.subtract(Duration(days: now.weekday - 1));
    final weekKey = weekStart.toIso8601String().split('T')[0];
    return weeklyStats[weekKey] ?? 0;
  }

  /// Get focus minutes for this month
  int get thisMonthFocusMinutes {
    final now = DateTime.now();
    final monthKey = '${now.year}-${now.month.toString().padLeft(2, '0')}';
    return monthlyStats[monthKey] ?? 0;
  }
}

/// User subscription information
class UserSubscription {
  final String id;
  final String planId;
  final String planName;
  final SubscriptionStatus status;
  final DateTime startDate;
  final DateTime? endDate;
  final DateTime? trialEndDate;
  final bool isTrialActive;
  final double monthlyPrice;
  final double yearlyPrice;
  final String currency;
  final Map<String, bool> features;
  final Map<String, dynamic> metadata;

  const UserSubscription({
    required this.id,
    required this.planId,
    required this.planName,
    required this.status,
    required this.startDate,
    this.endDate,
    this.trialEndDate,
    this.isTrialActive = false,
    this.monthlyPrice = 0.0,
    this.yearlyPrice = 0.0,
    this.currency = 'USD',
    this.features = const {},
    this.metadata = const {},
  });

  factory UserSubscription.fromJson(Map<String, dynamic> json) {
    return UserSubscription(
      id: json['id'] ?? '',
      planId: json['plan_id'] ?? '',
      planName: json['plan_name'] ?? '',
      status: SubscriptionStatus.values.firstWhere(
            (s) => s.name == json['status'],
        orElse: () => SubscriptionStatus.inactive,
      ),
      startDate: DateTime.tryParse(json['start_date'] ?? '') ?? DateTime.now(),
      endDate: json['end_date'] != null
          ? DateTime.tryParse(json['end_date'])
          : null,
      trialEndDate: json['trial_end_date'] != null
          ? DateTime.tryParse(json['trial_end_date'])
          : null,
      isTrialActive: json['is_trial_active'] ?? false,
      monthlyPrice: (json['monthly_price'] ?? 0.0).toDouble(),
      yearlyPrice: (json['yearly_price'] ?? 0.0).toDouble(),
      currency: json['currency'] ?? 'USD',
      features: Map<String, bool>.from(json['features'] ?? {}),
      metadata: Map<String, dynamic>.from(json['metadata'] ?? {}),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'plan_id': planId,
      'plan_name': planName,
      'status': status.name,
      'start_date': startDate.toIso8601String(),
      'end_date': endDate?.toIso8601String(),
      'trial_end_date': trialEndDate?.toIso8601String(),
      'is_trial_active': isTrialActive,
      'monthly_price': monthlyPrice,
      'yearly_price': yearlyPrice,
      'currency': currency,
      'features': features,
      'metadata': metadata,
    };
  }

  /// Check if subscription is currently active
  bool get isActive {
    final now = DateTime.now();
    return status == SubscriptionStatus.active &&
        (endDate == null || endDate!.isAfter(now));
  }

  /// Check if trial is still valid
  bool get isTrialValid {
    if (!isTrialActive || trialEndDate == null) return false;
    return DateTime.now().isBefore(trialEndDate!);
  }

  /// Check if subscription is about to expire (within 7 days)
  bool get isExpiringSoon {
    if (endDate == null) return false;
    final daysUntilExpiry = endDate!.difference(DateTime.now()).inDays;
    return daysUntilExpiry <= 7 && daysUntilExpiry > 0;
  }

  /// Get days remaining in subscription
  int get daysRemaining {
    if (endDate == null) return -1;
    final diff = endDate!.difference(DateTime.now()).inDays;
    return diff > 0 ? diff : 0;
  }

  /// Check if user has access to a specific feature
  bool hasFeature(String featureName) {
    return features[featureName] == true;
  }
}

/// Subscription status enumeration
enum SubscriptionStatus {
  active,
  inactive,
  cancelled,
  expired,
  suspended,
  trial,
  pastDue,
}

// ============================================================================
// UTILITY EXTENSIONS
// ============================================================================

/// Extension on User for additional utility methods
extension UserExtensions on User {
  /// Get a display-friendly name
  String get displayNameOrEmail => displayName ?? email ?? 'User';

  /// Get a short display name (first name or email prefix)
  String get shortDisplayName {
    if (firstName != null) return firstName!;
    if (email != null) return email!.split('@')[0];
    return 'User';
  }

  /// Check if user profile is complete
  bool get isProfileComplete {
    return displayName != null &&
        email != null &&
        emailVerified;
  }
}

/// Extension on AppUser for additional utility methods
extension AppUserExtensions on AppUser {
  /// Get productivity level based on stats
  ProductivityLevel get productivityLevel {
    final dailyAverage = stats.totalFocusMinutes /
        (DateTime.now().difference(createdAt).inDays + 1);

    if (dailyAverage >= 240) return ProductivityLevel.expert; // 4+ hours
    if (dailyAverage >= 120) return ProductivityLevel.advanced; // 2+ hours
    if (dailyAverage >= 60) return ProductivityLevel.intermediate; // 1+ hour
    if (dailyAverage >= 25) return ProductivityLevel.beginner; // 25+ minutes
    return ProductivityLevel.newcomer;
  }

  /// Get recommendation for daily goal based on current performance
  int get recommendedDailyGoal {
    final currentAverage = stats.totalFocusMinutes /
        (DateTime.now().difference(createdAt).inDays + 1);

    // Recommend 20% increase from current average, capped at 480 minutes (8 hours)
    final recommended = (currentAverage * 1.2).round();
    return recommended.clamp(25, 480);
  }
}

/// Productivity level enumeration
enum ProductivityLevel {
  newcomer,
  beginner,
  intermediate,
  advanced,
  expert,
}

// ============================================================================
// TYPE ALIASES FOR BACKWARD COMPATIBILITY
// ============================================================================

/// Type alias for backward compatibility
typedef AuthUser = User;