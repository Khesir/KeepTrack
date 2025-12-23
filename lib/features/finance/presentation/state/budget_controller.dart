import 'package:persona_codex/core/state/stream_state.dart';
import '../../modules/budget/domain/entities/budget.dart';
import '../../modules/budget/domain/entities/budget_category.dart';
import '../../modules/budget/domain/repositories/budget_repository.dart';

/// Controller for managing budgets
class BudgetController extends StreamState<AsyncState<List<Budget>>> {
  final BudgetRepository _repository;

  BudgetController(this._repository) : super(const AsyncLoading()) {
    loadBudgets();
  }

  /// Load all budgets
  Future<void> loadBudgets() async {
    await execute(() async {
      return await _repository.getBudgets().then((r) => r);
    });
  }

  /// Create a new budget
  Future<void> createBudget(Budget budget) async {
    await execute(() async {
      final created = await _repository.createBudget(budget);
      final current = data ?? [];

      return [...current, created];
    });
  }

  /// Update an existing budget
  Future<void> updateBudget(Budget budget) async {
    await execute(() async {
      final updated = await _repository.updateBudget(budget);
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
      await _repository.deleteBudget(id);
      final current = data ?? [];
      return current.where((b) => b.id != id).toList();
    });
  }

  /// Close a budget
  Future<void> closeBudget(String id, {String? notes}) async {
    await execute(() async {
      final closed = await _repository.closeBudget(id, notes);
      final current = data ?? [];
      final updatedList = current.map((b) => b.id == id ? closed : b).toList();
      return updatedList;
    });
  }

  /// Reopen a budget
  Future<void> reopenBudget(String id) async {
    await execute(() async {
      final reopened = await _repository.reopenBudget(id);
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
      final updatedBudget = await _repository.addCategory(budgetId, category);
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
      final updatedBudget = await _repository.updateCategory(
        budgetId,
        category,
      );
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
      final updatedBudget = await _repository.deleteCategory(
        budgetId,
        categoryId,
      );
      final current = data ?? [];
      final updatedList = current
          .map((b) => b.id == budgetId ? updatedBudget : b)
          .toList();
      return updatedList;
    });
  }

  /// Get the active budget
  Future<Budget?> getActiveBudget() async {
    return await _repository.getActiveBudget();
  }
}
