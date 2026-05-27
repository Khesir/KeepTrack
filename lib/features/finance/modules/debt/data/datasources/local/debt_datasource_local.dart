import 'package:keep_track/core/cache/local_cache.dart';
import 'package:keep_track/features/finance/modules/debt/data/models/debt_model.dart';
import 'package:uuid/uuid.dart';
import '../debt_datasource.dart';

class DebtDataSourceLocal implements DebtDataSource {
  final LocalCache _cache;
  final _uuid = const Uuid();

  static const _box = 'debts';

  DebtDataSourceLocal(this._cache);

  Future<List<DebtModel>> _getAll() async {
    final entries = await _cache.getAll(_box);
    return entries.map((e) => DebtModel.fromJson(e)).toList();
  }

  @override
  Future<List<DebtModel>> fetchDebts({String? budgetProfileId}) async {
    final all = await _getAll();
    if (budgetProfileId == null) return all;
    return all.where((d) => d.budgetProfileId == budgetProfileId).toList();
  }

  @override
  Future<DebtModel?> fetchDebtById(String id) async {
    final data = await _cache.get(_box, id);
    if (data == null) return null;
    return DebtModel.fromJson(data);
  }

  @override
  Future<DebtModel> createDebt(DebtModel debt) async {
    final id = debt.id ?? _uuid.v4();
    final model = DebtModel.fromJson({...debt.toJson(), 'id': id});
    await _cache.put(_box, id, model.toJson());
    return model;
  }

  @override
  Future<DebtModel> updateDebt(DebtModel debt) async {
    await _cache.put(_box, debt.id!, debt.toJson());
    return debt;
  }

  @override
  Future<void> deleteDebt(String id) async {
    await _cache.delete(_box, id);
  }

  @override
  Future<List<DebtModel>> fetchDebtsByType(String type) async {
    final all = await _getAll();
    return all.where((d) => d.type.name == type).toList();
  }

  @override
  Future<List<DebtModel>> fetchDebtsByStatus(String status) async {
    final all = await _getAll();
    return all.where((d) => d.status.name == status).toList();
  }

  @override
  Future<DebtModel> payDebt(String id, {required double amount, double? fee}) async {
    final data = await _cache.get(_box, id);
    if (data == null) throw StateError('Debt $id not found in cache');
    final current = DebtModel.fromJson(data);
    final updated = DebtModel.fromJson({
      ...current.toJson(),
      'remainingAmount': current.remainingAmount - amount,
      'feeAmount': current.feeAmount + (fee ?? 0.0),
    });
    await _cache.put(_box, id, updated.toJson());
    return updated;
  }
}
