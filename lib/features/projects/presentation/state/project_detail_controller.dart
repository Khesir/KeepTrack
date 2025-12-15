/// Project detail controller using Use Cases
library;

import 'package:persona_codex/core/state/stream_state.dart';
import 'package:persona_codex/features/projects/domain/entities/project.dart';
import 'package:persona_codex/features/projects/domain/usecase/usecases.dart';
import 'package:persona_codex/features/tasks/domain/entities/task.dart';
import 'package:persona_codex/features/tasks/domain/usecases/usecases.dart';

/// Controller for project detail screen
class ProjectDetailController extends StreamState<AsyncState<Project?>> {
  final UpdateProjectUseCase _updateProjectUseCase;
  final DeleteProjectUseCase _deleteProjectUseCase;
  final GetTasksByProjectUseCase _getTasksByProjectUseCase;

  List<Task> _tasks = [];
  List<Task> get tasks => _tasks;

  bool _isLoadingTasks = false;
  bool get isLoadingTasks => _isLoadingTasks;

  ProjectDetailController({
    required UpdateProjectUseCase updateProjectUseCase,
    required DeleteProjectUseCase deleteProjectUseCase,
    required GetTasksByProjectUseCase getTasksByProjectUseCase,
    required Project initialProject,
  }) : _updateProjectUseCase = updateProjectUseCase,
       _deleteProjectUseCase = deleteProjectUseCase,
       _getTasksByProjectUseCase = getTasksByProjectUseCase,
       super(AsyncData(initialProject)) {
    loadTasks();
  }

  /// Load tasks for this project using the use case
  Future<void> loadTasks() async {
    final currentState = state;
    if (currentState is! AsyncData<Project?>) return;

    final project = currentState.data;

    if (project == null) return;
    if (project.id == null) return;

    _isLoadingTasks = true;
    emit(currentState); // Trigger rebuild to show loading state

    try {
      _tasks = await _getTasksByProjectUseCase(project.id!);
      _isLoadingTasks = false;
      emit(currentState); // Trigger rebuild with loaded tasks
    } catch (e) {
      _isLoadingTasks = false;
      emit(currentState); // Trigger rebuild even on error
      // Silently fail - tasks are optional
    }
  }

  /// Update project details
  Future<bool> updateProject(UpdateProjectParams params) async {
    try {
      final project = await _updateProjectUseCase(params);
      emit(AsyncData(project));
      return true;
    } catch (e) {
      emit(AsyncError('Failed to update project: $e', e));
      return false;
    }
  }

  /// Delete the project
  Future<bool> deleteProject(String projectId) async {
    try {
      await _deleteProjectUseCase(projectId);
      emit(const AsyncData(null));
      return true;
    } catch (e) {
      emit(AsyncError('Failed to delete project: $e', e));
      return false;
    }
  }

  /// Get completed task count
  int get completedCount => _tasks.where((task) => task.isCompleted).length;

  /// Get total task count
  int get totalCount => _tasks.length;
}
