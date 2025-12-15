library;

import 'package:persona_codex/core/error/failure.dart';
import 'package:persona_codex/features/tasks/tasks.dart';

class CreateProjectUsecase {
  final ProjectRepository _repository;

  CreateProjectUsecase(this._repository);

  Future<Project> call(CreateProjectParams params) async {
    // Validation
    _validateParams(params);

    final project = Project(
      name: params.name.trim(),
      description: params.description?.trim(),
      color: params.color,
      isArchived: params.isArchived,
    );
    return await _repository.createProject(project);
  }

  void _validateParams(CreateProjectParams params) {
    // Name validation
    if (params.name.trim().isEmpty) {
      throw ValidationFailure('Task title cannot be empty');
    }

    if (params.name.length > 255) {
      throw ValidationFailure('Task title cannot exceed 255 characters');
    }
    // Description Validation

    // Description validation
    if (params.description != null && params.description!.length > 2000) {
      throw ValidationFailure('Description cannot exceed 2000 characters');
    }
  }
}

class CreateProjectParams {
  final String name;
  final String? description;
  final String? color;
  final bool isArchived;

  CreateProjectParams({
    required this.name,
    this.description,
    this.color,
    this.isArchived = false,
  });
}
