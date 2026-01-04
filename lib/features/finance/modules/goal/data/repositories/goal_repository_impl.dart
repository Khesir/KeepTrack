import 'package:keep_track/core/error/result.dart';
import 'package:keep_track/core/error/failure.dart';
import 'package:keep_track/features/finance/modules/goal/data/datasources/goal_datasource.dart';
import 'package:keep_track/features/finance/modules/goal/data/models/goal_model.dart';
import 'package:keep_track/features/finance/modules/goal/domain/entities/goal.dart';
import 'package:keep_track/features/finance/modules/goal/domain/repositories/goal_repository.dart';

/// Goal repository implementation
class GoalRepositoryImpl implements GoalRepository {
  final GoalDataSource dataSource;

  GoalRepositoryImpl(this.dataSource);

  @override
  Future<Result<List<Goal>>> getGoals() async {
    final goals = await dataSource.fetchGoals();
    return Result.success(goals);
  }

  @override
  Future<Result<Goal>> getGoalById(String id) async {
    final goal = await dataSource.fetchGoalById(id);
    if (goal == null) {
      return Result.error(NotFoundFailure(message: 'Goal not found: $id'));
    }
    return Result.success(goal);
  }

  @override
  Future<Result<Goal>> createGoal(Goal goal) async {
    final model = GoalModel.fromEntity(goal);
    final created = await dataSource.createGoal(model);
    return Result.success(created);
  }

  @override
  Future<Result<Goal>> updateGoal(Goal goal) async {
    final model = GoalModel.fromEntity(goal);
    final updated = await dataSource.updateGoal(model);
    return Result.success(updated);
  }

  @override
  Future<Result<void>> deleteGoal(String id) async {
    await dataSource.deleteGoal(id);
    return Result.success(null);
  }

  @override
  Future<Result<List<Goal>>> getGoalsByStatus(GoalStatus status) async {
    final statusString = status.name;
    final goals = await dataSource.fetchGoalsByStatus(statusString);
    return Result.success(goals);
  }

  @override
  Future<Result<Goal>> updateGoalProgress(String id, double newAmount) async {
    final result = await getGoalById(id);
    if (result.isError) {
      return result;
    }

    final goal = result.data;
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
  }
}
