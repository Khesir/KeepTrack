import 'package:keep_track/core/error/result.dart';
import 'package:keep_track/core/state/stream_state.dart';

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

  /// Get categories by IDs from cached data
  List<FinanceCategory> getCategoriesByIds(List<String> ids) {
    final categories = data ?? [];
    return categories.where((cat) => ids.contains(cat.id)).toList();
  }

  /// Get a single category by ID from cached data
  FinanceCategory? getCategoryById(String id) {
    final categories = data ?? [];
    try {
      return categories.firstWhere((cat) => cat.id == id);
    } catch (e) {
      return null;
    }
  }

  /// Returns the ID of a category matching [name] and [type], creating one if
  /// none exists. Falls back to any non-archived category of the same type.
  Future<String?> findOrCreate({
    required String name,
    required CategoryType type,
    required String userId,
  }) async {
    final cats = data ?? [];
    for (final c in cats) {
      if (c.type == type && c.name == name && !c.isArchive) return c.id;
    }
    for (final c in cats) {
      if (c.type == type && !c.isArchive) return c.id;
    }
    await createCategory(
      FinanceCategory(name: name, type: type, userId: userId),
    );
    final updated = data ?? [];
    for (final c in updated) {
      if (c.type == type && !c.isArchive) return c.id;
    }
    return null;
  }

  Future<String?> findOrCreateSavingsCategory(String userId) =>
      findOrCreate(name: 'Savings', type: CategoryType.savings, userId: userId);
}
