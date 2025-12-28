import 'package:persona_codex/core/error/result.dart';
import 'package:persona_codex/core/state/stream_state.dart';
import '../../modules/tasks/domain/entities/task.dart';
import '../../modules/tasks/domain/repositories/task_repository.dart';

/// Controller for managing task list state
class TaskController extends StreamState<AsyncState<List<Task>>> {
  final TaskRepository _repository;

  TaskController(this._repository) : super(const AsyncLoading()) {
    loadTasks();
  }

  /// Load all tasks
  Future<void> loadTasks() async {
    await execute(() async {
      return await _repository.getTasks().then((r) => r.unwrap());
    });
  }

  /// Create a new task
  Future<void> createTask(Task task) async {
    await execute(() async {
      final created = await _repository
          .createTask(task)
          .then((r) => r.unwrap());
      final current = data ?? [];
      return [...current, created];
    });
  }

  /// Update an existing task
  Future<void> updateTask(Task task) async {
    await execute(() async {
      await _repository.updateTask(task).then((r) => r.unwrap());
      await loadTasks();
      return data ?? [];
    });
  }

  /// Delete a task
  Future<void> deleteTask(String id) async {
    await execute(() async {
      await _repository.deleteTask(id).then((r) => r.unwrap());
      await loadTasks();
      return data ?? [];
    });
  }

  /// Get tasks by project
  Future<void> loadTasksByProject(String projectId) async {
    await execute(() async {
      return await _repository
          .getTasksByProject(projectId)
          .then((r) => r.unwrap());
    });
  }

  /// Get tasks by status
  Future<void> loadTasksByStatus(TaskStatus status) async {
    await execute(() async {
      return await _repository.getTasksByStatus(status).then((r) => r.unwrap());
    });
  }

  /// Search tasks
  Future<void> searchTasks(String query) async {
    await execute(() async {
      return await _repository.searchTasks(query).then((r) => r.unwrap());
    });
  }

  /// Get tasks with filters
  Future<void> loadTasksFiltered({
    TaskStatus? status,
    TaskPriority? priority,
    String? projectId,
    List<String>? tags,
  }) async {
    await execute(() async {
      return await _repository
          .getTasksFiltered(
            status: status,
            priority: priority,
            projectId: projectId,
            tags: tags,
          )
          .then((r) => r.unwrap());
    });
  }
}
