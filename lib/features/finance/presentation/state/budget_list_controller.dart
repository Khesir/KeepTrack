/// Budget list controller using Use Cases
library;

import 'package:persona_codex/core/state/stream_state.dart';
import '../../domain/entities/budget.dart';
import '../../domain/usecases/budget/create_budget_usecase.dart';
import '../../domain/usecases/budget/get_budgets_usecase.dart';

/// Controller for budget list screen
class BudgetListController extends StreamState<AsyncState<List<Budget>>> {
  final GetBudgetsUseCase _getBudgetsUseCase;
  final CreateBudgetUseCase _createBudgetUseCase;

  BudgetListController({
    required GetBudgetsUseCase getBudgetsUseCase,
    required CreateBudgetUseCase createBudgetUseCase,
  }) : _getBudgetsUseCase = getBudgetsUseCase,
       _createBudgetUseCase = createBudgetUseCase,
       super(const AsyncLoading()) {
    loadBudgets();
  }

  /// Load all budgets
  Future<void> loadBudgets() async {
    await execute(() async {
      return await _getBudgetsUseCase();
    });
  }

  /// Get active budget
  Future<Budget?> getActiveBudget() async {
    return await _getBudgetsUseCase.getActiveBudget();
  }

  /// Create a new budget
  Future<bool> createBudget(CreateBudgetParams params) async {
    try {
      await _createBudgetUseCase(params);
      await loadBudgets();
      return true;
    } catch (e) {
      emit(AsyncError('Failed to create budget: $e', e));
      return false;
    }
  }
}
