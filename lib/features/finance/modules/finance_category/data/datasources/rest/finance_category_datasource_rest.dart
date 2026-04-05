import 'package:dio/dio.dart';
import 'package:keep_track/core/error/failure.dart';
import 'package:keep_track/core/network/api_client.dart';
import 'package:keep_track/core/network/api_exception.dart';
import '../finance_category_datasource.dart';
import '../../models/finance_category_model.dart';

class FinanceCategoryDataSourceRest implements FinanceCategoryDataSource {
  final Dio _dio;

  FinanceCategoryDataSourceRest([Dio? dio]) : _dio = dio ?? ApiClient.instance;

  List<FinanceCategoryModel> _parseList(dynamic data) =>
      (data as List).map((j) => FinanceCategoryModel.fromJson(j as Map<String, dynamic>)).toList();

  @override
  Future<List<FinanceCategoryModel>> fetchCategories() async {
    try {
      final res = await _dio.get('/finance-categories');
      return _parseList(res.data);
    } on DioException catch (e) {
      throw mapDioError(e);
    } catch (e, st) {
      throw UnknownFailure(message: 'Failed to fetch categories', originalError: e, stackTrace: st);
    }
  }

  @override
  Future<List<FinanceCategoryModel>> fetchCategoriesByType(String type) async {
    try {
      final res = await _dio.get('/finance-categories', queryParameters: {'type': type});
      return _parseList(res.data);
    } on DioException catch (e) {
      throw mapDioError(e);
    } catch (e, st) {
      throw UnknownFailure(message: 'Failed to fetch categories by type', originalError: e, stackTrace: st);
    }
  }

  @override
  Future<FinanceCategoryModel?> fetchCategoryById(String id) async {
    try {
      final res = await _dio.get('/finance-categories/$id');
      return FinanceCategoryModel.fromJson(res.data as Map<String, dynamic>);
    } on DioException catch (e) {
      final f = mapDioError(e);
      if (f is NotFoundFailure) return null;
      throw f;
    } catch (e, st) {
      throw UnknownFailure(message: 'Failed to fetch category', originalError: e, stackTrace: st);
    }
  }

  @override
  Future<List<FinanceCategoryModel>> getByIds(List<String> ids) async {
    try {
      final res = await _dio.get('/finance-categories', queryParameters: {'ids': ids.join(',')});
      return _parseList(res.data);
    } on DioException catch (e) {
      throw mapDioError(e);
    } catch (e, st) {
      throw UnknownFailure(message: 'Failed to fetch categories by ids', originalError: e, stackTrace: st);
    }
  }

  @override
  Future<FinanceCategoryModel> createCategory(FinanceCategoryModel category) async {
    try {
      final res = await _dio.post('/finance-categories', data: category.toApiJson());
      return FinanceCategoryModel.fromJson(res.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw mapDioError(e);
    } catch (e, st) {
      throw UnknownFailure(message: 'Failed to create category', originalError: e, stackTrace: st);
    }
  }

  @override
  Future<FinanceCategoryModel> updateCategory(FinanceCategoryModel category) async {
    try {
      final res = await _dio.patch('/finance-categories/${category.id}', data: category.toApiJson());
      return FinanceCategoryModel.fromJson(res.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw mapDioError(e);
    } catch (e, st) {
      throw UnknownFailure(message: 'Failed to update category', originalError: e, stackTrace: st);
    }
  }

  @override
  Future<void> deleteCategory(String id) async {
    try {
      await _dio.delete('/finance-categories/$id');
    } on DioException catch (e) {
      throw mapDioError(e);
    } catch (e, st) {
      throw UnknownFailure(message: 'Failed to delete category', originalError: e, stackTrace: st);
    }
  }
}
