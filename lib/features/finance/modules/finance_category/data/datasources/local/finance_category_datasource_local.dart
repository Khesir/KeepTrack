import 'package:keep_track/core/cache/local_cache.dart';
import 'package:keep_track/features/finance/modules/finance_category/data/models/finance_category_model.dart';
import 'package:uuid/uuid.dart';
import '../finance_category_datasource.dart';

class FinanceCategoryDataSourceLocal implements FinanceCategoryDataSource {
  final LocalCache _cache;
  final _uuid = const Uuid();

  static const _box = 'finance_categories';

  FinanceCategoryDataSourceLocal(this._cache);

  Future<List<FinanceCategoryModel>> _getAll() async {
    final entries = await _cache.getAll(_box);
    return entries.map((e) => FinanceCategoryModel.fromJson(e)).toList();
  }

  @override
  Future<List<FinanceCategoryModel>> fetchCategories() async => _getAll();

  @override
  Future<List<FinanceCategoryModel>> fetchCategoriesByType(String type) async {
    final all = await _getAll();
    return all.where((c) => c.type.name == type).toList();
  }

  @override
  Future<FinanceCategoryModel?> fetchCategoryById(String id) async {
    final data = await _cache.get(_box, id);
    if (data == null) return null;
    return FinanceCategoryModel.fromJson(data);
  }

  @override
  Future<List<FinanceCategoryModel>> getByIds(List<String> ids) async {
    final all = await _getAll();
    final idSet = ids.toSet();
    return all.where((c) => idSet.contains(c.id)).toList();
  }

  @override
  Future<FinanceCategoryModel> createCategory(
    FinanceCategoryModel category,
  ) async {
    final id = category.id ?? _uuid.v4();
    final model = FinanceCategoryModel.fromJson({...category.toJson(), 'id': id});
    await _cache.put(_box, id, model.toJson());
    return model;
  }

  @override
  Future<FinanceCategoryModel> updateCategory(
    FinanceCategoryModel category,
  ) async {
    await _cache.put(_box, category.id!, category.toJson());
    return category;
  }

  @override
  Future<void> deleteCategory(String id) async {
    await _cache.delete(_box, id);
  }
}
