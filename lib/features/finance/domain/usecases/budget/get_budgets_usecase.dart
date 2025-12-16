/// Get budgets use case
library;

import '../../entities/budget.dart';
import '../../repositories/budget_repository.dart';

/// Use case for retrieving budgets
class GetBudgetsUseCase {
  final BudgetRepository _repository;

  GetBudgetsUseCase(this._repository);

  /// Get all budgets, sorted by month (newest first)
  Future<List<Budget>> call() async {
    final budgets = await _repository.getBudgets();

    // Business rule: Sort by month, newest first
    budgets.sort((a, b) => b.month.compareTo(a.month));

    return budgets;
  }

  /// Get active budget
  Future<Budget?> getActiveBudget() async {
    return await _repository.getActiveBudget();
  }

  /// Get budget by month
  Future<Budget?> getByMonth(String month) async {
    return await _repository.getBudgetByMonth(month);
  }
}
