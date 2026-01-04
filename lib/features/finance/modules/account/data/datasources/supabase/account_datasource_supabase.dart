import 'package:keep_track/core/error/failure.dart';
import 'package:keep_track/shared/infrastructure/supabase/supabase_service.dart';
import '../../models/account_model.dart';
import '../account_datasource.dart';

/// Supabase implementation of AccountDataSource
class AccountDataSourceSupabase implements AccountDataSource {
  final SupabaseService supabaseService;
  static const String tableName = 'accounts';

  AccountDataSourceSupabase(this.supabaseService);

  @override
  Future<List<AccountModel>> getAccounts() async {
    try {
      final response = await supabaseService.client
          .from(tableName)
          .select()
          .eq('user_id', supabaseService.userId!)
          .order('created_at', ascending: false);

      return (response as List)
          .map((doc) => AccountModel.fromJson(doc))
          .toList();
    } catch (e, stackTrace) {
      throw UnknownFailure(
        message: 'Failed to fetch accounts',
        originalError: e,
        stackTrace: stackTrace,
      );
    }
  }

  @override
  Future<AccountModel?> getAccountById(String id) async {
    try {
      final response = await supabaseService.client
          .from(tableName)
          .select()
          .eq('id', id)
          .eq('user_id', supabaseService.userId!)
          .maybeSingle();

      return response != null ? AccountModel.fromJson(response) : null;
    } catch (e, stackTrace) {
      throw UnknownFailure(
        message: 'Failed to fetch account',
        originalError: e,
        stackTrace: stackTrace,
      );
    }
  }

  @override
  Future<AccountModel> createAccount(AccountModel account) async {
    try {
      final doc = account.toJson();
      final response = await supabaseService.client
          .from(tableName)
          .insert(doc)
          .select()
          .single();

      return AccountModel.fromJson(response);
    } catch (e, stackTrace) {
      throw UnknownFailure(
        message: 'Failed to create account',
        originalError: e,
        stackTrace: stackTrace,
      );
    }
  }

  @override
  Future<AccountModel> updateAccount(AccountModel account) async {
    if (account.id == null) {
      throw Exception('Cannot update account without an ID');
    }

    try {
      final doc = account.toJson();
      final response = await supabaseService.client
          .from(tableName)
          .update(doc)
          .eq('id', account.id!)
          .eq('user_id', supabaseService.userId!)
          .select()
          .single();

      return AccountModel.fromJson(response);
    } catch (e, stackTrace) {
      throw UnknownFailure(
        message: 'Failed to update account',
        originalError: e,
        stackTrace: stackTrace,
      );
    }
  }

  @override
  Future<void> deleteAccount(String id) async {
    try {
      await supabaseService.client
          .from(tableName)
          .delete()
          .eq('id', id)
          .eq('user_id', supabaseService.userId!);
    } catch (e, stackTrace) {
      throw UnknownFailure(
        message: 'Failed to delete account',
        originalError: e,
        stackTrace: stackTrace,
      );
    }
  }
}
