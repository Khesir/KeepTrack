import 'package:keep_track/core/error/failure.dart';
import 'package:keep_track/shared/infrastructure/supabase/supabase_service.dart';
import '../../models/goal_model.dart';
import '../goal_datasource.dart';

/// Supabase implementation of GoalDataSource
class GoalDataSourceSupabase implements GoalDataSource {
  final SupabaseService supabaseService;
  static const String tableName = 'goals';

  GoalDataSourceSupabase(this.supabaseService);

  @override
  Future<List<GoalModel>> fetchGoals() async {
    try {
      final response = await supabaseService.client
          .from(tableName)
          .select()
          .eq('user_id', supabaseService.userId!)
          .order('created_at', ascending: false);

      return (response as List).map((doc) => GoalModel.fromJson(doc)).toList();
    } catch (e, stackTrace) {
      throw UnknownFailure(
        message: 'Failed to fetch goals',
        originalError: e,
        stackTrace: stackTrace,
      );
    }
  }

  @override
  Future<GoalModel?> fetchGoalById(String id) async {
    try {
      final response = await supabaseService.client
          .from(tableName)
          .select()
          .eq('id', id)
          .eq('user_id', supabaseService.userId!)
          .maybeSingle();

      return response != null ? GoalModel.fromJson(response) : null;
    } catch (e, stackTrace) {
      throw UnknownFailure(
        message: 'Failed to fetch goals',
        originalError: e,
        stackTrace: stackTrace,
      );
    }
  }

  @override
  Future<GoalModel> createGoal(GoalModel goal) async {
    try {
      final doc = goal.toJson();
      final response = await supabaseService.client
          .from(tableName)
          .insert(doc)
          .select()
          .single();

      return GoalModel.fromJson(response);
    } catch (e, stackTrace) {
      throw UnknownFailure(
        message: 'Failed to fetch goals',
        originalError: e,
        stackTrace: stackTrace,
      );
    }
  }

  @override
  Future<GoalModel> updateGoal(GoalModel goal) async {
    try {
      if (goal.id == null) {
        throw Exception('Cannot update goal without an ID');
      }

      final doc = goal.toJson();
      final response = await supabaseService.client
          .from(tableName)
          .update(doc)
          .eq('id', goal.id!)
          .eq('user_id', supabaseService.userId!)
          .select()
          .single();

      return GoalModel.fromJson(response);
    } catch (e, stackTrace) {
      throw UnknownFailure(
        message: 'Failed to create goal',
        originalError: e,
        stackTrace: stackTrace,
      );
    }
  }

  @override
  Future<void> deleteGoal(String id) async {
    try {
      await supabaseService.client
          .from(tableName)
          .delete()
          .eq('id', id)
          .eq('user_id', supabaseService.userId!);
    } catch (e, stackTrace) {
      throw UnknownFailure(
        message: 'Failed to delete goal',
        originalError: e,
        stackTrace: stackTrace,
      );
    }
  }

  @override
  Future<List<GoalModel>> fetchGoalsByStatus(String status) async {
    try {
      final response = await supabaseService.client
          .from(tableName)
          .select()
          .eq('status', status)
          .eq('user_id', supabaseService.userId!)
          .order('created_at', ascending: false);

      return (response as List).map((doc) => GoalModel.fromJson(doc)).toList();
    } catch (e, stackTrace) {
      throw UnknownFailure(
        message: 'Failed to fetch goals by status',
        originalError: e,
        stackTrace: stackTrace,
      );
    }
  }
}
