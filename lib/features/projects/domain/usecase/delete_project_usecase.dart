import 'package:persona_codex/core/error/failure.dart';
import 'package:persona_codex/features/tasks/tasks.dart';

/// Use case for deleting a project
class DeleteProjectUseCase {
  final ProjectRepository _repository;

  DeleteProjectUseCase(this._repository);

  /// Delete a project by ID
  /// Throws ValidationFailure if project doesn't exist
  Future<void> call(String projectId) async {
    // Verify project exists
    final project = await _repository.getProjectById(projectId);
    if (project == null) {
      throw ValidationFailure('Project not found');
    }

    // Business rule: Could add check for active tasks here
    // if (project.hasActiveTasks) {
    //   throw ValidationFailure('Cannot delete project with active tasks');
    // }

    await _repository.deleteProject(projectId);
  }
}
