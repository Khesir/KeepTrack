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
  Future<List<GoalModel>> fetchGoals() async {
    try {
      final res = await _dio.get('/goals');
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
}
