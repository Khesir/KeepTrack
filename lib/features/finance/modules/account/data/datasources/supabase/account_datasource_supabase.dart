import 'package:persona_codex/shared/infrastructure/supabase/supabase_service.dart';
import '../../models/account_model.dart';
import '../account_datasource.dart';

/// Supabase implementation of AccountDataSource
class AccountDataSourceSupabase implements AccountDataSource {
  final SupabaseService supabaseService;
  static const String tableName = 'accounts';

  AccountDataSourceSupabase(this.supabaseService);

  @override
  Future<List<AccountModel>> getAccounts() async {
    final response = await supabaseService.client
        .from(tableName)
        .select()
        .order('created_at', ascending: false);

    return (response as List).map((doc) => AccountModel.fromJson(doc)).toList();
  }

  @override
  Future<AccountModel?> getAccountById(String id) async {
    final response = await supabaseService.client
        .from(tableName)
        .select()
        .eq('id', id)
        .maybeSingle();

    return response != null ? AccountModel.fromJson(response) : null;
  }

  @override
  Future<AccountModel> createAccount(AccountModel account) async {
    final doc = account.toJson();
    final response = await supabaseService.client
        .from(tableName)
        .insert(doc)
        .select()
        .single();

    return AccountModel.fromJson(response);
  }

  @override
  Future<AccountModel> updateAccount(AccountModel account) async {
    if (account.id == null) {
      throw Exception('Cannot update account without an ID');
    }

    final doc = account.toJson();
    final response = await supabaseService.client
        .from(tableName)
        .update(doc)
        .eq('id', account.id!)
        .select()
        .single();

    return AccountModel.fromJson(response);
  }

  @override
  Future<void> deleteAccount(String id) async {
    await supabaseService.client.from(tableName).delete().eq('id', id);
  }
}
