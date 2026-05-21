import 'package:keep_track/features/finance/modules/budget/data/datasources/budget_datasource.dart';
import 'package:keep_track/features/finance/modules/budget/data/datasources/mock/budget_category_datasource_mock.dart';
import 'package:keep_track/features/finance/modules/budget/data/models/budget_model.dart';
import 'package:keep_track/features/finance/modules/budget/domain/entities/budget.dart';

final demoBudgets = <BudgetModel>[
  // ── Monthly budgets (no profileId) ───────────────────────────────────────
  BudgetModel(
    id: 'budget-inc-1',
    month: '2026-05',
    title: 'May Income',
    budgetType: BudgetType.income,
    periodType: BudgetPeriodType.monthly,
    status: BudgetStatus.active,
    userId: 'demo',
    categories: demoBudgetCategories.where((c) => c.budgetId == 'budget-inc-1').toList(),
  ),
  BudgetModel(
    id: 'budget-exp-1',
    month: '2026-05',
    title: 'May Expenses',
    budgetType: BudgetType.expense,
    periodType: BudgetPeriodType.monthly,
    status: BudgetStatus.active,
    userId: 'demo',
    categories: demoBudgetCategories.where((c) => c.budgetId == 'budget-exp-1').toList(),
  ),
  // ── Profile budgets (profile-personal) ───────────────────────────────────
  BudgetModel(
    id: 'budget-inc-prof',
    month: '2026-05',
    title: 'Income',
    budgetType: BudgetType.income,
    periodType: BudgetPeriodType.monthly,
    status: BudgetStatus.active,
    userId: 'demo',
    budgetProfileId: 'profile-personal',
    categories: demoBudgetCategories.where((c) => c.budgetId == 'budget-inc-prof').toList(),
  ),
  BudgetModel(
    id: 'budget-exp-prof',
    month: '2026-05',
    title: 'Expenses',
    budgetType: BudgetType.expense,
    periodType: BudgetPeriodType.monthly,
    status: BudgetStatus.active,
    userId: 'demo',
    budgetProfileId: 'profile-personal',
    categories: demoBudgetCategories.where((c) => c.budgetId == 'budget-exp-prof').toList(),
  ),
];

class BudgetDataSourceMock implements BudgetDataSource {
  @override
  Future<List<BudgetModel>> getBudgets() async => demoBudgets;

  @override
  Future<BudgetModel?> getBudgetById(String id) async =>
      demoBudgets.where((b) => b.id == id).firstOrNull;

  @override
  Future<BudgetModel?> getBudgetByMonth(String month) async =>
      demoBudgets.where((b) => b.month == month && b.budgetProfileId == null).firstOrNull;

  @override
  Future<List<BudgetModel>> getBudgetsByMonth(String month) async =>
      demoBudgets.where((b) => b.month == month).toList();

  @override
  Future<List<BudgetModel>> getBudgetsWithSpentAmounts() async => demoBudgets;

  @override
  Future<BudgetModel?> getBudgetWithSpentAmounts(String budgetId) async =>
      demoBudgets.where((b) => b.id == budgetId).firstOrNull;

  @override
  Future<BudgetModel> createBudget(BudgetModel budget) async => budget;

  @override
  Future<BudgetModel> updateBudget(BudgetModel budget) async => budget;

  @override
  Future<void> deleteBudget(String id) async {}

  @override
  Future<void> refreshBudgetSpentAmounts(String budgetId) async {}

  @override
  Future<void> manualRecalculateBudgetSpent(String budgetId) async {}

  @override
  Future<Map<String, dynamic>> debugBudgetCategories(String budgetId) async => {};
}
