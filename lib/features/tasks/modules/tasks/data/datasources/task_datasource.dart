import '../models/task_model.dart';

/// Task data source interface - Abstract database operations
abstract class TaskDataSource {
  /// Get all tasks
  Future<List<TaskModel>> getTasks();

  /// Get tasks by project
  Future<List<TaskModel>> getTasksByProject(String projectId);

  /// Get subtasks by parent task ID
  Future<List<TaskModel>> getSubtasks(String parentTaskId);

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

  /// Get task completion activity for the last N months
  /// Returns a map where key is the date (day) and value is the count of completed tasks
  Future<Map<DateTime, int>> getTaskActivityForLastMonths(int months);
}
