import 'package:keep_track/core/cache/local_cache.dart';
import 'package:keep_track/features/finance/modules/budget/data/models/budget_category_model.dart';
import 'package:keep_track/features/finance/modules/finance_category/data/models/finance_category_model.dart';
import 'package:uuid/uuid.dart';
import '../budget_category_datasource.dart';

class BudgetCategoryDataSourceLocal implements BudgetCategoryDataSource {
  final LocalCache _cache;
  final _uuid = const Uuid();

  static const _box = 'budget_categories';
  static const _fcBox = 'finance_categories';

  BudgetCategoryDataSourceLocal(this._cache);

  Future<BudgetCategoryModel> _hydrate(BudgetCategoryModel cat) async {
    if (cat.financeCategoryId.isEmpty) return cat;
    final data = await _cache.get(_fcBox, cat.financeCategoryId);
    if (data == null) return cat;
    final fc = FinanceCategoryModel.fromJson(data);
    return BudgetCategoryModel.fromEntity(cat.copyWith(financeCategory: fc));
  }

  Future<List<BudgetCategoryModel>> _getAll() async {
    final entries = await _cache.getAll(_box);
    final models = entries.map((e) => BudgetCategoryModel.fromJson(e)).toList();
    final hydrated = <BudgetCategoryModel>[];
    for (final m in models) {
      hydrated.add(await _hydrate(m));
    }
    return hydrated;
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
