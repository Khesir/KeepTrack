import 'package:keep_track/core/error/result.dart';
import 'package:keep_track/core/state/stream_state.dart';
import '../../modules/transaction/domain/entities/transaction.dart';
import '../../modules/transaction/domain/repositories/transaction_repository.dart';
import 'transaction_cache.dart';

/// Controller for managing transaction state
class TransactionController extends StreamState<AsyncState<List<Transaction>>> {
  final TransactionRepository _repository;
  final TransactionCache _cache;

  /// Called after any create/update/delete mutation so other controllers
  /// (e.g. BudgetController) can react without tight coupling.
  final void Function()? onMutated;

  TransactionController(this._repository, this._cache, {this.onMutated})
      : super(const AsyncLoading());

  /// Load all transactions
  Future<void> loadAllTransactions() async {
    await execute(() async {
      return await _repository.getTransactions().then((r) => r.unwrap());
    });
  }

  /// Load recent transactions
  Future<void> loadRecentTransactions({int limit = 10}) async {
    await execute(() async {
      return await _repository
          .getRecentTransactions(limit: limit)
          .then((r) => r.unwrap());
    });
  }

  /// Load transactions by budget
  Future<void> loadTransactionsByBudget(String budgetId) async {
    await execute(() async {
      return await _repository
          .getTransactionsByBudget(budgetId)
          .then((r) => r.unwrap());
    });
  }

  Future<void> loadTransactionsBySavings(String savingsId) async {
    await execute(() async {
      return await _repository
          .getTransactionsBySavings(savingsId)
          .then((r) => r.unwrap());
    });
  }

  /// Load transactions by date range
  Future<void> loadTransactionsByDateRange(
    DateTime startDate,
    DateTime endDate,
  ) async {
    await execute(() async {
      return await _repository
          .getTransactionsByDateRange(startDate, endDate)
          .then((r) => r.unwrap());
    });
  }

  /// Create a new transaction
  Future<void> createTransaction(Transaction transaction) async {
    await executeSilent(() async {
      final created = await _repository
          .createTransaction(transaction)
          .then((r) => r.unwrap());
      final current = data ?? [];
      return [...current, created];
    });
    _cache.invalidateAll();
    onMutated?.call();
  }

  /// Update an existing transaction
  Future<void> updateTransaction(Transaction transaction) async {
    await executeSilent(() async {
      await _repository.updateTransaction(transaction).then((r) => r.unwrap());
      await loadRecentTransactions();
      return data ?? [];
    });
    _cache.invalidateAll();
    onMutated?.call();
  }

  /// Delete a transaction
  Future<void> deleteTransaction(String id) async {
    await executeSilent(() async {
      await _repository.deleteTransaction(id).then((r) => r.unwrap());
      await loadRecentTransactions();
      return data ?? [];
    });
    _cache.invalidateAll();
    onMutated?.call();
  }
}
