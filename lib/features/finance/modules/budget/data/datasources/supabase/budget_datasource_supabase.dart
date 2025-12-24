import 'package:persona_codex/core/error/failure.dart';
import 'package:persona_codex/shared/infrastructure/supabase/supabase_service.dart';
import '../../models/budget_model.dart';
import '../../models/budget_category_model.dart';
import '../../../../finance_category/data/models/finance_category_model.dart';
import '../budget_datasource.dart';
import '../budget_category_datasource.dart';

/// Supabase implementation of BudgetDataSource
class BudgetDataSourceSupabase implements BudgetDataSource {
  final SupabaseService supabaseService;
  final BudgetCategoryDataSource categoryDataSource;
  static const String tableName = 'budgets';

  BudgetDataSourceSupabase(this.supabaseService, this.categoryDataSource);

  @override
  Future<List<BudgetModel>> getBudgets() async {
    try {
      // Use Supabase nested select to JOIN budget_categories and finance_categories in one query
      final response = await supabaseService.client
          .from(tableName)
          .select('''
            *,
            budget_categories (
              *,
              finance_categories (*)
            )
          ''')
          .eq('user_id', supabaseService.userId!)
          .order('month', ascending: false);

      return (response as List).map((doc) {
        final budgetData = Map<String, dynamic>.from(doc);

        // Extract nested budget_categories
        final categoriesData = budgetData.remove('budget_categories') as List?;

        // Create budget model
        final budget = BudgetModel.fromJson(budgetData);

        if (categoriesData == null || categoriesData.isEmpty) {
          return budget;
        }

        // Map budget_categories with nested finance_categories
        final categories = categoriesData.map((catData) {
          final categoryMap = Map<String, dynamic>.from(catData);

          // Extract nested finance_category
          final financeCategoryData = categoryMap.remove('finance_categories') as Map<String, dynamic>?;

          // Create budget category model
          final budgetCategory = BudgetCategoryModel.fromJson(categoryMap);

          // Hydrate with finance category if present
          if (financeCategoryData != null) {
            final financeCategory = FinanceCategoryModel.fromJson(financeCategoryData);
            // Create new BudgetCategoryModel with hydrated finance category
            return BudgetCategoryModel(
              id: budgetCategory.id,
              budgetId: budgetCategory.budgetId,
              financeCategoryId: budgetCategory.financeCategoryId,
              userId: budgetCategory.userId,
              targetAmount: budgetCategory.targetAmount,
              financeCategory: financeCategory.toEntity(),
              spentAmount: budgetCategory.spentAmount,
              createdAt: budgetCategory.createdAt,
              updatedAt: budgetCategory.updatedAt,
            );
          }

          return budgetCategory;
        }).toList();

        return budget.withCategories(categories);
      }).toList();
    } catch (e, stackTrace) {
      throw UnknownFailure(
        message: 'Failed to fetch budgets',
        originalError: e,
        stackTrace: stackTrace,
      );
    }
  }

  @override
  Future<BudgetModel?> getBudgetById(String id) async {
    try {
      // Use Supabase nested select to JOIN in one query
      final response = await supabaseService.client
          .from(tableName)
          .select('''
            *,
            budget_categories (
              *,
              finance_categories (*)
            )
          ''')
          .eq('id', id)
          .eq('user_id', supabaseService.userId!)
          .maybeSingle();

      if (response == null) return null;

      final budgetData = Map<String, dynamic>.from(response);

      // Extract nested budget_categories
      final categoriesData = budgetData.remove('budget_categories') as List?;

      // Create budget model
      final budget = BudgetModel.fromJson(budgetData);

      if (categoriesData == null || categoriesData.isEmpty) {
        return budget;
      }

      // Map budget_categories with nested finance_categories
      final categories = categoriesData.map((catData) {
        final categoryMap = Map<String, dynamic>.from(catData);
        final financeCategoryData = categoryMap.remove('finance_categories') as Map<String, dynamic>?;
        final budgetCategory = BudgetCategoryModel.fromJson(categoryMap);

        if (financeCategoryData != null) {
          final financeCategory = FinanceCategoryModel.fromJson(financeCategoryData);
          // Create new BudgetCategoryModel with hydrated finance category
          return BudgetCategoryModel(
            id: budgetCategory.id,
            budgetId: budgetCategory.budgetId,
            financeCategoryId: budgetCategory.financeCategoryId,
            userId: budgetCategory.userId,
            targetAmount: budgetCategory.targetAmount,
            financeCategory: financeCategory.toEntity(),
            spentAmount: budgetCategory.spentAmount,
            createdAt: budgetCategory.createdAt,
            updatedAt: budgetCategory.updatedAt,
          );
        }

        return budgetCategory;
      }).toList();

      return budget.withCategories(categories);
    } catch (e, stackTrace) {
      throw UnknownFailure(
        message: 'Failed to fetch budget by ID',
        originalError: e,
        stackTrace: stackTrace,
      );
    }
  }

