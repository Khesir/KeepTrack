import 'package:keep_track/features/finance/modules/budget/data/datasources/budget_category_datasource.dart';
import 'package:keep_track/features/finance/modules/budget/data/models/budget_category_model.dart';
import 'package:keep_track/features/finance/modules/finance_category/domain/entities/finance_category.dart';
import 'package:keep_track/features/finance/modules/finance_category/domain/entities/finance_category_enums.dart';

BudgetCategoryModel _bc(
  String id,
  String budgetId,
  String catId,
  String catName,
  CategoryType catType,
  double target,
  double spent,
) =>
    BudgetCategoryModel(
      id: id,
      budgetId: budgetId,
      financeCategoryId: catId,
      targetAmount: target,
      spentAmount: spent,
      financeCategory: FinanceCategory(id: catId, name: catName, type: catType, userId: 'demo'),
    );

final demoBudgetCategories = <BudgetCategoryModel>[
  // ── Monthly budget (no profile) ──────────────────────────────────────────
  _bc('bc-salary',    'budget-inc-1',      'cat-salary',        'Salary',        CategoryType.income,  5000, 5000),
  _bc('bc-freelance', 'budget-inc-1',      'cat-freelance',     'Freelance',     CategoryType.income,  1500, 1200),
  _bc('bc-food',      'budget-exp-1',      'cat-food',          'Food & Dining', CategoryType.expense,  800,  620),
  _bc('bc-transport', 'budget-exp-1',      'cat-transport',     'Transportation',CategoryType.expense,  250,  185),
  _bc('bc-housing',   'budget-exp-1',      'cat-housing',       'Housing',       CategoryType.expense, 1200, 1200),
  _bc('bc-entertain', 'budget-exp-1',      'cat-entertainment', 'Entertainment', CategoryType.expense,  300,  240),
  _bc('bc-shopping',  'budget-exp-1',      'cat-shopping',      'Shopping',      CategoryType.expense,  400,  380),
  _bc('bc-utilities', 'budget-exp-1',      'cat-utilities',     'Utilities',     CategoryType.expense,  150,  130),
  // ── Profile budget (profile-personal) ────────────────────────────────────
  _bc('pbc-salary',    'budget-inc-prof',  'cat-salary',        'Salary',        CategoryType.income,  5000, 5000),
  _bc('pbc-freelance', 'budget-inc-prof',  'cat-freelance',     'Freelance',     CategoryType.income,  1500, 1200),
  _bc('pbc-food',      'budget-exp-prof',  'cat-food',          'Food & Dining', CategoryType.expense,  800,  620),
  _bc('pbc-transport', 'budget-exp-prof',  'cat-transport',     'Transportation',CategoryType.expense,  250,  185),
  _bc('pbc-housing',   'budget-exp-prof',  'cat-housing',       'Housing',       CategoryType.expense, 1200, 1200),
  _bc('pbc-entertain', 'budget-exp-prof',  'cat-entertainment', 'Entertainment', CategoryType.expense,  300,  240),
  _bc('pbc-shopping',  'budget-exp-prof',  'cat-shopping',      'Shopping',      CategoryType.expense,  400,  380),
  _bc('pbc-utilities', 'budget-exp-prof',  'cat-utilities',     'Utilities',     CategoryType.expense,  150,  130),
];

class BudgetCategoryDataSourceMock implements BudgetCategoryDataSource {
  @override
  Future<List<BudgetCategoryModel>> getCategoriesByBudgetId(String budgetId) async =>
      demoBudgetCategories.where((c) => c.budgetId == budgetId).toList();

  @override
  Future<BudgetCategoryModel> createCategory(BudgetCategoryModel category) async => category;

  @override
  Future<BudgetCategoryModel> updateCategory(BudgetCategoryModel category) async => category;

  @override
  Future<void> deleteCategory(String id) async {}

  @override
  Future<void> deleteCategoriesByBudgetId(String budgetId) async {}
}
