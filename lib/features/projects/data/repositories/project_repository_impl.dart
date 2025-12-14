import '../../domain/entities/project.dart';
import '../../domain/repositories/project_repository.dart';
import '../datasources/project_datasource.dart';
import '../models/project_model.dart';

/// Project repository implementation
class ProjectRepositoryImpl implements ProjectRepository {
  final ProjectDataSource dataSource;

  ProjectRepositoryImpl(this.dataSource);

  @override
  Future<List<Project>> getProjects() async {
    final models = await dataSource.getProjects();
    return models.map((model) => model.toEntity()).toList();
  }

  @override
  Future<List<Project>> getActiveProjects() async {
    final models = await dataSource.getActiveProjects();
    return models.map((model) => model.toEntity()).toList();
  }

  @override
  Future<Project?> getProjectById(String id) async {
    final model = await dataSource.getProjectById(id);
    return model?.toEntity();
  }

  @override
  Future<Project> createProject(Project project) async {
    final model = ProjectModel.fromEntity(project);
    final created = await dataSource.createProject(model);
    return created.toEntity();
  }

  @override
  Future<Project> updateProject(Project project) async {
    final model = ProjectModel.fromEntity(project);
    final updated = await dataSource.updateProject(model);
    return updated.toEntity();
  }

  @override
  Future<void> deleteProject(String id) async {
    await dataSource.deleteProject(id);
  }

  @override
  Future<Project> archiveProject(String id) async {
    final project = await getProjectById(id);
    if (project == null) {
      throw Exception('Project not found: $id');
    }

    final archived = project.copyWith(
      isArchived: true,
      updatedAt: DateTime.now(),
    );

    return updateProject(archived);
  }

  @override
  Future<Project> unarchiveProject(String id) async {
    final project = await getProjectById(id);
    if (project == null) {
      throw Exception('Project not found: $id');
    }

    final unarchived = project.copyWith(
      isArchived: false,
      updatedAt: DateTime.now(),
    );

    return updateProject(unarchived);
  }
}
