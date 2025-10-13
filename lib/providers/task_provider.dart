import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:daily_planner/models/task_model.dart';
import 'package:daily_planner/services/storage_service.dart';

// ============================================================================
// TASK STATE CLASS
// ============================================================================

/// Represents the state of tasks in the application
class TaskState {
  final List<Task> tasks;
  final bool isLoading;
  final String? error;

  TaskState({
    required this.tasks,
    this.isLoading = false,
    this.error,
  });

  /// Create a copy of the current state with optional modifications
  TaskState copyWith({
    List<Task>? tasks,
    bool? isLoading,
    String? error,
  }) {
    return TaskState(
      tasks: tasks ?? this.tasks,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }

  // ========================================
  // COMPUTED PROPERTIES
  // ========================================

  /// Get all pending (incomplete) tasks
  List<Task> get pendingTasks => tasks.where((task) => !task.isCompleted).toList();

  /// Get all completed tasks
  List<Task> get completedTasks => tasks.where((task) => task.isCompleted).toList();

  /// Get tasks for today
  List<Task> get todayTasks {
    final now = DateTime.now();
    return tasks.where((task) {
      return task.dueDate.year == now.year &&
          task.dueDate.month == now.month &&
          task.dueDate.day == now.day;
    }).toList();
  }

  /// Get high priority tasks
  List<Task> get highPriorityTasks => getTasksByPriority(TaskPriority.high);

  /// Get urgent and important tasks
  List<Task> get urgentImportantTasks =>
      tasks.where((task) => task.isUrgent && task.isImportant).toList();

  // ========================================
  // FILTERING METHODS
  // ========================================

  /// Get tasks for a specific date
  List<Task> getTasksForDate(DateTime date) {
    return tasks.where((task) {
      return task.dueDate.year == date.year &&
          task.dueDate.month == date.month &&
          task.dueDate.day == date.day;
    }).toList();
  }

  /// Get tasks by priority level
  List<Task> getTasksByPriority(TaskPriority priority) {
    return tasks.where((task) => task.priority == priority).toList();
  }
}

// ============================================================================
// TASK NOTIFIER CLASS
// ============================================================================

/// Manages task state and provides methods for task operations
class TaskNotifier extends Notifier<TaskState> {
  // ========================================
  // PRIVATE FIELDS
  // ========================================

  final StorageService _storageService = StorageService();

  // ========================================
  // CONSTRUCTOR & INITIALIZATION
  // ========================================

  @override
  TaskState build() {
    _loadTasks();
    return TaskState(tasks: []);
  }

  /// Load tasks from storage
  Future<void> _loadTasks() async {
    state = state.copyWith(isLoading: true);

    try {
      final tasks = await _storageService.getAllTasks();
      state = state.copyWith(tasks: tasks, isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to load tasks: $e',
      );
    }
  }

  // ========================================
  // CORE CRUD OPERATIONS
  // ========================================

  /// Add a new task
  Future<void> addTask(Task task) async {
    state = state.copyWith(isLoading: true);

    try {
      await _storageService.saveTask(task);
      final updatedTasks = [...state.tasks, task];
      state = state.copyWith(tasks: updatedTasks, isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to add task: $e',
      );
    }
  }

  /// Update an existing task
  Future<void> updateTask(Task task) async {
    state = state.copyWith(isLoading: true);

    try {
      await _storageService.saveTask(task);
      final updatedTasks = state.tasks.map((t) {
        return t.id == task.id ? task : t;
      }).toList();
      state = state.copyWith(tasks: updatedTasks, isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to update task: $e',
      );
    }
  }

  /// Delete a task
  Future<void> deleteTask(String taskId) async {
    state = state.copyWith(isLoading: true);

    try {
      await _storageService.deleteTask(taskId);
      final updatedTasks = state.tasks.where((t) => t.id != taskId).toList();
      state = state.copyWith(tasks: updatedTasks, isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to delete task: $e',
      );
    }
  }

  /// Duplicate a task
  Future<void> duplicateTask(String taskId) async {
    final task = state.tasks.firstWhere((t) => t.id == taskId);
    final duplicatedTask = Task(
      title: '${task.title} (Copy)',
      description: task.description,
      dueDate: task.dueDate,
      dueTime: task.dueTime,
      priority: task.priority,
      category: task.category,
      isCompleted: false,
      isUrgent: task.isUrgent,
      isImportant: task.isImportant,
      createdAt: DateTime.now(),
      completedAt: null,
    );
    await addTask(duplicatedTask);
  }

  // ========================================
  // TASK STATUS OPERATIONS
  // ========================================

  /// Toggle task completion status
  Future<void> toggleTask(String taskId) async {
    final task = state.tasks.firstWhere((t) => t.id == taskId);
    final updatedTask = task.copyWith(
      isCompleted: !task.isCompleted,
      completedAt: !task.isCompleted ? DateTime.now() : null,
    );
    await updateTask(updatedTask);
  }

