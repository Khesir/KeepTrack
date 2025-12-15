/// Task entity - Pure domain model
class Task {
  final String? id; // Optional - Supabase auto-generates
  final String title;
  final String? description;
  final TaskStatus status;
  final TaskPriority priority;
  final String? projectId;
  final List<String> tags;
  final DateTime? createdAt; // Optional - Supabase auto-generates
  final DateTime? updatedAt; // Optional - Supabase auto-generates
  final DateTime? dueDate;
  final DateTime? completedAt;
  final bool archived; // Soft delete flag

  Task({
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

  /// Copy with method for immutability
  Task copyWith({
    String? id,
    String? title,
    String? description,
    TaskStatus? status,
    TaskPriority? priority,
    String? projectId,
    List<String>? tags,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? dueDate,
    DateTime? completedAt,
    bool? archived,
  }) {
    return Task(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      status: status ?? this.status,
      priority: priority ?? this.priority,
      projectId: projectId ?? this.projectId,
      tags: tags ?? this.tags,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      dueDate: dueDate ?? this.dueDate,
      completedAt: completedAt ?? this.completedAt,
      archived: archived ?? this.archived,
    );
  }

  bool get isCompleted => status == TaskStatus.completed;
  bool get isOverdue =>
      dueDate != null && !isCompleted && DateTime.now().isAfter(dueDate!);
  bool get isArchived => archived;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Task &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          title == other.title;

  @override
  int get hashCode => Object.hash(id, title);

  @override
  String toString() => 'Task(id: $id, title: $title, status: $status)';
}

enum TaskStatus {
  todo,
  inProgress,
  completed,
  cancelled;

  String get displayName {
    switch (this) {
      case TaskStatus.todo:
        return 'To Do';
      case TaskStatus.inProgress:
        return 'In Progress';
      case TaskStatus.completed:
        return 'Completed';
      case TaskStatus.cancelled:
        return 'Cancelled';
    }
  }
}

enum TaskPriority {
  low,
  medium,
  high,
  urgent;

  String get displayName {
    switch (this) {
      case TaskPriority.low:
        return 'Low';
      case TaskPriority.medium:
        return 'Medium';
      case TaskPriority.high:
        return 'High';
      case TaskPriority.urgent:
        return 'Urgent';
    }
  }
}
