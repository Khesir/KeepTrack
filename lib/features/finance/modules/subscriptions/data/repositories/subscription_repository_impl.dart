import 'package:keep_track/core/error/result.dart';
import '../../domain/entities/subscription.dart';
import '../../domain/repositories/subscription_repository.dart';
import '../datasources/subscription_datasource.dart';
import '../models/subscription_model.dart';

class SubscriptionRepositoryImpl implements SubscriptionRepository {
  final SubscriptionDataSource _dataSource;

  SubscriptionRepositoryImpl(this._dataSource);

  @override
  Future<Result<List<Subscription>>> getSubscriptions({String? budgetProfileId}) async {
    final list = await _dataSource.getSubscriptions(budgetProfileId: budgetProfileId);
    return Result.success(list);
  }

  @override
  Future<Result<Subscription>> createSubscription(Subscription subscription) async {
    final created = await _dataSource.createSubscription(SubscriptionModel.fromEntity(subscription));
    return Result.success(created);
  }

  @override
  Future<Result<Subscription>> updateSubscription(Subscription subscription) async {
    final updated = await _dataSource.updateSubscription(SubscriptionModel.fromEntity(subscription));
    return Result.success(updated);
  }

  @override
  Future<Result<void>> deleteSubscription(String id) async {
    await _dataSource.deleteSubscription(id);
    return Result.success(null);
  }

  @override
  Future<Result<Subscription>> pay(String id, {String? budgetId}) async {
    final updated = await _dataSource.pay(id, budgetId: budgetId);
    return Result.success(updated);
  }
}
