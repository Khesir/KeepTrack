import '../../domain/entities/task.dart';

/// Task model - Data transfer object for Supabase
class TaskModel extends Task {
  TaskModel({
    super.id,
    required super.title,
    super.description,
    required TaskStatus status,
    required TaskPriority priority,
    super.projectId,
    super.parentTaskId,
    super.tags,
    super.createdAt,
    super.updatedAt,
    super.dueDate,
    super.completedAt,
    super.archived,
    super.isMoneyRelated,
    super.expectedAmount,
    TaskTransactionType? transactionType,
    super.financeCategoryId,
    super.actualTransactionId,
    super.userId,
    super.bucketId,
  }) : super(
         status: status,
         priority: priority,
         transactionType: transactionType,
       );

  /// Convert from domain entity to model
  factory TaskModel.fromEntity(Task task) {
    return TaskModel(
      id: task.id,
      title: task.title,
      description: task.description,
      status: task.status,
      priority: task.priority,
      projectId: task.projectId,
      parentTaskId: task.parentTaskId,
      tags: task.tags,
      createdAt: task.createdAt,
      updatedAt: task.updatedAt,
      dueDate: task.dueDate,
      completedAt: task.completedAt,
      archived: task.archived,
      isMoneyRelated: task.isMoneyRelated,
      expectedAmount: task.expectedAmount,
      transactionType: task.transactionType,
      financeCategoryId: task.financeCategoryId,
      actualTransactionId: task.actualTransactionId,
      userId: task.userId,
      bucketId: task.bucketId,
    );
  }

  /// Convert from Supabase JSON
  factory TaskModel.fromJson(Map<String, dynamic> json) {
    return TaskModel(
      id: json['id'] as String?,
      title: json['title'] as String,
      description: json['description'] as String?,
      status: TaskStatus.values.firstWhere((e) => e.name == json['status']),
      priority: TaskPriority.values.firstWhere(
        (e) => e.name == json['priority'],
      ),
      projectId: json['project_id'] as String?,
      parentTaskId: json['parent_task_id'] as String?,
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
      isMoneyRelated: json['is_money_related'] as bool? ?? false,
      expectedAmount: (json['expected_amount'] as num?)?.toDouble(),
      transactionType: json['transaction_type'] != null
          ? TaskTransactionType.values.firstWhere(
              (e) => e.name == json['transaction_type'],
            )
          : null,
      financeCategoryId: json['finance_category_id'] as String?,
      actualTransactionId: json['actual_transaction_id'] as String?,
      userId: json['user_id'] as String?,
      bucketId: json['bucket_id'] as String?,
    );
  }

  /// Convert to Supabase JSON
  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'title': title,
      if (description != null) 'description': description,
      'status': status.name,
      'priority': priority.name,
      if (projectId != null) 'project_id': projectId,
      if (parentTaskId != null) 'parent_task_id': parentTaskId,
      'tags': tags,
      if (dueDate != null) 'due_date': dueDate!.toIso8601String(),
      if (completedAt != null) 'completed_at': completedAt!.toIso8601String(),
      'archived': archived,
      'is_money_related': isMoneyRelated,
      if (expectedAmount != null) 'expected_amount': expectedAmount,
      if (transactionType != null) 'transaction_type': transactionType!.name,
      if (financeCategoryId != null) 'finance_category_id': financeCategoryId,
      if (actualTransactionId != null)
        'actual_transaction_id': actualTransactionId,
      if (userId != null) 'user_id': userId,
    };
  }
}
