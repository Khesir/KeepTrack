import 'package:persona_codex/core/error/result.dart';

import '../entities/task.dart';

/// Task repository interface - Defines data access contract
abstract class TaskRepository {
  /// Get all tasks
  Future<Result<List<Task>>> getTasks();

  /// Get tasks by project
  Future<Result<List<Task>>> getTasksByProject(String projectId);

  /// Get tasks by status
  Future<Result<List<Task>>> getTasksByStatus(TaskStatus status);

  /// Get task by ID
  Future<Result<Task>> getTaskById(String id);

  /// Create a new task
  Future<Result<Task>> createTask(Task task);

  /// Update an existing task
  Future<Result<Task>> updateTask(Task task);

  /// Delete a task
  Future<Result<void>> deleteTask(String id);

  /// Search tasks by title or description
  Future<Result<List<Task>>> searchTasks(String query);

  /// Get tasks with filters
  Future<Result<List<Task>>> getTasksFiltered({
    TaskStatus? status,
    TaskPriority? priority,
    String? projectId,
    List<String>? tags,
  });

  /// Get task completion activity for the last N months
  /// Returns a map where key is the date (day) and value is the count of completed tasks
  Future<Result<Map<DateTime, int>>> getTaskActivityForLastMonths(int months);
}
