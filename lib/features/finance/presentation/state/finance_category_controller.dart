import 'package:persona_codex/core/error/result.dart';
import 'package:persona_codex/core/state/stream_state.dart';

import '../../modules/finance_category/domain/entities/finance_category.dart';
import '../../modules/finance_category/domain/entities/finance_category_enums.dart';
import '../../modules/finance_category/domain/repositories/finance_repository.dart';

/// Controller for managing finance categories
class FinanceCategoryController
    extends StreamState<AsyncState<List<FinanceCategory>>> {
  final FinanceCategoryRepository _repository;

  FinanceCategoryController(this._repository) : super(const AsyncLoading()) {
    loadCategories();
  }

  /// Load all categories
  Future<void> loadCategories() async {
    await execute(() async {
      return await _repository.getCategories().then((r) => r.unwrap());
    });
  }

  /// Load categories filtered by type
  Future<void> loadCategoriesByType(CategoryType type) async {
    await execute(() async {
      return await _repository
          .getCategoriesByType(type)
          .then((r) => r.unwrap());
    });
  }

  /// Create a new category
  Future<void> createCategory(FinanceCategory category) async {
    await execute(() async {
      final created = await _repository
          .createCategory(category)
          .then((r) => r.unwrap());
      final current = data ?? [];
      return [...current, created];
    });
  }

  /// Update an existing category
  Future<void> updateCategory(FinanceCategory category) async {
    await execute(() async {
      await _repository.updateCategory(category).then((r) => r.unwrap());
      await loadCategories();
      final current = data ?? [];
      return current;
    });
  }

  /// Delete a category
  Future<void> deleteCategory(String id) async {
    await execute(() async {
      await _repository.deleteCategory(id).then((r) => r.unwrap());
      await loadCategories();
      final current = data ?? [];
      return current;
    });
  }
}
