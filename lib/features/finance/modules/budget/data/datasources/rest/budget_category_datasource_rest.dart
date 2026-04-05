import 'package:dio/dio.dart';
import 'package:keep_track/core/error/failure.dart';
import 'package:keep_track/core/network/api_client.dart';
import 'package:keep_track/core/network/api_exception.dart';
import '../budget_category_datasource.dart';
import '../../models/budget_category_model.dart';

class BudgetCategoryDataSourceRest implements BudgetCategoryDataSource {
  final Dio _dio;

  BudgetCategoryDataSourceRest([Dio? dio]) : _dio = dio ?? ApiClient.instance;

  List<BudgetCategoryModel> _parseList(dynamic data) =>
      (data as List).map((j) => BudgetCategoryModel.fromJson(j as Map<String, dynamic>)).toList();

  @override
  Future<List<BudgetCategoryModel>> getCategoriesByBudgetId(String budgetId) async {
    try {
      final res = await _dio.get('/budget-categories', queryParameters: {'budgetId': budgetId});
      return _parseList(res.data);
    } on DioException catch (e) {
      throw mapDioError(e);
    } catch (e, st) {
      throw UnknownFailure(message: 'Failed to fetch budget categories', originalError: e, stackTrace: st);
    }
  }

  @override
  Future<BudgetCategoryModel> createCategory(BudgetCategoryModel category) async {
    try {
      final res = await _dio.post('/budget-categories', data: category.toApiJson());
      return BudgetCategoryModel.fromJson(res.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw mapDioError(e);
    } catch (e, st) {
      throw UnknownFailure(message: 'Failed to create budget category', originalError: e, stackTrace: st);
    }
  }

  @override
  Future<BudgetCategoryModel> updateCategory(BudgetCategoryModel category) async {
    try {
      final res = await _dio.patch('/budget-categories/${category.id}', data: category.toApiJson());
      return BudgetCategoryModel.fromJson(res.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw mapDioError(e);
    } catch (e, st) {
      throw UnknownFailure(message: 'Failed to update budget category', originalError: e, stackTrace: st);
    }
  }

  @override
  Future<void> deleteCategory(String id) async {
    try {
      await _dio.delete('/budget-categories/$id');
    } on DioException catch (e) {
      throw mapDioError(e);
    } catch (e, st) {
      throw UnknownFailure(message: 'Failed to delete budget category', originalError: e, stackTrace: st);
    }
  }

  @override
  Future<void> deleteCategoriesByBudgetId(String budgetId) async {
    try {
      await _dio.delete('/budget-categories', queryParameters: {'budgetId': budgetId});
    } on DioException catch (e) {
      throw mapDioError(e);
    } catch (e, st) {
      throw UnknownFailure(message: 'Failed to delete budget categories', originalError: e, stackTrace: st);
    }
  }
}
