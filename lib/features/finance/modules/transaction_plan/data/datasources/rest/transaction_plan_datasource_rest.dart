import 'package:dio/dio.dart';
import 'package:keep_track/core/error/failure.dart';
import 'package:keep_track/core/network/api_client.dart';
import 'package:keep_track/core/network/api_exception.dart';
import '../transaction_plan_datasource.dart';
import '../../models/transaction_plan_model.dart';

class TransactionPlanDataSourceRest implements TransactionPlanDataSource {
  final Dio _dio;

  TransactionPlanDataSourceRest([Dio? dio]) : _dio = dio ?? ApiClient.instance;

  List<TransactionPlanModel> _parseList(dynamic data) =>
      (data as List).map((j) => TransactionPlanModel.fromJson(j as Map<String, dynamic>)).toList();

  TransactionPlanModel _parsePlan(dynamic data) =>
      TransactionPlanModel.fromJson((data as Map<String, dynamic>)['plan'] as Map<String, dynamic>? ?? data as Map<String, dynamic>);

  @override
  Future<List<TransactionPlanModel>> getPlans({String? status}) async {
    try {
      final res = await _dio.get('/transaction-plans',
          queryParameters: {if (status != null) 'status': status});
      return _parseList(res.data);
    } on DioException catch (e) {
      throw mapDioError(e);
    } catch (e, st) {
      throw UnknownFailure(message: 'Failed to fetch plans', originalError: e, stackTrace: st);
    }
  }

  @override
  Future<TransactionPlanModel> createPlan(TransactionPlanModel plan) async {
    try {
      final res = await _dio.post('/transaction-plans', data: plan.toApiJson());
      return TransactionPlanModel.fromJson(res.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw mapDioError(e);
    } catch (e, st) {
      throw UnknownFailure(message: 'Failed to create plan', originalError: e, stackTrace: st);
    }
  }

  @override
  Future<TransactionPlanModel> updatePlan(TransactionPlanModel plan) async {
    try {
      final res = await _dio.patch('/transaction-plans/${plan.id}', data: plan.toApiJson());
      return TransactionPlanModel.fromJson(res.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw mapDioError(e);
    } catch (e, st) {
      throw UnknownFailure(message: 'Failed to update plan', originalError: e, stackTrace: st);
    }
  }

  @override
  Future<void> deletePlan(String id) async {
    try {
      await _dio.delete('/transaction-plans/$id');
    } on DioException catch (e) {
      throw mapDioError(e);
    } catch (e, st) {
      throw UnknownFailure(message: 'Failed to delete plan', originalError: e, stackTrace: st);
    }
  }

  @override
  Future<TransactionPlanModel> cancelPlan(String id) async {
    try {
      final res = await _dio.post('/transaction-plans/$id/cancel');
      return TransactionPlanModel.fromJson(res.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw mapDioError(e);
    } catch (e, st) {
      throw UnknownFailure(message: 'Failed to cancel plan', originalError: e, stackTrace: st);
    }
  }

  @override
  Future<TransactionPlanModel> completePlan(String id, {double? amount, DateTime? date}) async {
    try {
      final res = await _dio.post('/transaction-plans/$id/complete', data: {
        if (amount != null) 'amount': amount,
        if (date != null) 'date': DateTime.fromMillisecondsSinceEpoch(date.millisecondsSinceEpoch, isUtc: true).toIso8601String(),
      });
      return _parsePlan(res.data);
    } on DioException catch (e) {
      throw mapDioError(e);
    } catch (e, st) {
      throw UnknownFailure(message: 'Failed to complete plan', originalError: e, stackTrace: st);
    }
  }
}
