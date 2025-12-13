import '../../domain/entities/task.dart';

/// Task model - Data transfer object for database
class TaskModel {
  final String id;
  final String title;
  final String? description;
  final String status;
  final String priority;
  final String? projectId;
  final List<String> tags;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? dueDate;
  final DateTime? completedAt;

  TaskModel({
    required this.id,
    required this.title,
    this.description,
    required this.status,
    required this.priority,
    this.projectId,
    this.tags = const [],
    required this.createdAt,
    required this.updatedAt,
    this.dueDate,
    this.completedAt,
  });

  /// Convert from domain entity to model
  factory TaskModel.fromEntity(Task task) {
    return TaskModel(
      id: task.id,
      title: task.title,
      description: task.description,
      status: task.status.name,
      priority: task.priority.name,
      projectId: task.projectId,
      tags: task.tags,
      createdAt: task.createdAt,
      updatedAt: task.updatedAt,
      dueDate: task.dueDate,
      completedAt: task.completedAt,
    );
  }

  /// Convert from model to domain entity
  Task toEntity() {
    return Task(
      id: id,
      title: title,
      description: description,
      status: TaskStatus.values.firstWhere((e) => e.name == status),
      priority: TaskPriority.values.firstWhere((e) => e.name == priority),
      projectId: projectId,
      tags: tags,
      createdAt: createdAt,
      updatedAt: updatedAt,
      dueDate: dueDate,
      completedAt: completedAt,
    );
  }

  /// Convert from MongoDB document
  factory TaskModel.fromJson(Map<String, dynamic> json) {
    return TaskModel(
      id: json['_id'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      status: json['status'] as String,
      priority: json['priority'] as String,
      projectId: json['projectId'] as String?,
      tags: (json['tags'] as List<dynamic>?)?.cast<String>() ?? [],
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      dueDate: json['dueDate'] != null
          ? DateTime.parse(json['dueDate'] as String)
          : null,
      completedAt: json['completedAt'] != null
          ? DateTime.parse(json['completedAt'] as String)
          : null,
    );
  }

  /// Convert to MongoDB document
  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'title': title,
      'description': description,
      'status': status,
      'priority': priority,
      'projectId': projectId,
      'tags': tags,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'dueDate': dueDate?.toIso8601String(),
      'completedAt': completedAt?.toIso8601String(),
    };
  }
}
