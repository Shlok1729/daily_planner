import 'package:daily_planner/models/task_model.dart';
import 'package:daily_planner/utils/error_handler.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

// ============================================================================
// ENUMS & TYPES
// ============================================================================

/// Enum for schedule item types
enum ScheduleItemType {
  task,
  break_time,
  meeting,
  focus_session,
  personal,
  meal,
  exercise,
  commute,
  other,
  // Additional enum values
  focus,
  break_,
  routine,
  study,
  leisure,
}

// ============================================================================
// EXTENSIONS
// ============================================================================

/// Extension to get display names, colors, and icons for schedule item types
extension ScheduleItemTypeExtension on ScheduleItemType {
  /// Get display name for the schedule item type
  String get displayName {
    switch (this) {
      case ScheduleItemType.task:
        return 'Task';
      case ScheduleItemType.break_time:
        return 'Break';
      case ScheduleItemType.meeting:
        return 'Meeting';
      case ScheduleItemType.focus_session:
        return 'Focus Session';
      case ScheduleItemType.personal:
        return 'Personal';
      case ScheduleItemType.meal:
        return 'Meal';
      case ScheduleItemType.exercise:
        return 'Exercise';
      case ScheduleItemType.commute:
        return 'Commute';
      case ScheduleItemType.other:
        return 'Other';
      case ScheduleItemType.focus:
        return 'Focus';
      case ScheduleItemType.break_:
        return 'Break Time';
      case ScheduleItemType.routine:
        return 'Routine';
      case ScheduleItemType.study:
        return 'Study';
      case ScheduleItemType.leisure:
        return 'Leisure';
    }
  }

  /// Get color for UI display
  Color get color {
    switch (this) {
      case ScheduleItemType.task:
        return Colors.blue;
      case ScheduleItemType.break_time:
      case ScheduleItemType.break_:
        return Colors.green;
      case ScheduleItemType.meeting:
        return Colors.orange;
      case ScheduleItemType.focus_session:
      case ScheduleItemType.focus:
        return Colors.purple;
      case ScheduleItemType.personal:
        return Colors.teal;
      case ScheduleItemType.meal:
        return Colors.amber;
      case ScheduleItemType.exercise:
        return Colors.red;
      case ScheduleItemType.commute:
        return Colors.grey;
      case ScheduleItemType.other:
        return Colors.blueGrey;
      case ScheduleItemType.routine:
        return Colors.indigo;
      case ScheduleItemType.study:
        return Colors.deepPurple;
      case ScheduleItemType.leisure:
        return Colors.pink;
    }
  }

  /// Get icon for UI display
  IconData get icon {
    switch (this) {
      case ScheduleItemType.task:
        return Icons.task;
      case ScheduleItemType.break_time:
      case ScheduleItemType.break_:
        return Icons.coffee;
      case ScheduleItemType.meeting:
        return Icons.people;
      case ScheduleItemType.focus_session:
      case ScheduleItemType.focus:
        return Icons.center_focus_strong;
      case ScheduleItemType.personal:
        return Icons.person;
      case ScheduleItemType.meal:
        return Icons.restaurant;
      case ScheduleItemType.exercise:
        return Icons.fitness_center;
      case ScheduleItemType.commute:
        return Icons.directions_car;
      case ScheduleItemType.other:
        return Icons.category;
      case ScheduleItemType.routine:
        return Icons.repeat;
      case ScheduleItemType.study:
        return Icons.school;
      case ScheduleItemType.leisure:
        return Icons.sports_esports;
    }
  }
}

// ============================================================================
// MODELS
// ============================================================================

/// Model class for schedule items
class ScheduleItem {
  final String id;
  final String title;
  final String? description;
  final DateTime startTime;
  final DateTime endTime;
  final ScheduleItemType type;
  final TaskPriority? priority;
  final bool isCompleted;
  final String? taskId; // Reference to associated task
  final Map<String, dynamic>? metadata;

  const ScheduleItem({
    required this.id,
    required this.title,
    this.description,
    required this.startTime,
    required this.endTime,
    required this.type,
    this.priority,
    this.isCompleted = false,
    this.taskId,
    this.metadata,
  });

