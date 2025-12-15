/// Get all tasks use case
library;

import '../entities/task.dart';
import '../repositories/task_repository.dart';

/// Simple use case for retrieving all tasks
/// May include business logic like sorting or filtering in the future
class GetTasksUseCase {
  final TaskRepository _repository;

  GetTasksUseCase(this._repository);

  /// Execute the use case
  /// Returns all non-archived tasks, sorted by creation date (newest first)
  Future<List<Task>> call({bool includeArchived = false}) async {
    final tasks = await _repository.getTasks();

    // Business rule: Filter out archived tasks by default
    final filteredTasks = includeArchived
        ? tasks
        : tasks.where((task) => !task.archived).toList();

    // Business rule: Sort by creation date, newest first
    filteredTasks.sort((a, b) {
      // Handle nullable createdAt (tasks from DB should always have it)
      if (a.createdAt == null && b.createdAt == null) return 0;
      if (a.createdAt == null) return 1; // a goes last
      if (b.createdAt == null) return -1; // b goes last
      return b.createdAt!.compareTo(a.createdAt!);
    });

    return filteredTasks;
  }

  /// Get only archived tasks
  Future<List<Task>> getArchivedTasks() async {
    final tasks = await _repository.getTasks();
    return tasks.where((task) => task.archived).toList();
  }
}
