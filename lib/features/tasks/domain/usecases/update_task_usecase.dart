/// Update task use case for general task updates
library;

import 'package:persona_codex/core/error/failure.dart';

import '../entities/task.dart';
import '../repositories/task_repository.dart';
import '../failures/task_failures.dart';

/// Use case for updating task details (title, description, etc.)
///
/// Business Rules:
/// - Task must exist
/// - Title must not be empty
/// - Title must be <= 255 characters
/// - Description must be <= 2000 characters (if provided)
class UpdateTaskUseCase {
  final TaskRepository _repository;

  UpdateTaskUseCase(this._repository);

  /// Update task details
  Future<Task> call(UpdateTaskParams params) async {
    // Verify task exists
    final existingTask = await _repository.getTaskById(params.taskId);
    if (existingTask == null) {
      throw TaskNotFoundFailure(params.taskId);
    }

    // Validation
    _validateParams(params);

    // Create updated task
    final updated = existingTask.copyWith(
      title: params.title?.trim(),
      description: params.description?.trim(),
      status: params.status,
      priority: params.priority,
      dueDate: params.dueDate,
      projectId: params.projectId,
      isMoneyRelated: params.isMoneyRelated,
      expectedAmount: params.expectedAmount,
      transactionType: params.transactionType,
      financeCategoryId: params.financeCategoryId,
      updatedAt: DateTime.now(),
    );

    return await _repository.updateTask(updated);
  }

  void _validateParams(UpdateTaskParams params) {
    // Title validation
    if (params.title != null) {
      if (params.title!.trim().isEmpty) {
        throw ValidationFailure('Task title cannot be empty');
      }

      if (params.title!.length > 255) {
        throw ValidationFailure('Task title cannot exceed 255 characters');
      }
    }

    // Description validation
    if (params.description != null && params.description!.length > 2000) {
      throw ValidationFailure('Description cannot exceed 2000 characters');
    }
  }
}

/// Parameters for updating a task
class UpdateTaskParams {
  final String taskId;
  final String? title;
  final String? description;
  final TaskStatus? status;
  final TaskPriority? priority;
  final DateTime? dueDate;
  final String? projectId;
  final bool? isMoneyRelated;
  final double? expectedAmount;
  final TaskTransactionType? transactionType;
  final String? financeCategoryId;

  UpdateTaskParams({
    required this.taskId,
    this.title,
    this.description,
    this.status,
    this.priority,
    this.dueDate,
    this.projectId,
    this.isMoneyRelated,
    this.expectedAmount,
    this.transactionType,
    this.financeCategoryId,
  });
}
