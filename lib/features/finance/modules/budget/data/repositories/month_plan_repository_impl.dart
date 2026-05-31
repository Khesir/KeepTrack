import 'package:keep_track/core/error/result.dart';
import 'package:keep_track/core/error/failure.dart';

import '../../domain/entities/month_plan.dart';
import '../../domain/repositories/month_plan_repository.dart';
import '../datasources/month_plan_datasource.dart';
import '../models/month_plan_model.dart';

/// MonthPlan repository implementation
class MonthPlanRepositoryImpl implements MonthPlanRepository {
  final MonthPlanDataSource dataSource;

  MonthPlanRepositoryImpl(this.dataSource);

  @override
  Future<Result<List<MonthPlan>>> getMonthPlans() async {
    try {
      final plans = await dataSource.getMonthPlans();
      return Result.success(plans);
    } catch (e) {
      return Result.error(
        UnknownFailure(message: 'Failed to get month plans: $e'),
      );
    }
  }

  @override
  Future<Result<MonthPlan?>> getMonthPlanByMonth(String month) async {
    try {
      final plan = await dataSource.getMonthPlanByMonth(month);
      return Result.success(plan);
    } catch (e) {
      return Result.error(
        UnknownFailure(message: 'Failed to get month plan for $month: $e'),
      );
    }
  }

  @override
  Future<Result<MonthPlan>> getOrCreateMonthPlan(String month) async {
    try {
      final existing = await dataSource.getMonthPlanByMonth(month);
      if (existing != null) return Result.success(existing);

      final created = await dataSource.createMonthPlan(
        MonthPlanModel(month: month),
      );
      return Result.success(created);
    } catch (e) {
      return Result.error(
        UnknownFailure(message: 'Failed to get or create month plan: $e'),
      );
    }
  }

  @override
  Future<Result<MonthPlan>> copyMonthPlan(
    String sourceMonth,
    String targetMonth,
  ) async {
    try {
      final copied =
          await dataSource.copyMonthPlan(sourceMonth, targetMonth);
      return Result.success(copied);
    } catch (e) {
      return Result.error(
        UnknownFailure(
          message:
              'Failed to copy month plan from $sourceMonth to $targetMonth: $e',
        ),
      );
    }
  }

  @override
  Future<Result<MonthPlan>> updateMonthPlan(MonthPlan plan) async {
    try {
      final model = MonthPlanModel.fromEntity(plan);
      final updated = await dataSource.updateMonthPlan(model);
      return Result.success(updated);
    } catch (e) {
      return Result.error(
        UnknownFailure(message: 'Failed to update month plan: $e'),
      );
    }
  }

  @override
  Future<Result<void>> deleteMonthPlan(String id) async {
    try {
      await dataSource.deleteMonthPlan(id);
      return Result.success(null);
    } catch (e) {
      return Result.error(
        UnknownFailure(message: 'Failed to delete month plan: $e'),
      );
    }
  }

  @override
  Future<Result<void>> deleteMonthPlanWithBudgets(
    String id,
    String month,
  ) async {
    try {
      await dataSource.deleteMonthPlanWithBudgets(id, month);
      return Result.success(null);
    } catch (e) {
      return Result.error(
        UnknownFailure(
          message: 'Failed to delete month plan with budgets: $e',
        ),
      );
    }
  }

  @override
  Future<Result<void>> addBudgetToMonthPlan(String planId, String budgetId) async {
    try {
      await dataSource.addBudgetToMonthPlan(planId, budgetId);
      return Result.success(null);
    } catch (e) {
      return Result.error(
        UnknownFailure(message: 'Failed to add budget to month plan: $e'),
      );
    }
  }

  @override
  Future<Result<MonthPlan>> getOrCreatePlanForProfile(String profileId) async {
    try {
      final plan = await dataSource.getOrCreatePlanForProfile(profileId);
      return Result.success(plan);
    } catch (e) {
      return Result.error(
        UnknownFailure(message: 'Failed to get or create profile plan: $e'),
      );
    }
  }

  @override
  Future<Result<MonthPlan>> getOrCreateMonthPlanForMonthlyProfile(String month, String profileId) async {
    try {
      final plan = await dataSource.getOrCreateMonthPlanForMonthlyProfile(month, profileId);
      return Result.success(plan);
    } catch (e) {
      return Result.error(UnknownFailure(message: 'Failed to get or create monthly profile plan: $e'));
    }
  }

  @override
  Future<Result<MonthPlan>> closeMonthPlan(String id) async {
    try {
      final plan = await dataSource.closeMonthPlan(id);
      return Result.success(plan);
    } catch (e) {
      return Result.error(UnknownFailure(message: 'Failed to close month plan: $e'));
    }
  }

  @override
  Future<Result<MonthPlan>> reopenMonthPlan(String id) async {
    try {
      final plan = await dataSource.reopenMonthPlan(id);
      return Result.success(plan);
    } catch (e) {
      return Result.error(UnknownFailure(message: 'Failed to reopen month plan: $e'));
    }
  }
}
