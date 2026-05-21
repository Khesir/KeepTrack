import 'package:keep_track/features/finance/modules/finance_category/data/datasources/finance_category_datasource.dart';
import 'package:keep_track/features/finance/modules/finance_category/data/models/finance_category_model.dart';
import 'package:keep_track/features/finance/modules/finance_category/domain/entities/finance_category_enums.dart';

final _categories = <FinanceCategoryModel>[
  FinanceCategoryModel(id: 'cat-salary',        name: 'Salary',          type: CategoryType.income,     userId: 'demo'),
  FinanceCategoryModel(id: 'cat-freelance',      name: 'Freelance',       type: CategoryType.income,     userId: 'demo'),
  FinanceCategoryModel(id: 'cat-food',           name: 'Food & Dining',   type: CategoryType.expense,    userId: 'demo'),
  FinanceCategoryModel(id: 'cat-transport',      name: 'Transportation',  type: CategoryType.expense,    userId: 'demo'),
  FinanceCategoryModel(id: 'cat-housing',        name: 'Housing',         type: CategoryType.expense,    userId: 'demo'),
  FinanceCategoryModel(id: 'cat-entertainment',  name: 'Entertainment',   type: CategoryType.expense,    userId: 'demo'),
  FinanceCategoryModel(id: 'cat-shopping',       name: 'Shopping',        type: CategoryType.expense,    userId: 'demo'),
  FinanceCategoryModel(id: 'cat-utilities',      name: 'Utilities',       type: CategoryType.expense,    userId: 'demo'),
  FinanceCategoryModel(id: 'cat-health',         name: 'Health',          type: CategoryType.expense,    userId: 'demo'),
  FinanceCategoryModel(id: 'cat-stocks',         name: 'Stocks',          type: CategoryType.investment, userId: 'demo'),
  FinanceCategoryModel(id: 'cat-savings-c',      name: 'Savings',         type: CategoryType.savings,    userId: 'demo'),
];

class FinanceCategoryDataSourceMock implements FinanceCategoryDataSource {
  @override
  Future<List<FinanceCategoryModel>> fetchCategories() async => _categories;

  @override
  Future<List<FinanceCategoryModel>> fetchCategoriesByType(String type) async =>
      _categories.where((c) => c.type.name == type).toList();

  @override
  Future<FinanceCategoryModel?> fetchCategoryById(String id) async =>
      _categories.where((c) => c.id == id).firstOrNull;

  @override
  Future<List<FinanceCategoryModel>> getByIds(List<String> ids) async =>
      _categories.where((c) => ids.contains(c.id)).toList();

  @override
  Future<FinanceCategoryModel> createCategory(FinanceCategoryModel category) async => category;

  @override
  Future<FinanceCategoryModel> updateCategory(FinanceCategoryModel category) async => category;

  @override
  Future<void> deleteCategory(String id) async {}
}
