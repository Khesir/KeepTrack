import 'package:persona_codex/core/error/result.dart';
import 'package:persona_codex/core/error/failure.dart';
import 'package:persona_codex/features/finance/data/datasources/goal_datasource.dart';
import 'package:persona_codex/features/finance/data/models/goal_model.dart';
import 'package:persona_codex/features/finance/domain/entities/goal.dart';
import 'package:persona_codex/features/finance/domain/repositories/goal_repository.dart';

/// Goal repository implementation
class GoalRepositoryImpl implements GoalRepository {
  final GoalDataSource dataSource;

  GoalRepositoryImpl(this.dataSource);

  @override
  Future<Result<List<Goal>>> getGoals() async {
    try {
      final goals = await dataSource.fetchGoals();
      return Result.success(goals);
    } catch (e) {
      return Result.error(
        UnknownFailure(message: 'Failed to fetch goals', originalError: e),
      );
    }
  }

  @override
  Future<Result<Goal>> getGoalById(String id) async {
    try {
      final goal = await dataSource.fetchGoalById(id);
      if (goal == null) {
        return Result.error(
          NotFoundFailure(message: 'Goal not found: $id'),
        );
      }
      return Result.success(goal);
    } catch (e) {
      return Result.error(
        UnknownFailure(message: 'Failed to fetch goal', originalError: e),
      );
    }
  }

  @override
  Future<Result<Goal>> createGoal(Goal goal) async {
    try {
      final model = GoalModel.fromEntity(goal);
      final created = await dataSource.createGoal(model);
      return Result.success(created);
    } catch (e) {
      return Result.error(
        UnknownFailure(message: 'Failed to create goal', originalError: e),
      );
    }
  }

  @override
  Future<Result<Goal>> updateGoal(Goal goal) async {
    try {
      final model = GoalModel.fromEntity(goal);
      final updated = await dataSource.updateGoal(model);
      return Result.success(updated);
    } catch (e) {
      return Result.error(
        UnknownFailure(message: 'Failed to update goal', originalError: e),
      );
    }
  }

  @override
  Future<Result<void>> deleteGoal(String id) async {
    try {
      await dataSource.deleteGoal(id);
      return Result.success(null);
    } catch (e) {
      return Result.error(
        UnknownFailure(message: 'Failed to delete goal', originalError: e),
      );
    }
  }

  @override
  Future<Result<List<Goal>>> getGoalsByStatus(GoalStatus status) async {
    try {
      final statusString = status.name;
      final goals = await dataSource.fetchGoalsByStatus(statusString);
      return Result.success(goals);
    } catch (e) {
      return Result.error(
        UnknownFailure(message: 'Failed to fetch goals by status', originalError: e),
      );
    }
  }

  @override
  Future<Result<Goal>> updateGoalProgress(String id, double newAmount) async {
    try {
      final result = await getGoalById(id);
      if (result.isError) {
        return result;
      }

      final goal = result.data!;
      final updated = goal.copyWith(
        currentAmount: newAmount,
        updatedAt: DateTime.now(),
        // If the goal is now complete, update the status
        status: newAmount >= goal.targetAmount
            ? GoalStatus.completed
            : goal.status,
        completedAt: newAmount >= goal.targetAmount
            ? DateTime.now()
            : goal.completedAt,
      );

      return updateGoal(updated);
    } catch (e) {
      return Result.error(
        UnknownFailure(message: 'Failed to update goal progress', originalError: e),
      );
    }
  }
}
