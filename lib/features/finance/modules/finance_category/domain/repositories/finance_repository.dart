import 'package:keep_track/core/error/result.dart';

import '../entities/finance_category.dart';
import '../entities/finance_category_enums.dart';

/// Repository contract for finance categories
abstract class FinanceCategoryRepository {
  /// Get all categories available to the current user
  /// (system + user-created)
  Future<Result<List<FinanceCategory>>> getCategories();

  /// Get categories filtered by type (income, expense, etc.)
  Future<Result<List<FinanceCategory>>> getCategoriesByType(CategoryType type);

  /// Get a specific category by ID
  Future<Result<FinanceCategory>> getCategoryById(String id);

  /// Get multiple categories by IDs (used for hydration)
  Future<Result<List<FinanceCategory>>> getByIds(List<String> ids);

  /// Create a new user-defined category
  Future<Result<FinanceCategory>> createCategory(FinanceCategory category);

  /// Update an existing category
  Future<Result<FinanceCategory>> updateCategory(FinanceCategory category);

  /// Delete a category
  ///
  /// Note:
  Future<Result<void>> deleteCategory(String id);
}
