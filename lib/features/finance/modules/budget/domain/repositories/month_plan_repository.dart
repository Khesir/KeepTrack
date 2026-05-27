import 'package:keep_track/core/error/result.dart';
import '../entities/month_plan.dart';

/// Repository interface for MonthPlan operations
abstract class MonthPlanRepository {
  /// Get all month plans for the current user (ordered newest first)
  Future<Result<List<MonthPlan>>> getMonthPlans();

  /// Get a month plan by month string (YYYY-MM).
  /// Returns null value in Result if no plan exists for the month.
  Future<Result<MonthPlan?>> getMonthPlanByMonth(String month);

  /// Get an existing month plan or create a new empty one for the given month.
  Future<Result<MonthPlan>> getOrCreateMonthPlan(String month);

  /// Copy all budgets from [sourceMonth] to [targetMonth].
  ///
  /// Creates (or reuses) a MonthPlan for [targetMonth] and duplicates every
  /// budget and its categories from [sourceMonth], resetting ids, spent
  /// amounts, status, and timestamps.
  ///
  /// Fails if [sourceMonth] has no budgets to copy.
  Future<Result<MonthPlan>> copyMonthPlan(
    String sourceMonth,
    String targetMonth,
  );

  /// Update the notes on a month plan
  Future<Result<MonthPlan>> updateMonthPlan(MonthPlan plan);

  /// Delete a month plan record. Does NOT delete the associated budgets.
  Future<Result<void>> deleteMonthPlan(String id);

  /// Delete the month plan AND all budgets (+ categories) for [month].
  Future<Result<void>> deleteMonthPlanWithBudgets(String id, String month);

  /// Link [budgetId] to this plan's budgetIds list.
  Future<Result<void>> addBudgetToMonthPlan(String planId, String budgetId);

  /// Get or create the plan for a custom budget profile.
  Future<Result<MonthPlan>> getOrCreatePlanForProfile(String profileId);
}
