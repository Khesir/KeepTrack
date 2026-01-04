import 'package:keep_track/core/error/result.dart';

import '../entities/project.dart';

/// Project repository interface - Defines data access contract
abstract class ProjectRepository {
  /// Get all projects
  Future<Result<List<Project>>> getProjects();

  /// Get active (non-archived) projects
  Future<Result<List<Project>>> getActiveProjects();

  /// Get project by ID
  Future<Result<Project>> getProjectById(String id);

  /// Create a new project
  Future<Result<Project>> createProject(Project project);

  /// Update an existing project
  Future<Result<Project>> updateProject(Project project);

  /// Delete a project
  Future<Result<void>> deleteProject(String id);

  /// Archive a project
  Future<Result<Project>> archiveProject(String id);

  /// Unarchive a project
  Future<Result<Project>> unarchiveProject(String id);
}
