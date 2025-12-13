import '../models/task_model.dart';

/// Task data source interface - Abstract database operations
abstract class TaskDataSource {
  /// Get all tasks
  Future<List<TaskModel>> getTasks();

  /// Get tasks by project
  Future<List<TaskModel>> getTasksByProject(String projectId);

  /// Get tasks by status
  Future<List<TaskModel>> getTasksByStatus(String status);

  /// Get task by ID
  Future<TaskModel?> getTaskById(String id);

  /// Create a new task
  Future<TaskModel> createTask(TaskModel task);

  /// Update an existing task
  Future<TaskModel> updateTask(TaskModel task);

  /// Delete a task
  Future<void> deleteTask(String id);

  /// Search tasks by query
  Future<List<TaskModel>> searchTasks(String query);

  /// Get tasks with filters
  Future<List<TaskModel>> getTasksFiltered(Map<String, dynamic> filters);
}
