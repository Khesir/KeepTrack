import '../../domain/entities/budget.dart';
import '../../domain/entities/budget_category.dart';
import '../../domain/repositories/budget_repository.dart';
import '../datasources/budget_datasource.dart';
import '../models/budget_model.dart';

/// Budget repository implementation
class BudgetRepositoryImpl implements BudgetRepository {
  final BudgetDataSource dataSource;

  BudgetRepositoryImpl(this.dataSource);

  @override
  Future<List<Budget>> getBudgets() async {
    final models = await dataSource.getBudgets();
    return models.map((model) => model.toEntity()).toList();
  }

  @override
  Future<Budget?> getBudgetById(String id) async {
    final model = await dataSource.getBudgetById(id);
    return model?.toEntity();
  }

  @override
  Future<Budget?> getBudgetByMonth(String month) async {
    final model = await dataSource.getBudgetByMonth(month);
    return model?.toEntity();
  }

  @override
  Future<Budget?> getActiveBudget() async {
    final budgets = await getBudgets();
    try {
      return budgets.firstWhere(
        (budget) => budget.status == BudgetStatus.active,
      );
    } catch (e) {
      return null;
    }
  }

  @override
  Future<Budget> createBudget(Budget budget) async {
    final model = BudgetModel.fromEntity(budget);
    final created = await dataSource.createBudget(model);
    return created.toEntity();
  }

  @override
  Future<Budget> updateBudget(Budget budget) async {
    final model = BudgetModel.fromEntity(budget);
    final updated = await dataSource.updateBudget(model);
    return updated.toEntity();
  }

  @override
  Future<void> deleteBudget(String id) async {
    await dataSource.deleteBudget(id);
  }

  @override
  Future<Budget> closeBudget(String id, String? notes) async {
    final budget = await getBudgetById(id);
    if (budget == null) {
      throw Exception('Budget not found: $id');
    }

    final closed = budget.copyWith(
      status: BudgetStatus.closed,
      notes: notes,
      closedAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    return updateBudget(closed);
  }

  @override
  Future<Budget> reopenBudget(String id) async {
    final budget = await getBudgetById(id);
    if (budget == null) {
      throw Exception('Budget not found: $id');
    }

    if (budget.status != BudgetStatus.closed) {
      throw Exception('Budget is not closed');
    }

    // Check if budget month matches current month
    final now = DateTime.now();
    final currentMonth = '${now.year}-${now.month.toString().padLeft(2, '0')}';

    if (budget.month != currentMonth) {
      throw Exception(
        'Can only reopen budgets for the current month. '
        'Budget month: ${budget.month}, Current month: $currentMonth',
      );
    }

    final reopened = budget.copyWith(
      status: BudgetStatus.active,
      closedAt: null,
      updatedAt: DateTime.now(),
    );

    return updateBudget(reopened);
  }

  /// @deprecated Use TransactionRepository.deleteTransaction() instead.
  /// Records are now managed as independent transactions.
  @override
  @Deprecated('Use TransactionRepository.deleteTransaction() instead')
  Future<Budget> deleteRecord(String budgetId, String recordId) async {
    throw UnsupportedError(
      'Budget records are deprecated. Use TransactionRepository to delete transactions.',
    );
  }

  @override
  Future<Budget> addCategory(String budgetId, BudgetCategory category) async {
    final budget = await getBudgetById(budgetId);
    if (budget == null) {
      throw Exception('Budget not found: $budgetId');
    }

    final updatedCategories = [...budget.categories, category];
    final updated = budget.copyWith(
      categories: updatedCategories,
      updatedAt: DateTime.now(),
    );

    return updateBudget(updated);
  }

  @override
  Future<Budget> updateCategory(
    String budgetId,
    BudgetCategory category,
  ) async {
    final budget = await getBudgetById(budgetId);
    if (budget == null) {
      throw Exception('Budget not found: $budgetId');
    }

    final updatedCategories = budget.categories.map((c) {
      return c.id == category.id ? category : c;
    }).toList();

    final updated = budget.copyWith(
      categories: updatedCategories,
      updatedAt: DateTime.now(),
    );

    return updateBudget(updated);
  }

  @override
  Future<Budget> deleteCategory(String budgetId, String categoryId) async {
    final budget = await getBudgetById(budgetId);
    if (budget == null) {
      throw Exception('Budget not found: $budgetId');
    }

    // Note: Check for existing transactions should be done in the UI or use case layer
    // by querying TransactionRepository.getTransactionsByCategory(categoryId)
    // We no longer have embedded records to check

    final updatedCategories = budget.categories
        .where((c) => c.id != categoryId)
        .toList();

    final updated = budget.copyWith(
      categories: updatedCategories,
      updatedAt: DateTime.now(),
    );

    return updateBudget(updated);
  }
}