  /// Alternative method name for compatibility
  Future<void> toggleTaskCompletion(String taskId) async {
    await toggleTask(taskId);
  }

  /// Complete a task
  Future<void> completeTask(String taskId) async {
    final task = state.tasks.firstWhere((t) => t.id == taskId);
    final updatedTask = task.copyWith(
      isCompleted: true,
      completedAt: DateTime.now(),
    );
    await updateTask(updatedTask);
  }

  /// Mark task as urgent
  Future<void> markTaskAsUrgent(String taskId) async {
    final task = state.tasks.firstWhere(
          (t) => t.id == taskId,
      orElse: () => throw Exception('Task not found'),
    );
    final updatedTask = task.copyWith(isUrgent: true);
    await updateTask(updatedTask);
  }

  /// Mark task as urgent (alternative method name)
  Future<void> markAsUrgent(String taskId) async {
    final task = state.tasks.firstWhere((t) => t.id == taskId);
    final updatedTask = task.copyWith(isUrgent: true);
    await updateTask(updatedTask);
  }

  /// Mark task as important
  Future<void> markAsImportant(String taskId) async {
    final task = state.tasks.firstWhere((t) => t.id == taskId);
    final updatedTask = task.copyWith(isImportant: true);
    await updateTask(updatedTask);
  }

  /// Update task priority
  Future<void> updateTaskPriority(String taskId, TaskPriority priority) async {
    final task = state.tasks.firstWhere((t) => t.id == taskId);
    final updatedTask = task.copyWith(priority: priority);
    await updateTask(updatedTask);
  }

  // ========================================
  // BULK OPERATIONS
  // ========================================

  /// Clear all completed tasks
  Future<void> clearCompleted() async {
    state = state.copyWith(isLoading: true);

    try {
      final completedTasks = state.tasks.where((task) => task.isCompleted).toList();

      // Delete completed tasks from storage
      for (final task in completedTasks) {
        await _storageService.deleteTask(task.id);
      }

      // Update state with only pending tasks
      final pendingTasks = state.tasks.where((task) => !task.isCompleted).toList();
      state = state.copyWith(tasks: pendingTasks, isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to clear completed tasks: $e',
      );
    }
  }

  /// Delete multiple tasks
  Future<void> deleteMultipleTasks(List<String> taskIds) async {
    state = state.copyWith(isLoading: true);

    try {
      for (final taskId in taskIds) {
        await _storageService.deleteTask(taskId);
      }

      final updatedTasks = state.tasks.where((task) => !taskIds.contains(task.id)).toList();
      state = state.copyWith(tasks: updatedTasks, isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to delete tasks: $e',
      );
    }
  }

  /// Mark multiple tasks as completed
  Future<void> markMultipleAsCompleted(List<String> taskIds) async {
    state = state.copyWith(isLoading: true);

    try {
      final updatedTasks = state.tasks.map((task) {
        if (taskIds.contains(task.id)) {
          final updatedTask = task.copyWith(
            isCompleted: true,
            completedAt: DateTime.now(),
          );
          _storageService.saveTask(updatedTask); // Save to storage
          return updatedTask;
        }
        return task;
      }).toList();

      state = state.copyWith(tasks: updatedTasks, isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to complete tasks: $e',
      );
    }
  }

  /// Archive completed tasks (move to separate storage)
  Future<void> archiveCompletedTasks() async {
    // Implementation would move completed tasks to archive storage
    await clearCompleted();
  }

  // ========================================
  // SEARCH & FILTERING
  // ========================================

  /// Filter tasks by search query
  List<Task> searchTasks(String query) {
    if (query.isEmpty) return state.tasks;

    final lowerQuery = query.toLowerCase();
    return state.tasks.where((task) {
      return task.title.toLowerCase().contains(lowerQuery) ||
          task.description.toLowerCase().contains(lowerQuery);
    }).toList();
  }

  /// Get tasks for a specific date
  List<Task> getTasksForDate(DateTime date) {
    return state.tasks.where((task) {
      return task.dueDate.year == date.year &&
          task.dueDate.month == date.month &&
          task.dueDate.day == date.day;
    }).toList();
  }

  /// Filter tasks with multiple criteria
  List<Task> filterTasks({
    TaskPriority? priority,
    bool? isCompleted,
    bool? isUrgent,
    bool? isImportant,
    DateTime? dueBefore,
    DateTime? dueAfter,
  }) {
    return state.tasks.where((task) {
      if (priority != null && task.priority != priority) return false;
      if (isCompleted != null && task.isCompleted != isCompleted) return false;
      if (isUrgent != null && task.isUrgent != isUrgent) return false;
      if (isImportant != null && task.isImportant != isImportant) return false;
      if (dueBefore != null && task.dueDate.isAfter(dueBefore)) return false;
      if (dueAfter != null && task.dueDate.isBefore(dueAfter)) return false;
      return true;
    }).toList();
  }

