import 'package:keep_track/core/di/service_locator.dart';
import 'package:keep_track/core/state/stream_state.dart';
import '../../modules/goal/data/datasources/rest/goal_datasource_rest.dart';
import '../../modules/goal/domain/entities/goal.dart';
import '../../modules/goal/domain/repositories/goal_repository.dart';
import 'budget_profile_controller.dart';

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

  String? get _activeProfileId =>
      locator.get<BudgetProfileController>().activeProfileId;

  Goal _withProfile(Goal goal) =>
      goal.budgetProfileId != null ? goal : goal.copyWith(budgetProfileId: _activeProfileId);

  /// Create a new goal
  Future<void> createGoal(Goal goal) async {
    await executeSilent(() async {
      await _repository.createGoal(_withProfile(goal));
      return (await _repository.getGoals()).dataOrNull ?? [];
    });
  }

  /// Update an existing goal
  Future<void> updateGoal(Goal goal) async {
    await executeSilent(() async {
      await _repository.updateGoal(goal);
      return (await _repository.getGoals()).dataOrNull ?? [];
    });
  }

  /// Delete a goal
  Future<void> deleteGoal(String id) async {
    await executeSilent(() async {
      await _repository.deleteGoal(id);
      return (await _repository.getGoals()).dataOrNull ?? [];
    });
  }

  /// Update goal progress (contribution)
  Future<void> updateGoalProgress(String id, double newAmount) async {
    await executeSilent(() async {
      await _repository.updateGoalProgress(id, newAmount);
      return (await _repository.getGoals()).dataOrNull ?? [];
    });
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
