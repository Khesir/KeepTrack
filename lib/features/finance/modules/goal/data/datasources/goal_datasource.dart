import 'package:persona_codex/features/finance/modules/goal/data/models/goal_model.dart';

/// Data source interface for Goal operations
abstract class GoalDataSource {
  /// Fetch all goals for the current user
  Future<List<GoalModel>> fetchGoals();

  /// Fetch a specific goal by ID
  Future<GoalModel?> fetchGoalById(String id);

  /// Create a new goal
  Future<GoalModel> createGoal(GoalModel goal);

  /// Update an existing goal
  Future<GoalModel> updateGoal(GoalModel goal);

  /// Delete a goal
  Future<void> deleteGoal(String id);

  /// Fetch goals filtered by status
  Future<List<GoalModel>> fetchGoalsByStatus(String status);
}