  // ========================================
  // TASK QUERIES BY DATE
  // ========================================

  /// Get tasks due today
  List<Task> getTasksDueToday() {
    final today = DateTime.now();
    return state.tasks.where((task) {
      return task.dueDate.year == today.year &&
          task.dueDate.month == today.month &&
          task.dueDate.day == today.day &&
          !task.isCompleted;
    }).toList();
  }

  /// Get overdue tasks
  List<Task> getOverdueTasks() {
    final now = DateTime.now();
    return state.tasks.where((task) {
      return task.dueDate.isBefore(now) && !task.isCompleted;
    }).toList();
  }

  /// Get upcoming tasks (within next 7 days)
  List<Task> getUpcomingTasks() {
    final now = DateTime.now();
    final nextWeek = now.add(Duration(days: 7));
    return state.tasks.where((task) {
      return task.dueDate.isAfter(now) &&
          task.dueDate.isBefore(nextWeek) &&
          !task.isCompleted;
    }).toList();
  }

  // ========================================
  // STATISTICS & ANALYTICS
  // ========================================

  /// Get task statistics
  Map<String, int> getTaskStats() {
    final totalTasks = state.tasks.length;
    final completedTasks = state.tasks.where((task) => task.isCompleted).length;
    final pendingTasks = totalTasks - completedTasks;
    final highPriorityTasks = state.tasks.where((task) => task.priority == TaskPriority.high).length;
    final urgentTasks = state.tasks.where((task) => task.isUrgent).length;

    return {
      'total': totalTasks,
      'completed': completedTasks,
      'pending': pendingTasks,
      'high_priority': highPriorityTasks,
      'urgent': urgentTasks,
    };
  }

  // ========================================
  // SORTING & ORGANIZATION
  // ========================================

  /// Sort tasks by specified criteria
  void sortTasks({
    required String sortBy, // 'title', 'dueDate', 'priority', 'createdAt'
    required bool ascending,
  }) {
    final sortedTasks = List<Task>.from(state.tasks);

    sortedTasks.sort((a, b) {
      int comparison = 0;

      switch (sortBy) {
        case 'title':
          comparison = a.title.compareTo(b.title);
          break;
        case 'dueDate':
          comparison = a.dueDate.compareTo(b.dueDate);
          break;
        case 'priority':
          final priorityOrder = {
            TaskPriority.high: 0,
            TaskPriority.medium: 1,
            TaskPriority.low: 2
          };
          comparison = priorityOrder[a.priority]!.compareTo(priorityOrder[b.priority]!);
          break;
        case 'createdAt':
          comparison = a.createdAt.compareTo(b.createdAt);
          break;
        default:
          comparison = 0;
      }

      return ascending ? comparison : -comparison;
    });

    state = state.copyWith(tasks: sortedTasks);
  }

  // ========================================
  // UTILITY METHODS
  // ========================================

  /// Clear error state
  void clearError() {
    state = state.copyWith(error: null);
  }

  /// Refresh tasks from storage
  Future<void> refreshTasks() async {
    await _loadTasks();
  }
}

// ============================================================================
// PROVIDERS
// ============================================================================

/// Main task provider
final taskProvider = NotifierProvider<TaskNotifier, TaskState>(() {
  return TaskNotifier();
});

// ========================================
// COMPUTED PROVIDERS
// ========================================

/// Provider for pending tasks
final pendingTasksProvider = Provider<List<Task>>((ref) {
  final taskState = ref.watch(taskProvider);
  return taskState.pendingTasks;
});

/// Provider for completed tasks
final completedTasksProvider = Provider<List<Task>>((ref) {
  final taskState = ref.watch(taskProvider);
  return taskState.completedTasks;
});

/// Provider for today's tasks
final todayTasksProvider = Provider<List<Task>>((ref) {
  final taskState = ref.watch(taskProvider);
  return taskState.todayTasks;
});

/// Provider for task statistics
final taskStatsProvider = Provider<Map<String, int>>((ref) {
  final taskNotifier = ref.watch(taskProvider.notifier);
  return taskNotifier.getTaskStats();
});

/// Provider for overdue tasks
final overdueTasksProvider = Provider<List<Task>>((ref) {
  final taskNotifier = ref.watch(taskProvider.notifier);
  return taskNotifier.getOverdueTasks();
});

/// Provider for upcoming tasks
final upcomingTasksProvider = Provider<List<Task>>((ref) {
  final taskNotifier = ref.watch(taskProvider.notifier);
  return taskNotifier.getUpcomingTasks();
});