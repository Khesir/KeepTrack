import 'package:dio/dio.dart';
import 'package:keep_track/core/error/failure.dart';
import 'package:keep_track/core/network/api_client.dart';
import 'package:keep_track/core/network/api_exception.dart';
import '../subscription_datasource.dart';
import '../../models/subscription_model.dart';

class SubscriptionDataSourceRest implements SubscriptionDataSource {
  final Dio _dio;

  SubscriptionDataSourceRest([Dio? dio]) : _dio = dio ?? ApiClient.instance;

  List<SubscriptionModel> _parseList(dynamic data) =>
      (data as List).map((j) => SubscriptionModel.fromJson(j as Map<String, dynamic>)).toList();

  @override
  Future<List<SubscriptionModel>> getSubscriptions({String? budgetProfileId}) async {
    try {
      final res = await _dio.get('/subscriptions',
        queryParameters: budgetProfileId != null ? {'budgetProfileId': budgetProfileId} : null);
      return _parseList(res.data);
    } on DioException catch (e) {
      throw mapDioError(e);
    } catch (e, st) {
      throw UnknownFailure(message: 'Failed to fetch subscriptions', originalError: e, stackTrace: st);
    }
  }

  @override
  Future<SubscriptionModel> createSubscription(SubscriptionModel subscription) async {
    try {
      final res = await _dio.post('/subscriptions', data: subscription.toApiJson());
      return SubscriptionModel.fromJson(res.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw mapDioError(e);
    } catch (e, st) {
      throw UnknownFailure(message: 'Failed to create subscription', originalError: e, stackTrace: st);
    }
  }

  @override
  Future<SubscriptionModel> updateSubscription(SubscriptionModel subscription) async {
    try {
      final res = await _dio.patch('/subscriptions/${subscription.id}', data: subscription.toApiJson());
      return SubscriptionModel.fromJson(res.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw mapDioError(e);
    } catch (e, st) {
      throw UnknownFailure(message: 'Failed to update subscription', originalError: e, stackTrace: st);
    }
  }

  @override
  Future<void> deleteSubscription(String id) async {
    try {
      await _dio.delete('/subscriptions/$id');
    } on DioException catch (e) {
      throw mapDioError(e);
    } catch (e, st) {
      throw UnknownFailure(message: 'Failed to delete subscription', originalError: e, stackTrace: st);
    }
  }

  @override
  Future<SubscriptionModel> pay(String id, {String? budgetId}) async {
    try {
      final res = await _dio.post('/subscriptions/$id/pay', data: {
        if (budgetId != null) 'budgetId': budgetId,
      });
      return SubscriptionModel.fromJson((res.data as Map<String, dynamic>)['subscription'] as Map<String, dynamic>);
    } on DioException catch (e) {
      throw mapDioError(e);
    } catch (e, st) {
      throw UnknownFailure(message: 'Failed to record subscription payment', originalError: e, stackTrace: st);
    }
  }
}
