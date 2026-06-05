import 'package:keep_track/core/di/service_locator.dart';
import 'package:keep_track/core/error/result.dart';
import 'package:keep_track/core/services/notification/notification_scheduler.dart';
import 'package:keep_track/core/services/notification/platform_notification_helper.dart';
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
      final subscriptions = await _repository
          .getSubscriptions(budgetProfileId: budgetProfileId)
          .then((r) => r.unwrap());
      _scheduleSubscriptionNotifications(subscriptions);
      return subscriptions;
    });
  }

  String? get _activeProfileId =>
      locator.get<BudgetProfileController>().activeProfileId;

  Future<void> createSubscription(Subscription subscription) async {
    final withProfile = subscription.budgetProfileId != null
        ? subscription
        : subscription.copyWith(budgetProfileId: _activeProfileId);
    await executeSilent(() async {
      final created = await _repository.createSubscription(withProfile).then((r) => r.unwrap());
      _scheduleNotificationForSubscription(created);
      return await _repository.getSubscriptions().then((r) => r.unwrap());
    });
  }

  Future<void> updateSubscription(Subscription subscription) async {
    await _repository.updateSubscription(subscription).then((r) => r.unwrap());
    if (subscription.id != null) _cancelSubscriptionNotification(subscription.id!);
    _scheduleNotificationForSubscription(subscription);
    await executeSilent(() async {
      return await _repository.getSubscriptions().then((r) => r.unwrap());
    });
  }

  Future<void> deleteSubscription(String id) async {
    await _repository.deleteSubscription(id).then((r) => r.unwrap());
    _cancelSubscriptionNotification(id);
    await loadSubscriptions();
  }

  Future<Subscription> pay(String id, {String? budgetId}) async {
    final updated = await _repository.pay(id, budgetId: budgetId).then((r) => r.unwrap());
    _cancelSubscriptionNotification(id);
    _scheduleNotificationForSubscription(updated);
    await executeSilent(() async {
      return await _repository.getSubscriptions().then((r) => r.unwrap());
    });
    return updated;
  }

  void _scheduleSubscriptionNotifications(List<Subscription> subscriptions) {
    for (final s in subscriptions) {
      _scheduleNotificationForSubscription(s);
    }
  }

  void _scheduleNotificationForSubscription(Subscription subscription) {
    if (!PlatformNotificationHelper.instance.isSupportedPlatform) return;
    if (subscription.id == null) return;
    if (subscription.status != SubscriptionStatus.active) return;
    if (subscription.nextBillingDate.isBefore(DateTime.now())) return;
    locator.get<NotificationScheduler>().scheduleSubscriptionDueNotifications(
      subscriptionId: subscription.id!,
      name: subscription.name,
      amount: subscription.amount,
      billingDate: subscription.nextBillingDate,
    );
  }

  void _cancelSubscriptionNotification(String id) {
    if (!PlatformNotificationHelper.instance.isSupportedPlatform) return;
    locator.get<NotificationScheduler>().cancelSubscriptionDueNotifications(id);
  }
}
