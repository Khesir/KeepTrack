import 'package:dio/dio.dart';
import 'package:keep_track/core/error/failure.dart';
import 'package:keep_track/core/network/api_client.dart';
import 'package:keep_track/core/network/api_exception.dart';
import '../savings_datasource.dart';
import '../../models/savings_bucket_model.dart';

class SavingsDataSourceRest implements SavingsDataSource {
  final Dio _dio;

  SavingsDataSourceRest([Dio? dio]) : _dio = dio ?? ApiClient.instance;

  List<SavingsBucketModel> _parseList(dynamic data) =>
      (data as List).map((j) => SavingsBucketModel.fromJson(j as Map<String, dynamic>)).toList();

  @override
  Future<List<SavingsBucketModel>> getSavingsBuckets() async {
    try {
      final res = await _dio.get('/savings');
      return _parseList(res.data);
    } on DioException catch (e) {
      throw mapDioError(e);
    } catch (e, st) {
      throw UnknownFailure(message: 'Failed to fetch savings', originalError: e, stackTrace: st);
    }
  }

  @override
  Future<SavingsBucketModel> createSavingsBucket(SavingsBucketModel bucket) async {
    try {
      final res = await _dio.post('/savings', data: bucket.toApiJson());
      return SavingsBucketModel.fromJson(res.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw mapDioError(e);
    } catch (e, st) {
      throw UnknownFailure(message: 'Failed to create savings bucket', originalError: e, stackTrace: st);
    }
  }

  @override
  Future<SavingsBucketModel> updateSavingsBucket(SavingsBucketModel bucket) async {
    try {
      final res = await _dio.patch('/savings/${bucket.id}', data: bucket.toApiJson());
      return SavingsBucketModel.fromJson(res.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw mapDioError(e);
    } catch (e, st) {
      throw UnknownFailure(message: 'Failed to update savings bucket', originalError: e, stackTrace: st);
    }
  }

  @override
  Future<void> deleteSavingsBucket(String id) async {
    try {
      await _dio.delete('/savings/$id');
    } on DioException catch (e) {
      throw mapDioError(e);
    } catch (e, st) {
      throw UnknownFailure(message: 'Failed to delete savings bucket', originalError: e, stackTrace: st);
    }
  }
}
