/// Task list controller using Use Cases (Clean Architecture)
/// This is the CORRECT version - delegates to use cases, not repositories
library;

import '../../../../core/di/service_locator.dart';
import '../../../../core/state/stream_state.dart';
import '../../domain/entities/task.dart';
import '../../domain/usecases/usecases.dart';

/// Controller for task list screen using use cases
/// Follows Clean Architecture: Controller → Use Case → Repository
class TaskListController extends StreamState<AsyncState<List<Task>>> {
  final GetTasksUseCase _getTasksUseCase;
  final GetFilteredTasksUseCase _getFilteredTasksUseCase;
  final UpdateTaskStatusUseCase _updateTaskStatusUseCase;
  final DeleteTaskUseCase _deleteTaskUseCase;

  TaskStatus? _filterStatus;

  TaskListController({
    required GetTasksUseCase getTasksUseCase,
    required GetFilteredTasksUseCase getFilteredTasksUseCase,
    required UpdateTaskStatusUseCase updateTaskStatusUseCase,
    required DeleteTaskUseCase deleteTaskUseCase,
  })  : _getTasksUseCase = getTasksUseCase,
        _getFilteredTasksUseCase = getFilteredTasksUseCase,
        _updateTaskStatusUseCase = updateTaskStatusUseCase,
        _deleteTaskUseCase = deleteTaskUseCase,
        super(const AsyncLoading()) {
    loadTasks();
  }

  TaskStatus? get filterStatus => _filterStatus;

  /// Load all tasks or filtered by status
  Future<void> loadTasks() async {
    await execute(() async {
      if (_filterStatus != null) {
        return await _getFilteredTasksUseCase.byStatus(_filterStatus!);
      }
      return await _getTasksUseCase();
    });
  }

  /// Filter tasks by status
  Future<void> filterByStatus(TaskStatus? status) async {
    _filterStatus = status;
    await loadTasks();
  }

  /// Get overdue tasks
  Future<void> showOverdueTasks() async {
    _filterStatus = null; // Clear status filter
    await execute(() => _getFilteredTasksUseCase.overdue());
  }

  /// Get tasks due today
  Future<void> showTasksDueToday() async {
    _filterStatus = null;
    await execute(() => _getFilteredTasksUseCase.dueToday());
  }

  /// Get tasks due this week
  Future<void> showTasksDueThisWeek() async {
    _filterStatus = null;
    await execute(() => _getFilteredTasksUseCase.dueThisWeek());
  }

  /// Delete a task
  Future<void> deleteTask(String taskId) async {
    try {
      await _deleteTaskUseCase(taskId);
      await loadTasks(); // Reload list
    } catch (e) {
      emit(AsyncError('Failed to delete task: $e', e));
    }
  }

  /// Toggle task completion
  Future<void> toggleTaskCompletion(Task task) async {
    try {
      if (task.isCompleted) {
        await _updateTaskStatusUseCase.moveToTodo(task.id);
      } else {
        await _updateTaskStatusUseCase.complete(task.id);
      }
      await loadTasks(); // Reload list
    } catch (e) {
      emit(AsyncError('Failed to update task: $e', e));
    }
  }

  /// Mark task as in progress
  Future<void> markTaskInProgress(String taskId) async {
    try {
      await _updateTaskStatusUseCase.markInProgress(taskId);
      await loadTasks();
    } catch (e) {
      emit(AsyncError('Failed to update task: $e', e));
    }
  }

  /// Search tasks
  Future<void> searchTasks(String query) async {
    if (query.trim().isEmpty) {
      await loadTasks();
      return;
    }

    await execute(() => _getFilteredTasksUseCase.search(query));
  }

  /// Delete multiple tasks
  Future<void> deleteMultipleTasks(List<String> taskIds) async {
    try {
      final failures = await _deleteTaskUseCase.deleteMultiple(taskIds);

      if (failures.isEmpty) {
        await loadTasks();
      } else {
        await loadTasks();
        emit(AsyncError(
          'Failed to delete ${failures.length} task(s)',
          failures,
        ));
      }
    } catch (e) {
      emit(AsyncError('Failed to delete tasks: $e', e));
    }
  }
}

/// Factory function for DI registration
TaskListController createTaskListController(ServiceLocator locator) {
  return TaskListController(
    getTasksUseCase: locator.get<GetTasksUseCase>(),
    getFilteredTasksUseCase: locator.get<GetFilteredTasksUseCase>(),
    updateTaskStatusUseCase: locator.get<UpdateTaskStatusUseCase>(),
    deleteTaskUseCase: locator.get<DeleteTaskUseCase>(),
  );
}
