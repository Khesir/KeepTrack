/// Update project use case
library;

import 'package:persona_codex/core/error/failure.dart';
import 'package:persona_codex/features/tasks/tasks.dart';

/// Use case for updating project details
class UpdateProjectUseCase {
  final ProjectRepository _repository;

  UpdateProjectUseCase(this._repository);

  /// Update project
  Future<Project> call(UpdateProjectParams params) async {
    // Get existing project
    final existing = await _repository.getProjectById(params.projectId);
    if (existing == null) {
      throw ValidationFailure('Project not found');
    }

    // Validation
    _validateParams(params);

    // Create updated project
    final updated = existing.copyWith(
      name: params.name?.trim(),
      description: params.description?.trim(),
      color: params.color,
      isArchived: params.isArchived,
    );

    return await _repository.updateProject(updated);
  }

  void _validateParams(UpdateProjectParams params) {
    // Name validation
    if (params.name != null) {
      if (params.name!.trim().isEmpty) {
        throw ValidationFailure('Project name cannot be empty');
      }

      if (params.name!.length > 255) {
        throw ValidationFailure('Project name cannot exceed 255 characters');
      }
    }

    // Description validation
    if (params.description != null && params.description!.length > 2000) {
      throw ValidationFailure('Description cannot exceed 2000 characters');
    }
  }
}

/// Parameters for updating a project
class UpdateProjectParams {
  final String projectId;
  final String? name;
  final String? description;
  final String? color;
  final bool? isArchived;

  UpdateProjectParams({
    required this.projectId,
    this.name,
    this.description,
    this.color,
    this.isArchived,
  });
}
