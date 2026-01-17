// Sentinel value for clearing nullable fields in copyWith
const _sentinel = Object();

/// Task entity - Pure domain model
class Task {
  final String? id; // Optional - Supabase auto-generates
  final String title;
  final String? description;
  final TaskStatus status;
  final TaskPriority priority;
  final String? projectId;
  final String? parentTaskId; // Reference to parent task for subtasks
  final List<String> tags;
  final DateTime? createdAt; // Optional - Supabase auto-generates
  final DateTime? updatedAt; // Optional - Supabase auto-generates
  final DateTime? dueDate;
  final DateTime? completedAt;
  final bool archived; // Soft delete flag
  final String? userId;
  final String? bucketId;

  // Financial integration fields
  final bool
  isMoneyRelated; // Whether this task involves a financial transaction
  final double? expectedAmount; // Expected transaction amount
  final TaskTransactionType? transactionType; // Income or expense
  final String? financeCategoryId; // Link to finance category
  final String?
  actualTransactionId; // Link to created transaction after completion

  Task({
    this.id,
    required this.title,
    this.description,
    required this.status,
    required this.priority,
    this.projectId,
    this.parentTaskId,
    this.tags = const [],
    this.createdAt,
    this.updatedAt,
    this.dueDate,
    this.completedAt,
    this.archived = false,
    this.isMoneyRelated = false,
    this.expectedAmount,
    this.transactionType,
    this.financeCategoryId,
    this.actualTransactionId,
    this.bucketId,
    this.userId,
  });

  /// Copy with method for immutability
  /// Use Object? for nullable fields to allow explicitly setting them to null
  Task copyWith({
    String? id,
    String? title,
    Object? description = _sentinel,
    TaskStatus? status,
    TaskPriority? priority,
    Object? projectId = _sentinel,
    Object? parentTaskId = _sentinel,
    List<String>? tags,
    Object? createdAt = _sentinel,
    Object? updatedAt = _sentinel,
    Object? dueDate = _sentinel,
    Object? completedAt = _sentinel,
    bool? archived,
    bool? isMoneyRelated,
    Object? expectedAmount = _sentinel,
    Object? transactionType = _sentinel,
    Object? financeCategoryId = _sentinel,
    Object? actualTransactionId = _sentinel,
    String? userId,
    Object? bucketId = _sentinel,
  }) {
    return Task(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description == _sentinel
          ? this.description
          : description as String?,
      status: status ?? this.status,
      priority: priority ?? this.priority,
      projectId: projectId == _sentinel
          ? this.projectId
          : projectId as String?,
      parentTaskId: parentTaskId == _sentinel
          ? this.parentTaskId
          : parentTaskId as String?,
      tags: tags ?? this.tags,
      createdAt: createdAt == _sentinel
          ? this.createdAt
          : createdAt as DateTime?,
      updatedAt: updatedAt == _sentinel
          ? this.updatedAt
          : updatedAt as DateTime?,
      dueDate: dueDate == _sentinel
          ? this.dueDate
          : dueDate as DateTime?,
      completedAt: completedAt == _sentinel
          ? this.completedAt
          : completedAt as DateTime?,
      archived: archived ?? this.archived,
      isMoneyRelated: isMoneyRelated ?? this.isMoneyRelated,
      expectedAmount: expectedAmount == _sentinel
          ? this.expectedAmount
          : expectedAmount as double?,
      transactionType: transactionType == _sentinel
          ? this.transactionType
          : transactionType as TaskTransactionType?,
      financeCategoryId: financeCategoryId == _sentinel
          ? this.financeCategoryId
          : financeCategoryId as String?,
      actualTransactionId: actualTransactionId == _sentinel
          ? this.actualTransactionId
          : actualTransactionId as String?,
      userId: userId ?? this.userId,
      bucketId: bucketId == _sentinel
          ? this.bucketId
          : bucketId as String?,
    );
  }

  bool get isCompleted => status == TaskStatus.completed;
  bool get isOverdue =>
      dueDate != null && !isCompleted && DateTime.now().isAfter(dueDate!);
  bool get isArchived => archived;
  bool get hasFinancialIntent => isMoneyRelated && expectedAmount != null;
  bool get hasTransactionCreated => actualTransactionId != null;
  bool get isSubtask => parentTaskId != null;

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

enum TaskTransactionType {
  income,
  expense;

  String get displayName {
    switch (this) {
      case TaskTransactionType.income:
        return 'Income';
      case TaskTransactionType.expense:
        return 'Expense';
    }
  }
}
