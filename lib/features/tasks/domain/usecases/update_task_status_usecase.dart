/// Update task status use case with business rules
library;

import '../entities/task.dart';
import '../repositories/task_repository.dart';
import '../failures/task_failures.dart';

/// Use case for updating task status with business validation
///
/// Business Rules:
/// - Cannot move completed task back to todo/in-progress without clearing completed date
/// - Completing a task sets completedAt timestamp
/// - Moving to in-progress clears completed date
/// - Task must exist
class UpdateTaskStatusUseCase {
  final TaskRepository _repository;

  UpdateTaskStatusUseCase(this._repository);

  /// Update task status
  Future<Task> call(String taskId, TaskStatus newStatus) async {
    // Get current task
    final task = await _repository.getTaskById(taskId);
    if (task == null) {
      throw TaskNotFoundFailure(taskId);
    }

    // No change needed
    if (task.status == newStatus) {
      return task;
    }

    // Business rule: Handle completion
    DateTime? completedAt;
    if (newStatus == TaskStatus.completed) {
      completedAt = DateTime.now();
    } else if (task.isCompleted && newStatus != TaskStatus.completed) {
      // Moving away from completed status - clear completion time
      completedAt = null;
    } else {
      // Keep existing completed date
      completedAt = task.completedAt;
    }

    // Create updated task
    final updated = task.copyWith(
      status: newStatus,
      completedAt: completedAt,
      updatedAt: DateTime.now(),
    );

    return await _repository.updateTask(updated);
  }

  /// Quick helper: Mark task as completed
  Future<Task> complete(String taskId) async {
    return call(taskId, TaskStatus.completed);
  }

  /// Quick helper: Mark task as in progress
  Future<Task> markInProgress(String taskId) async {
    return call(taskId, TaskStatus.inProgress);
  }

  /// Quick helper: Move task back to todo
  Future<Task> moveToTodo(String taskId) async {
    return call(taskId, TaskStatus.todo);
  }
}
