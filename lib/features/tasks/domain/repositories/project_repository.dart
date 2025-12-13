import '../entities/project.dart';

/// Project repository interface - Defines data access contract
abstract class ProjectRepository {
  /// Get all projects
  Future<List<Project>> getProjects();

  /// Get active (non-archived) projects
  Future<List<Project>> getActiveProjects();

  /// Get project by ID
  Future<Project?> getProjectById(String id);

  /// Create a new project
  Future<Project> createProject(Project project);

  /// Update an existing project
  Future<Project> updateProject(Project project);

  /// Delete a project
  Future<void> deleteProject(String id);

  /// Archive a project
  Future<Project> archiveProject(String id);

  /// Unarchive a project
  Future<Project> unarchiveProject(String id);
}
