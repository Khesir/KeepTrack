import '../../domain/entities/task.dart';

/// Task model - Data transfer object for Supabase
class TaskModel {
  final String? id; // Optional - Supabase auto-generates
  final String title;
  final String? description;
  final String status;
  final String priority;
  final String? projectId;
  final List<String> tags;
  final DateTime? createdAt; // Optional - Supabase auto-generates
  final DateTime? updatedAt; // Optional - Supabase auto-generates
  final DateTime? dueDate;
  final DateTime? completedAt;
  final bool archived;

  TaskModel({
    this.id,
    required this.title,
    this.description,
    required this.status,
    required this.priority,
    this.projectId,
    this.tags = const [],
    this.createdAt,
    this.updatedAt,
    this.dueDate,
    this.completedAt,
    this.archived = false,
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
      archived: task.archived,
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
      archived: archived,
    );
  }

  /// Convert from Supabase JSON
  factory TaskModel.fromJson(Map<String, dynamic> json) {
    return TaskModel(
      id: json['id'] as String?,
      title: json['title'] as String,
      description: json['description'] as String?,
      status: json['status'] as String,
      priority: json['priority'] as String,
      projectId: json['project_id'] as String?,
      tags: (json['tags'] as List<dynamic>?)?.cast<String>() ?? [],
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
      dueDate: json['due_date'] != null
          ? DateTime.parse(json['due_date'] as String)
          : null,
      completedAt: json['completed_at'] != null
          ? DateTime.parse(json['completed_at'] as String)
          : null,
      archived: json['archived'] as bool? ?? false,
    );
  }

  /// Convert to Supabase JSON
  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'title': title,
      if (description != null) 'description': description,
      'status': status,
      'priority': priority,
      if (projectId != null) 'project_id': projectId,
      'tags': tags,
      if (createdAt != null) 'created_at': createdAt!.toIso8601String(),
      if (updatedAt != null) 'updated_at': updatedAt!.toIso8601String(),
      if (dueDate != null) 'due_date': dueDate!.toIso8601String(),
      if (completedAt != null) 'completed_at': completedAt!.toIso8601String(),
      'archived': archived,
    };
  }
}
