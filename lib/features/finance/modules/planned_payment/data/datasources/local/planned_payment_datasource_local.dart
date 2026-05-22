import 'package:keep_track/core/cache/local_cache.dart';
import 'package:keep_track/features/finance/modules/planned_payment/data/models/planned_payment_model.dart';
import 'package:uuid/uuid.dart';
import '../planned_payment_datasource.dart';

class PlannedPaymentDataSourceLocal implements PlannedPaymentDataSource {
  final LocalCache _cache;
  final _uuid = const Uuid();

  static const _box = 'planned_payments';

  PlannedPaymentDataSourceLocal(this._cache);

  Future<List<PlannedPaymentModel>> _getAll() async {
    final entries = await _cache.getAll(_box);
    return entries.map((e) => PlannedPaymentModel.fromJson(e)).toList();
  }

  @override
  Future<List<PlannedPaymentModel>> fetchPlannedPayments() async => _getAll();

  @override
  Future<PlannedPaymentModel?> fetchPlannedPaymentById(String id) async {
    final data = await _cache.get(_box, id);
    if (data == null) return null;
    return PlannedPaymentModel.fromJson(data);
  }

  @override
  Future<PlannedPaymentModel> createPlannedPayment(
    PlannedPaymentModel payment,
  ) async {
    final id = payment.id ?? _uuid.v4();
    final model = PlannedPaymentModel.fromJson({...payment.toJson(), 'id': id});
    await _cache.put(_box, id, model.toJson());
    return model;
  }

  @override
  Future<PlannedPaymentModel> updatePlannedPayment(
    PlannedPaymentModel payment,
  ) async {
    await _cache.put(_box, payment.id!, payment.toJson());
    return payment;
  }

  @override
  Future<void> deletePlannedPayment(String id) async {
    await _cache.delete(_box, id);
  }

  @override
  Future<List<PlannedPaymentModel>> fetchPlannedPaymentsByStatus(
    String status,
  ) async {
    final all = await _getAll();
    return all.where((p) => p.status.name == status).toList();
  }

  @override
  Future<List<PlannedPaymentModel>> fetchPlannedPaymentsByCategory(
    String category,
  ) async {
    final all = await _getAll();
    return all.where((p) => p.category.name == category).toList();
  }

  @override
  Future<List<PlannedPaymentModel>> fetchUpcomingPayments() async {
    final now = DateTime.now();
    final cutoff = now.add(const Duration(days: 7));
    final all = await _getAll();
    return all
        .where((p) =>
            !p.nextPaymentDate.isBefore(now) &&
            !p.nextPaymentDate.isAfter(cutoff))
        .toList();
  }
}
