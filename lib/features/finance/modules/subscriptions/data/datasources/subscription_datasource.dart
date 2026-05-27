import '../models/subscription_model.dart';

abstract class SubscriptionDataSource {
  Future<List<SubscriptionModel>> getSubscriptions({String? budgetProfileId});
  Future<SubscriptionModel> createSubscription(SubscriptionModel subscription);
  Future<SubscriptionModel> updateSubscription(SubscriptionModel subscription);
  Future<void> deleteSubscription(String id);
  Future<SubscriptionModel> pay(String id, {String? budgetId});
}
