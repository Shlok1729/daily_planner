import 'package:uuid/uuid.dart';

/// Model class representing a focus session
class FocusSession {
  final String id;
  final String? title;
  final DateTime startTime;
  final DateTime? endTime;
  final int plannedDuration; // in seconds
  final int completedDuration; // in seconds
  final bool wasCompleted;
  final List<String>? blockedApps;
  final String? taskId;
  final Map<String, dynamic>? metadata;

  FocusSession({
    String? id,
    this.title,
    required this.startTime,
    this.endTime,
    required this.plannedDuration,
    this.completedDuration = 0,
    this.wasCompleted = false,
    this.blockedApps,
    this.taskId,
    this.metadata,
  }) : id = id ?? Uuid().v4();

  /// Create a copy of this focus session with optional parameter overrides
  FocusSession copyWith({
    String? title,
    DateTime? startTime,
    DateTime? endTime,
    int? plannedDuration,
    int? completedDuration,
    bool? wasCompleted,
    List<String>? blockedApps,
    String? taskId,
    Map<String, dynamic>? metadata,
  }) {
    return FocusSession(
      id: id,
      title: title ?? this.title,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      plannedDuration: plannedDuration ?? this.plannedDuration,
      completedDuration: completedDuration ?? this.completedDuration,
      wasCompleted: wasCompleted ?? this.wasCompleted,
      blockedApps: blockedApps ?? this.blockedApps,
      taskId: taskId ?? this.taskId,
      metadata: metadata ?? this.metadata,
    );
  }

  /// Convert focus session to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'startTime': startTime.toIso8601String(),
      'endTime': endTime?.toIso8601String(),
      'plannedDuration': plannedDuration,
      'completedDuration': completedDuration,
      'wasCompleted': wasCompleted,
      'blockedApps': blockedApps,
      'taskId': taskId,
      'metadata': metadata,
    };
  }

  /// Create focus session from JSON
  static FocusSession fromJson(Map<String, dynamic> json) {
    return FocusSession(
      id: json['id'],
      title: json['title'],
      startTime: DateTime.parse(json['startTime']),
      endTime: json['endTime'] != null ? DateTime.parse(json['endTime']) : null,
      plannedDuration: json['plannedDuration'] ?? 0,
      completedDuration: json['completedDuration'] ?? 0,
      wasCompleted: json['wasCompleted'] ?? false,
      blockedApps: json['blockedApps'] != null
          ? List<String>.from(json['blockedApps'])
          : null,
      taskId: json['taskId'],
      metadata: json['metadata'] != null
          ? Map<String, dynamic>.from(json['metadata'])
          : null,
    );
  }

  // Computed properties
  Duration get plannedDurationAsDuration => Duration(seconds: plannedDuration);
  Duration get completedDurationAsDuration => Duration(seconds: completedDuration);

  double get completionPercentage {
    if (plannedDuration == 0) return 0.0;
    return (completedDuration / plannedDuration * 100).clamp(0.0, 100.0);
  }

  bool get isInProgress => endTime == null && !wasCompleted;
}

/// Model class representing focus session statistics
class FocusStats {
  final int totalSessions;
  final int totalFocusTime; // in seconds
  final double completionRate; // 0.0 to 1.0
  final int averageDuration; // in seconds
  final int currentStreak; // days
  final int longestStreak; // days
  final Map<int, int> weeklyData; // day of week (0-6) -> minutes
  final String? bestFocusTime; // e.g., "Morning", "9:00 AM"
  final String? mostProductiveDay; // e.g., "Monday"
  final int? appsBlockedCount;
  final int? distractionsBlocked;
  final DateTime? lastSessionDate;

  FocusStats({
    required this.totalSessions,
    required this.totalFocusTime,
    required this.completionRate,
    required this.averageDuration,
    required this.currentStreak,
    required this.longestStreak,
    required this.weeklyData,
    this.bestFocusTime,
    this.mostProductiveDay,
    this.appsBlockedCount,
    this.distractionsBlocked,
    this.lastSessionDate,
  });

  /// Convert focus stats to JSON
  Map<String, dynamic> toJson() {
    return {
      'totalSessions': totalSessions,
      'totalFocusTime': totalFocusTime,
      'completionRate': completionRate,
      'averageDuration': averageDuration,
      'currentStreak': currentStreak,
      'longestStreak': longestStreak,
      'weeklyData': weeklyData,
      'bestFocusTime': bestFocusTime,
      'mostProductiveDay': mostProductiveDay,
      'appsBlockedCount': appsBlockedCount,
      'distractionsBlocked': distractionsBlocked,
      'lastSessionDate': lastSessionDate?.toIso8601String(),
    };
  }

  /// Create focus stats from JSON
  static FocusStats fromJson(Map<String, dynamic> json) {
    return FocusStats(
      totalSessions: json['totalSessions'] ?? 0,
      totalFocusTime: json['totalFocusTime'] ?? 0,
      completionRate: (json['completionRate'] ?? 0.0).toDouble(),
      averageDuration: json['averageDuration'] ?? 0,
      currentStreak: json['currentStreak'] ?? 0,
      longestStreak: json['longestStreak'] ?? 0,
      weeklyData: json['weeklyData'] != null
          ? Map<int, int>.from(json['weeklyData'])
          : {},
      bestFocusTime: json['bestFocusTime'],
      mostProductiveDay: json['mostProductiveDay'],
      appsBlockedCount: json['appsBlockedCount'],
      distractionsBlocked: json['distractionsBlocked'],
      lastSessionDate: json['lastSessionDate'] != null
          ? DateTime.parse(json['lastSessionDate'])
          : null,
    );
  }

  // Computed properties
  Duration get totalFocusTimeAsDuration => Duration(seconds: totalFocusTime);
  Duration get averageDurationAsDuration => Duration(seconds: averageDuration);
}