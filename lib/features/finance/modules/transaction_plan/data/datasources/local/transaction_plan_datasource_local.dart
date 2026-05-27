import 'package:keep_track/core/cache/local_cache.dart';
import 'package:keep_track/features/finance/modules/transaction_plan/data/models/transaction_plan_model.dart';
import 'package:keep_track/features/finance/modules/transaction_plan/domain/entities/transaction_plan.dart';
import 'package:uuid/uuid.dart';
import '../transaction_plan_datasource.dart';

class TransactionPlanDataSourceLocal implements TransactionPlanDataSource {
  final LocalCache _cache;
  final _uuid = const Uuid();

  static const _box = 'transaction_plans';

  TransactionPlanDataSourceLocal(this._cache);

  Future<List<TransactionPlanModel>> _getAll() async {
    final entries = await _cache.getAll(_box);
    return entries.map((e) => TransactionPlanModel.fromJson(e)).toList();
  }

  @override
  Future<List<TransactionPlanModel>> getPlans({String? status}) async {
    final all = await _getAll();
    if (status == null) return all;
    return all.where((p) => p.status.name == status).toList();
  }

  @override
  Future<TransactionPlanModel> createPlan(TransactionPlanModel plan) async {
    final id = plan.id ?? _uuid.v4();
    final model = TransactionPlanModel.fromJson({...plan.toJson(), 'id': id});
    await _cache.put(_box, id, model.toJson());
    return model;
  }

  @override
  Future<TransactionPlanModel> updatePlan(TransactionPlanModel plan) async {
    await _cache.put(_box, plan.id!, plan.toJson());
    return plan;
  }

  @override
  Future<void> deletePlan(String id) async {
    await _cache.delete(_box, id);
  }

  @override
  Future<TransactionPlanModel> cancelPlan(String id) async {
    final data = await _cache.get(_box, id);
    if (data == null) throw StateError('TransactionPlan $id not found in cache');
    final updated = TransactionPlanModel.fromJson({
      ...data,
      'status': TransactionPlanStatus.cancelled.name,
    });
    await _cache.put(_box, id, updated.toJson());
    return updated;
  }

  @override
  Future<TransactionPlanModel> completePlan(
    String id, {
    double? amount,
    DateTime? date,
  }) async {
    final data = await _cache.get(_box, id);
    if (data == null) throw StateError('TransactionPlan $id not found in cache');
    final updated = TransactionPlanModel.fromJson({
      ...data,
      'status': TransactionPlanStatus.completed.name,
      'completedAt': DateTime.now().toIso8601String(),
      if (amount != null) 'amount': amount,
      if (date != null) 'plannedDate': date.toIso8601String(),
    });
    await _cache.put(_box, id, updated.toJson());
    return updated;
  }
}
