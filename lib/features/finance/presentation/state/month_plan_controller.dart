import 'package:keep_track/core/error/result.dart';
import 'package:keep_track/core/state/stream_state.dart';
import '../../modules/budget/domain/entities/month_plan.dart';
import '../../modules/budget/domain/repositories/month_plan_repository.dart';

/// Controller for managing MonthPlan state
class MonthPlanController extends StreamState<AsyncState<List<MonthPlan>>> {
  final MonthPlanRepository _repository;

  MonthPlanController(this._repository) : super(const AsyncLoading()) {
    loadMonthPlans();
  }

  Future<void> loadMonthPlans() async {
    await execute(() async {
      final result = await _repository.getMonthPlans();
      return result.unwrap();
    });
  }

  /// Get existing plan for [month] or create a new empty one
  Future<MonthPlan> getOrCreateMonthPlan(String month) async {
    MonthPlan? plan;
    await executeSilent(() async {
      final result = await _repository.getOrCreateMonthPlan(month);
      plan = result.unwrap();
      final current = data ?? [];
      if (!current.any((p) => p.month == month)) {
        return [...current, plan!];
      }
      return current.map((p) => p.month == month ? plan! : p).toList();
    });
    return plan!;
  }

  /// Remove the month plan row only — budgets are kept
  Future<void> deleteMonthPlan(String id) async {
    await executeSilent(() async {
      final result = await _repository.deleteMonthPlan(id);
      result.unwrap();
      final current = data ?? [];
      return current.where((p) => p.id != id).toList();
    });
  }

  /// Remove the month plan row AND all budgets + categories for [month]
  Future<void> deleteMonthPlanWithBudgets(String id, String month) async {
    await executeSilent(() async {
      final result = await _repository.deleteMonthPlanWithBudgets(id, month);
      result.unwrap();
      final current = data ?? [];
      return current.where((p) => p.id != id).toList();
    });
  }

  /// Copy all budgets from [sourceMonth] into [targetMonth]
  Future<MonthPlan> copyMonthPlan(
    String sourceMonth,
    String targetMonth,
  ) async {
    MonthPlan? copied;
    await executeSilent(() async {
      final result = await _repository.copyMonthPlan(sourceMonth, targetMonth);
      copied = result.unwrap();
      final current = data ?? [];
      if (!current.any((p) => p.month == targetMonth)) {
        return [...current, copied!];
      }
      return current
          .map((p) => p.month == targetMonth ? copied! : p)
          .toList();
    });
    return copied!;
  }

  /// Link [budgetId] to the month plan for [month].
  /// Finds the plan in current state by month, calls the API, and is a no-op
  /// if no plan exists yet (the budget will still be shown via its month field).
  Future<void> addBudgetToMonthPlan(String month, String budgetId) async {
    final current = data ?? [];
    final plan = current.cast<MonthPlan?>().firstWhere(
      (p) => p?.month == month,
      orElse: () => null,
    );
    if (plan?.id == null) return; // no plan to link to yet
    await executeSilent(() async {
      final result = await _repository.addBudgetToMonthPlan(plan!.id!, budgetId);
      result.unwrap();
      // Reload month plans so the new budget group appears immediately
      final refreshed = await _repository.getMonthPlans();
      return refreshed.unwrap();
    });
  }

  /// Clear all month plan state (called on sign-out to prevent data leaking to next user)
  void clear() {
    emit(const AsyncData([]));
  }
}
