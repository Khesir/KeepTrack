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
  /// Returns all tasks, sorted by creation date (newest first)
  Future<List<Task>> call() async {
    final tasks = await _repository.getTasks();

    // Business rule: Sort by creation date, newest first
    tasks.sort((a, b) => b.createdAt.compareTo(a.createdAt));

    return tasks;
  }
}
