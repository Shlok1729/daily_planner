import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

enum TaskPriority { high, medium, low }
enum TaskCategory { personal, work, health, other }

class Task {
  final String id;
  final String title;
  final String description;
  final DateTime dueDate;
  final TimeOfDay dueTime;
  final TaskPriority priority;
  final TaskCategory category;
  final bool isCompleted;
  final bool isUrgent;
  final bool isImportant;
  final DateTime createdAt;  // ADDED: Missing property
  final DateTime? completedAt;  // ADDED: Missing property

  Task({
    String? id,
    required this.title,
    this.description = '',
    required this.dueDate,
    required this.dueTime,
    this.priority = TaskPriority.medium,
    this.category = TaskCategory.other,
    this.isCompleted = false,
    this.isUrgent = false,
    this.isImportant = false,
    DateTime? createdAt,  // ADDED: Constructor parameter
    this.completedAt,  // ADDED: Constructor parameter
  }) : id = id ?? const Uuid().v4(),
        createdAt = createdAt ?? DateTime.now();  // ADDED: Default value

  Task copyWith({
    String? title,
    String? description,
    DateTime? dueDate,
    TimeOfDay? dueTime,
    TaskPriority? priority,
    TaskCategory? category,
    bool? isCompleted,
    bool? isUrgent,
    bool? isImportant,
    DateTime? createdAt,  // ADDED: copyWith parameter
    DateTime? completedAt,  // ADDED: copyWith parameter
  }) {
    return Task(
      id: this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      dueDate: dueDate ?? this.dueDate,
      dueTime: dueTime ?? this.dueTime,
      priority: priority ?? this.priority,
      category: category ?? this.category,
      isCompleted: isCompleted ?? this.isCompleted,
      isUrgent: isUrgent ?? this.isUrgent,
      isImportant: isImportant ?? this.isImportant,
      createdAt: createdAt ?? this.createdAt,  // ADDED: copyWith logic
      completedAt: completedAt ?? this.completedAt,  // ADDED: copyWith logic
    );
  }

  // For Eisenhower Matrix positioning
  String get quadrant {
    if (isUrgent && isImportant) return 'urgentImportant';
    if (isUrgent && !isImportant) return 'urgentNotImportant';
    if (!isUrgent && isImportant) return 'notUrgentImportant';
    return 'notUrgentNotImportant';
  }

  // Convert to Map for storage
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'dueDate': dueDate.millisecondsSinceEpoch,
      'dueTime': {
        'hour': dueTime.hour,
        'minute': dueTime.minute,
      },
      'priority': priority.index,
      'category': category.index,
      'isCompleted': isCompleted,
      'isUrgent': isUrgent,
      'isImportant': isImportant,
      'createdAt': createdAt.millisecondsSinceEpoch,  // ADDED: toMap logic
      'completedAt': completedAt?.millisecondsSinceEpoch,  // ADDED: toMap logic
    };
  }

  // Create from Map for storage retrieval
  factory Task.fromMap(Map<String, dynamic> map) {
    return Task(
      id: map['id'],
      title: map['title'],
      description: map['description'],
      dueDate: DateTime.fromMillisecondsSinceEpoch(map['dueDate']),
      dueTime: TimeOfDay(
        hour: map['dueTime']['hour'],
        minute: map['dueTime']['minute'],
      ),
      priority: TaskPriority.values[map['priority']],
      category: TaskCategory.values[map['category']],
      isCompleted: map['isCompleted'],
      isUrgent: map['isUrgent'],
      isImportant: map['isImportant'],
      createdAt: map['createdAt'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['createdAt'])  // ADDED: fromMap logic
          : DateTime.now(),
      completedAt: map['completedAt'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['completedAt'])  // ADDED: fromMap logic
          : null,
    );
  }
}