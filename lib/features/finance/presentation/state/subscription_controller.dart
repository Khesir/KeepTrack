import 'package:keep_track/core/di/service_locator.dart';
import 'package:keep_track/core/error/result.dart';
import 'package:keep_track/core/state/stream_state.dart';
import '../../modules/subscriptions/domain/entities/subscription.dart';
import '../../modules/subscriptions/domain/repositories/subscription_repository.dart';
import 'budget_profile_controller.dart';

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

  String? get _activeProfileId =>
      locator.get<BudgetProfileController>().activeProfileId;

  Future<void> createSubscription(Subscription subscription) async {
    final withProfile = subscription.budgetProfileId != null
        ? subscription
        : subscription.copyWith(budgetProfileId: _activeProfileId);
    await executeSilent(() async {
      await _repository.createSubscription(withProfile).then((r) => r.unwrap());
      return await _repository.getSubscriptions().then((r) => r.unwrap());
    });
  }

  Future<void> updateSubscription(Subscription subscription) async {
    await _repository.updateSubscription(subscription).then((r) => r.unwrap());
    await executeSilent(() async {
      return await _repository.getSubscriptions().then((r) => r.unwrap());
    });
  }

  Future<void> deleteSubscription(String id) async {
    await _repository.deleteSubscription(id).then((r) => r.unwrap());
    await loadSubscriptions();
  }

  Future<Subscription> pay(String id, {String? budgetId}) async {
    final updated = await _repository.pay(id, budgetId: budgetId).then((r) => r.unwrap());
    // Use executeSilent so we don't flash AsyncLoading — the list stays visible during refresh
    await executeSilent(() async {
      return await _repository.getSubscriptions().then((r) => r.unwrap());
    });
    return updated;
  }
}
