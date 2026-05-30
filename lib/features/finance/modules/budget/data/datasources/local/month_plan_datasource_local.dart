import 'package:keep_track/core/cache/local_cache.dart';
import 'package:keep_track/features/finance/modules/budget/data/models/budget_model.dart';
import 'package:keep_track/features/finance/modules/budget/data/models/month_plan_model.dart';
import 'package:uuid/uuid.dart';
import '../month_plan_datasource.dart';

class MonthPlanDataSourceLocal implements MonthPlanDataSource {
  final LocalCache _cache;
  final _uuid = const Uuid();

  static const _box = 'month_plans';
  static const _budgetsBox = 'budgets';

  MonthPlanDataSourceLocal(this._cache);

  Future<List<MonthPlanModel>> _getAll() async {
    final entries = await _cache.getAll(_box);
    return entries.map((e) => MonthPlanModel.fromJson(e)).toList();
  }

  @override
  Future<List<MonthPlanModel>> getMonthPlans() async => _getAll();

  @override
  Future<MonthPlanModel?> getMonthPlanByMonth(String month) async {
    final all = await _getAll();
    try {
      return all.firstWhere((p) => p.month == month);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<MonthPlanModel> createMonthPlan(MonthPlanModel plan) async {
    final id = plan.id ?? _uuid.v4();
    final model = MonthPlanModel.fromJson({...plan.toJson(), 'id': id});
    await _cache.put(_box, id, model.toJson());
    return model;
  }

  @override
  Future<MonthPlanModel> updateMonthPlan(MonthPlanModel plan) async {
    await _cache.put(_box, plan.id!, plan.toJson());
    return plan;
  }

  @override
  Future<void> deleteMonthPlan(String id) async {
    await _cache.delete(_box, id);
  }

  @override
  Future<MonthPlanModel> copyMonthPlan(
    String sourceMonth,
    String targetMonth,
  ) async {
    final allPlans = await _getAll();
    final source = allPlans.firstWhere(
      (p) => p.month == sourceMonth,
      orElse: () => throw StateError('Source month plan $sourceMonth not found'),
    );

    final allBudgetEntries = await _cache.getAll(_budgetsBox);
    final sourceBudgets = allBudgetEntries
        .map((e) => BudgetModel.fromJson(e))
        .where((b) => source.budgetIds.contains(b.id))
        .toList();

    final newBudgetIds = <String>[];
    for (final budget in sourceBudgets) {
      final newBudgetId = _uuid.v4();
      final newBudget = BudgetModel.fromJson({
        ...budget.toJson(),
        'id': newBudgetId,
        'month': targetMonth,
      });
      await _cache.put(_budgetsBox, newBudgetId, newBudget.toJson());
      newBudgetIds.add(newBudgetId);
    }

    final existing = allPlans.firstWhere(
      (p) => p.month == targetMonth,
      orElse: () => MonthPlanModel(id: null),
    );

    if (existing.id != null) {
      final merged = MonthPlanModel.fromJson({
        ...existing.toJson(),
        'budgetIds': [...existing.budgetIds, ...newBudgetIds],
      });
      await _cache.put(_box, existing.id!, merged.toJson());
      return merged;
    }

    final newPlanId = _uuid.v4();
    final newPlan = MonthPlanModel.fromJson({
      'id': newPlanId,
      'month': targetMonth,
      if (source.userId != null) 'userId': source.userId,
      if (source.budgetProfileId != null)
        'budgetProfileId': source.budgetProfileId,
      'budgetIds': newBudgetIds,
    });
    await _cache.put(_box, newPlanId, newPlan.toJson());
    return newPlan;
  }

  @override
  Future<void> deleteMonthPlanWithBudgets(String id, String month) async {
    final data = await _cache.get(_box, id);
    if (data != null) {
      final plan = MonthPlanModel.fromJson(data);
      for (final budgetId in plan.budgetIds) {
        await _cache.delete(_budgetsBox, budgetId);
      }
    }
    await _cache.delete(_box, id);
  }

  @override
  Future<void> addBudgetToMonthPlan(String planId, String budgetId) async {
    final data = await _cache.get(_box, planId);
    if (data == null) throw StateError('MonthPlan $planId not found in cache');
    final plan = MonthPlanModel.fromJson(data);
    final updated = MonthPlanModel.fromJson({
      ...plan.toJson(),
      'budgetIds': [...plan.budgetIds, budgetId],
    });
    await _cache.put(_box, planId, updated.toJson());
  }

  @override
  Future<MonthPlanModel> getOrCreatePlanForProfile(String profileId) async {
    final all = await _getAll();
    try {
      return all.firstWhere((p) => p.budgetProfileId == profileId);
    } catch (_) {
      final id = _uuid.v4();
      final plan = MonthPlanModel.fromJson({
        'id': id,
        'budgetProfileId': profileId,
        'budgetIds': <String>[],
      });
      await _cache.put(_box, id, plan.toJson());
      return plan;
    }
  }

  @override
  Future<MonthPlanModel> closeMonthPlan(String id) async {
    final data = await _cache.get(_box, id);
    if (data == null) throw StateError('MonthPlan $id not found');
    final plan = MonthPlanModel.fromJson(data);
    final closed = MonthPlanModel.fromJson({
      ...plan.toJson(),
      'status': 'closed',
    });
    await _cache.put(_box, id, closed.toJson());
    return closed;
  }
}
