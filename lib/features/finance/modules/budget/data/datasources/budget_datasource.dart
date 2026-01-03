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

  /// Debug: Get raw budget category data to verify spent amounts
  Future<Map<String, dynamic>> debugBudgetCategories(String budgetId);
}
