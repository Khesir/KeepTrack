import '../../domain/entities/task.dart';
import '../../domain/repositories/task_repository.dart';
import '../datasources/task_datasource.dart';
import '../models/task_model.dart';

/// Task repository implementation
class TaskRepositoryImpl implements TaskRepository {
  final TaskDataSource dataSource;

  TaskRepositoryImpl(this.dataSource);

  @override
  Future<List<Task>> getTasks() async {
    final models = await dataSource.getTasks();
    return models.map((model) => model.toEntity()).toList();
  }

  @override
  Future<List<Task>> getTasksByProject(String projectId) async {
    final models = await dataSource.getTasksByProject(projectId);
    return models.map((model) => model.toEntity()).toList();
  }

  @override
  Future<List<Task>> getTasksByStatus(TaskStatus status) async {
    final models = await dataSource.getTasksByStatus(status.name);
    return models.map((model) => model.toEntity()).toList();
  }

  @override
  Future<Task?> getTaskById(String id) async {
    final model = await dataSource.getTaskById(id);
    return model?.toEntity();
  }

  @override
  Future<Task> createTask(Task task) async {
    final model = TaskModel.fromEntity(task);
    final created = await dataSource.createTask(model);
    return created.toEntity();
  }

  @override
  Future<Task> updateTask(Task task) async {
    final model = TaskModel.fromEntity(task);
    final updated = await dataSource.updateTask(model);
    return updated.toEntity();
  }

  @override
  Future<void> deleteTask(String id) async {
    await dataSource.deleteTask(id);
  }

  @override
  Future<List<Task>> searchTasks(String query) async {
    final models = await dataSource.searchTasks(query);
    return models.map((model) => model.toEntity()).toList();
  }

  @override
  Future<List<Task>> getTasksFiltered({
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

    final models = await dataSource.getTasksFiltered(filters);
    return models.map((model) => model.toEntity()).toList();
  }
}
