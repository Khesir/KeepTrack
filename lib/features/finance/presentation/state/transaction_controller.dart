import 'package:persona_codex/core/error/result.dart';
import 'package:persona_codex/core/state/stream_state.dart';
import '../../modules/transaction/domain/entities/transaction.dart';
import '../../modules/transaction/domain/repositories/transaction_repository.dart';

/// Controller for managing transaction state
class TransactionController extends StreamState<AsyncState<List<Transaction>>> {
  final TransactionRepository _repository;

  TransactionController(this._repository) : super(const AsyncLoading()) {
    loadRecentTransactions();
  }

  /// Load recent transactions
  Future<void> loadRecentTransactions({int limit = 10}) async {
    await execute(() async {
      final transactions = await _repository
          .getRecentTransactions(limit: limit)
          .then((r) => r.unwrap());
      return transactions;
    });
  }

  /// Load transactions by account
  Future<void> loadTransactionsByAccount(String accountId) async {
    await execute(() async {
      final transactions = await _repository
          .getTransactionsByAccount(accountId)
          .then((r) => r.unwrap());
      return transactions;
    });
  }

  /// Load transactions by budget
  Future<void> loadTransactionsByBudget(String budgetId) async {
    await execute(() async {
      final transactions = await _repository
          .getTransactionsByBudget(budgetId)
          .then((r) => r.unwrap());
      return transactions;
    });
  }

  /// Load transactions by date range
  Future<void> loadTransactionsByDateRange(
    DateTime startDate,
    DateTime endDate,
  ) async {
    await execute(() async {
      final transactions = await _repository
          .getTransactionsByDateRange(startDate, endDate)
          .then((r) => r.unwrap());
      return transactions;
    });
  }

  /// Create a new transaction
  Future<void> createTransaction(Transaction transaction) async {
    await execute(() async {
      final created = await _repository
          .createTransaction(transaction)
          .then((r) => r.unwrap());
      final current = data ?? [];
      return [...current, created];
    });
  }

  /// Update an existing transaction
  Future<void> updateTransaction(Transaction transaction) async {
    await execute(() async {
      await _repository.updateTransaction(transaction).then((r) => r.unwrap());
      await loadRecentTransactions();
      return data ?? [];
    });
  }

  /// Delete a transaction
  Future<void> deleteTransaction(String id) async {
    await execute(() async {
      await _repository.deleteTransaction(id).then((r) => r.unwrap());
      await loadRecentTransactions();
      return data ?? [];
    });
  }
}
