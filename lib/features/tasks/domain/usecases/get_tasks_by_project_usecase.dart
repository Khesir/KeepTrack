/// Get tasks by project use case
library;

import '../entities/task.dart';
import '../repositories/task_repository.dart';

/// Use case for retrieving tasks belonging to a specific project
class GetTasksByProjectUseCase {
  final TaskRepository _repository;

  GetTasksByProjectUseCase(this._repository);

  /// Execute the use case
  /// Returns all tasks for the given project ID
  Future<List<Task>> call(String projectId) async {
    final tasks = await _repository.getTasksByProject(projectId);

    // Business rule: Sort by creation date, newest first
    tasks.sort((a, b) {
      if (a.createdAt == null && b.createdAt == null) return 0;
      if (a.createdAt == null) return 1; // a goes last
      if (b.createdAt == null) return -1; // b goes last
      return b.createdAt!.compareTo(a.createdAt!);
    });

    return tasks;
  }
}
