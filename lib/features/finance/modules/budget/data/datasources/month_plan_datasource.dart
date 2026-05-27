import '../models/month_plan_model.dart';

/// Abstract data source for MonthPlan operations
abstract class MonthPlanDataSource {
  Future<List<MonthPlanModel>> getMonthPlans();
  Future<MonthPlanModel?> getMonthPlanByMonth(String month);
  Future<MonthPlanModel> createMonthPlan(MonthPlanModel plan);
  Future<MonthPlanModel> updateMonthPlan(MonthPlanModel plan);
  Future<void> deleteMonthPlan(String id);

  /// Copy all budgets from [sourceMonth] to [targetMonth].
  /// Creates a MonthPlan for [targetMonth] if one does not exist.
  Future<MonthPlanModel> copyMonthPlan(String sourceMonth, String targetMonth);

  /// Delete the month plan row AND all budgets (+ their categories) for [month].
  Future<void> deleteMonthPlanWithBudgets(String id, String month);

  /// Link [budgetId] to this plan's budgetIds list.
  Future<void> addBudgetToMonthPlan(String planId, String budgetId);

  /// Get or create the plan for a custom budget profile.
  Future<MonthPlanModel> getOrCreatePlanForProfile(String profileId);
}
