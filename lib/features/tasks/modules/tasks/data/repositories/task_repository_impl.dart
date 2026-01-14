import 'package:keep_track/core/error/failure.dart';
import 'package:keep_track/core/error/result.dart';

import '../../domain/entities/task.dart';
import '../../domain/repositories/task_repository.dart';
import '../datasources/task_datasource.dart';
import '../models/task_model.dart';

/// Task repository implementation
class TaskRepositoryImpl implements TaskRepository {
  final TaskDataSource dataSource;

  TaskRepositoryImpl(this.dataSource);

  @override
  Future<Result<List<Task>>> getTasks() async {
    final taskModels = await dataSource.getTasks();
    final tasks = taskModels.cast<Task>();
    return Result.success(tasks);
  }

  @override
  Future<Result<List<Task>>> getTasksByProject(String projectId) async {
    final taskModels = await dataSource.getTasksByProject(projectId);
    final tasks = taskModels.cast<Task>();
    return Result.success(tasks);
  }

  @override
  Future<Result<List<Task>>> getTasksByStatus(TaskStatus status) async {
    final taskModels = await dataSource.getTasksByStatus(status.name);
    final tasks = taskModels.cast<Task>();
    return Result.success(tasks);
  }

  @override
  Future<Result<Task>> getTaskById(String id) async {
    final task = await dataSource.getTaskById(id);
    if (task == null) {
      return Result.error(NotFoundFailure(message: 'Task not found: $id'));
    }
    return Result.success(task);
  }

  @override
  Future<Result<List<Task>>> getTasksByBucketID(String bucketId) async {
    final taskModels = await dataSource.getTasksByBucketId(bucketId);
    final tasks = taskModels.cast<Task>();
    return Result.success(tasks);
  }

  @override
  Future<Result<Task>> createTask(Task task) async {
    final model = TaskModel.fromEntity(task);
    final created = await dataSource.createTask(model);
    return Result.success(created);
  }

  @override
  Future<Result<Task>> updateTask(Task task) async {
    final model = TaskModel.fromEntity(task);
    final updated = await dataSource.updateTask(model);
    return Result.success(updated);
  }

  @override
  Future<Result<void>> deleteTask(String id) async {
    await dataSource.deleteTask(id);
    return Result.success(null);
  }

  @override
  Future<Result<List<Task>>> searchTasks(String query) async {
    final taskModels = await dataSource.searchTasks(query);
    final tasks = taskModels.cast<Task>();
    return Result.success(tasks);
  }

  @override
  Future<Result<List<Task>>> getTasksFiltered({
    TaskStatus? status,
    TaskPriority? priority,
    String? projectId,
    List<String>? tags,
  }) async {
    final filters = <String, dynamic>{};

    if (status != null) filters['status'] = status.name;
    if (priority != null) filters['priority'] = priority.name;
    if (projectId != null) filters['projectId'] = projectId;
    if (tags != null) filters['tags'] = tags;

    final taskModels = await dataSource.getTasksFiltered(filters);
    final tasks = taskModels.cast<Task>();
    return Result.success(tasks);
  }

  @override
  Future<Result<Map<DateTime, int>>> getTaskActivityForLastMonths(
    int months,
  ) async {
    try {
      final activity = await dataSource.getTaskActivityForLastMonths(months);
      return Result.success(activity);
    } catch (e) {
      return Result.error(
        ServerFailure(message: 'Failed to fetch task activity: $e'),
      );
    }
  }
}
