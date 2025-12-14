import '../../models/task_model.dart';
import '../task_datasource.dart';
import '../../../../../shared/infrastructure/supabase/supabase_service.dart';

/// Supabase implementation of TaskDataSource
class TaskDataSourceSupabase implements TaskDataSource {
  final SupabaseService supabaseService;
  static const String tableName = 'tasks';

  TaskDataSourceSupabase(this.supabaseService);

  @override
  Future<List<TaskModel>> getTasks() async {
    final response = await supabaseService.client
        .from(tableName)
        .select()
        .order('createdAt', ascending: false);

    return (response as List)
        .map((doc) => TaskModel.fromJson(doc as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<List<TaskModel>> getTasksByProject(String projectId) async {
    final response = await supabaseService.client
        .from(tableName)
        .select()
        .eq('projectId', projectId)
        .order('createdAt', ascending: false);

    return (response as List)
        .map((doc) => TaskModel.fromJson(doc as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<List<TaskModel>> getTasksByStatus(String status) async {
    final response = await supabaseService.client
        .from(tableName)
        .select()
        .eq('status', status)
        .order('createdAt', ascending: false);

    return (response as List)
        .map((doc) => TaskModel.fromJson(doc as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<TaskModel?> getTaskById(String id) async {
    final response = await supabaseService.client
        .from(tableName)
        .select()
        .eq('id', id)
        .maybeSingle();

    return response != null ? TaskModel.fromJson(response as Map<String, dynamic>) : null;
  }

  @override
  Future<TaskModel> createTask(TaskModel task) async {
    final doc = task.toJson();
    final response = await supabaseService.client
        .from(tableName)
        .insert(doc)
        .select()
        .single();

    return TaskModel.fromJson(response as Map<String, dynamic>);
  }

  @override
  Future<TaskModel> updateTask(TaskModel task) async {
    final doc = task.toJson();
    final response = await supabaseService.client
        .from(tableName)
        .update(doc)
        .eq('id', task.id)
        .select()
        .single();

    return TaskModel.fromJson(response as Map<String, dynamic>);
  }

  @override
  Future<void> deleteTask(String id) async {
    await supabaseService.client
        .from(tableName)
        .delete()
        .eq('id', id);
  }

  @override
  Future<List<TaskModel>> searchTasks(String query) async {
    final response = await supabaseService.client
        .from(tableName)
        .select()
        .or('title.ilike.%$query%,description.ilike.%$query%')
        .order('createdAt', ascending: false);

    return (response as List)
        .map((doc) => TaskModel.fromJson(doc as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<List<TaskModel>> getTasksFiltered(Map<String, dynamic> filters) async {
    var query = supabaseService.client.from(tableName).select();

    if (filters['status'] != null) {
      query = query.eq('status', filters['status']);
    }

    if (filters['priority'] != null) {
      query = query.eq('priority', filters['priority']);
    }

    if (filters['projectId'] != null) {
      query = query.eq('projectId', filters['projectId']);
    }

    if (filters['tags'] != null) {
      final tags = filters['tags'] as List<String>;
      query = query.contains('tags', tags);
    }

    final response = await query.order('createdAt', ascending: false);

    return (response as List)
        .map((doc) => TaskModel.fromJson(doc as Map<String, dynamic>))
        .toList();
  }
}
