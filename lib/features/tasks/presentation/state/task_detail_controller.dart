/// Task detail controller using Use Cases
library;

import '../../../../core/state/stream_state.dart';
import '../../../projects/domain/entities/project.dart';
import '../../../projects/domain/repositories/project_repository.dart';
import '../../domain/entities/task.dart';
import '../../domain/usecases/usecases.dart';

/// Controller for task detail screen using use cases
class TaskDetailController extends StreamState<AsyncState<Task?>> {
  final CreateTaskUseCase _createTaskUseCase;
  final UpdateTaskUseCase _updateTaskUseCase;
  final DeleteTaskUseCase _deleteTaskUseCase;
  final ProjectRepository _projectRepository;

  List<Project> _projects = [];
  List<Project> get projects => _projects;

  TaskDetailController({
    required CreateTaskUseCase createTaskUseCase,
    required UpdateTaskUseCase updateTaskUseCase,
    required DeleteTaskUseCase deleteTaskUseCase,
    required ProjectRepository projectRepository,
    Task? initialTask,
  })  : _createTaskUseCase = createTaskUseCase,
        _updateTaskUseCase = updateTaskUseCase,
        _deleteTaskUseCase = deleteTaskUseCase,
        _projectRepository = projectRepository,
        super(AsyncData(initialTask)) {
    loadProjects();
  }

  /// Load available projects for the dropdown
  Future<void> loadProjects() async {
    try {
      _projects = await _projectRepository.getActiveProjects();
      // Don't emit state change for projects, they're just for the dropdown
    } catch (e) {
      // Ignore error, projects are optional
    }
  }

  /// Create a new task
  Future<bool> createTask(CreateTaskParams params) async {
    try {
      final task = await _createTaskUseCase(params);
      emit(AsyncData(task));
      return true;
    } catch (e) {
      emit(AsyncError('Failed to create task: $e', e));
      return false;
    }
  }

  /// Update an existing task
  Future<bool> updateTask(UpdateTaskParams params) async {
    try {
      final task = await _updateTaskUseCase(params);
      emit(AsyncData(task));
      return true;
    } catch (e) {
      emit(AsyncError('Failed to update task: $e', e));
      return false;
    }
  }

  /// Delete the task
  Future<bool> deleteTask(String taskId) async {
    try {
      await _deleteTaskUseCase(taskId);
      emit(const AsyncData(null));
      return true;
    } catch (e) {
      emit(AsyncError('Failed to delete task: $e', e));
      return false;
    }
  }
}
