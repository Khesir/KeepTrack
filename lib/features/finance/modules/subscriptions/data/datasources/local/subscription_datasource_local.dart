import 'package:keep_track/core/cache/local_cache.dart';
import 'package:keep_track/features/finance/modules/subscriptions/data/models/subscription_model.dart';
import 'package:keep_track/features/finance/modules/subscriptions/domain/entities/subscription.dart';
import 'package:uuid/uuid.dart';
import '../subscription_datasource.dart';

class SubscriptionDataSourceLocal implements SubscriptionDataSource {
  final LocalCache _cache;
  final _uuid = const Uuid();

  static const _box = 'subscriptions';

  SubscriptionDataSourceLocal(this._cache);

  Future<List<SubscriptionModel>> _getAll() async {
    final entries = await _cache.getAll(_box);
    return entries.map((e) => SubscriptionModel.fromJson(e)).toList();
  }

  DateTime _advanceBillingDate(DateTime current, BillingCycle cycle) {
    return switch (cycle) {
      BillingCycle.weekly => current.add(const Duration(days: 7)),
      BillingCycle.monthly => DateTime(
          current.year,
          current.month + 1,
          current.day,
        ),
      BillingCycle.quarterly => DateTime(
          current.year,
          current.month + 3,
          current.day,
        ),
      BillingCycle.annual => DateTime(
          current.year + 1,
          current.month,
          current.day,
        ),
    };
  }

  @override
  Future<List<SubscriptionModel>> getSubscriptions({
    String? budgetProfileId,
  }) async {
    final all = await _getAll();
    if (budgetProfileId == null) return all;
    return all.where((s) => s.budgetProfileId == budgetProfileId).toList();
  }

  @override
  Future<SubscriptionModel> createSubscription(
    SubscriptionModel subscription,
  ) async {
    final id = subscription.id ?? _uuid.v4();
    final model =
        SubscriptionModel.fromJson({...subscription.toJson(), 'id': id});
    await _cache.put(_box, id, model.toJson());
    return model;
  }

  @override
  Future<SubscriptionModel> updateSubscription(
    SubscriptionModel subscription,
  ) async {
    await _cache.put(_box, subscription.id!, subscription.toJson());
    return subscription;
  }

  @override
  Future<void> deleteSubscription(String id) async {
    await _cache.delete(_box, id);
  }

  @override
  Future<SubscriptionModel> pay(String id, {String? budgetId}) async {
    final data = await _cache.get(_box, id);
    if (data == null) throw StateError('Subscription $id not found in cache');
    final current = SubscriptionModel.fromJson(data);
    final now = DateTime.now();
    final nextBillingDate =
        _advanceBillingDate(current.nextBillingDate, current.billingCycle);
    final updated = SubscriptionModel.fromJson({
      ...current.toJson(),
      'lastBilledDate': now.toIso8601String(),
      'nextBillingDate': nextBillingDate.toIso8601String(),
    });
    await _cache.put(_box, id, updated.toJson());
    return updated;
  }
}
