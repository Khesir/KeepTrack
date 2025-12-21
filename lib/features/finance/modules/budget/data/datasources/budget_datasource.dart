import '../models/budget_model.dart';

/// Budget data source interface
abstract class BudgetDataSource {
  Future<List<BudgetModel>> getBudgets();
  Future<BudgetModel?> getBudgetById(String id);
  Future<BudgetModel?> getBudgetByMonth(String month);
  Future<BudgetModel> createBudget(BudgetModel budget);
  Future<BudgetModel> updateBudget(BudgetModel budget);
  Future<void> deleteBudget(String id);
}
