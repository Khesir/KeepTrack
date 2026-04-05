import 'package:dio/dio.dart';
import 'package:keep_track/core/error/failure.dart';
import 'package:keep_track/core/network/api_client.dart';
import 'package:keep_track/core/network/api_exception.dart';
import '../account_datasource.dart';
import '../../models/account_model.dart';

class AccountDataSourceRest implements AccountDataSource {
  final Dio _dio;

  AccountDataSourceRest([Dio? dio]) : _dio = dio ?? ApiClient.instance;

  @override
  Future<List<AccountModel>> getAccounts() async {
    try {
      final res = await _dio.get('/accounts');
      return (res.data as List)
          .map((j) => AccountModel.fromJson(j as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw mapDioError(e);
    } catch (e, st) {
      throw UnknownFailure(message: 'Failed to fetch accounts', originalError: e, stackTrace: st);
    }
  }

  @override
  Future<AccountModel?> getAccountById(String id) async {
    try {
      final res = await _dio.get('/accounts/$id');
      return AccountModel.fromJson(res.data as Map<String, dynamic>);
    } on DioException catch (e) {
      final f = mapDioError(e);
      if (f is NotFoundFailure) return null;
      throw f;
    } catch (e, st) {
      throw UnknownFailure(message: 'Failed to fetch account', originalError: e, stackTrace: st);
    }
  }

  @override
  Future<AccountModel> createAccount(AccountModel account) async {
    try {
      final res = await _dio.post('/accounts', data: account.toApiJson());
      return AccountModel.fromJson(res.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw mapDioError(e);
    } catch (e, st) {
      throw UnknownFailure(message: 'Failed to create account', originalError: e, stackTrace: st);
    }
  }

  @override
  Future<AccountModel> updateAccount(AccountModel account) async {
    try {
      final res = await _dio.patch('/accounts/${account.id}', data: account.toApiJson());
      return AccountModel.fromJson(res.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw mapDioError(e);
    } catch (e, st) {
      throw UnknownFailure(message: 'Failed to update account', originalError: e, stackTrace: st);
    }
  }

  @override
  Future<void> deleteAccount(String id) async {
    try {
      await _dio.delete('/accounts/$id');
    } on DioException catch (e) {
      throw mapDioError(e);
    } catch (e, st) {
      throw UnknownFailure(message: 'Failed to delete account', originalError: e, stackTrace: st);
    }
  }
}
