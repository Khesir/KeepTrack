import 'package:persona_codex/core/error/failure.dart';
import 'package:persona_codex/shared/infrastructure/supabase/supabase_service.dart';
import '../../models/budget_category_model.dart';
import '../budget_category_datasource.dart';

/// Supabase implementation of BudgetCategoryDataSource
class BudgetCategoryDataSourceSupabase implements BudgetCategoryDataSource {
  final SupabaseService supabaseService;
  static const String tableName = 'budget_categories';

  BudgetCategoryDataSourceSupabase(this.supabaseService);

  @override
  Future<List<BudgetCategoryModel>> getCategoriesByBudgetId(
    String budgetId,
  ) async {
    try {
      final response = await supabaseService.client
          .from(tableName)
          .select()
          .eq('budget_id', budgetId)
          .order('created_at', ascending: true);

      return (response as List)
          .map(
            (doc) => BudgetCategoryModel.fromJson(doc as Map<String, dynamic>),
          )
          .toList();
    } catch (e, stackTrace) {
      throw UnknownFailure(
        message: 'Failed to fetch budget categories',
        originalError: e,
        stackTrace: stackTrace,
      );
    }
  }

  @override
  Future<BudgetCategoryModel> createCategory(
    BudgetCategoryModel category,
  ) async {
    try {
      final doc = category.toJson();
      // Ensure user_id is set if not already
      if (doc['user_id'] == null) {
        doc['user_id'] = supabaseService.userId;
      }

      final response = await supabaseService.client
          .from(tableName)
          .insert(doc)
          .select()
          .single();

      return BudgetCategoryModel.fromJson(response as Map<String, dynamic>);
    } catch (e, stackTrace) {
      throw UnknownFailure(
        message: 'Failed to create budget category',
        originalError: e,
        stackTrace: stackTrace,
      );
    }
  }

  @override
  Future<BudgetCategoryModel> updateCategory(
    BudgetCategoryModel category,
  ) async {
    try {
      if (category.id == null) {
        throw Exception('Cannot update category without an ID');
      }

      final doc = category.toJson();
      final response = await supabaseService.client
          .from(tableName)
          .update(doc)
          .eq('id', category.id!)
          .select()
          .single();

      return BudgetCategoryModel.fromJson(response as Map<String, dynamic>);
    } catch (e, stackTrace) {
      throw UnknownFailure(
        message: 'Failed to update budget category',
        originalError: e,
        stackTrace: stackTrace,
      );
    }
  }

  @override
  Future<void> deleteCategory(String id) async {
    try {
      await supabaseService.client.from(tableName).delete().eq('id', id);
    } catch (e, stackTrace) {
      throw UnknownFailure(
        message: 'Failed to delete budget category',
        originalError: e,
        stackTrace: stackTrace,
      );
    }
  }

  @override
  Future<void> deleteCategoriesByBudgetId(String budgetId) async {
    try {
      await supabaseService.client
          .from(tableName)
          .delete()
          .eq('budget_id', budgetId);
    } catch (e, stackTrace) {
      throw UnknownFailure(
        message: 'Failed to delete budget categories',
        originalError: e,
        stackTrace: stackTrace,
      );
    }
  }
}
