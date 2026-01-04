import 'package:persona_codex/core/error/result.dart';
import 'package:persona_codex/core/state/stream_state.dart';
import '../../modules/budget/domain/entities/budget.dart';
import '../../modules/budget/domain/entities/budget_category.dart';
import '../../modules/budget/domain/repositories/budget_repository.dart';

/// Controller for managing budgets
class BudgetController extends StreamState<AsyncState<List<Budget>>> {
  final BudgetRepository _repository;

  BudgetController(this._repository) : super(const AsyncLoading()) {
    loadBudgetsWithSpentAmounts();
  }

  /// Load all budgets (without spent amounts calculated)
  Future<void> loadBudgets() async {
    await execute(() async {
      final result = await _repository.getBudgets();
      return result.unwrap();
    });
  }

  /// Load all budgets with spent amounts calculated from transactions
  Future<void> loadBudgetsWithSpentAmounts() async {
    await execute(() async {
      final result = await _repository.getBudgetsWithSpentAmounts();
      return result.unwrap();
    });
  }

  /// Create a new budget
  Future<Budget> createBudget(Budget budget) async {
    Budget? createdBudget;
    await execute(() async {
      final result = await _repository.createBudget(budget);
      final created = result.unwrap();
      createdBudget = created;
      final current = data ?? [];
      return [...current, created];
    });
    return createdBudget!;
  }

  /// Update an existing budget
  Future<void> updateBudget(Budget budget) async {
    await execute(() async {
      final result = await _repository.updateBudget(budget);
      final updated = result.unwrap();
      final current = data ?? [];

      // Replace the updated budget
      final updatedList = current
          .map((b) => b.id == budget.id ? updated : b)
          .toList();
      return updatedList;
    });
  }

  /// Delete a budget
  Future<void> deleteBudget(String id) async {
    await execute(() async {
      final result = await _repository.deleteBudget(id);
      result.unwrap();
      final current = data ?? [];
      return current.where((b) => b.id != id).toList();
    });
  }

  /// Close a budget
  Future<void> closeBudget(String id, {String? notes}) async {
    await execute(() async {
      final result = await _repository.closeBudget(id, notes);
      final closed = result.unwrap();
      final current = data ?? [];
      final updatedList = current.map((b) => b.id == id ? closed : b).toList();
      return updatedList;
    });
  }

  /// Reopen a budget
  Future<void> reopenBudget(String id) async {
    await execute(() async {
      final result = await _repository.reopenBudget(id);
      final reopened = result.unwrap();
      final current = data ?? [];
      final updatedList = current
          .map((b) => b.id == id ? reopened : b)
          .toList();
      return updatedList;
    });
  }

  /// Add a category to a budget
  Future<void> addCategory(String budgetId, BudgetCategory category) async {
    await execute(() async {
      final result = await _repository.addCategory(budgetId, category);
      final updatedBudget = result.unwrap();
      final current = data ?? [];
      final updatedList = current
          .map((b) => b.id == budgetId ? updatedBudget : b)
          .toList();
      return updatedList;
    });
  }

  /// Update a category in a budget
  Future<void> updateCategory(String budgetId, BudgetCategory category) async {
    await execute(() async {
      final result = await _repository.updateCategory(budgetId, category);
      final updatedBudget = result.unwrap();
      final current = data ?? [];
      final updatedList = current
          .map((b) => b.id == budgetId ? updatedBudget : b)
          .toList();
      return updatedList;
    });
  }

  /// Delete a category from a budget
  Future<void> deleteCategory(String budgetId, String categoryId) async {
    await execute(() async {
      final result = await _repository.deleteCategory(budgetId, categoryId);
      final updatedBudget = result.unwrap();
      final current = data ?? [];
      final updatedList = current
          .map((b) => b.id == budgetId ? updatedBudget : b)
          .toList();
      return updatedList;
    });
  }

  /// Get the active budget
  Future<Budget?> getActiveBudget() async {
    final result = await _repository.getActiveBudget();
    return result.isSuccess ? result.data : null;
  }

  /// Refresh budget spent amounts (manually trigger recalculation)
  Future<void> refreshBudgetSpentAmounts(String budgetId) async {
    await execute(() async {
      final result = await _repository.refreshBudgetSpentAmounts(budgetId);
      final refreshedBudget = result.unwrap();

      // Update the budget in the current list
      final current = data ?? [];
      final updatedList = current
          .map((b) => b.id == budgetId ? refreshedBudget : b)
          .toList();
      return updatedList;
    });
  }

  /// Manually recalculate budget spent amounts (bypasses database function)
  Future<void> manualRecalculateBudgetSpent(String budgetId) async {
    await execute(() async {
      final datasource = _repository as dynamic;
      if (datasource.dataSource != null) {
        await datasource.dataSource.manualRecalculateBudgetSpent(budgetId);
      }

      // Reload budgets to get updated values
      final result = await _repository.getBudgets();
      return result.unwrap();
    });
  }

  /// Debug budget categories and transactions (for troubleshooting)
  Future<Map<String, dynamic>> debugBudgetCategories(String budgetId) async {
    final datasource = _repository as dynamic;
    if (datasource.dataSource != null) {
      return await datasource.dataSource.debugBudgetCategories(budgetId);
    }
    return {};
  }
}
