import '../../../../../shared/infrastructure/supabase/supabase_service.dart';
import '../../models/project_model.dart';
import '../project_datasource.dart';

/// Supabase implementation of ProjectDataSource
class ProjectDataSourceSupabase implements ProjectDataSource {
  final SupabaseService supabaseService;
  static const String tableName = 'projects';

  ProjectDataSourceSupabase(this.supabaseService);

  @override
  Future<List<ProjectModel>> getProjects() async {
    final response = await supabaseService.client
        .from(tableName)
        .select()
        .order('created_at', ascending: false);

    return (response as List)
        .map((doc) => ProjectModel.fromJson(doc as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<List<ProjectModel>> getActiveProjects() async {
    final response = await supabaseService.client
        .from(tableName)
        .select()
        .eq('is_archived', false)
        .order('created_at', ascending: false);

    return (response as List)
        .map((doc) => ProjectModel.fromJson(doc as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<ProjectModel?> getProjectById(String id) async {
    final response = await supabaseService.client
        .from(tableName)
        .select()
        .eq('id', id)
        .maybeSingle();

    return response != null
        ? ProjectModel.fromJson(response as Map<String, dynamic>)
        : null;
  }

  @override
  Future<ProjectModel> createProject(ProjectModel project) async {
    final doc = project.toJson();
    final response = await supabaseService.client
        .from(tableName)
        .insert(doc)
        .select()
        .single();

    return ProjectModel.fromJson(response as Map<String, dynamic>);
  }

  @override
  Future<ProjectModel> updateProject(ProjectModel project) async {
    if (project.id == null) {
      throw Exception('Cannot update project without an ID');
    }

    final doc = project.toJson();
    final response = await supabaseService.client
        .from(tableName)
        .update(doc)
        .eq('id', project.id!)
        .select()
        .single();

    return ProjectModel.fromJson(response as Map<String, dynamic>);
  }

  @override
  Future<void> deleteProject(String id) async {
    await supabaseService.client.from(tableName).delete().eq('id', id);
  }
}
