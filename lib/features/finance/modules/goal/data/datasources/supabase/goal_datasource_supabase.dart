import 'package:persona_codex/shared/infrastructure/supabase/supabase_service.dart';
import '../../models/goal_model.dart';
import '../goal_datasource.dart';

/// Supabase implementation of GoalDataSource
class GoalDataSourceSupabase implements GoalDataSource {
  final SupabaseService supabaseService;
  static const String tableName = 'goals';

  GoalDataSourceSupabase(this.supabaseService);

  @override
  Future<List<GoalModel>> fetchGoals() async {
    final response = await supabaseService.client
        .from(tableName)
        .select()
        .order('created_at', ascending: false);

    return (response as List).map((doc) => GoalModel.fromJson(doc)).toList();
  }

  @override
  Future<GoalModel?> fetchGoalById(String id) async {
    final response = await supabaseService.client
        .from(tableName)
        .select()
        .eq('id', id)
        .maybeSingle();

    return response != null ? GoalModel.fromJson(response) : null;
  }

  @override
  Future<GoalModel> createGoal(GoalModel goal) async {
    final doc = goal.toJson();
    final response = await supabaseService.client
        .from(tableName)
        .insert(doc)
        .select()
        .single();

    return GoalModel.fromJson(response);
  }

  @override
  Future<GoalModel> updateGoal(GoalModel goal) async {
    if (goal.id == null) {
      throw Exception('Cannot update goal without an ID');
    }

    final doc = goal.toJson();
    final response = await supabaseService.client
        .from(tableName)
        .update(doc)
        .eq('id', goal.id!)
        .select()
        .single();

    return GoalModel.fromJson(response);
  }

  @override
  Future<void> deleteGoal(String id) async {
    await supabaseService.client.from(tableName).delete().eq('id', id);
  }

  @override
  Future<List<GoalModel>> fetchGoalsByStatus(String status) async {
    final response = await supabaseService.client
        .from(tableName)
        .select()
        .eq('status', status)
        .order('created_at', ascending: false);

    return (response as List).map((doc) => GoalModel.fromJson(doc)).toList();
  }
}
