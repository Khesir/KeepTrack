import '../entities/task.dart';

/// Task repository interface - Defines data access contract
abstract class TaskRepository {
  /// Get all tasks
  Future<List<Task>> getTasks();

  /// Get tasks by project
  Future<List<Task>> getTasksByProject(String projectId);

  /// Get tasks by status
  Future<List<Task>> getTasksByStatus(TaskStatus status);

  /// Get task by ID
  Future<Task?> getTaskById(String id);

  /// Create a new task
  Future<Task> createTask(Task task);

  /// Update an existing task
  Future<Task> updateTask(Task task);

  /// Delete a task
  Future<void> deleteTask(String id);

  /// Search tasks by title or description
  Future<List<Task>> searchTasks(String query);

  /// Get tasks with filters
  Future<List<Task>> getTasksFiltered({
    TaskStatus? status,
    TaskPriority? priority,
    String? projectId,
    List<String>? tags,
  });
}
