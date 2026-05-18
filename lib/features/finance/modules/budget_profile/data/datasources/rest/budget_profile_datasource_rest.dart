import 'package:dio/dio.dart';
import 'package:keep_track/core/error/failure.dart';
import 'package:keep_track/core/network/api_client.dart';
import 'package:keep_track/core/network/api_exception.dart';
import 'package:keep_track/features/finance/modules/budget/data/models/budget_model.dart';
import '../../models/budget_profile_model.dart';

class BudgetProfileDataSourceRest {
  final Dio _dio;
  BudgetProfileDataSourceRest([Dio? dio]) : _dio = dio ?? ApiClient.instance;

  List<BudgetProfileModel> _parse(dynamic data) =>
      (data as List).map((j) => BudgetProfileModel.fromJson(j as Map<String, dynamic>)).toList();

  Future<List<BudgetProfileModel>> getProfiles() async {
    try {
      final res = await _dio.get('/budget-profiles');
      return _parse(res.data);
    } on DioException catch (e) { throw mapDioError(e); }
    catch (e, st) { throw UnknownFailure(message: 'Failed to fetch profiles', originalError: e, stackTrace: st); }
  }

  Future<BudgetProfileModel> createProfile(BudgetProfileModel profile) async {
    try {
      final res = await _dio.post('/budget-profiles', data: profile.toApiJson());
      return BudgetProfileModel.fromJson(res.data as Map<String, dynamic>);
    } on DioException catch (e) { throw mapDioError(e); }
    catch (e, st) { throw UnknownFailure(message: 'Failed to create profile', originalError: e, stackTrace: st); }
  }

  Future<BudgetProfileModel> updateProfile(BudgetProfileModel profile) async {
    try {
      final res = await _dio.patch('/budget-profiles/${profile.id}', data: profile.toApiJson());
      return BudgetProfileModel.fromJson(res.data as Map<String, dynamic>);
    } on DioException catch (e) { throw mapDioError(e); }
    catch (e, st) { throw UnknownFailure(message: 'Failed to update profile', originalError: e, stackTrace: st); }
  }

  Future<void> deleteProfile(String id) async {
    try { await _dio.delete('/budget-profiles/$id'); }
    on DioException catch (e) { throw mapDioError(e); }
    catch (e, st) { throw UnknownFailure(message: 'Failed to delete profile', originalError: e, stackTrace: st); }
  }

  Future<BudgetProfileModel> setAsMain(String id) async {
    try {
      final res = await _dio.patch('/budget-profiles/$id/set-main');
      return BudgetProfileModel.fromJson(res.data as Map<String, dynamic>);
    } on DioException catch (e) { throw mapDioError(e); }
    catch (e, st) { throw UnknownFailure(message: 'Failed to set main profile', originalError: e, stackTrace: st); }
  }

  Future<List<BudgetModel>> getBudgetGroups(String profileId) async {
    try {
      final res = await _dio.get('/budget-profiles/$profileId/groups');
      return (res.data as List).map((j) => BudgetModel.fromJson(j as Map<String, dynamic>)).toList();
    } on DioException catch (e) { throw mapDioError(e); }
    catch (e, st) { throw UnknownFailure(message: 'Failed to fetch budget groups', originalError: e, stackTrace: st); }
  }
}
