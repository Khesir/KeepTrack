import 'package:dio/dio.dart';
import 'package:keep_track/core/error/failure.dart';
import 'package:keep_track/core/network/api_client.dart';
import 'package:keep_track/core/network/api_exception.dart';
import '../month_plan_datasource.dart';
import '../../models/month_plan_model.dart';

class MonthPlanDataSourceRest implements MonthPlanDataSource {
  final Dio _dio;

  MonthPlanDataSourceRest([Dio? dio]) : _dio = dio ?? ApiClient.instance;

  List<MonthPlanModel> _parseList(dynamic data) =>
      (data as List).map((j) => MonthPlanModel.fromJson(j as Map<String, dynamic>)).toList();

  @override
  Future<List<MonthPlanModel>> getMonthPlans() async {
    try {
      final res = await _dio.get('/month-plans');
      return _parseList(res.data);
    } on DioException catch (e) {
      throw mapDioError(e);
    } catch (e, st) {
      throw UnknownFailure(message: 'Failed to fetch month plans', originalError: e, stackTrace: st);
    }
  }

  @override
  Future<MonthPlanModel?> getMonthPlanByMonth(String month) async {
    try {
      final res = await _dio.get('/month-plans', queryParameters: {'month': month});
      final list = _parseList(res.data);
      return list.isEmpty ? null : list.first;
    } on DioException catch (e) {
      final f = mapDioError(e);
      if (f is NotFoundFailure) return null;
      throw f;
    } catch (e, st) {
      throw UnknownFailure(message: 'Failed to fetch month plan by month', originalError: e, stackTrace: st);
    }
  }

  @override
  Future<MonthPlanModel> createMonthPlan(MonthPlanModel plan) async {
    try {
      final res = await _dio.post('/month-plans', data: plan.toApiJson());
      return MonthPlanModel.fromJson(res.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw mapDioError(e);
    } catch (e, st) {
      throw UnknownFailure(message: 'Failed to create month plan', originalError: e, stackTrace: st);
    }
  }

  @override
  Future<MonthPlanModel> updateMonthPlan(MonthPlanModel plan) async {
    try {
      final res = await _dio.patch('/month-plans/${plan.id}', data: plan.toApiJson());
      return MonthPlanModel.fromJson(res.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw mapDioError(e);
    } catch (e, st) {
      throw UnknownFailure(message: 'Failed to update month plan', originalError: e, stackTrace: st);
    }
  }

  @override
  Future<void> deleteMonthPlan(String id) async {
    try {
      await _dio.delete('/month-plans/$id');
    } on DioException catch (e) {
      throw mapDioError(e);
    } catch (e, st) {
      throw UnknownFailure(message: 'Failed to delete month plan', originalError: e, stackTrace: st);
    }
  }

  @override
  Future<MonthPlanModel> copyMonthPlan(String sourceMonth, String targetMonth) async {
    try {
      final res = await _dio.post('/month-plans/copy', data: {
        'sourceMonth': sourceMonth,
        'targetMonth': targetMonth,
      });
      return MonthPlanModel.fromJson(res.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw mapDioError(e);
    } catch (e, st) {
      throw UnknownFailure(message: 'Failed to copy month plan', originalError: e, stackTrace: st);
    }
  }

  @override
  Future<void> deleteMonthPlanWithBudgets(String id, String month) async {
    try {
      await _dio.delete('/month-plans/$id', queryParameters: {'includeBudgets': true});
    } on DioException catch (e) {
      throw mapDioError(e);
    } catch (e, st) {
      throw UnknownFailure(message: 'Failed to delete month plan with budgets', originalError: e, stackTrace: st);
    }
  }

  @override
  Future<void> addBudgetToMonthPlan(String planId, String budgetId) async {
    try {
      await _dio.post('/month-plans/$planId/budgets', data: {'budgetId': budgetId});
    } on DioException catch (e) {
      throw mapDioError(e);
    } catch (e, st) {
      throw UnknownFailure(message: 'Failed to add budget to month plan', originalError: e, stackTrace: st);
    }
  }
}
