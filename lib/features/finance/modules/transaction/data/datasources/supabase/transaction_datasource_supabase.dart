import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../domain/entities/transaction.dart';
import '../../models/transaction_model.dart';
import '../transaction_datasource.dart';

/// Supabase implementation of TransactionDataSource
class TransactionDataSourceSupabase implements TransactionDataSource {
  final SupabaseClient _client;

  TransactionDataSourceSupabase(this._client);

  static const String _tableName = 'transactions';

  @override
  Future<List<Transaction>> getTransactions() async {
    final response = await _client
        .from(_tableName)
        .select()
        .order('date', ascending: false);

    return (response as List)
        .map((json) => TransactionModel.fromJson(json).toEntity())
        .toList();
  }

  @override
  Future<List<Transaction>> getTransactionsByAccount(String accountId) async {
    final response = await _client
        .from(_tableName)
        .select()
        .eq('account_id', accountId)
        .order('date', ascending: false);

    return (response as List)
        .map((json) => TransactionModel.fromJson(json).toEntity())
        .toList();
  }

  @override
  Future<List<Transaction>> getTransactionsByBudget(String budgetId) async {
    final response = await _client
        .from(_tableName)
        .select()
        .eq('budget_id', budgetId)
        .order('date', ascending: false);

    return (response as List)
        .map((json) => TransactionModel.fromJson(json).toEntity())
        .toList();
  }

  @override
  Future<List<Transaction>> getTransactionsByCategory(String categoryId) async {
    final response = await _client
        .from(_tableName)
        .select()
        .eq('category_id', categoryId)
        .order('date', ascending: false);

    return (response as List)
        .map((json) => TransactionModel.fromJson(json).toEntity())
        .toList();
  }

  @override
  Future<List<Transaction>> getTransactionsByDateRange(
    DateTime startDate,
    DateTime endDate,
  ) async {
    final response = await _client
        .from(_tableName)
        .select()
        .gte('date', startDate.toIso8601String())
        .lte('date', endDate.toIso8601String())
        .order('date', ascending: false);

    return (response as List)
        .map((json) => TransactionModel.fromJson(json).toEntity())
        .toList();
  }

  @override
  Future<List<Transaction>> getRecentTransactions({int limit = 10}) async {
    final response = await _client
        .from(_tableName)
        .select()
        .order('date', ascending: false)
        .limit(limit);

    return (response as List)
        .map((json) => TransactionModel.fromJson(json).toEntity())
        .toList();
  }

  @override
  Future<Transaction?> getTransactionById(String id) async {
    final response = await _client
        .from(_tableName)
        .select()
        .eq('id', id)
        .maybeSingle();

    if (response == null) return null;

    return TransactionModel.fromJson(response).toEntity();
  }

  @override
  Future<Transaction> createTransaction(Transaction transaction) async {
    final model = TransactionModel.fromEntity(transaction);
    final json = model.toJson();
    json.remove('id'); // Let Supabase generate the ID

    final response = await _client
        .from(_tableName)
        .insert(json)
        .select()
        .single();

    return TransactionModel.fromJson(response).toEntity();
  }

  @override
  Future<Transaction> updateTransaction(Transaction transaction) async {
    if (transaction.id == null) {
      throw ArgumentError('Transaction ID cannot be null for update');
    }

    final model = TransactionModel.fromEntity(transaction);
    final json = model.toJson();

    final response = await _client
        .from(_tableName)
        .update(json)
        .eq('id', transaction.id!)
        .select()
        .single();

    return TransactionModel.fromJson(response).toEntity();
  }

  @override
  Future<void> deleteTransaction(String id) async {
    await _client.from(_tableName).delete().eq('id', id);
  }

  @override
  Future<double> getTotalIncome(DateTime startDate, DateTime endDate) async {
    final response = await _client
        .from(_tableName)
        .select('amount')
        .eq('type', 'income')
        .gte('date', startDate.toIso8601String())
        .lte('date', endDate.toIso8601String());

    if (response is! List || response.isEmpty) return 0.0;

    return response.fold<double>(
      0.0,
      (sum, item) => sum + ((item['amount'] as num?)?.toDouble() ?? 0.0),
    );
  }

  @override
  Future<double> getTotalExpenses(DateTime startDate, DateTime endDate) async {
    final response = await _client
        .from(_tableName)
        .select('amount')
        .eq('type', 'expense')
        .gte('date', startDate.toIso8601String())
        .lte('date', endDate.toIso8601String());

    if (response is! List || response.isEmpty) return 0.0;

    return response.fold<double>(
      0.0,
      (sum, item) => sum + ((item['amount'] as num?)?.toDouble() ?? 0.0),
    );
  }
}
