library;

import 'package:persona_codex/features/tasks/tasks.dart';

class GetProjectsUsecase {
  final ProjectRepository _repository;

  GetProjectsUsecase(this._repository);

  Future<List<Project>> call() async {
    final projects = await _repository.getActiveProjects();
    return projects;
  }
}
