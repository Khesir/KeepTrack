/// Budget detail controller using Use Cases
library;

import 'package:persona_codex/core/state/stream_state.dart';

import '../../domain/entities/budget.dart';
import '../../domain/usecases/budget/delete_budget_usecase.dart';
import '../../domain/usecases/budget/update_budget_usecase.dart';

/// Controller for budget detail screen
class BudgetDetailController extends StreamState<AsyncState<Budget?>> {
  final UpdateBudgetUseCase _updateBudgetUseCase;
  final DeleteBudgetUseCase _deleteBudgetUseCase;

  BudgetDetailController({
    required UpdateBudgetUseCase updateBudgetUseCase,
    required DeleteBudgetUseCase deleteBudgetUseCase,
    required Budget initialBudget,
  }) : _updateBudgetUseCase = updateBudgetUseCase,
       _deleteBudgetUseCase = deleteBudgetUseCase,
       super(AsyncData(initialBudget));

  /// Update budget details
  Future<bool> updateBudget(UpdateBudgetParams params) async {
    try {
      final budget = await _updateBudgetUseCase(params);
      emit(AsyncData(budget));
      return true;
    } catch (e) {
      emit(AsyncError('Failed to update budget: $e', e));
      return false;
    }
  }

  /// Delete the budget
  Future<bool> deleteBudget(String budgetId) async {
    try {
      await _deleteBudgetUseCase(budgetId);
      emit(const AsyncData(null));
      return true;
    } catch (e) {
      emit(AsyncError('Failed to delete budget: $e', e));
      return false;
    }
  }
}
