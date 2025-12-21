import '../entities/budget.dart';
import '../entities/budget_category.dart';

/// Budget repository interface
abstract class BudgetRepository {
  /// Get all budgets
  Future<List<Budget>> getBudgets();

  /// Get budget by ID
  Future<Budget?> getBudgetById(String id);

  /// Get budget by month (YYYY-MM format)
  Future<Budget?> getBudgetByMonth(String month);

  /// Get active budget
  Future<Budget?> getActiveBudget();

  /// Create a new budget
  Future<Budget> createBudget(Budget budget);

  /// Update a budget
  Future<Budget> updateBudget(Budget budget);

  /// Delete a budget
  Future<void> deleteBudget(String id);

  /// Close a budget with notes
  Future<Budget> closeBudget(String id, String? notes);

  /// Reopen a closed budget
  Future<Budget> reopenBudget(String id);

  /// Add a category to a budget
  Future<Budget> addCategory(String budgetId, BudgetCategory category);

  /// Update a category
  Future<Budget> updateCategory(String budgetId, BudgetCategory category);

  /// Delete a category
  Future<Budget> deleteCategory(String budgetId, String categoryId);
}
