import '../models/project_model.dart';

/// Project data source interface - Abstract database operations
abstract class ProjectDataSource {
  /// Get all projects
  Future<List<ProjectModel>> getProjects();

  /// Get active projects
  Future<List<ProjectModel>> getActiveProjects();

  /// Get project by ID
  Future<ProjectModel?> getProjectById(String id);

  // Get Projects by bucketIDs
  Future<List<ProjectModel>> getProjectsByBucketId(String bucketId);

  /// Create a new project
  Future<ProjectModel> createProject(ProjectModel project);

  /// Update an existing project
  Future<ProjectModel> updateProject(ProjectModel project);

  /// Delete a project
  Future<void> deleteProject(String id);
}
