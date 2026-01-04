import 'package:keep_track/core/error/failure.dart';
import 'package:keep_track/core/error/result.dart';

import '../../domain/entities/project.dart';
import '../../domain/repositories/project_repository.dart';
import '../datasources/project_datasource.dart';
import '../models/project_model.dart';

/// Project repository implementation
class ProjectRepositoryImpl implements ProjectRepository {
  final ProjectDataSource dataSource;

  ProjectRepositoryImpl(this.dataSource);

  @override
  Future<Result<List<Project>>> getProjects() async {
    final projectModels = await dataSource.getProjects();
    final projects = projectModels.cast<Project>();
    return Result.success(projects);
  }

  @override
  Future<Result<List<Project>>> getActiveProjects() async {
    final projectModels = await dataSource.getActiveProjects();
    final projects = projectModels.cast<Project>();
    return Result.success(projects);
  }

  @override
  Future<Result<Project>> getProjectById(String id) async {
    final project = await dataSource.getProjectById(id);
    if (project == null) {
      return Result.error(NotFoundFailure(message: 'Project not found: $id'));
    }
    return Result.success(project);
  }

  @override
  Future<Result<Project>> createProject(Project project) async {
    final model = ProjectModel.fromEntity(project);
    final created = await dataSource.createProject(model);
    return Result.success(created);
  }

  @override
  Future<Result<Project>> updateProject(Project project) async {
    final model = ProjectModel.fromEntity(project);
    final updated = await dataSource.updateProject(model);
    return Result.success(updated);
  }

  @override
  Future<Result<void>> deleteProject(String id) async {
    await dataSource.deleteProject(id);
    return Result.success(null);
  }

  @override
  Future<Result<Project>> archiveProject(String id) async {
    final result = await getProjectById(id);
    if (result.isError) return result;

    final project = result.data;
    final archived = project.copyWith(
      isArchived: true,
      updatedAt: DateTime.now(),
    );

    return updateProject(archived);
  }

  @override
  Future<Result<Project>> unarchiveProject(String id) async {
    final result = await getProjectById(id);
    if (result.isError) return result;

    final project = result.data;
    final unarchived = project.copyWith(
      isArchived: false,
      updatedAt: DateTime.now(),
    );

    return updateProject(unarchived);
  }
}
