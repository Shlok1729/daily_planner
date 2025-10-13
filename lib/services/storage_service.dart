import 'package:hive_flutter/hive_flutter.dart';
import 'package:daily_planner/models/task_model.dart';
import 'package:daily_planner/models/message_model.dart';
import 'package:daily_planner/models/user_model.dart';
import 'package:daily_planner/utils/error_handler.dart';

class StorageService {
  static final StorageService _instance = StorageService._internal();
  factory StorageService() => _instance;

  StorageService._internal();

  // Box names
  static const String _tasksBoxName = 'tasks';
  static const String _messagesBoxName = 'messages';
  static const String _userBoxName = 'user';
  static const String _settingsBoxName = 'settings';

  bool _isInitialized = false;

  /// FIXED: Added missing initialize method
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      await init();
      _isInitialized = true;
    } catch (e) {
      ErrorHandler.logError('StorageService initialization failed', e);
      rethrow;
    }
  }

  /// Check if service is initialized
  bool get isInitialized => _isInitialized;

  // Initialize Hive and open boxes
  Future<void> init() async {
    await Hive.initFlutter();

    // Register adapters (you would need to create these adapters)
    // Hive.registerAdapter(TaskAdapter());
    // Hive.registerAdapter(MessageAdapter());
    // Hive.registerAdapter(UserAdapter());

    // Open boxes
    await Hive.openBox<Map>(_tasksBoxName);
    await Hive.openBox<Map>(_messagesBoxName);
    await Hive.openBox<Map>(_userBoxName);
    await Hive.openBox(_settingsBoxName);
  }

  // Task methods
  Future<void> saveTask(Task task) async {
    try {
      final box = Hive.box<Map>(_tasksBoxName);
      await box.put(task.id, task.toMap());
    } catch (e) {
      ErrorHandler.logError('Failed to save task', e);
      rethrow;
    }
  }

  Future<void> deleteTask(String taskId) async {
    try {
      final box = Hive.box<Map>(_tasksBoxName);
      await box.delete(taskId);
    } catch (e) {
      ErrorHandler.logError('Failed to delete task', e);
      rethrow;
    }
  }

  Future<Task?> getTask(String taskId) async {
    try {
      final box = Hive.box<Map>(_tasksBoxName);
      final taskMap = box.get(taskId);

      if (taskMap != null) {
        return Task.fromMap(Map<String, dynamic>.from(taskMap));
      }

      return null;
    } catch (e) {
      ErrorHandler.logError('Failed to get task', e);
      return null;
    }
  }

  Future<List<Task>> getAllTasks() async {
    try {
      final box = Hive.box<Map>(_tasksBoxName);
      return box.values
          .map((taskMap) => Task.fromMap(Map<String, dynamic>.from(taskMap)))
          .toList();
    } catch (e) {
      ErrorHandler.logError('Failed to get all tasks', e);
      return [];
    }
  }

  Future<List<Task>> getTasksByDate(DateTime date) async {
    try {
      final allTasks = await getAllTasks();

      return allTasks.where((task) {
        return task.dueDate.year == date.year &&
            task.dueDate.month == date.month &&
            task.dueDate.day == date.day;
      }).toList();
    } catch (e) {
      ErrorHandler.logError('Failed to get tasks by date', e);
      return [];
    }
  }

  // Message methods
  Future<void> saveMessage(Message message) async {
    try {
      final box = Hive.box<Map>(_messagesBoxName);
      await box.put(message.id, message.toMap());
    } catch (e) {
      ErrorHandler.logError('Failed to save message', e);
      rethrow;
    }
  }

  Future<List<Message>> getAllMessages() async {
    try {
      final box = Hive.box<Map>(_messagesBoxName);
      return box.values
          .map((messageMap) => Message.fromMap(Map<String, dynamic>.from(messageMap)))
          .toList();
    } catch (e) {
      ErrorHandler.logError('Failed to get all messages', e);
      return [];
    }
  }

  Future<void> clearMessages() async {
    try {
      final box = Hive.box<Map>(_messagesBoxName);
      await box.clear();
    } catch (e) {
      ErrorHandler.logError('Failed to clear messages', e);
      rethrow;
    }
  }

  // User methods
  Future<void> saveUser(User user) async {
    try {
      final box = Hive.box<Map>(_userBoxName);
      // FIXED: Using the proper map method for User model
      await box.put('current_user', _userToMap(user));
    } catch (e) {
      ErrorHandler.logError('Failed to save user', e);
      rethrow;
    }
  }

  Future<User?> getUser() async {
    try {
      final box = Hive.box<Map>(_userBoxName);
      final userMap = box.get('current_user');

      if (userMap != null) {
        // FIXED: Using the proper fromMap method for User model
        return _userFromMap(Map<String, dynamic>.from(userMap));
      }

      return null;
    } catch (e) {
      ErrorHandler.logError('Failed to get user', e);
      return null;
    }
  }

  Future<void> deleteUser() async {
    try {
      final box = Hive.box<Map>(_userBoxName);
      await box.delete('current_user');
    } catch (e) {
      ErrorHandler.logError('Failed to delete user', e);
      rethrow;
    }
  }

  // FIXED: Added User model conversion methods with the correct fields
  Map<String, dynamic> _userToMap(User user) {
    return {
      'id': user.id,
      'email': user.email,
      'displayName': user.displayName,
      'photoURL': user.photoURL,
      'metadata': user.metadata,
      'createdAt': user.createdAt?.toIso8601String(),
    };
  }

  User _userFromMap(Map<String, dynamic> map) {
    return User(
      id: map['id'] ?? '',
      email: map['email'],
      displayName: map['displayName'],
      photoURL: map['photoURL'],
      metadata: Map<String, dynamic>.from(map['metadata'] ?? {}),
      createdAt: map['createdAt'] != null ? DateTime.parse(map['createdAt']) : DateTime.now(),
    );
  }

  // Settings methods
  Future<void> saveSetting(String key, dynamic value) async {
    try {
      final box = Hive.box(_settingsBoxName);
      await box.put(key, value);
    } catch (e) {
      ErrorHandler.logError('Failed to save setting', e);
      rethrow;
    }
  }

  dynamic getSetting(String key, {dynamic defaultValue}) {
    try {
      final box = Hive.box(_settingsBoxName);
      return box.get(key, defaultValue: defaultValue);
    } catch (e) {
      ErrorHandler.logError('Failed to get setting', e);
      return defaultValue;
    }
  }

  Future<void> clearSettings() async {
    try {
      final box = Hive.box(_settingsBoxName);
      await box.clear();
    } catch (e) {
      ErrorHandler.logError('Failed to clear settings', e);
      rethrow;
    }
  }

  // Clear all data
  Future<void> clearAllData() async {
    try {
      final tasksBox = Hive.box<Map>(_tasksBoxName);
      final messagesBox = Hive.box<Map>(_messagesBoxName);
      final userBox = Hive.box<Map>(_userBoxName);
      final settingsBox = Hive.box(_settingsBoxName);

      await tasksBox.clear();
      await messagesBox.clear();
      await userBox.clear();
      await settingsBox.clear();
    } catch (e) {
      ErrorHandler.logError('Failed to clear all data', e);
      rethrow;
    }
  }

  // Additional utility methods
  Future<bool> hasData() async {
    try {
      final tasksBox = Hive.box<Map>(_tasksBoxName);
      return tasksBox.isNotEmpty;
    } catch (e) {
      ErrorHandler.logError('Failed to check if has data', e);
      return false;
    }
  }

  Future<int> getTaskCount() async {
    try {
      final tasksBox = Hive.box<Map>(_tasksBoxName);
      return tasksBox.length;
    } catch (e) {
      ErrorHandler.logError('Failed to get task count', e);
      return 0;
    }
  }

  Future<int> getMessageCount() async {
    try {
      final messagesBox = Hive.box<Map>(_messagesBoxName);
      return messagesBox.length;
    } catch (e) {
      ErrorHandler.logError('Failed to get message count', e);
      return 0;
    }
  }

  /// Get storage statistics
  Map<String, dynamic> getStorageStats() {
    try {
      final tasksBox = Hive.box<Map>(_tasksBoxName);
      final messagesBox = Hive.box<Map>(_messagesBoxName);
      final userBox = Hive.box<Map>(_userBoxName);
      final settingsBox = Hive.box(_settingsBoxName);

      return {
        'tasks_count': tasksBox.length,
        'messages_count': messagesBox.length,
        'users_count': userBox.length,
        'settings_count': settingsBox.length,
        'total_boxes': 4,
        'initialized': _isInitialized,
      };
    } catch (e) {
      ErrorHandler.logError('Failed to get storage stats', e);
      return {
        'error': 'Failed to get storage statistics',
        'initialized': _isInitialized,
      };
    }
  }
}