  // ========================================
  // COMPUTED PROPERTIES
  // ========================================

  /// Duration of the schedule item
  Duration get duration => endTime.difference(startTime);

  /// Duration in minutes
  int get durationInMinutes => duration.inMinutes;

  // ========================================
  // SERIALIZATION
  // ========================================

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'startTime': startTime.toIso8601String(),
      'endTime': endTime.toIso8601String(),
      'type': type.name,
      'priority': priority?.name,
      'isCompleted': isCompleted,
      'taskId': taskId,
      'metadata': metadata,
    };
  }

  /// Create from JSON
  factory ScheduleItem.fromJson(Map<String, dynamic> json) {
    return ScheduleItem(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      startTime: DateTime.parse(json['startTime']),
      endTime: DateTime.parse(json['endTime']),
      type: ScheduleItemType.values.firstWhere(
            (e) => e.name == json['type'],
        orElse: () => ScheduleItemType.other,
      ),
      priority: json['priority'] != null
          ? TaskPriority.values.firstWhere(
            (e) => e.name == json['priority'],
        orElse: () => TaskPriority.medium,
      )
          : null,
      isCompleted: json['isCompleted'] ?? false,
      taskId: json['taskId'],
      metadata: json['metadata'] != null
          ? Map<String, dynamic>.from(json['metadata'])
          : null,
    );
  }

  // ========================================
  // COPY METHODS
  // ========================================

  /// Copy with method
  ScheduleItem copyWith({
    String? id,
    String? title,
    String? description,
    DateTime? startTime,
    DateTime? endTime,
    ScheduleItemType? type,
    TaskPriority? priority,
    bool? isCompleted,
    String? taskId,
    Map<String, dynamic>? metadata,
  }) {
    return ScheduleItem(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      type: type ?? this.type,
      priority: priority ?? this.priority,
      isCompleted: isCompleted ?? this.isCompleted,
      taskId: taskId ?? this.taskId,
      metadata: metadata ?? this.metadata,
    );
  }
}

// ============================================================================
// SCHEDULE SERVICE
// ============================================================================

/// Main ScheduleService class for managing schedule items
class ScheduleService {
  // ========================================
  // SINGLETON PATTERN
  // ========================================

  static final ScheduleService _instance = ScheduleService._internal();
  factory ScheduleService() => _instance;
  ScheduleService._internal();

  // ========================================
  // PRIVATE FIELDS
  // ========================================

  late Box _scheduleBox;
  late Box _preferencesBox;
  bool _isInitialized = false;

  // ========================================
  // INITIALIZATION
  // ========================================

  /// Initialize the service
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      _scheduleBox = await Hive.openBox('schedule_items');
      _preferencesBox = await Hive.openBox('schedule_preferences');
      _isInitialized = true;

