/// Archive task use case
library;

import '../entities/task.dart';
import '../repositories/task_repository.dart';
import '../failures/task_failures.dart';

/// Use case for archiving/unarchiving tasks (soft delete)
class ArchiveTaskUseCase {
  final TaskRepository _repository;

  ArchiveTaskUseCase(this._repository);

  /// Archive a task (soft delete)
  Future<Task> archive(String taskId) async {
    // Get current task
    final task = await _repository.getTaskById(taskId);
    if (task == null) {
      throw TaskNotFoundFailure(taskId);
    }

    // Business rule: Already archived tasks cannot be archived again
    if (task.archived) {
      return task; // Idempotent operation
    }

    // Create archived task
    final archived = task.copyWith(
      archived: true,
      updatedAt: DateTime.now(),
    );

    return await _repository.updateTask(archived);
  }

  /// Unarchive a task (restore from archive)
  Future<Task> unarchive(String taskId) async {
    // Get current task
    final task = await _repository.getTaskById(taskId);
    if (task == null) {
      throw TaskNotFoundFailure(taskId);
    }

    // Business rule: Only archived tasks can be unarchived
    if (!task.archived) {
      return task; // Idempotent operation
    }

    // Create unarchived task
    final unarchived = task.copyWith(
      archived: false,
      updatedAt: DateTime.now(),
    );

    return await _repository.updateTask(unarchived);
  }

  /// Toggle archive status
  Future<Task> toggle(String taskId) async {
    final task = await _repository.getTaskById(taskId);
    if (task == null) {
      throw TaskNotFoundFailure(taskId);
    }

    return task.archived ? await unarchive(taskId) : await archive(taskId);
  }
}
