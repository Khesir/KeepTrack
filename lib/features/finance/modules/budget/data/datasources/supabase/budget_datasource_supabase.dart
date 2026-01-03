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
              feeSpent: budgetCategory.feeSpent,
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
            feeSpent: budgetCategory.feeSpent,
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
            feeSpent: budgetCategory.feeSpent,
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
        if (budget.title != null) 'title': budget.title,
        'budget_type': budget.budgetType.name,
        'period_type': budget.periodType.name,
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
        if (budget.title != null) 'title': budget.title,
        'budget_type': budget.budgetType.name,
        'period_type': budget.periodType.name,
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

  @override
  Future<void> refreshBudgetSpentAmounts(String budgetId) async {
    try {
      // Call the database function to recalculate spent amounts
      await supabaseService.client.rpc(
        'update_budget_spent_amounts',
        params: {'p_budget_id': budgetId},
      );
    } catch (e, stackTrace) {
      throw UnknownFailure(
        message: 'Failed to refresh budget spent amounts',
        originalError: e,
        stackTrace: stackTrace,
      );
    }
  }

  @override
  Future<void> manualRecalculateBudgetSpent(String budgetId) async {
    try {
      // Get budget month
      final budgetResponse = await supabaseService.client
          .from(tableName)
          .select('month')
          .eq('id', budgetId)
          .single();

      final budgetMonth = budgetResponse['month'] as String;

      // Parse month to get date range
      final parts = budgetMonth.split('-');
      final year = int.parse(parts[0]);
      final month = int.parse(parts[1]);
      final startDate = DateTime(year, month, 1);
      final endDate = DateTime(year, month + 1, 0, 23, 59, 59);

      // Get all budget categories for this budget
      final categoriesResponse = await supabaseService.client
          .from('budget_categories')
          .select('id, finance_category_id')
          .eq('budget_id', budgetId);

      final categories = categoriesResponse as List;

      print('🔄 Recalculating budget for month: $budgetMonth');
      print('📅 Date range: ${startDate.toIso8601String()} to ${endDate.toIso8601String()}');
      print('📊 Processing ${categories.length} categories');

      // For each category, calculate spent amounts from transactions
      for (final category in categories) {
        final categoryId = category['id'] as String;
        final financeCategoryId = category['finance_category_id'] as String;

        // Get all transactions for this category in this month
        final transactions = await supabaseService.client
            .from('transactions')
            .select('amount, fee, date, description')
            .eq('finance_category_id', financeCategoryId)
            .gte('date', startDate.toIso8601String())
            .lte('date', endDate.toIso8601String());

        // Calculate totals
        double totalSpent = 0.0;
        double totalFees = 0.0;

        for (final transaction in transactions as List) {
          final amount = (transaction['amount'] as num?)?.toDouble() ?? 0.0;
          final fee = (transaction['fee'] as num?)?.toDouble() ?? 0.0;
          totalSpent += amount.abs();
          totalFees += fee.abs();
        }

        print('💰 Category $financeCategoryId: ${(transactions as List).length} transactions, ₱$totalSpent spent, ₱$totalFees fees');

        // Update budget category with calculated amounts
        await supabaseService.client
            .from('budget_categories')
            .update({
              'spent_amount': totalSpent,
              'fee_spent': totalFees,
            })
            .eq('id', categoryId);
      }

      print('✅ Budget recalculation complete!');
    } catch (e, stackTrace) {
      print('❌ Error recalculating budget: $e');
      throw UnknownFailure(
        message: 'Failed to manually recalculate budget spent amounts',
        originalError: e,
        stackTrace: stackTrace,
      );
    }
  }

  @override
  Future<Map<String, dynamic>> debugBudgetCategories(String budgetId) async {
    try {
      // Get budget info
      final budgetResponse = await supabaseService.client
          .from(tableName)
          .select('id, month')
          .eq('id', budgetId)
          .single();

      final budgetMonth = budgetResponse['month'] as String;

      // Get budget categories
      final categoriesResponse = await supabaseService.client
          .from('budget_categories')
          .select('id, finance_category_id, target_amount, spent_amount, fee_spent')
          .eq('budget_id', budgetId);

      // For each category, get matching transactions
      final categoriesWithTransactions = [];
      for (final cat in categoriesResponse as List) {
        final categoryId = cat['finance_category_id'];

        // Parse month to get date range
        final parts = budgetMonth.split('-');
        final year = int.parse(parts[0]);
        final month = int.parse(parts[1]);
        final startDate = DateTime(year, month, 1);
        final endDate = DateTime(year, month + 1, 0);

        // Get transactions for this category in this month
        final transactions = await supabaseService.client
            .from('transactions')
            .select('id, amount, fee, date, description')
            .eq('finance_category_id', categoryId)
            .gte('date', startDate.toIso8601String())
            .lte('date', endDate.toIso8601String());

        categoriesWithTransactions.add({
          'category': cat,
          'transactions': transactions,
          'transaction_count': (transactions as List).length,
          'calculated_spent': (transactions as List).fold<double>(
            0.0,
            (sum, t) => sum + ((t['amount'] as num?)?.toDouble() ?? 0.0).abs(),
          ),
          'calculated_fees': (transactions as List).fold<double>(
            0.0,
            (sum, t) => sum + ((t['fee'] as num?)?.toDouble() ?? 0.0).abs(),
          ),
        });
      }

      return {
        'budget_id': budgetId,
        'budget_month': budgetMonth,
        'categories': categoriesWithTransactions,
      };
    } catch (e, stackTrace) {
      throw UnknownFailure(
        message: 'Failed to debug budget categories',
        originalError: e,
        stackTrace: stackTrace,
      );
    }
  }
}