  @override
  Future<BudgetModel?> getBudgetByMonth(String month) async {
    try {
      // Use Supabase nested select to JOIN in one query
      final response = await supabaseService.client
          .from(tableName)
          .select('''
            *,
            budget_categories (
              *,
              finance_categories (*)
            )
          ''')
          .eq('month', month)
          .eq('user_id', supabaseService.userId!)
          .maybeSingle();

      if (response == null) return null;

      final budgetData = Map<String, dynamic>.from(response);

      // Extract nested budget_categories
      final categoriesData = budgetData.remove('budget_categories') as List?;

      // Create budget model
      final budget = BudgetModel.fromJson(budgetData);

      if (categoriesData == null || categoriesData.isEmpty) {
        return budget;
      }

      // Map budget_categories with nested finance_categories
      final categories = categoriesData.map((catData) {
        final categoryMap = Map<String, dynamic>.from(catData);
        final financeCategoryData = categoryMap.remove('finance_categories') as Map<String, dynamic>?;
        final budgetCategory = BudgetCategoryModel.fromJson(categoryMap);

        if (financeCategoryData != null) {
          final financeCategory = FinanceCategoryModel.fromJson(financeCategoryData);
          // Create new BudgetCategoryModel with hydrated finance category
          return BudgetCategoryModel(
            id: budgetCategory.id,
            budgetId: budgetCategory.budgetId,
            financeCategoryId: budgetCategory.financeCategoryId,
            userId: budgetCategory.userId,
            targetAmount: budgetCategory.targetAmount,
            financeCategory: financeCategory.toEntity(),
            spentAmount: budgetCategory.spentAmount,
            createdAt: budgetCategory.createdAt,
            updatedAt: budgetCategory.updatedAt,
          );
        }

        return budgetCategory;
      }).toList();

      return budget.withCategories(categories);
    } catch (e, stackTrace) {
      throw UnknownFailure(
        message: 'Failed to fetch budget by month',
        originalError: e,
        stackTrace: stackTrace,
      );
    }
  }

  @override
  Future<BudgetModel> createBudget(BudgetModel budget) async {
    try {
      // Create budget WITHOUT categories first
      final budgetData = {
        'month': budget.month,
        'status': budget.status.name,
        if (budget.notes != null) 'notes': budget.notes,
        'user_id': supabaseService.userId!,
      };

      final response = await supabaseService.client
          .from(tableName)
          .insert(budgetData)
          .select()
          .single();

      final createdBudget = BudgetModel.fromJson(
        response as Map<String, dynamic>,
      );

      // Create categories separately if any
      if (budget.categories.isNotEmpty && createdBudget.id != null) {
        final createdCategories = await Future.wait(
          budget.categories.map((cat) {
            final categoryWithIds = BudgetCategoryModel(
              budgetId: createdBudget.id!,
              financeCategoryId: cat.financeCategoryId,
              targetAmount: cat.targetAmount,
              userId: supabaseService.userId,
            );
            return categoryDataSource.createCategory(categoryWithIds);
          }),
        );

        return createdBudget.withCategories(createdCategories);
      }

      return createdBudget;
    } catch (e, stackTrace) {
      throw UnknownFailure(
        message: 'Failed to create budget',
        originalError: e,
        stackTrace: stackTrace,
      );
    }
  }

  @override
  Future<BudgetModel> updateBudget(BudgetModel budget) async {
    try {
      if (budget.id == null) {
        throw Exception('Cannot update budget without an ID');
      }

      // Update budget data (WITHOUT categories)
      final budgetData = {
        'month': budget.month,
        'status': budget.status.name,
        if (budget.notes != null) 'notes': budget.notes,
        'updated_at': DateTime.now().toIso8601String(),
      };

      await supabaseService.client
          .from(tableName)
          .update(budgetData)
          .eq('id', budget.id!)
          .eq('user_id', supabaseService.userId!);

      // Fetch updated budget with nested categories
      final updated = await getBudgetById(budget.id!);

      if (updated == null) {
        throw Exception('Budget not found after update');
      }

      return updated;
    } catch (e, stackTrace) {
      throw UnknownFailure(
        message: 'Failed to update budget',
        originalError: e,
        stackTrace: stackTrace,
      );
    }
  }

  @override
  Future<void> deleteBudget(String id) async {
    try {
      // Delete categories first (cascade delete if not set up in DB)
      await categoryDataSource.deleteCategoriesByBudgetId(id);

      // Then delete budget
      await supabaseService.client
          .from(tableName)
          .delete()
          .eq('id', id)
          .eq('user_id', supabaseService.userId!);
    } catch (e, stackTrace) {
      throw UnknownFailure(
        message: 'Failed to delete budget',
        originalError: e,
        stackTrace: stackTrace,
      );
    }
  }
}
