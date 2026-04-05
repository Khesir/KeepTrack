import 'package:dio/dio.dart';
import 'package:keep_track/core/error/failure.dart';
import 'package:keep_track/core/network/api_client.dart';
import 'package:keep_track/core/network/api_exception.dart';
import '../debt_datasource.dart';
import '../../models/debt_model.dart';

class DebtDataSourceRest implements DebtDataSource {
  final Dio _dio;

  DebtDataSourceRest([Dio? dio]) : _dio = dio ?? ApiClient.instance;

  List<DebtModel> _parseList(dynamic data) =>
      (data as List).map((j) => DebtModel.fromJson(j as Map<String, dynamic>)).toList();

  @override
  Future<List<DebtModel>> fetchDebts() async {
    try {
      final res = await _dio.get('/debts');
      return _parseList(res.data);
    } on DioException catch (e) {
      throw mapDioError(e);
    } catch (e, st) {
      throw UnknownFailure(message: 'Failed to fetch debts', originalError: e, stackTrace: st);
    }
  }

  @override
  Future<DebtModel?> fetchDebtById(String id) async {
    try {
      final res = await _dio.get('/debts/$id');
      return DebtModel.fromJson(res.data as Map<String, dynamic>);
    } on DioException catch (e) {
      final f = mapDioError(e);
      if (f is NotFoundFailure) return null;
      throw f;
    } catch (e, st) {
      throw UnknownFailure(message: 'Failed to fetch debt', originalError: e, stackTrace: st);
    }
  }

  @override
  Future<DebtModel> createDebt(DebtModel debt) async {
    try {
      final res = await _dio.post('/debts', data: debt.toApiJson());
      return DebtModel.fromJson(res.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw mapDioError(e);
    } catch (e, st) {
      throw UnknownFailure(message: 'Failed to create debt', originalError: e, stackTrace: st);
    }
  }

  @override
  Future<DebtModel> updateDebt(DebtModel debt) async {
    try {
      final res = await _dio.patch('/debts/${debt.id}', data: debt.toApiJson());
      return DebtModel.fromJson(res.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw mapDioError(e);
    } catch (e, st) {
      throw UnknownFailure(message: 'Failed to update debt', originalError: e, stackTrace: st);
    }
  }

  @override
  Future<void> deleteDebt(String id) async {
    try {
      await _dio.delete('/debts/$id');
    } on DioException catch (e) {
      throw mapDioError(e);
    } catch (e, st) {
      throw UnknownFailure(message: 'Failed to delete debt', originalError: e, stackTrace: st);
    }
  }

  @override
  Future<List<DebtModel>> fetchDebtsByType(String type) async {
    try {
      final res = await _dio.get('/debts', queryParameters: {'type': type});
      return _parseList(res.data);
    } on DioException catch (e) {
      throw mapDioError(e);
    } catch (e, st) {
      throw UnknownFailure(message: 'Failed to fetch debts by type', originalError: e, stackTrace: st);
    }
  }

  @override
  Future<List<DebtModel>> fetchDebtsByStatus(String status) async {
    try {
      final res = await _dio.get('/debts', queryParameters: {'status': status});
      return _parseList(res.data);
    } on DioException catch (e) {
      throw mapDioError(e);
    } catch (e, st) {
      throw UnknownFailure(message: 'Failed to fetch debts by status', originalError: e, stackTrace: st);
    }
  }
}
