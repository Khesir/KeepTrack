import 'package:persona_codex/core/error/failure.dart';
import 'package:persona_codex/shared/infrastructure/supabase/supabase_service.dart';
import '../../models/finance_category_model.dart';
import '../finance_category_datasource.dart';

/// Supabase implementation of FinanceCategoryDataSource
class FinanceCategoryDataSourceSupabase implements FinanceCategoryDataSource {
  final SupabaseService supabaseService;
  static const String tableName = 'finance_categories';

  FinanceCategoryDataSourceSupabase(this.supabaseService);

  @override
  Future<List<FinanceCategoryModel>> fetchCategories() async {
    try {
      final response = await supabaseService.client
          .from(tableName)
          .select()
          .or('user_id.eq.${supabaseService.userId},user_id.is.null')
          .order('created_at', ascending: false);

      return (response as List)
          .map((doc) => FinanceCategoryModel.fromJson(doc))
          .toList();
    } catch (e, stackTrace) {
      throw UnknownFailure(
        message: 'Failed to fetch finance categories',
        originalError: e,
        stackTrace: stackTrace,
      );
    }
  }

  @override
  Future<List<FinanceCategoryModel>> fetchCategoriesByType(String type) async {
    try {
      final response = await supabaseService.client
          .from(tableName)
          .select()
          .eq('type', type)
          .or('user_id.eq.${supabaseService.userId},user_id.is.null')
          .order('created_at', ascending: false);

      return (response as List)
          .map((doc) => FinanceCategoryModel.fromJson(doc))
          .toList();
    } catch (e, stackTrace) {
      throw UnknownFailure(
        message: 'Failed to fetch categories by type',
        originalError: e,
        stackTrace: stackTrace,
      );
    }
  }

  @override
  Future<FinanceCategoryModel?> fetchCategoryById(String id) async {
    try {
      final response = await supabaseService.client
          .from(tableName)
          .select()
          .eq('id', id)
          .eq('user_id', supabaseService.userId!)
          .maybeSingle();

      return response != null ? FinanceCategoryModel.fromJson(response) : null;
    } catch (e, stackTrace) {
      throw UnknownFailure(
        message: 'Failed to fetch finance category by ID',
        originalError: e,
        stackTrace: stackTrace,
      );
    }
  }

  @override
  Future<FinanceCategoryModel> createCategory(
    FinanceCategoryModel category,
  ) async {
    try {
      final doc = category.toJson();
      final response = await supabaseService.client
          .from(tableName)
          .insert(doc)
          .select()
          .single();

      return FinanceCategoryModel.fromJson(response);
    } catch (e, stackTrace) {
      throw UnknownFailure(
        message: 'Failed to create finance category',
        originalError: e,
        stackTrace: stackTrace,
      );
    }
  }

  @override
  Future<FinanceCategoryModel> updateCategory(
    FinanceCategoryModel category,
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
          .eq('user_id', supabaseService.userId!)
          .select()
          .single();

      return FinanceCategoryModel.fromJson(response);
    } catch (e, stackTrace) {
      throw UnknownFailure(
        message: 'Failed to update finance category',
        originalError: e,
        stackTrace: stackTrace,
      );
    }
  }

  @override
  Future<void> deleteCategory(String id) async {
    try {
      await supabaseService.client
          .from(tableName)
          .delete()
          .eq('id', id)
          .eq('user_id', supabaseService.userId!);
    } catch (e, stackTrace) {
      throw UnknownFailure(
        message: 'Failed to delete finance category',
        originalError: e,
        stackTrace: stackTrace,
      );
    }
  }
}
