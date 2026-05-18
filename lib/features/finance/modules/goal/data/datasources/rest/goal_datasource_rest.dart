import 'package:dio/dio.dart';
import 'package:keep_track/core/error/failure.dart';
import 'package:keep_track/core/network/api_client.dart';
import 'package:keep_track/core/network/api_exception.dart';
import '../goal_datasource.dart';
import '../../models/goal_model.dart';

class GoalDataSourceRest implements GoalDataSource {
  final Dio _dio;

  GoalDataSourceRest([Dio? dio]) : _dio = dio ?? ApiClient.instance;

  List<GoalModel> _parseList(dynamic data) =>
      (data as List).map((j) => GoalModel.fromJson(j as Map<String, dynamic>)).toList();

  @override
  Future<List<GoalModel>> fetchGoals({String? budgetProfileId}) async {
    try {
      final res = await _dio.get('/goals',
        queryParameters: budgetProfileId != null ? {'budgetProfileId': budgetProfileId} : null);
      return _parseList(res.data);
    } on DioException catch (e) {
      throw mapDioError(e);
    } catch (e, st) {
      throw UnknownFailure(message: 'Failed to fetch goals', originalError: e, stackTrace: st);
    }
  }

  @override
  Future<GoalModel?> fetchGoalById(String id) async {
    try {
      final res = await _dio.get('/goals/$id');
      return GoalModel.fromJson(res.data as Map<String, dynamic>);
    } on DioException catch (e) {
      final f = mapDioError(e);
      if (f is NotFoundFailure) return null;
      throw f;
    } catch (e, st) {
      throw UnknownFailure(message: 'Failed to fetch goal', originalError: e, stackTrace: st);
    }
  }

  @override
  Future<GoalModel> createGoal(GoalModel goal) async {
    try {
      final res = await _dio.post('/goals', data: goal.toApiJson());
      return GoalModel.fromJson(res.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw mapDioError(e);
    } catch (e, st) {
      throw UnknownFailure(message: 'Failed to create goal', originalError: e, stackTrace: st);
    }
  }

  @override
  Future<GoalModel> updateGoal(GoalModel goal) async {
    try {
      final res = await _dio.patch('/goals/${goal.id}', data: goal.toApiJson());
      return GoalModel.fromJson(res.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw mapDioError(e);
    } catch (e, st) {
      throw UnknownFailure(message: 'Failed to update goal', originalError: e, stackTrace: st);
    }
  }

  @override
  Future<void> deleteGoal(String id) async {
    try {
      await _dio.delete('/goals/$id');
    } on DioException catch (e) {
      throw mapDioError(e);
    } catch (e, st) {
      throw UnknownFailure(message: 'Failed to delete goal', originalError: e, stackTrace: st);
    }
  }

  @override
  Future<List<GoalModel>> fetchGoalsByStatus(String status) async {
    try {
      final res = await _dio.get('/goals', queryParameters: {'status': status});
      return _parseList(res.data);
    } on DioException catch (e) {
      throw mapDioError(e);
    } catch (e, st) {
      throw UnknownFailure(message: 'Failed to fetch goals by status', originalError: e, stackTrace: st);
    }
  }

  Future<GoalModel> contributeToGoal(String id, double amount) async {
    try {
      final res = await _dio.post('/goals/$id/contribute', data: {'amount': amount});
      return GoalModel.fromJson(res.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw mapDioError(e);
    } catch (e, st) {
      throw UnknownFailure(message: 'Failed to contribute to goal', originalError: e, stackTrace: st);
    }
  }

  Future<GoalModel> withdrawFromGoal(String id, double amount) async {
    try {
      final res = await _dio.post('/goals/$id/withdraw', data: {'amount': amount});
      return GoalModel.fromJson(res.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw mapDioError(e);
    } catch (e, st) {
      throw UnknownFailure(message: 'Failed to withdraw from goal', originalError: e, stackTrace: st);
    }
  }
}
