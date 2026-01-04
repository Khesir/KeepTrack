import '../models/budget_model.dart';

/// Budget data source interface
abstract class BudgetDataSource {
  Future<List<BudgetModel>> getBudgets();
  Future<BudgetModel?> getBudgetById(String id);
  Future<BudgetModel?> getBudgetByMonth(String month);
  Future<BudgetModel> createBudget(BudgetModel budget);
  Future<BudgetModel> updateBudget(BudgetModel budget);
  Future<void> deleteBudget(String id);

  /// Manually trigger refresh of budget spent amounts
  Future<void> refreshBudgetSpentAmounts(String budgetId);

  /// Manually recalculate and update budget spent amounts (direct calculation)
  Future<void> manualRecalculateBudgetSpent(String budgetId);

  /// Get budget with spent amounts calculated from transactions
  Future<BudgetModel?> getBudgetWithSpentAmounts(String budgetId);

  /// Get all budgets with spent amounts calculated from transactions
  Future<List<BudgetModel>> getBudgetsWithSpentAmounts();

  /// Debug: Get raw budget category data to verify spent amounts
  Future<Map<String, dynamic>> debugBudgetCategories(String budgetId);
}
