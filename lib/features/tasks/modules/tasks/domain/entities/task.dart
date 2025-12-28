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
    this.userId,
  });

  /// Copy with method for immutability
  Task copyWith({
    String? id,
    String? title,
    String? description,
    TaskStatus? status,
    TaskPriority? priority,
    String? projectId,
    String? parentTaskId,
    List<String>? tags,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? dueDate,
    DateTime? completedAt,
    bool? archived,
    bool? isMoneyRelated,
    double? expectedAmount,
    TaskTransactionType? transactionType,
    String? financeCategoryId,
    String? actualTransactionId,
    String? userId,
  }) {
    return Task(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      status: status ?? this.status,
      priority: priority ?? this.priority,
      projectId: projectId ?? this.projectId,
      parentTaskId: parentTaskId ?? this.parentTaskId,
      tags: tags ?? this.tags,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      dueDate: dueDate ?? this.dueDate,
      completedAt: completedAt ?? this.completedAt,
      archived: archived ?? this.archived,
      isMoneyRelated: isMoneyRelated ?? this.isMoneyRelated,
      expectedAmount: expectedAmount ?? this.expectedAmount,
      transactionType: transactionType ?? this.transactionType,
      financeCategoryId: financeCategoryId ?? this.financeCategoryId,
      actualTransactionId: actualTransactionId ?? this.actualTransactionId,
      userId: userId ?? this.userId,
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
