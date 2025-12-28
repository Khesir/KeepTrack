import 'package:persona_codex/core/error/result.dart';
import 'package:persona_codex/core/state/stream_state.dart';
import '../../modules/projects/domain/entities/project.dart';
import '../../modules/projects/domain/repositories/project_repository.dart';

/// Controller for managing project list state
class ProjectController extends StreamState<AsyncState<List<Project>>> {
  final ProjectRepository _repository;

  ProjectController(this._repository) : super(const AsyncLoading()) {
    loadProjects();
  }

  /// Load all projects
  Future<void> loadProjects() async {
    await execute(() async {
      return await _repository.getProjects().then((r) => r.unwrap());
    });
  }

  /// Load active projects only
  Future<void> loadActiveProjects() async {
    await execute(() async {
      return await _repository.getActiveProjects().then((r) => r.unwrap());
    });
  }

  /// Create a new project
  Future<void> createProject(Project project) async {
    await execute(() async {
      final created = await _repository
          .createProject(project)
          .then((r) => r.unwrap());
      final current = data ?? [];
      return [...current, created];
    });
  }

  /// Update an existing project
  Future<void> updateProject(Project project) async {
    await execute(() async {
      await _repository.updateProject(project).then((r) => r.unwrap());
      await loadProjects();
      return data ?? [];
    });
  }

  /// Delete a project
  Future<void> deleteProject(String id) async {
    await execute(() async {
      await _repository.deleteProject(id).then((r) => r.unwrap());
      await loadProjects();
      return data ?? [];
    });
  }

  /// Archive a project
  Future<void> archiveProject(String id) async {
    await execute(() async {
      await _repository.archiveProject(id).then((r) => r.unwrap());
      await loadProjects();
      return data ?? [];
    });
  }

  /// Unarchive a project
  Future<void> unarchiveProject(String id) async {
    await execute(() async {
      await _repository.unarchiveProject(id).then((r) => r.unwrap());
      await loadProjects();
      return data ?? [];
    });
  }
}
