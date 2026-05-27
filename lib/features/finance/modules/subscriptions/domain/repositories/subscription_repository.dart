import 'package:keep_track/core/error/result.dart';
import '../entities/subscription.dart';

abstract class SubscriptionRepository {
  Future<Result<List<Subscription>>> getSubscriptions({String? budgetProfileId});
  Future<Result<Subscription>> createSubscription(Subscription subscription);
  Future<Result<Subscription>> updateSubscription(Subscription subscription);
  Future<Result<void>> deleteSubscription(String id);
  Future<Result<Subscription>> pay(String id, {String? budgetId});
}