      if (kDebugMode) {
        print('✅ ScheduleService initialized successfully');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Failed to initialize ScheduleService: $e');
      }
      rethrow;
    }
  }

  // ========================================
  // PUBLIC API METHODS
  // ========================================

  /// Get schedule items for a specific date
  Future<List<ScheduleItem>> getTimeBlocks(DateTime date) async {
    if (!_isInitialized) await initialize();

    return await ErrorHandler.handleAsyncError(() async {
      final dateKey = _dateToKey(date);
      final scheduleData = _scheduleBox.get(dateKey);

      if (scheduleData == null) return <ScheduleItem>[];

      final List<dynamic> itemsJson = scheduleData['items'] ?? [];
      return itemsJson
          .map((json) => ScheduleItem.fromJson(Map<String, dynamic>.from(json)))
          .toList();
    }, context: 'Get time blocks') ?? [];
  }

  /// Generate a new schedule for a given date
  Future<List<ScheduleItem>> generateSchedule({
    required DateTime date,
    required List<Task> tasks,
    required Map<String, dynamic> preferences,
  }) async {
    if (!_isInitialized) await initialize();

    return await ErrorHandler.handleAsyncError(() async {
      final schedule = <ScheduleItem>[];

      // Extract preferences
      final schedulePrefs = _extractSchedulePreferences(preferences);

      // Set up time boundaries
      final timeSlots = _calculateTimeSlots(date, schedulePrefs);

      // Add morning routine
      _addMorningRoutine(schedule, timeSlots);

      // Schedule tasks with breaks
      _scheduleTasksWithBreaks(schedule, tasks, timeSlots, schedulePrefs);

      // Add evening routine
      _addEveningRoutine(schedule, timeSlots);

      return schedule;
    }, context: 'Generate schedule') ?? [];
  }

  /// Save schedule to storage
  Future<void> saveSchedule(DateTime date, List<ScheduleItem> items) async {
    if (!_isInitialized) await initialize();

    await ErrorHandler.handleAsyncError(() async {
      final dateKey = _dateToKey(date);
      final scheduleData = {
        'date': date.toIso8601String(),
        'items': items.map((item) => item.toJson()).toList(),
        'created_at': DateTime.now().toIso8601String(),
      };

      await _scheduleBox.put(dateKey, scheduleData);
    }, context: 'Save schedule');
  }

  /// Get schedule suggestions
  Future<List<String>> getScheduleSuggestions({
    required List<Task> tasks,
    required DateTime targetDate,
  }) async {
    if (!_isInitialized) await initialize();

    return await ErrorHandler.handleAsyncError(() async {
      final suggestions = <String>[];
      final pendingTasks = tasks.where((task) => !task.isCompleted).toList();

      if (pendingTasks.isEmpty) {
        suggestions.addAll(_getEmptyScheduleSuggestions());
      } else {
        suggestions.addAll(_getTaskBasedSuggestions(pendingTasks));
      }

      return suggestions;
    }, context: 'Get schedule suggestions') ?? ['Consider time-blocking your most important tasks'];
  }

  /// Optimize existing schedule
  Future<List<ScheduleItem>> optimizeSchedule(
      List<ScheduleItem> items,
      List<Task> tasks,
      Map<String, dynamic> preferences,
      ) async {
    if (!_isInitialized) await initialize();

    return await ErrorHandler.handleAsyncError(() async {
      final optimizedItems = <ScheduleItem>[];
      final sortedItems = List<ScheduleItem>.from(items);

      // Sort by priority and type
      sortedItems.sort(_compareScheduleItems);

      // Rebuild schedule with optimized order
      var currentTime = sortedItems.first.startTime;

      for (final item in sortedItems) {
        if (_isFixedTimeItem(item)) {
          // Keep meals and breaks in their original time slots
          optimizedItems.add(item);
        } else {
          // Reschedule other items
          final optimizedItem = item.copyWith(
            startTime: currentTime,
            endTime: currentTime.add(item.duration),
          );
          optimizedItems.add(optimizedItem);
          currentTime = optimizedItem.endTime;
        }
      }

      return optimizedItems;
    }, context: 'Optimize schedule') ?? items;
  }

  /// Delete schedule for a specific date
  Future<void> deleteSchedule(DateTime date) async {
    if (!_isInitialized) await initialize();

    await ErrorHandler.handleAsyncError(() async {
      final dateKey = _dateToKey(date);
      await _scheduleBox.delete(dateKey);
    }, context: 'Delete schedule');
  }

  /// Get all scheduled dates
  Future<List<DateTime>> getScheduledDates() async {
    if (!_isInitialized) await initialize();

    return await ErrorHandler.handleAsyncError(() async {
      final dates = <DateTime>[];
      for (final key in _scheduleBox.keys) {
        if (key is String && key.startsWith('schedule_')) {
          final dateStr = key.substring('schedule_'.length);
          try {
            final date = DateTime.parse(dateStr);
            dates.add(date);
          } catch (e) {
            // Skip invalid date keys
          }
        }
      }
      dates.sort();
      return dates;
    }, context: 'Get scheduled dates') ?? [];
  }

  /// Get service status
  Map<String, dynamic> getStatus() {
    return {
      'initialized': _isInitialized,
      'ai_enabled': true, // Since we're using mock AI
      'version': '1.0.0',
      'features': ['schedule_generation', 'optimization', 'suggestions'],
    };
  }

  /// Cleanup method
  Future<void> cleanup() async {
    if (_isInitialized) {
      await _scheduleBox.close();
      await _preferencesBox.close();
      _isInitialized = false;
    }
  }

  // ========================================
  // PRIVATE HELPER METHODS
  // ========================================

  /// Convert date to storage key
  String _dateToKey(DateTime date) {
    return 'schedule_${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  /// Compare task priorities
  int _comparePriority(TaskPriority a, TaskPriority b) {
    const priorityOrder = {
      TaskPriority.high: 0,
      TaskPriority.medium: 1,
      TaskPriority.low: 2,
    };
    return priorityOrder[a]!.compareTo(priorityOrder[b]!);
  }

  /// Estimate task duration based on complexity
  int _estimateTaskDuration(Task task, int defaultDuration) {
    // Simple estimation based on task complexity
    // In a real app, this could be more sophisticated
    if (task.description != null && task.description!.length > 100) {
      return defaultDuration + 15; // Add 15 minutes for complex tasks
    }
    if (task.priority == TaskPriority.high) {
      return defaultDuration + 10; // Add 10 minutes for high priority
    }
    return defaultDuration;
  }

  /// Extract schedule preferences from preferences map
  _SchedulePreferences _extractSchedulePreferences(Map<String, dynamic> preferences) {
    return _SchedulePreferences(
      workStartHour: preferences['work_start_hour'] ?? 9,
      workEndHour: preferences['work_end_hour'] ?? 17,
      breakDuration: preferences['break_duration'] ?? 15,
      lunchDuration: preferences['lunch_duration'] ?? 60,
      focusSessionDuration: preferences['focus_session_duration'] ?? 45,
    );
  }

  /// Calculate time slots for the day
  _TimeSlots _calculateTimeSlots(DateTime date, _SchedulePreferences prefs) {
    final workStart = DateTime(date.year, date.month, date.day, prefs.workStartHour);
    final workEnd = DateTime(date.year, date.month, date.day, prefs.workEndHour);
    final lunchStart = DateTime(date.year, date.month, date.day, 12, 30);

    return _TimeSlots(
      workStart: workStart,
      workEnd: workEnd,
      lunchStart: lunchStart,
      lunchEnd: lunchStart.add(Duration(minutes: prefs.lunchDuration)),
    );
  }

  /// Add morning routine to schedule
  void _addMorningRoutine(List<ScheduleItem> schedule, _TimeSlots timeSlots) {
    schedule.add(ScheduleItem(
      id: 'morning_routine_${timeSlots.workStart.millisecondsSinceEpoch}',
      title: 'Morning Routine',
      description: 'Start your day with intention',
      startTime: timeSlots.workStart.subtract(Duration(hours: 1)),
      endTime: timeSlots.workStart,
      type: ScheduleItemType.routine,
    ));
  }

  /// Schedule tasks with breaks
  void _scheduleTasksWithBreaks(
      List<ScheduleItem> schedule,
      List<Task> tasks,
      _TimeSlots timeSlots,
      _SchedulePreferences prefs,
      ) {
    // Filter and sort tasks by priority
    final pendingTasks = tasks.where((task) => !task.isCompleted).toList();
    pendingTasks.sort((a, b) => _comparePriority(a.priority, b.priority));

    var currentTime = timeSlots.workStart;

    for (int i = 0; i < pendingTasks.length && currentTime.isBefore(timeSlots.workEnd); i++) {
      final task = pendingTasks[i];
      final estimatedDuration = _estimateTaskDuration(task, prefs.focusSessionDuration);

      // Check if we need lunch break
      if (currentTime.hour >= 12 && currentTime.hour < 14) {
        schedule.add(ScheduleItem(
          id: 'lunch_${timeSlots.lunchStart.millisecondsSinceEpoch}',
          title: 'Lunch Break',
          description: 'Take time to recharge',
          startTime: timeSlots.lunchStart,
          endTime: timeSlots.lunchEnd,
          type: ScheduleItemType.meal,
        ));

        currentTime = timeSlots.lunchEnd;
      }

      // Schedule the task
      if (currentTime.add(Duration(minutes: estimatedDuration)).isBefore(timeSlots.workEnd)) {
        schedule.add(ScheduleItem(
          id: 'task_${task.id}_${timeSlots.workStart.millisecondsSinceEpoch}',
          title: task.title,
          description: task.description,
          startTime: currentTime,
          endTime: currentTime.add(Duration(minutes: estimatedDuration)),
          type: ScheduleItemType.task,
          priority: task.priority,
          taskId: task.id,
        ));

        currentTime = currentTime.add(Duration(minutes: estimatedDuration));

        // Add break after task (except for the last task)
        if (i < pendingTasks.length - 1 &&
            currentTime.add(Duration(minutes: prefs.breakDuration)).isBefore(timeSlots.workEnd)) {
          schedule.add(ScheduleItem(
            id: 'break_${i}_${timeSlots.workStart.millisecondsSinceEpoch}',
            title: 'Break',
            description: 'Short break to recharge',
            startTime: currentTime,
            endTime: currentTime.add(Duration(minutes: prefs.breakDuration)),
            type: ScheduleItemType.break_time,
          ));

          currentTime = currentTime.add(Duration(minutes: prefs.breakDuration));
        }
      }
    }
  }

  /// Add evening routine to schedule
  void _addEveningRoutine(List<ScheduleItem> schedule, _TimeSlots timeSlots) {
    schedule.add(ScheduleItem(
      id: 'evening_routine_${timeSlots.workEnd.millisecondsSinceEpoch}',
      title: 'Day Review & Planning',
      description: 'Review accomplishments and plan tomorrow',
      startTime: timeSlots.workEnd.subtract(Duration(minutes: 30)),
      endTime: timeSlots.workEnd,
      type: ScheduleItemType.routine,
    ));
  }

  /// Get suggestions for empty schedule
  List<String> _getEmptyScheduleSuggestions() {
    return [
      'Great! No pending tasks for this day.',
      'Consider adding some personal development activities.',
    ];
  }

  /// Get task-based suggestions
  List<String> _getTaskBasedSuggestions(List<Task> pendingTasks) {
    final suggestions = <String>[];
    final highPriorityTasks = pendingTasks.where((task) => task.priority == TaskPriority.high).length;
    final urgentTasks = pendingTasks.where((task) => task.isUrgent).length;

    if (highPriorityTasks > 0) {
      suggestions.add('You have $highPriorityTasks high-priority tasks. Schedule them during your peak energy hours.');
    }

    if (urgentTasks > 3) {
      suggestions.add('Consider delegating some urgent tasks to manage your workload better.');
    }

    suggestions.addAll([
      'Use the Pomodoro Technique for focused work sessions.',
      'Schedule breaks between tasks to maintain productivity.',
      'Time-block your most important tasks first.',
    ]);

    return suggestions;
  }

  /// Compare schedule items for optimization
  int _compareScheduleItems(ScheduleItem a, ScheduleItem b) {
    // Meals and breaks should stay in their time slots
    if (_isFixedTimeItem(a)) {
      return -1;
    }
    if (_isFixedTimeItem(b)) {
      return 1;
    }

    // Sort tasks by priority
    if (a.priority != null && b.priority != null) {
      return _comparePriority(a.priority!, b.priority!);
    }

    return 0;
  }

  /// Check if item should stay in fixed time slot
  bool _isFixedTimeItem(ScheduleItem item) {
    return item.type == ScheduleItemType.meal ||
        item.type == ScheduleItemType.break_time;
  }
}

// ============================================================================
// PRIVATE HELPER CLASSES
// ============================================================================

/// Internal class for schedule preferences
class _SchedulePreferences {
  final int workStartHour;
  final int workEndHour;
  final int breakDuration;
  final int lunchDuration;
  final int focusSessionDuration;

  const _SchedulePreferences({
    required this.workStartHour,
    required this.workEndHour,
    required this.breakDuration,
    required this.lunchDuration,
    required this.focusSessionDuration,
  });
}

/// Internal class for time slots
class _TimeSlots {
  final DateTime workStart;
  final DateTime workEnd;
  final DateTime lunchStart;
  final DateTime lunchEnd;

  const _TimeSlots({
    required this.workStart,
    required this.workEnd,
    required this.lunchStart,
    required this.lunchEnd,
  });
}