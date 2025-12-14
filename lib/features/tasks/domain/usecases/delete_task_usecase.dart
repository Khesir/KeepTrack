/// Delete task use case
library;

import '../repositories/task_repository.dart';
import '../failures/task_failures.dart';

/// Use case for deleting a task
///
/// Business Rules:
/// - Task must exist before deletion
/// - Can add soft-delete support in the future
/// - Can add permission checks here
class DeleteTaskUseCase {
  final TaskRepository _repository;

  DeleteTaskUseCase(this._repository);

  /// Delete a task by ID
  ///
  /// Throws [TaskNotFoundFailure] if task doesn't exist
  Future<void> call(String taskId) async {
    // Verify task exists before deletion
    final task = await _repository.getTaskById(taskId);
    if (task == null) {
      throw TaskNotFoundFailure(taskId);
    }

    // Business rule: Could add check here like:
    // if (task.hasActiveSubtasks) {
    //   throw OperationNotAllowedFailure('Cannot delete task with active subtasks');
    // }

    await _repository.deleteTask(taskId);
  }

  /// Delete multiple tasks
  ///
  /// Continues deleting even if some fail
  /// Returns list of IDs that failed to delete
  Future<List<String>> deleteMultiple(List<String> taskIds) async {
    final failures = <String>[];

    for (final id in taskIds) {
      try {
        await call(id);
      } catch (e) {
        failures.add(id);
      }
    }

    return failures;
  }
}
