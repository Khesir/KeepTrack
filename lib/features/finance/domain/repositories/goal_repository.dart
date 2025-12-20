import 'package:persona_codex/core/error/result.dart';
import 'package:persona_codex/features/finance/domain/entities/goal.dart';

/// Repository interface for managing financial goals
abstract class GoalRepository {
  /// Get all goals for the current user
  Future<Result<List<Goal>>> getGoals();

  /// Get a specific goal by ID
  Future<Result<Goal>> getGoalById(String id);

  /// Create a new goal
  Future<Result<Goal>> createGoal(Goal goal);

  /// Update an existing goal
  Future<Result<Goal>> updateGoal(Goal goal);

  /// Delete a goal
  Future<Result<void>> deleteGoal(String id);

  /// Get goals filtered by status
  Future<Result<List<Goal>>> getGoalsByStatus(GoalStatus status);

  /// Update the current amount of a goal (for contributions)
  Future<Result<Goal>> updateGoalProgress(String id, double newAmount);
}
