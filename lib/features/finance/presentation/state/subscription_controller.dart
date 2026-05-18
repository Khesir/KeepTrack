import 'package:keep_track/core/error/result.dart';
import 'package:keep_track/core/state/stream_state.dart';
import '../../modules/subscriptions/domain/entities/subscription.dart';
import '../../modules/subscriptions/domain/repositories/subscription_repository.dart';

class SubscriptionController extends StreamState<AsyncState<List<Subscription>>> {
  final SubscriptionRepository _repository;

  SubscriptionController(this._repository) : super(const AsyncLoading()) {
    loadSubscriptions();
  }

  Future<void> loadSubscriptions({String? budgetProfileId}) async {
    await execute(() async {
      return await _repository.getSubscriptions(budgetProfileId: budgetProfileId).then((r) => r.unwrap());
    });
  }

  Future<void> createSubscription(Subscription subscription) async {
    final created = await _repository.createSubscription(subscription).then((r) => r.unwrap());
    emit(AsyncData([...data ?? [], created]));
  }

  Future<void> updateSubscription(Subscription subscription) async {
    await _repository.updateSubscription(subscription).then((r) => r.unwrap());
    await loadSubscriptions();
  }

  Future<void> deleteSubscription(String id) async {
    await _repository.deleteSubscription(id).then((r) => r.unwrap());
    await loadSubscriptions();
  }

  Future<Subscription> pay(String id, {String? budgetId}) async {
    final updated = await _repository.pay(id, budgetId: budgetId).then((r) => r.unwrap());
    await loadSubscriptions();
    return updated;
  }
}
