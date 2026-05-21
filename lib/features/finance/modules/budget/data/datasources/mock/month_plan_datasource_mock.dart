import 'package:keep_track/features/finance/modules/budget/data/datasources/month_plan_datasource.dart';
import 'package:keep_track/features/finance/modules/budget/data/datasources/mock/budget_datasource_mock.dart';
import 'package:keep_track/features/finance/modules/budget/data/models/month_plan_model.dart';

final _monthlyPlan = MonthPlanModel(
  id: 'plan-may-1',
  month: '2026-05',
  userId: 'demo',
  budgetIds: ['budget-inc-1', 'budget-exp-1'],
  budgets: demoBudgets.where((b) => b.budgetProfileId == null).toList(),
);

final _profilePlan = MonthPlanModel(
  id: 'plan-personal-prof',
  month: '2026-05',
  budgetProfileId: 'profile-personal',
  userId: 'demo',
  budgetIds: ['budget-inc-prof', 'budget-exp-prof'],
  budgets: demoBudgets.where((b) => b.budgetProfileId == 'profile-personal').toList(),
);

final _plans = [_monthlyPlan, _profilePlan];

class MonthPlanDataSourceMock implements MonthPlanDataSource {
  @override
  Future<List<MonthPlanModel>> getMonthPlans() async => _plans;

  @override
  Future<MonthPlanModel?> getMonthPlanByMonth(String month) async =>
      _plans.where((p) => p.month == month && p.budgetProfileId == null).firstOrNull;

  @override
  Future<MonthPlanModel> createMonthPlan(MonthPlanModel plan) async => plan;

  @override
  Future<MonthPlanModel> updateMonthPlan(MonthPlanModel plan) async => plan;

  @override
  Future<void> deleteMonthPlan(String id) async {}

  @override
  Future<MonthPlanModel> copyMonthPlan(String sourceMonth, String targetMonth) async =>
      MonthPlanModel(id: 'plan-copied', month: targetMonth, userId: 'demo', budgetIds: []);

  @override
  Future<void> deleteMonthPlanWithBudgets(String id, String month) async {}

  @override
  Future<void> addBudgetToMonthPlan(String planId, String budgetId) async {}

  @override
  Future<MonthPlanModel> getOrCreatePlanForProfile(String profileId) async =>
      _plans.where((p) => p.budgetProfileId == profileId).firstOrNull ??
      MonthPlanModel(id: 'plan-empty', month: '2026-05', budgetProfileId: profileId, userId: 'demo', budgetIds: []);
}
