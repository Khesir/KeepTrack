import '../../domain/entities/budget.dart';
import '../../domain/entities/budget_category.dart';
import '../../domain/entities/budget_record.dart';
import '../../domain/repositories/budget_repository.dart';
import '../datasources/budget_datasource.dart';
import '../models/budget_model.dart';
import '../models/budget_category_model.dart';
import '../models/budget_record_model.dart';

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
      return budgets.firstWhere((budget) => budget.status == BudgetStatus.active);
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
  Future<Budget> addRecord(String budgetId, BudgetRecord record) async {
    final budget = await getBudgetById(budgetId);
    if (budget == null) {
      throw Exception('Budget not found: $budgetId');
    }

    final updatedRecords = [...budget.records, record];
    final updated = budget.copyWith(
      records: updatedRecords,
      updatedAt: DateTime.now(),
    );

    return updateBudget(updated);
  }

  @override
  Future<Budget> updateRecord(String budgetId, BudgetRecord record) async {
    final budget = await getBudgetById(budgetId);
    if (budget == null) {
      throw Exception('Budget not found: $budgetId');
    }

    final updatedRecords = budget.records.map((r) {
      return r.id == record.id ? record : r;
    }).toList();

    final updated = budget.copyWith(
      records: updatedRecords,
      updatedAt: DateTime.now(),
    );

    return updateBudget(updated);
  }

  @override
  Future<Budget> deleteRecord(String budgetId, String recordId) async {
    final budget = await getBudgetById(budgetId);
    if (budget == null) {
      throw Exception('Budget not found: $budgetId');
    }

    final updatedRecords =
        budget.records.where((r) => r.id != recordId).toList();

    final updated = budget.copyWith(
      records: updatedRecords,
      updatedAt: DateTime.now(),
    );

    return updateBudget(updated);
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
      String budgetId, BudgetCategory category) async {
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

    // Check if category has records
    final hasRecords =
        budget.records.any((record) => record.categoryId == categoryId);
    if (hasRecords) {
      throw Exception(
          'Cannot delete category with existing records. Delete records first.');
    }

    final updatedCategories =
        budget.categories.where((c) => c.id != categoryId).toList();

    final updated = budget.copyWith(
      categories: updatedCategories,
      updatedAt: DateTime.now(),
    );

    return updateBudget(updated);
  }
}
