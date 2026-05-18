import 'package:keep_track/core/state/stream_state.dart';
import '../../modules/goal/data/datasources/rest/goal_datasource_rest.dart';
import '../../modules/goal/domain/entities/goal.dart';
import '../../modules/goal/domain/repositories/goal_repository.dart';

/// Controller for managing goal list state
class GoalController extends StreamState<AsyncState<List<Goal>>> {
  final GoalRepository _repository;
  final GoalDataSourceRest _dataSource;

  GoalController(this._repository, this._dataSource) : super(const AsyncLoading()) {
    loadGoals();
  }

  /// Load all goals, optionally scoped to a budget profile
  Future<void> loadGoals({String? budgetProfileId}) async {
    final result = await _repository.getGoals(budgetProfileId: budgetProfileId);
    result.fold(
      onSuccess: (goals) => emit(AsyncData(goals)),
      onError: (failure) => emit(AsyncError(failure.message, failure)),
    );
  }

  /// Create a new goal
  Future<void> createGoal(Goal goal) async {
    final result = await _repository.createGoal(goal);
    result.fold(
      onSuccess: (_) => loadGoals(),
      onError: (failure) => emit(AsyncError(failure.message, failure)),
    );
  }

  /// Update an existing goal
  Future<void> updateGoal(Goal goal) async {
    final result = await _repository.updateGoal(goal);
    result.fold(
      onSuccess: (_) => loadGoals(),
      onError: (failure) => emit(AsyncError(failure.message, failure)),
    );
  }

  /// Delete a goal
  Future<void> deleteGoal(String id) async {
    final result = await _repository.deleteGoal(id);
    result.fold(
      onSuccess: (_) => loadGoals(),
      onError: (failure) => emit(AsyncError(failure.message, failure)),
    );
  }

  /// Update goal progress (contribution)
  Future<void> updateGoalProgress(String id, double newAmount) async {
    final result = await _repository.updateGoalProgress(id, newAmount);
    result.fold(
      onSuccess: (_) => loadGoals(),
      onError: (failure) => emit(AsyncError(failure.message, failure)),
    );
  }

  /// Contribute an amount to a goal — optimistic update so the list never
  /// flickers to empty, then persists via updateGoalProgress.
  /// The caller is responsible for creating the transaction record.
  Future<void> contributeToGoal(String goalId, double amount) async {
    final previous = data;
    final goal = previous?.where((g) => g.id == goalId).firstOrNull;
    if (goal == null) return;
    final newAmount = goal.currentAmount + amount;
    if (previous != null) {
      emit(AsyncData(previous
          .map((g) => g.id == goalId
              ? g.copyWith(currentAmount: newAmount)
              : g)
          .toList()));
    }
    try {
      await _repository.updateGoalProgress(goalId, newAmount);
      await loadGoals();
    } catch (e) {
      if (previous != null) emit(AsyncData(previous));
      emit(AsyncError('Failed to contribute to goal: $e', e));
    }
  }

  /// Withdraw from a goal — optimistic update then server confirmation.
  Future<void> withdrawFromGoal(String goalId, double amount) async {
    final previous = data;
    if (previous != null) {
      emit(AsyncData(previous
          .map((g) => g.id == goalId
              ? g.copyWith(
                  currentAmount: (g.currentAmount - amount).clamp(0, double.infinity))
              : g)
          .toList()));
    }
    try {
      await _dataSource.withdrawFromGoal(goalId, amount);
      await loadGoals();
    } catch (e) {
      if (previous != null) emit(AsyncData(previous));
      emit(AsyncError('Failed to withdraw from goal: $e', e));
    }
  }

  /// Load goals by status
  Future<void> loadGoalsByStatus(GoalStatus status) async {
    final result = await _repository.getGoalsByStatus(status);
    result.fold(
      onSuccess: (goals) => emit(AsyncData(goals)),
      onError: (failure) => emit(AsyncError(failure.message, failure)),
    );
  }
}
