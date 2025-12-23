import '../models/finance_category_model.dart';

/// Data source interface for FinanceCategory operations
abstract class FinanceCategoryDataSource {
  /// Fetch all categories available to the current user (system + user-defined)
  Future<List<FinanceCategoryModel>> fetchCategories();

  /// Fetch categories filtered by type (income, expense, investment, savings)
  Future<List<FinanceCategoryModel>> fetchCategoriesByType(String type);

  /// Fetch a specific category by ID
  Future<FinanceCategoryModel?> fetchCategoryById(String id);

  Future<List<FinanceCategoryModel>> getByIds(List<String> ids);

  /// Create a new category
  Future<FinanceCategoryModel> createCategory(FinanceCategoryModel category);

  /// Update an existing category
  Future<FinanceCategoryModel> updateCategory(FinanceCategoryModel category);

  /// Delete a category by ID
  Future<void> deleteCategory(String id);
}
