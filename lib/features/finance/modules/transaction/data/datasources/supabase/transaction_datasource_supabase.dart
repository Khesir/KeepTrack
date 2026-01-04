import 'package:keep_track/core/error/failure.dart';
import 'package:keep_track/shared/infrastructure/supabase/supabase_service.dart';

import '../../../domain/entities/transaction.dart';
import '../../models/transaction_model.dart';
import '../transaction_datasource.dart';

/// Supabase implementation of TransactionDataSource
class TransactionDataSourceSupabase implements TransactionDataSource {
  final SupabaseService supabaseService;

  TransactionDataSourceSupabase(this.supabaseService);

  static const String _tableName = 'transactions';

  @override
  Future<List<Transaction>> getTransactions() async {
    try {
      final response = await supabaseService.client
          .from(_tableName)
          .select()
          .order('date', ascending: false);

      return (response as List)
          .map((json) => TransactionModel.fromJson(json).toEntity())
          .toList();
    } catch (e, stackTrace) {
      throw UnknownFailure(
        message: 'Failed to fetch transactions',
        originalError: e,
        stackTrace: stackTrace,
      );
    }
  }

  @override
  Future<List<Transaction>> getTransactionsByAccount(String accountId) async {
    try {
      final response = await supabaseService.client
          .from(_tableName)
          .select()
          .eq('account_id', accountId)
          .order('date', ascending: false);

      return (response as List)
          .map((json) => TransactionModel.fromJson(json).toEntity())
          .toList();
    } catch (e, stackTrace) {
      throw UnknownFailure(
        message: 'Failed to fetch transactions for account $accountId',
        originalError: e,
        stackTrace: stackTrace,
      );
    }
  }

  @override
  Future<List<Transaction>> getTransactionsByBudget(String budgetId) async {
    try {
      final response = await supabaseService.client
          .from(_tableName)
          .select()
          .eq('budget_id', budgetId)
          .order('date', ascending: false);

      return (response as List)
          .map((json) => TransactionModel.fromJson(json).toEntity())
          .toList();
    } catch (e, stackTrace) {
      throw UnknownFailure(
        message: 'Failed to fetch transactions for budget $budgetId',
        originalError: e,
        stackTrace: stackTrace,
      );
    }
  }

  @override
  Future<List<Transaction>> getTransactionsByCategory(String categoryId) async {
    try {
      final response = await supabaseService.client
          .from(_tableName)
          .select()
          .eq('category_id', categoryId)
          .order('date', ascending: false);

      return (response as List)
          .map((json) => TransactionModel.fromJson(json).toEntity())
          .toList();
    } catch (e, stackTrace) {
      throw UnknownFailure(
        message: 'Failed to fetch transactions for category $categoryId',
        originalError: e,
        stackTrace: stackTrace,
      );
    }
  }

  @override
  Future<List<Transaction>> getTransactionsByDateRange(
    DateTime startDate,
    DateTime endDate,
  ) async {
    try {
      final response = await supabaseService.client
          .from(_tableName)
          .select()
          .gte('date', startDate.toIso8601String())
          .lte('date', endDate.toIso8601String())
          .order('date', ascending: false);

      return (response as List)
          .map((json) => TransactionModel.fromJson(json).toEntity())
          .toList();
    } catch (e, stackTrace) {
      throw UnknownFailure(
        message: 'Failed to fetch transactions by date range',
        originalError: e,
        stackTrace: stackTrace,
      );
    }
  }

  @override
  Future<List<Transaction>> getRecentTransactions({int limit = 10}) async {
    try {
      final response = await supabaseService.client
          .from(_tableName)
          .select()
          .order('date', ascending: false)
          .limit(limit);

      return (response as List)
          .map((json) => TransactionModel.fromJson(json).toEntity())
          .toList();
    } catch (e, stackTrace) {
      throw UnknownFailure(
        message: 'Failed to fetch recent transactions',
        originalError: e,
        stackTrace: stackTrace,
      );
    }
  }

  @override
  Future<Transaction?> getTransactionById(String id) async {
    try {
      final response = await supabaseService.client
          .from(_tableName)
          .select()
          .eq('id', id)
          .maybeSingle();

      if (response == null) return null;

      return TransactionModel.fromJson(response).toEntity();
    } catch (e, stackTrace) {
      throw UnknownFailure(
        message: 'Failed to fetch transaction by ID $id',
        originalError: e,
        stackTrace: stackTrace,
      );
    }
  }

  @override
  Future<Transaction> createTransaction(Transaction transaction) async {
    try {
      final model = TransactionModel.fromEntity(transaction);
      final json = model.toJson();
      json.remove('id');

      final response = await supabaseService.client
          .from(_tableName)
          .insert(json)
          .select()
          .single();

      return TransactionModel.fromJson(response).toEntity();
    } catch (e, stackTrace) {
      throw UnknownFailure(
        message: 'Failed to create transaction',
        originalError: e,
        stackTrace: stackTrace,
      );
    }
  }

  @override
  Future<Transaction> updateTransaction(Transaction transaction) async {
    try {
      if (transaction.id == null) {
        throw ArgumentError('Transaction ID cannot be null for update');
      }

      final model = TransactionModel.fromEntity(transaction);
      final json = model.toJson();

      final response = await supabaseService.client
          .from(_tableName)
          .update(json)
          .eq('id', transaction.id!)
          .select()
          .single();

      return TransactionModel.fromJson(response).toEntity();
    } catch (e, stackTrace) {
      throw UnknownFailure(
        message: 'Failed to update transaction',
        originalError: e,
        stackTrace: stackTrace,
      );
    }
  }

  @override
  Future<void> deleteTransaction(String id) async {
    try {
      await supabaseService.client.from(_tableName).delete().eq('id', id);
    } catch (e, stackTrace) {
      throw UnknownFailure(
        message: 'Failed to delete transaction',
        originalError: e,
        stackTrace: stackTrace,
      );
    }
  }

  @override
  Future<double> getTotalIncome(DateTime startDate, DateTime endDate) async {
    try {
      final response = await supabaseService.client
          .from(_tableName)
          .select('amount')
          .eq('type', 'income')
          .gte('date', startDate.toIso8601String())
          .lte('date', endDate.toIso8601String());

      if (response.isEmpty) return 0.0;

      return response.fold<double>(
        0.0,
        (sum, item) => sum + ((item['amount'] as num?)?.toDouble() ?? 0.0),
      );
    } catch (e, stackTrace) {
      throw UnknownFailure(
        message: 'Failed to calculate total income',
        originalError: e,
        stackTrace: stackTrace,
      );
    }
  }

  @override
  Future<double> getTotalExpenses(DateTime startDate, DateTime endDate) async {
    try {
      final response = await supabaseService.client
          .from(_tableName)
          .select('amount')
          .eq('type', 'expense')
          .gte('date', startDate.toIso8601String())
          .lte('date', endDate.toIso8601String());

      if (response.isEmpty) return 0.0;

      return response.fold<double>(
        0.0,
        (sum, item) => sum + ((item['amount'] as num?)?.toDouble() ?? 0.0),
      );
    } catch (e, stackTrace) {
      throw UnknownFailure(
        message: 'Failed to calculate total expenses',
        originalError: e,
        stackTrace: stackTrace,
      );
    }
  }
}
