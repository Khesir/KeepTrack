import 'package:dio/dio.dart';
import 'package:keep_track/core/error/failure.dart';
import 'package:keep_track/core/network/api_client.dart';
import 'package:keep_track/core/network/api_exception.dart';
import '../budget_datasource.dart';
import '../../models/budget_model.dart';

class BudgetDataSourceRest implements BudgetDataSource {
  final Dio _dio;

  BudgetDataSourceRest([Dio? dio]) : _dio = dio ?? ApiClient.instance;

  List<BudgetModel> _parseList(dynamic data) =>
      (data as List).map((j) => BudgetModel.fromJson(j as Map<String, dynamic>)).toList();

  @override
  Future<List<BudgetModel>> getBudgets() async {
    try {
      final res = await _dio.get('/budgets');
      return _parseList(res.data);
    } on DioException catch (e) {
      throw mapDioError(e);
    } catch (e, st) {
      throw UnknownFailure(message: 'Failed to fetch budgets', originalError: e, stackTrace: st);
    }
  }

  @override
  Future<BudgetModel?> getBudgetById(String id) async {
    try {
      final res = await _dio.get('/budgets/$id');
      return BudgetModel.fromJson(res.data as Map<String, dynamic>);
    } on DioException catch (e) {
      final f = mapDioError(e);
      if (f is NotFoundFailure) return null;
      throw f;
    } catch (e, st) {
      throw UnknownFailure(message: 'Failed to fetch budget', originalError: e, stackTrace: st);
    }
  }

  @override
  Future<BudgetModel?> getBudgetByMonth(String month) async {
    try {
      final res = await _dio.get('/budgets', queryParameters: {'month': month, 'limit': 1});
      final list = _parseList(res.data);
      return list.isEmpty ? null : list.first;
    } on DioException catch (e) {
      throw mapDioError(e);
    } catch (e, st) {
      throw UnknownFailure(message: 'Failed to fetch budget by month', originalError: e, stackTrace: st);
    }
  }

  @override
  Future<List<BudgetModel>> getBudgetsByMonth(String month) async {
    try {
      final res = await _dio.get('/budgets', queryParameters: {'month': month});
      return _parseList(res.data);
    } on DioException catch (e) {
      throw mapDioError(e);
    } catch (e, st) {
      throw UnknownFailure(message: 'Failed to fetch budgets by month', originalError: e, stackTrace: st);
    }
  }

  @override
  Future<BudgetModel> createBudget(BudgetModel budget) async {
    try {
      final res = await _dio.post('/budgets', data: budget.toApiJson());
      return BudgetModel.fromJson(res.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw mapDioError(e);
    } catch (e, st) {
      throw UnknownFailure(message: 'Failed to create budget', originalError: e, stackTrace: st);
    }
  }

  @override
  Future<BudgetModel> updateBudget(BudgetModel budget) async {
    try {
      final res = await _dio.patch('/budgets/${budget.id}', data: budget.toApiJson());
      return BudgetModel.fromJson(res.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw mapDioError(e);
    } catch (e, st) {
      throw UnknownFailure(message: 'Failed to update budget', originalError: e, stackTrace: st);
    }
  }

  @override
  Future<void> deleteBudget(String id) async {
    try {
      await _dio.delete('/budgets/$id');
    } on DioException catch (e) {
      throw mapDioError(e);
    } catch (e, st) {
      throw UnknownFailure(message: 'Failed to delete budget', originalError: e, stackTrace: st);
    }
  }

  @override
  Future<void> refreshBudgetSpentAmounts(String budgetId) async {
    try {
      await _dio.post('/budgets/$budgetId/refresh-spent');
    } on DioException catch (e) {
      throw mapDioError(e);
    } catch (e, st) {
      throw UnknownFailure(message: 'Failed to refresh budget spent amounts', originalError: e, stackTrace: st);
    }
  }

  @override
  Future<void> manualRecalculateBudgetSpent(String budgetId) async {
    try {
      await _dio.post('/budgets/$budgetId/recalculate');
    } on DioException catch (e) {
      throw mapDioError(e);
    } catch (e, st) {
      throw UnknownFailure(message: 'Failed to recalculate budget spent', originalError: e, stackTrace: st);
    }
  }

  @override
  Future<BudgetModel?> getBudgetWithSpentAmounts(String budgetId) async {
    try {
      final res = await _dio.get('/budgets/$budgetId', queryParameters: {'includeSpent': true});
      return BudgetModel.fromJson(res.data as Map<String, dynamic>);
    } on DioException catch (e) {
      final f = mapDioError(e);
      if (f is NotFoundFailure) return null;
      throw f;
    } catch (e, st) {
      throw UnknownFailure(message: 'Failed to fetch budget with spent amounts', originalError: e, stackTrace: st);
    }
  }

  @override
  Future<List<BudgetModel>> getBudgetsWithSpentAmounts() async {
    try {
      final res = await _dio.get('/budgets', queryParameters: {'includeSpent': true});
      return _parseList(res.data);
    } on DioException catch (e) {
      throw mapDioError(e);
    } catch (e, st) {
      throw UnknownFailure(message: 'Failed to fetch budgets with spent amounts', originalError: e, stackTrace: st);
    }
  }

  @override
  Future<Map<String, dynamic>> debugBudgetCategories(String budgetId) async {
    try {
      final res = await _dio.get('/budgets/$budgetId/debug');
      return res.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw mapDioError(e);
    } catch (e, st) {
      throw UnknownFailure(message: 'Failed to debug budget categories', originalError: e, stackTrace: st);
    }
  }
}
