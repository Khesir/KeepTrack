import 'package:dio/dio.dart';
import 'package:keep_track/core/error/failure.dart';
import 'package:keep_track/core/network/api_client.dart';
import 'package:keep_track/core/network/api_exception.dart';
import '../../../domain/entities/transaction.dart';
import '../transaction_datasource.dart';
import '../../models/transaction_model.dart';

class TransactionDataSourceRest implements TransactionDataSource {
  final Dio _dio;

  TransactionDataSourceRest([Dio? dio]) : _dio = dio ?? ApiClient.instance;

  List<TransactionModel> _parseList(dynamic data) =>
      (data as List).map((j) => TransactionModel.fromJson(j as Map<String, dynamic>)).toList();

  @override
  Future<List<Transaction>> getTransactions() async {
    try {
      final res = await _dio.get('/transactions');
      return _parseList(res.data);
    } on DioException catch (e) {
      throw mapDioError(e);
    } catch (e, st) {
      throw UnknownFailure(message: 'Failed to fetch transactions', originalError: e, stackTrace: st);
    }
  }

  @override
  Future<List<Transaction>> getTransactionsByBudget(String budgetId) async {
    try {
      final res = await _dio.get('/transactions', queryParameters: {'budgetId': budgetId});
      return _parseList(res.data);
    } on DioException catch (e) {
      throw mapDioError(e);
    } catch (e, st) {
      throw UnknownFailure(message: 'Failed to fetch transactions by budget', originalError: e, stackTrace: st);
    }
  }

  @override
  Future<List<Transaction>> getTransactionsByCategory(String categoryId) async {
    try {
      final res = await _dio.get('/transactions', queryParameters: {'financeCategoryId': categoryId});
      return _parseList(res.data);
    } on DioException catch (e) {
      throw mapDioError(e);
    } catch (e, st) {
      throw UnknownFailure(message: 'Failed to fetch transactions by category', originalError: e, stackTrace: st);
    }
  }

  @override
  Future<List<Transaction>> getTransactionsByDateRange(DateTime startDate, DateTime endDate) async {
    try {
      final res = await _dio.get('/transactions', queryParameters: {
        'startDate': startDate.toIso8601String(),
        'endDate': endDate.toIso8601String(),
      });
      return _parseList(res.data);
    } on DioException catch (e) {
      throw mapDioError(e);
    } catch (e, st) {
      throw UnknownFailure(message: 'Failed to fetch transactions by date range', originalError: e, stackTrace: st);
    }
  }

  @override
  Future<List<Transaction>> getRecentTransactions({int limit = 10}) async {
    try {
      final res = await _dio.get('/transactions', queryParameters: {'limit': limit});
      return _parseList(res.data);
    } on DioException catch (e) {
      throw mapDioError(e);
    } catch (e, st) {
      throw UnknownFailure(message: 'Failed to fetch recent transactions', originalError: e, stackTrace: st);
    }
  }

  @override
  Future<Transaction?> getTransactionById(String id) async {
    try {
      final res = await _dio.get('/transactions/$id');
      return TransactionModel.fromJson(res.data as Map<String, dynamic>);
    } on DioException catch (e) {
      final f = mapDioError(e);
      if (f is NotFoundFailure) return null;
      throw f;
    } catch (e, st) {
      throw UnknownFailure(message: 'Failed to fetch transaction', originalError: e, stackTrace: st);
    }
  }

  @override
  Future<Transaction> createTransaction(Transaction transaction) async {
    try {
      final model = TransactionModel.fromEntity(transaction);
      final res = await _dio.post('/transactions', data: model.toApiJson());
      return TransactionModel.fromJson(res.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw mapDioError(e);
    } catch (e, st) {
      throw UnknownFailure(message: 'Failed to create transaction', originalError: e, stackTrace: st);
    }
  }

  @override
  Future<Transaction> updateTransaction(Transaction transaction) async {
    try {
      final model = TransactionModel.fromEntity(transaction);
      final res = await _dio.patch('/transactions/${transaction.id}', data: model.toApiJson());
      return TransactionModel.fromJson(res.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw mapDioError(e);
    } catch (e, st) {
      throw UnknownFailure(message: 'Failed to update transaction', originalError: e, stackTrace: st);
    }
  }

  @override
  Future<void> deleteTransaction(String id) async {
    try {
      await _dio.delete('/transactions/$id');
    } on DioException catch (e) {
      throw mapDioError(e);
    } catch (e, st) {
      throw UnknownFailure(message: 'Failed to delete transaction', originalError: e, stackTrace: st);
    }
  }

  @override
  Future<double> getTotalIncome(DateTime startDate, DateTime endDate) async {
    try {
      final res = await _dio.get('/transactions/summary', queryParameters: {
        'type': 'income',
        'startDate': startDate.toIso8601String(),
        'endDate': endDate.toIso8601String(),
      });
      return (res.data['total'] as num?)?.toDouble() ?? 0.0;
    } on DioException catch (e) {
      throw mapDioError(e);
    } catch (e, st) {
      throw UnknownFailure(message: 'Failed to get total income', originalError: e, stackTrace: st);
    }
  }

  @override
  Future<double> getTotalExpenses(DateTime startDate, DateTime endDate) async {
    try {
      final res = await _dio.get('/transactions/summary', queryParameters: {
        'type': 'expense',
        'startDate': startDate.toIso8601String(),
        'endDate': endDate.toIso8601String(),
      });
      return (res.data['total'] as num?)?.toDouble() ?? 0.0;
    } on DioException catch (e) {
      throw mapDioError(e);
    } catch (e, st) {
      throw UnknownFailure(message: 'Failed to get total expenses', originalError: e, stackTrace: st);
    }
  }
}
