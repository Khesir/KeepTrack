import '../../models/task_model.dart';
import '../task_datasource.dart';
import '../../../../../../../shared/infrastructure/supabase/supabase_service.dart';

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
        .eq('user_id', supabaseService.userId!)
        .order('created_at', ascending: false);

    return (response as List)
        .map((doc) => TaskModel.fromJson(doc as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<List<TaskModel>> getTasksByProject(String projectId) async {
    final response = await supabaseService.client
        .from(tableName)
        .select()
        .eq('user_id', supabaseService.userId!)
        .eq('project_id', projectId)
        .order('created_at', ascending: false);

    return (response as List)
        .map((doc) => TaskModel.fromJson(doc as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<List<TaskModel>> getSubtasks(String parentTaskId) async {
    final response = await supabaseService.client
        .from(tableName)
        .select()
        .eq('user_id', supabaseService.userId!)
        .eq('parent_task_id', parentTaskId)
        .order('created_at', ascending: false);

    return (response as List)
        .map((doc) => TaskModel.fromJson(doc as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<List<TaskModel>> getTasksByStatus(String status) async {
    final response = await supabaseService.client
        .from(tableName)
        .select()
        .eq('user_id', supabaseService.userId!)
        .eq('status', status)
        .order('created_at', ascending: false);

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
        .eq('user_id', supabaseService.userId!)
        .maybeSingle();

    return response != null
        ? TaskModel.fromJson(response as Map<String, dynamic>)
        : null;
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
    if (task.id == null) {
      throw Exception('Cannot update task without an ID');
    }

    final doc = task.toJson();
    final response = await supabaseService.client
        .from(tableName)
        .update(doc)
        .eq('id', task.id!)
        .eq('user_id', supabaseService.userId!)
        .select()
        .single();

    return TaskModel.fromJson(response as Map<String, dynamic>);
  }

  @override
  Future<void> deleteTask(String id) async {
    await supabaseService.client
        .from(tableName)
        .delete()
        .eq('id', id)
        .eq('user_id', supabaseService.userId!);
  }

  @override
  Future<List<TaskModel>> searchTasks(String query) async {
    final response = await supabaseService.client
        .from(tableName)
        .select()
        .eq('user_id', supabaseService.userId!)
        .or('title.ilike.%$query%,description.ilike.%$query%')
        .order('created_at', ascending: false);

    return (response as List)
        .map((doc) => TaskModel.fromJson(doc as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<List<TaskModel>> getTasksFiltered(Map<String, dynamic> filters) async {
    var query = supabaseService.client
        .from(tableName)
        .select()
        .eq('user_id', supabaseService.userId!);

    if (filters['status'] != null) {
      query = query.eq('status', filters['status']);
    }

    if (filters['priority'] != null) {
      query = query.eq('priority', filters['priority']);
    }

    if (filters['projectId'] != null) {
      query = query.eq('project_id', filters['projectId']);
    }

    if (filters['tags'] != null) {
      final tags = filters['tags'] as List<String>;
      query = query.contains('tags', tags);
    }

    final response = await query.order('created_at', ascending: false);

    return (response as List)
        .map((doc) => TaskModel.fromJson(doc as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<Map<DateTime, int>> getTaskActivityForLastMonths(int months) async {
    // Calculate the start date (N months ago)
    final now = DateTime.now();
    final startDate = DateTime(now.year, now.month - months, now.day);

    // Query completed tasks in the date range
    final response = await supabaseService.client
        .from(tableName)
        .select('completed_at')
        .eq('user_id', supabaseService.userId!)
        .eq('status', 'completed')
        .not('completed_at', 'is', null)
        .gte('completed_at', startDate.toIso8601String())
        .order('completed_at', ascending: true);

    // Group tasks by date (day)
    final Map<DateTime, int> activity = {};

    for (final task in (response as List)) {
      final completedAtStr = task['completed_at'] as String?;
      if (completedAtStr != null) {
        final completedAt = DateTime.parse(completedAtStr);
        // Normalize to day (remove time component)
        final date = DateTime(completedAt.year, completedAt.month, completedAt.day);
        activity[date] = (activity[date] ?? 0) + 1;
      }
    }

    return activity;
  }
}
