/// Task list controller using custom StreamState
/// Pure business logic, framework-agnostic
library;

import '../../../../core/di/service_locator.dart';
import '../../../../core/state/stream_state.dart';
import '../../domain/entities/task.dart';
import '../../domain/repositories/task_repository.dart';

/// Controller for task list screen
/// Uses StreamState for reactive updates
class TaskListController extends StreamState<AsyncState<List<Task>>> {
  final TaskRepository _repository;
  TaskStatus? _filterStatus;

  TaskListController(this._repository) : super(const AsyncLoading()) {
    loadTasks();
  }

  TaskStatus? get filterStatus => _filterStatus;

  /// Load all tasks or filtered by status
  Future<void> loadTasks() async {
    await execute(() async {
      if (_filterStatus != null) {
        return await _repository.getTasksByStatus(_filterStatus!);
      }
      return await _repository.getTasks();
    });
  }

  /// Filter tasks by status
  Future<void> filterByStatus(TaskStatus? status) async {
    _filterStatus = status;
    await loadTasks();
  }

  /// Delete a task
  Future<void> deleteTask(String taskId) async {
    try {
      await _repository.deleteTask(taskId);
      await loadTasks(); // Reload list
    } catch (e) {
      emit(AsyncError('Failed to delete task: $e', e));
    }
  }

  /// Toggle task completion
  Future<void> toggleTaskCompletion(Task task) async {
    try {
      final newStatus = task.isCompleted
          ? TaskStatus.inProgress
          : TaskStatus.completed;

      final updated = task.copyWith(
        status: newStatus,
        completedAt: newStatus == TaskStatus.completed ? DateTime.now() : null,
        updatedAt: DateTime.now(),
      );

      await _repository.updateTask(updated);
      await loadTasks(); // Reload list
    } catch (e) {
      emit(AsyncError('Failed to update task: $e', e));
    }
  }

  /// Search tasks
  Future<void> searchTasks(String query) async {
    if (query.isEmpty) {
      await loadTasks();
      return;
    }

    await execute(() => _repository.searchTasks(query));
  }
}

/// Factory function for DI registration
TaskListController createTaskListController(ScopedServiceLocator locator) {
  return TaskListController(locator.get<TaskRepository>());
}
