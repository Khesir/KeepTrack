import 'package:keep_track/core/cache/local_cache.dart';
import 'package:keep_track/features/finance/modules/budget/data/models/budget_category_model.dart';
import 'package:uuid/uuid.dart';
import '../budget_category_datasource.dart';

class BudgetCategoryDataSourceLocal implements BudgetCategoryDataSource {
  final LocalCache _cache;
  final _uuid = const Uuid();

  static const _box = 'budget_categories';

  BudgetCategoryDataSourceLocal(this._cache);

  Future<List<BudgetCategoryModel>> _getAll() async {
    final entries = await _cache.getAll(_box);
    return entries.map((e) => BudgetCategoryModel.fromJson(e)).toList();
  }

  @override
  Future<List<BudgetCategoryModel>> getCategoriesByBudgetId(
    String budgetId,
  ) async {
    final all = await _getAll();
    return all.where((c) => c.budgetId == budgetId).toList();
  }

  @override
  Future<BudgetCategoryModel> createCategory(
    BudgetCategoryModel category,
  ) async {
    final id = category.id ?? _uuid.v4();
    final model = BudgetCategoryModel.fromJson({...category.toJson(), 'id': id});
    await _cache.put(_box, id, model.toJson());
    return model;
  }

  @override
  Future<BudgetCategoryModel> updateCategory(
    BudgetCategoryModel category,
  ) async {
    await _cache.put(_box, category.id!, category.toJson());
    return category;
  }

  @override
  Future<void> deleteCategory(String id) async {
    await _cache.delete(_box, id);
  }

  @override
  Future<void> deleteCategoriesByBudgetId(String budgetId) async {
    final all = await _getAll();
    final toDelete = all.where((c) => c.budgetId == budgetId).toList();
    for (final c in toDelete) {
      await _cache.delete(_box, c.id!);
    }
  }
}
