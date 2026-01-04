import 'package:keep_track/core/error/result.dart';
import '../entities/budget.dart';
import '../entities/budget_category.dart';

/// Budget repository interface
abstract class BudgetRepository {
  /// Get all budgets
  Future<Result<List<Budget>>> getBudgets();

  /// Get budget by ID
  Future<Result<Budget>> getBudgetById(String id);

  /// Get budget by month (YYYY-MM format)
  Future<Result<Budget>> getBudgetByMonth(String month);

  /// Get active budget
  Future<Result<Budget>> getActiveBudget();

  /// Create a new budget
  Future<Result<Budget>> createBudget(Budget budget);

  /// Update a budget
  Future<Result<Budget>> updateBudget(Budget budget);

  /// Delete a budget
  Future<Result<void>> deleteBudget(String id);

  /// Close a budget with notes
  Future<Result<Budget>> closeBudget(String id, String? notes);

  /// Reopen a closed budget
  Future<Result<Budget>> reopenBudget(String id);

  /// Add a category to a budget
  Future<Result<Budget>> addCategory(String budgetId, BudgetCategory category);

  /// Update a category
  Future<Result<Budget>> updateCategory(
    String budgetId,
    BudgetCategory category,
  );

  /// Delete a category
  Future<Result<Budget>> deleteCategory(String budgetId, String categoryId);

  /// Refresh spent amounts for a budget (manually trigger recalculation)
  Future<Result<Budget>> refreshBudgetSpentAmounts(String budgetId);

  /// Get all budgets with spent amounts calculated from transactions
  Future<Result<List<Budget>>> getBudgetsWithSpentAmounts();

  /// Get budget by ID with spent amounts calculated from transactions
  Future<Result<Budget>> getBudgetByIdWithSpentAmounts(String id);
}
