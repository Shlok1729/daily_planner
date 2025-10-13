import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'package:daily_planner/models/focus_session.dart';
import 'package:daily_planner/utils/error_handler.dart';

class FocusHistoryService {
  static final FocusHistoryService _instance = FocusHistoryService._internal();
  factory FocusHistoryService() => _instance;
  FocusHistoryService._internal();

  late Box _sessionsBox;
  late Box _statsBox;
  bool _isInitialized = false;

  /// Initialize the service
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      _sessionsBox = await Hive.openBox('focus_sessions');
      _statsBox = await Hive.openBox('focus_stats');
      _isInitialized = true;

      if (kDebugMode) {
        print('✅ FocusHistoryService initialized');
      }
    } catch (e) {
      if (kDebugMode) {
        print('⚠️ FocusHistoryService initialization failed: $e');
      }
      rethrow;
    }
  }

  /// Save a focus session
  Future<void> saveSession(FocusSession session) async {
    await ErrorHandler.handleAsyncError(() async {
      if (!_isInitialized) await initialize();

      await _sessionsBox.put(session.id, session.toJson());
      await _updateStats();

      if (kDebugMode) {
        print('Focus session saved: ${session.id}');
      }
    }, context: 'Save focus session');
  }

  /// Get recent sessions with optional limit
  Future<List<FocusSession>> getRecentSessions({int? limit}) async {
    return await ErrorHandler.handleAsyncError(() async {
      if (!_isInitialized) await initialize();

      final sessions = <FocusSession>[];

      for (final key in _sessionsBox.keys) {
        final sessionData = _sessionsBox.get(key);
        if (sessionData != null) {
          try {
            final session = FocusSession.fromJson(Map<String, dynamic>.from(sessionData));
            sessions.add(session);
          } catch (e) {
            if (kDebugMode) {
              print('Error parsing session $key: $e');
            }
          }
        }
      }

      // Sort by start time (most recent first)
      sessions.sort((a, b) => b.startTime.compareTo(a.startTime));

      if (limit != null && sessions.length > limit) {
        return sessions.take(limit).toList();
      }

      return sessions;
    }, context: 'Get recent sessions') ?? [];
  }

  /// Get sessions for a specific date
  Future<List<FocusSession>> getSessionsForDate(DateTime date) async {
    return await ErrorHandler.handleAsyncError(() async {
      final allSessions = await getRecentSessions();

      return allSessions.where((session) {
        final sessionDate = DateTime(
          session.startTime.year,
          session.startTime.month,
          session.startTime.day,
        );
        final targetDate = DateTime(date.year, date.month, date.day);
        return sessionDate.isAtSameMomentAs(targetDate);
      }).toList();
    }, context: 'Get sessions for date') ?? [];
  }

  /// Get sessions within a date range
  Future<List<FocusSession>> getSessionsInRange(DateTime start, DateTime end) async {
    return await ErrorHandler.handleAsyncError(() async {
      final allSessions = await getRecentSessions();

      return allSessions.where((session) {
        return session.startTime.isAfter(start) && session.startTime.isBefore(end);
      }).toList();
    }, context: 'Get sessions in range') ?? [];
  }

  /// Get focus statistics for a given period
  Future<FocusStats> getStats({String period = 'week'}) async {
    return await ErrorHandler.handleAsyncError(() async {
      if (!_isInitialized) await initialize();

      final now = DateTime.now();
      late DateTime startDate;

      switch (period) {
        case 'week':
          startDate = now.subtract(Duration(days: 7));
          break;
        case 'month':
          startDate = DateTime(now.year, now.month - 1, now.day);
          break;
        case 'year':
          startDate = DateTime(now.year - 1, now.month, now.day);
          break;
        default:
          startDate = now.subtract(Duration(days: 7));
      }

      final sessions = await getSessionsInRange(startDate, now);
      return _calculateStats(sessions, period);
    }, context: 'Get stats') ?? _getEmptyStats();
  }

  /// Calculate statistics from sessions
  FocusStats _calculateStats(List<FocusSession> sessions, String period) {
    if (sessions.isEmpty) {
      return _getEmptyStats();
    }

    // Basic stats
    final totalSessions = sessions.length;
    final totalFocusTime = sessions.fold<int>(
      0,
          (sum, session) => sum + session.completedDuration,
    );
    final completedSessions = sessions.where((s) => s.wasCompleted).length;
    final completionRate = totalSessions > 0 ? completedSessions / totalSessions : 0.0;
    final averageDuration = totalSessions > 0 ? totalFocusTime ~/ totalSessions : 0;

    // Weekly data (day of week -> minutes)
    final weeklyData = <int, int>{};
    for (int i = 0; i < 7; i++) {
      weeklyData[i] = 0;
    }

    for (final session in sessions) {
      final dayOfWeek = session.startTime.weekday - 1; // 0-6 (Mon-Sun)
      weeklyData[dayOfWeek] = (weeklyData[dayOfWeek] ?? 0) + (session.completedDuration ~/ 60);
    }

    // Find best focus time
    final hourCounts = <int, int>{};
    for (final session in sessions) {
      final hour = session.startTime.hour;
      hourCounts[hour] = (hourCounts[hour] ?? 0) + 1;
    }

    final bestHour = hourCounts.entries.isNotEmpty
        ? hourCounts.entries.reduce((a, b) => a.value > b.value ? a : b).key
        : 9;

    final bestFocusTime = _formatHour(bestHour);

    // Find most productive day
    final dayCounts = <int, int>{};
    for (final session in sessions) {
      final dayOfWeek = session.startTime.weekday;
      dayCounts[dayOfWeek] = (dayCounts[dayOfWeek] ?? 0) + session.completedDuration;
    }

    final mostProductiveDay = dayCounts.entries.isNotEmpty
        ? _getDayName(dayCounts.entries.reduce((a, b) => a.value > b.value ? a : b).key)
        : 'Monday';

    // Calculate streaks
    final currentStreak = _calculateCurrentStreak(sessions);
    final longestStreak = _calculateLongestStreak(sessions);

    // App blocking stats
    final allBlockedApps = sessions
        .where((s) => s.blockedApps != null)
        .expand((s) => s.blockedApps!)
        .toSet();

    final distractionsBlocked = sessions.fold<int>(
      0,
          (sum, session) => sum + (session.blockedApps?.length ?? 0),
    );

    return FocusStats(
      totalSessions: totalSessions,
      totalFocusTime: totalFocusTime,
      completionRate: completionRate,
      averageDuration: averageDuration,
      currentStreak: currentStreak,
      longestStreak: longestStreak,
      weeklyData: weeklyData,
      bestFocusTime: bestFocusTime,
      mostProductiveDay: mostProductiveDay,
      appsBlockedCount: allBlockedApps.length,
      distractionsBlocked: distractionsBlocked,
      lastSessionDate: sessions.isNotEmpty ? sessions.first.startTime : null,
    );
  }

  /// Get empty stats object
  FocusStats _getEmptyStats() {
    return FocusStats(
      totalSessions: 0,
      totalFocusTime: 0,
      completionRate: 0.0,
      averageDuration: 0,
      currentStreak: 0,
      longestStreak: 0,
      weeklyData: {for (int i = 0; i < 7; i++) i: 0},
    );
  }

  /// Calculate current focus streak
  int _calculateCurrentStreak(List<FocusSession> sessions) {
    if (sessions.isEmpty) return 0;

    // Sort sessions by date (most recent first)
    final sortedSessions = List<FocusSession>.from(sessions);
    sortedSessions.sort((a, b) => b.startTime.compareTo(a.startTime));

    final now = DateTime.now();
    var currentDate = DateTime(now.year, now.month, now.day);
    var streak = 0;

    // Group sessions by date
    final sessionsByDate = <DateTime, List<FocusSession>>{};
    for (final session in sortedSessions) {
      final date = DateTime(
        session.startTime.year,
        session.startTime.month,
        session.startTime.day,
      );
      sessionsByDate.putIfAbsent(date, () => []).add(session);
    }

    // Check each day backwards from today
    while (true) {
      final sessionsOnDate = sessionsByDate[currentDate] ?? [];
      final hasCompletedSession = sessionsOnDate.any((s) => s.wasCompleted);

      if (hasCompletedSession) {
        streak++;
        currentDate = currentDate.subtract(Duration(days: 1));
      } else {
        break;
      }
    }

    return streak;
  }

  /// Calculate longest focus streak
  int _calculateLongestStreak(List<FocusSession> sessions) {
    if (sessions.isEmpty) return 0;

    // Group sessions by date
    final sessionsByDate = <DateTime, List<FocusSession>>{};
    for (final session in sessions) {
      final date = DateTime(
        session.startTime.year,
        session.startTime.month,
        session.startTime.day,
      );
      sessionsByDate.putIfAbsent(date, () => []).add(session);
    }

    final dates = sessionsByDate.keys.toList();
    dates.sort();

    var longestStreak = 0;
    var currentStreak = 0;
    DateTime? previousDate;

    for (final date in dates) {
      final sessionsOnDate = sessionsByDate[date] ?? [];
      final hasCompletedSession = sessionsOnDate.any((s) => s.wasCompleted);

      if (hasCompletedSession) {
        if (previousDate == null ||
            date.difference(previousDate).inDays == 1) {
          currentStreak++;
        } else {
          currentStreak = 1;
        }

        longestStreak = currentStreak > longestStreak ? currentStreak : longestStreak;
        previousDate = date;
      } else {
        currentStreak = 0;
      }
    }

    return longestStreak;
  }

  /// Format hour as readable time
  String _formatHour(int hour) {
    if (hour < 6) return 'Early Morning';
    if (hour < 12) return 'Morning';
    if (hour < 17) return 'Afternoon';
    if (hour < 21) return 'Evening';
    return 'Night';
  }

  /// Get day name from weekday number
  String _getDayName(int weekday) {
    const days = [
      'Monday', 'Tuesday', 'Wednesday', 'Thursday',
      'Friday', 'Saturday', 'Sunday'
    ];
    return days[weekday - 1];
  }

  /// Update overall statistics
  Future<void> _updateStats() async {
    await ErrorHandler.handleAsyncError(() async {
      // This could update cached stats or trigger recalculation
      // For now, stats are calculated on-demand
      final lastUpdate = DateTime.now().toIso8601String();
      await _statsBox.put('last_update', lastUpdate);
    }, context: 'Update stats');
  }

  /// Delete a specific session
  Future<void> deleteSession(String sessionId) async {
    await ErrorHandler.handleAsyncError(() async {
      if (!_isInitialized) await initialize();

      await _sessionsBox.delete(sessionId);
      await _updateStats();

      if (kDebugMode) {
        print('Focus session deleted: $sessionId');
      }
    }, context: 'Delete session');
  }

  /// Clear all focus history
  Future<void> clearHistory() async {
    await ErrorHandler.handleAsyncError(() async {
      if (!_isInitialized) await initialize();

      await _sessionsBox.clear();
      await _statsBox.clear();

      if (kDebugMode) {
        print('Focus history cleared');
      }
    }, context: 'Clear history');
  }

  /// Export focus data to JSON file
  Future<void> exportData() async {
    await ErrorHandler.handleAsyncError(() async {
      final sessions = await getRecentSessions();
      final stats = await getStats(period: 'year');

      final exportData = {
        'export_date': DateTime.now().toIso8601String(),
        'sessions': sessions.map((s) => s.toJson()).toList(),
        'stats': stats.toJson(),
      };

      final jsonString = jsonEncode(exportData);

      // Save to device storage
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/focus_history_export.json');
      await file.writeAsString(jsonString);

      if (kDebugMode) {
        print('Focus data exported to: ${file.path}');
      }
    }, context: 'Export data');
  }

  /// Import focus data from JSON
  Future<void> importData(String jsonData) async {
    await ErrorHandler.handleAsyncError(() async {
      if (!_isInitialized) await initialize();

      final data = jsonDecode(jsonData) as Map<String, dynamic>;
      final sessionsData = data['sessions'] as List<dynamic>;

      for (final sessionData in sessionsData) {
        final session = FocusSession.fromJson(
          Map<String, dynamic>.from(sessionData),
        );
        await _sessionsBox.put(session.id, session.toJson());
      }

      await _updateStats();

      if (kDebugMode) {
        print('Focus data imported successfully');
      }
    }, context: 'Import data');
  }

  /// Get service status
  Map<String, dynamic> getStatus() {
    return {
      'initialized': _isInitialized,
      'sessions_count': _sessionsBox.length,
      'last_update': _statsBox.get('last_update'),
    };
  }
}