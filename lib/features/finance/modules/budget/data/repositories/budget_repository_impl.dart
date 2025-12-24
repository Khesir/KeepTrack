import 'package:persona_codex/core/error/result.dart';
import 'package:persona_codex/core/error/failure.dart';

import '../../domain/entities/budget.dart';
import '../../domain/entities/budget_category.dart';
import '../../domain/repositories/budget_repository.dart';
import '../datasources/budget_datasource.dart';
import '../datasources/budget_category_datasource.dart';
import '../models/budget_model.dart';
import '../models/budget_category_model.dart';

/// Budget repository implementation
class BudgetRepositoryImpl implements BudgetRepository {
  final BudgetDataSource dataSource;
  final BudgetCategoryDataSource categoryDataSource;

  BudgetRepositoryImpl(
    this.dataSource,
    this.categoryDataSource,
  );

  @override
  Future<Result<List<Budget>>> getBudgets() async {
    final models = await dataSource.getBudgets();
    // Models are already hydrated with finance categories from datasource
    return Result.success(models);
  }

  @override
  Future<Result<Budget>> getBudgetById(String id) async {
    final model = await dataSource.getBudgetById(id);
    if (model == null) {
      return Result.error(NotFoundFailure(message: 'Budget not found: $id'));
    }
    // Model is already hydrated with finance categories from datasource
    return Result.success(model);
  }

  @override
  Future<Result<Budget>> getBudgetByMonth(String month) async {
    final model = await dataSource.getBudgetByMonth(month);
    if (model == null) {
      return Result.error(
        NotFoundFailure(message: 'Budget not found for month: $month'),
      );
    }
    // Model is already hydrated with finance categories from datasource
    return Result.success(model);
  }

  @override
  Future<Result<Budget>> getActiveBudget() async {
    final result = await getBudgets();
    if (result.isError) {
      return Result.error(result.failure);
    }

    final budgets = result.data;
    try {
      final activeBudget = budgets.firstWhere(
        (budget) => budget.status == BudgetStatus.active,
      );
      return Result.success(activeBudget);
    } catch (e) {
      return Result.error(NotFoundFailure(message: 'No active budget found'));
    }
  }

  @override
  Future<Result<Budget>> createBudget(Budget budget) async {
    final model = BudgetModel.fromEntity(budget);
    final created = await dataSource.createBudget(model);
    // Created budget is already hydrated with finance categories from datasource
    return Result.success(created);
  }

  @override
  Future<Result<Budget>> updateBudget(Budget budget) async {
    final model = BudgetModel.fromEntity(budget);
    final updated = await dataSource.updateBudget(model);
    // Updated budget is already hydrated with finance categories from datasource
    return Result.success(updated);
  }

  @override
  Future<Result<void>> deleteBudget(String id) async {
    await dataSource.deleteBudget(id);
    return Result.success(null);
  }

  @override
  Future<Result<Budget>> closeBudget(String id, String? notes) async {
    final result = await getBudgetById(id);
    if (result.isError) {
      return result;
    }

    final budget = result.data;
    final closed = budget.copyWith(
      status: BudgetStatus.closed,
      notes: notes,
      closedAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    return updateBudget(closed);
  }

  @override
  Future<Result<Budget>> reopenBudget(String id) async {
    final result = await getBudgetById(id);
    if (result.isError) {
      return result;
    }

    final budget = result.data;

    if (budget.status != BudgetStatus.closed) {
      return Result.error(ValidationFailure('Budget is not closed'));
    }

    // Check if budget month matches current month
    final now = DateTime.now();
    final currentMonth = '${now.year}-${now.month.toString().padLeft(2, '0')}';

    if (budget.month != currentMonth) {
      return Result.error(
        ValidationFailure(
          'Can only reopen budgets for the current month. '
          'Budget month: ${budget.month}, Current month: $currentMonth',
        ),
      );
    }

    final reopened = budget.copyWith(
      status: BudgetStatus.active,
      closedAt: null,
      updatedAt: DateTime.now(),
    );

    return updateBudget(reopened);
  }

  @override
  Future<Result<Budget>> addCategory(
    String budgetId,
    BudgetCategory category,
  ) async {
    // Create category in database
    final categoryModel = BudgetCategoryModel.fromEntity(
      category.copyWith(budgetId: budgetId),
    );

    await categoryDataSource.createCategory(categoryModel);

    // Return updated budget with all categories
    return getBudgetById(budgetId);
  }

  @override
  Future<Result<Budget>> updateCategory(
    String budgetId,
    BudgetCategory category,
  ) async {
    if (category.id == null) {
      return Result.error(
        ValidationFailure('Cannot update category without an ID'),
      );
    }

    // Update category in database
    final categoryModel = BudgetCategoryModel.fromEntity(category);
    await categoryDataSource.updateCategory(categoryModel);

    // Return updated budget with all categories
    return getBudgetById(budgetId);
  }

  @override
  Future<Result<Budget>> deleteCategory(
    String budgetId,
    String categoryId,
  ) async {
    // Delete category from database
    await categoryDataSource.deleteCategory(categoryId);

    // Return updated budget with remaining categories
    return getBudgetById(budgetId);
  }

}
