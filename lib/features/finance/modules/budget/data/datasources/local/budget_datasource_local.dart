import 'package:keep_track/core/cache/local_cache.dart';
import 'package:keep_track/features/finance/modules/budget/data/models/budget_category_model.dart';
import 'package:keep_track/features/finance/modules/budget/data/models/budget_model.dart';
import 'package:keep_track/features/finance/modules/finance_category/data/models/finance_category_model.dart';
import 'package:uuid/uuid.dart';
import '../budget_datasource.dart';

class BudgetDataSourceLocal implements BudgetDataSource {
  final LocalCache _cache;
  final _uuid = const Uuid();

  static const _box = 'budgets';
  static const _categoriesBox = 'budget_categories';
  static const _fcBox = 'finance_categories';

  BudgetDataSourceLocal(this._cache);

  Future<BudgetCategoryModel> _hydrateCategory(BudgetCategoryModel cat) async {
    if (cat.financeCategory != null || cat.financeCategoryId.isEmpty) return cat;
    final data = await _cache.get(_fcBox, cat.financeCategoryId);
    if (data == null) return cat;
    final fc = FinanceCategoryModel.fromJson(data);
    return BudgetCategoryModel.fromEntity(cat.copyWith(financeCategory: fc));
  }

  Future<List<BudgetCategoryModel>> _categoriesFor(String budgetId) async {
    final entries = await _cache.getAll(_categoriesBox);
    final models = entries
        .map((e) => BudgetCategoryModel.fromJson(e))
        .where((c) => c.budgetId == budgetId)
        .toList();
    final hydrated = <BudgetCategoryModel>[];
    for (final m in models) {
      hydrated.add(await _hydrateCategory(m));
    }
    return hydrated;
  }

  Future<BudgetModel> _hydrate(BudgetModel budget) async {
    if (budget.id == null) return budget;
    final cats = await _categoriesFor(budget.id!);
    if (cats.isEmpty && budget.categories.isNotEmpty) return budget;
    return budget.withCategories(cats.isNotEmpty ? cats : budget.categories.cast());
  }

  Future<List<BudgetModel>> _getAll() async {
    final entries = await _cache.getAll(_box);
    final budgets = entries.map((e) => BudgetModel.fromJson(e)).toList();
    final hydrated = <BudgetModel>[];
    for (final b in budgets) {
      hydrated.add(await _hydrate(b));
    }
    return hydrated;
  }

  @override
  Future<List<BudgetModel>> getBudgets() async => _getAll();

  @override
  Future<BudgetModel?> getBudgetById(String id) async {
    final data = await _cache.get(_box, id);
    if (data == null) return null;
    return _hydrate(BudgetModel.fromJson(data));
  }

  @override
  Future<BudgetModel?> getBudgetByMonth(String month) async {
    final all = await _getAll();
    try {
      return all.firstWhere((b) => b.month == month);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<BudgetModel> createBudget(BudgetModel budget) async {
    final id = budget.id ?? _uuid.v4();
    final model = BudgetModel.fromJson({...budget.toJson(), 'id': id});
    await _cache.put(_box, id, model.toJson());
    // Also save embedded categories to the categories box
    for (final cat in model.categories) {
      final catModel = cat is BudgetCategoryModel
          ? cat
          : BudgetCategoryModel.fromEntity(cat);
      final catId = catModel.id ?? _uuid.v4();
      final saved = BudgetCategoryModel.fromJson({
        ...catModel.toJson(),
        'id': catId,
        'budgetId': id,
      });
      await _cache.put(_categoriesBox, catId, saved.toJson());
    }
    return _hydrate(model);
  }

  @override
  Future<BudgetModel> updateBudget(BudgetModel budget) async {
    await _cache.put(_box, budget.id!, budget.toJson());
    return budget;
  }

  @override
  Future<void> deleteBudget(String id) async {
    await _cache.delete(_box, id);
  }

  @override
  Future<void> refreshBudgetSpentAmounts(String budgetId) async {}

  @override
  Future<void> manualRecalculateBudgetSpent(String budgetId) async {}

  @override
  Future<BudgetModel?> getBudgetWithSpentAmounts(String budgetId) async =>
      getBudgetById(budgetId);

  @override
  Future<List<BudgetModel>> getBudgetsByMonth(String month) async {
    final all = await _getAll();
    return all.where((b) => b.month == month).toList();
  }

  @override
  Future<List<BudgetModel>> getBudgetsWithSpentAmounts() async => _getAll();

  @override
  Future<Map<String, dynamic>> debugBudgetCategories(String budgetId) async =>
      {};
}
