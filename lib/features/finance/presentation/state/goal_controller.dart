import 'package:persona_codex/core/state/stream_state.dart';
import '../../modules/goal/domain/entities/goal.dart';
import '../../modules/goal/domain/repositories/goal_repository.dart';

/// Controller for managing goal list state
class GoalController extends StreamState<AsyncState<List<Goal>>> {
  final GoalRepository _repository;

  GoalController(this._repository) : super(const AsyncLoading()) {
    loadGoals();
  }

  /// Load all goals
  Future<void> loadGoals() async {
    final result = await _repository.getGoals();
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

  /// Load goals by status
  Future<void> loadGoalsByStatus(GoalStatus status) async {
    final result = await _repository.getGoalsByStatus(status);
    result.fold(
      onSuccess: (goals) => emit(AsyncData(goals)),
      onError: (failure) => emit(AsyncError(failure.message, failure)),
    );
  }
}
