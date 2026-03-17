import 'package:flutter/material.dart';

enum TaskPriority { high, medium, low }

enum TaskStatus { todo, inProgress, completed }

class Task {
  final String id;
  final String title;
  final String? description;
  final TaskPriority priority;
  final TaskStatus status;
  final String? assignedTo;
  final String? assignedToName;
  final String? assignedToAvatar;
  final DateTime? dueDate;
  final DateTime createdDate;
  final DateTime? completedDate;
  final int commentCount;
  final bool isOverdue;

  Task({
    required this.id,
    required this.title,
    this.description,
    required this.priority,
    required this.status,
    this.assignedTo,
    this.assignedToName,
    this.assignedToAvatar,
    this.dueDate,
    required this.createdDate,
    this.completedDate,
    this.commentCount = 0,
    this.isOverdue = false,
  });

  factory Task.fromJson(Map<String, dynamic> json) {
    final dueDateRaw = json['due_date'] as String?;
    DateTime? dueDate =
        dueDateRaw != null ? DateTime.tryParse(dueDateRaw) : null;
    final status = TaskStatus.values.firstWhere(
      (s) => s.name == (json['status'] ?? 'todo'),
      orElse: () => TaskStatus.todo,
    );
    return Task(
      id: json['id']?.toString() ?? '',
      title: json['title'] ?? '',
      description: json['description'] as String?,
      priority: TaskPriority.values.firstWhere(
        (p) => p.name == (json['priority'] ?? 'medium'),
        orElse: () => TaskPriority.medium,
      ),
      status: status,
      assignedTo: json['assigned_to'] as String?,
      assignedToName: json['assigned_to_name'] as String?,
      assignedToAvatar: json['assigned_to_avatar'] as String?,
      dueDate: dueDate,
      createdDate: json['created_date'] != null
          ? DateTime.parse(json['created_date'])
          : DateTime.now(),
      completedDate: json['completed_date'] != null
          ? DateTime.tryParse(json['completed_date'])
          : null,
      commentCount: (json['comment_count'] as num?)?.toInt() ?? 0,
      isOverdue: dueDate != null &&
          status != TaskStatus.completed &&
          dueDate.isBefore(DateTime.now()),
    );
  }

  Color get priorityColor {
    switch (priority) {
      case TaskPriority.high:
        return Colors.red;
      case TaskPriority.medium:
        return Colors.orange;
      case TaskPriority.low:
        return Colors.green;
    }
  }

  String get priorityLabel {
    switch (priority) {
      case TaskPriority.high:
        return 'High';
      case TaskPriority.medium:
        return 'Medium';
      case TaskPriority.low:
        return 'Low';
    }
  }

  String get statusLabel {
    switch (status) {
      case TaskStatus.todo:
        return 'To Do';
      case TaskStatus.inProgress:
        return 'In Progress';
      case TaskStatus.completed:
        return 'Completed';
    }
  }
}
