import 'package:persona_codex/core/state/stream_state.dart';
import '../../domain/entities/transaction.dart';
import '../../domain/repositories/transaction_repository.dart';

/// Controller for managing transaction state
class TransactionController extends StreamState<AsyncState<List<Transaction>>> {
  final TransactionRepository _repository;

  TransactionController(this._repository) : super(const AsyncLoading());

  /// Load recent transactions
  Future<void> loadRecentTransactions({int limit = 10}) async {
    await execute(() => _repository.getRecentTransactions(limit: limit));
  }

  /// Load transactions by account
  Future<void> loadTransactionsByAccount(String accountId) async {
    await execute(() => _repository.getTransactionsByAccount(accountId));
  }

  /// Load transactions by budget
  Future<void> loadTransactionsByBudget(String budgetId) async {
    await execute(() => _repository.getTransactionsByBudget(budgetId));
  }

  /// Load transactions by date range
  Future<void> loadTransactionsByDateRange(
    DateTime startDate,
    DateTime endDate,
  ) async {
    await execute(
      () => _repository.getTransactionsByDateRange(startDate, endDate),
    );
  }

  /// Create a new transaction
  Future<void> createTransaction(Transaction transaction) async {
    try {
      await _repository.createTransaction(transaction);
      await loadRecentTransactions();
    } catch (e) {
      emit(AsyncError('Failed to create transaction: $e', e));
    }
  }

  /// Update an existing transaction
  Future<void> updateTransaction(Transaction transaction) async {
    try {
      await _repository.updateTransaction(transaction);
      await loadRecentTransactions();
    } catch (e) {
      emit(AsyncError('Failed to update transaction: $e', e));
    }
  }

  /// Delete a transaction
  Future<void> deleteTransaction(String id) async {
    try {
      await _repository.deleteTransaction(id);
      await loadRecentTransactions();
    } catch (e) {
      emit(AsyncError('Failed to delete transaction: $e', e));
    }
  }
}
