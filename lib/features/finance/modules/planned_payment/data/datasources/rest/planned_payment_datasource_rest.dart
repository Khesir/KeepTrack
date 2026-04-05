import 'package:dio/dio.dart';
import 'package:keep_track/core/error/failure.dart';
import 'package:keep_track/core/network/api_client.dart';
import 'package:keep_track/core/network/api_exception.dart';
import '../planned_payment_datasource.dart';
import '../../models/planned_payment_model.dart';

class PlannedPaymentDataSourceRest implements PlannedPaymentDataSource {
  final Dio _dio;

  PlannedPaymentDataSourceRest([Dio? dio]) : _dio = dio ?? ApiClient.instance;

  List<PlannedPaymentModel> _parseList(dynamic data) =>
      (data as List).map((j) => PlannedPaymentModel.fromJson(j as Map<String, dynamic>)).toList();

  @override
  Future<List<PlannedPaymentModel>> fetchPlannedPayments() async {
    try {
      final res = await _dio.get('/planned-payments');
      return _parseList(res.data);
    } on DioException catch (e) {
      throw mapDioError(e);
    } catch (e, st) {
      throw UnknownFailure(message: 'Failed to fetch planned payments', originalError: e, stackTrace: st);
    }
  }

  @override
  Future<PlannedPaymentModel?> fetchPlannedPaymentById(String id) async {
    try {
      final res = await _dio.get('/planned-payments/$id');
      return PlannedPaymentModel.fromJson(res.data as Map<String, dynamic>);
    } on DioException catch (e) {
      final f = mapDioError(e);
      if (f is NotFoundFailure) return null;
      throw f;
    } catch (e, st) {
      throw UnknownFailure(message: 'Failed to fetch planned payment', originalError: e, stackTrace: st);
    }
  }

  @override
  Future<PlannedPaymentModel> createPlannedPayment(PlannedPaymentModel payment) async {
    try {
      final res = await _dio.post('/planned-payments', data: payment.toApiJson());
      return PlannedPaymentModel.fromJson(res.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw mapDioError(e);
    } catch (e, st) {
      throw UnknownFailure(message: 'Failed to create planned payment', originalError: e, stackTrace: st);
    }
  }

  @override
  Future<PlannedPaymentModel> updatePlannedPayment(PlannedPaymentModel payment) async {
    try {
      final res = await _dio.patch('/planned-payments/${payment.id}', data: payment.toApiJson());
      return PlannedPaymentModel.fromJson(res.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw mapDioError(e);
    } catch (e, st) {
      throw UnknownFailure(message: 'Failed to update planned payment', originalError: e, stackTrace: st);
    }
  }

  @override
  Future<void> deletePlannedPayment(String id) async {
    try {
      await _dio.delete('/planned-payments/$id');
    } on DioException catch (e) {
      throw mapDioError(e);
    } catch (e, st) {
      throw UnknownFailure(message: 'Failed to delete planned payment', originalError: e, stackTrace: st);
    }
  }

  @override
  Future<List<PlannedPaymentModel>> fetchPlannedPaymentsByStatus(String status) async {
    try {
      final res = await _dio.get('/planned-payments', queryParameters: {'status': status});
      return _parseList(res.data);
    } on DioException catch (e) {
      throw mapDioError(e);
    } catch (e, st) {
      throw UnknownFailure(message: 'Failed to fetch planned payments by status', originalError: e, stackTrace: st);
    }
  }

  @override
  Future<List<PlannedPaymentModel>> fetchPlannedPaymentsByCategory(String category) async {
    try {
      final res = await _dio.get('/planned-payments', queryParameters: {'category': category});
      return _parseList(res.data);
    } on DioException catch (e) {
      throw mapDioError(e);
    } catch (e, st) {
      throw UnknownFailure(message: 'Failed to fetch planned payments by category', originalError: e, stackTrace: st);
    }
  }

  @override
  Future<List<PlannedPaymentModel>> fetchUpcomingPayments() async {
    try {
      final res = await _dio.get('/planned-payments/upcoming');
      return _parseList(res.data);
    } on DioException catch (e) {
      throw mapDioError(e);
    } catch (e, st) {
      throw UnknownFailure(message: 'Failed to fetch upcoming payments', originalError: e, stackTrace: st);
    }
  }
}
