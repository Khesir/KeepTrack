import 'package:persona_codex/core/error/failure.dart';
import 'package:persona_codex/shared/infrastructure/supabase/supabase_service.dart';
import '../../models/budget_model.dart';
import '../../models/budget_category_model.dart';
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
      final response = await supabaseService.client
          .from(tableName)
          .select()
          .eq('user_id', supabaseService.userId!)
          .order('month', ascending: false);

      final budgets = (response as List)
          .map((doc) => BudgetModel.fromJson(doc as Map<String, dynamic>))
          .toList();

      // Load categories for each budget
      return Future.wait(
        budgets.map((budget) async {
          if (budget.id == null) return budget;

          final categories = await categoryDataSource.getCategoriesByBudgetId(
            budget.id!,
          );

          return budget.withCategories(categories);
        }),
      );
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
      final response = await supabaseService.client
          .from(tableName)
          .select()
          .eq('id', id)
          .eq('user_id', supabaseService.userId!)
          .maybeSingle();

      if (response == null) return null;

      final budget = BudgetModel.fromJson(response as Map<String, dynamic>);

      // Load categories
      final categories = await categoryDataSource.getCategoriesByBudgetId(id);

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
      final response = await supabaseService.client
          .from(tableName)
          .select()
          .eq('month', month)
          .eq('user_id', supabaseService.userId!)
          .maybeSingle();

      if (response == null) return null;

      final budget = BudgetModel.fromJson(response as Map<String, dynamic>);

      // Load categories if budget has id
      if (budget.id != null) {
        final categories = await categoryDataSource.getCategoriesByBudgetId(
          budget.id!,
        );

        return budget.withCategories(categories);
      }

      return budget;
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

      final response = await supabaseService.client
          .from(tableName)
          .update(budgetData)
          .eq('id', budget.id!)
          .eq('user_id', supabaseService.userId!)
          .select()
          .single();

      final updatedBudget = BudgetModel.fromJson(
        response as Map<String, dynamic>,
      );

      // Load current categories
      final categories = await categoryDataSource.getCategoriesByBudgetId(
        budget.id!,
      );

      return updatedBudget.withCategories(categories);
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
