import 'package:persona_codex/core/state/state.dart';
import 'package:persona_codex/features/projects/domain/entities/project.dart';
import 'package:persona_codex/features/projects/domain/usecase/create_project_usecase.dart';
import 'package:persona_codex/features/projects/domain/usecase/get_projects_usecase.dart';

class ProjectListController extends StreamState<AsyncState<List<Project>>> {
  final GetProjectsUsecase _getProjectsUsecase;
  final CreateProjectUsecase _createProjectUsecase;

  ProjectListController({
    required GetProjectsUsecase getProjectUsecase,
    required CreateProjectUsecase createProjectUsecase,
  }) : _getProjectsUsecase = getProjectUsecase,
       _createProjectUsecase = createProjectUsecase,
       super(const AsyncLoading()) {
    loadProjects();
  }

  Future<void> loadProjects() async {
    await execute(() async {
      return await _getProjectsUsecase();
    });
  }

  Future<void> createProject(CreateProjectParams project) async {
    await _createProjectUsecase(project);
  }
}
