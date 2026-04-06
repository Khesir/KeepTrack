import 'package:keep_track/core/error/result.dart';

import '../../domain/entities/transaction.dart';
import '../../domain/repositories/transaction_repository.dart';
import '../../../account/domain/repositories/account_repository.dart';
import '../datasources/transaction_datasource.dart';

/// Transaction repository implementation
class TransactionRepositoryImpl implements TransactionRepository {
  final TransactionDataSource _dataSource;
  final AccountRepository _accountRepository;

  TransactionRepositoryImpl(this._dataSource, this._accountRepository);

  @override
  Future<Result<List<Transaction>>> getTransactions() async {
    final transactions = await _dataSource.getTransactions();
    return Result.success(transactions);
  }

  @override
  Future<Result<List<Transaction>>> getTransactionsByAccount(
    String accountId,
  ) async {
    final transactions = await _dataSource.getTransactionsByAccount(accountId);
    return Result.success(transactions);
  }

  @override
  Future<Result<List<Transaction>>> getTransactionsByBudget(
    String budgetId,
  ) async {
    final transactions = await _dataSource.getTransactionsByBudget(budgetId);
    return Result.success(transactions);
  }

  @override
  Future<Result<List<Transaction>>> getTransactionsByCategory(
    String categoryId,
  ) async {
    final transactions = await _dataSource.getTransactionsByCategory(
      categoryId,
    );
    return Result.success(transactions);
  }

  @override
  Future<Result<List<Transaction>>> getTransactionsByDateRange(
    DateTime startDate,
    DateTime endDate,
  ) async {
    final transactions = await _dataSource.getTransactionsByDateRange(
      startDate,
      endDate,
    );
    return Result.success(transactions);
  }

  @override
  Future<Result<List<Transaction>>> getRecentTransactions({
    int limit = 10,
  }) async {
    final transactions = await _dataSource.getRecentTransactions(limit: limit);
    return Result.success(transactions);
  }

  @override
  Future<Result<Transaction?>> getTransactionById(String id) async {
    final transaction = await _dataSource.getTransactionById(id);
    return Result.success(transaction);
  }

  @override
  Future<Result<Transaction>> createTransaction(Transaction transaction) async {
    final t = await _dataSource.createTransaction(transaction);

    // Adjust source account
    if (t.accountId != null) {
      await _accountRepository.adjustBalance(
        t.accountId!,
        _calculateBalanceAdjustment(t),
      );
    }

    // For transfers, credit the destination account (receives amount minus fee)
    if (t.type == TransactionType.transfer && t.toAccountId != null) {
      await _accountRepository.adjustBalance(
        t.toAccountId!,
        t.amount - t.fee,
      );
    }

    return Result.success(t);
  }

  @override
  Future<Result<Transaction>> updateTransaction(Transaction transaction) async {
    if (transaction.id == null) {
      throw Exception('Cannot update transaction without an ID');
    }

    final old = await _dataSource.getTransactionById(transaction.id!);
    final updated = await _dataSource.updateTransaction(transaction);

    // Reverse old source
    if (old?.accountId != null) {
      await _accountRepository.adjustBalance(
        old!.accountId!,
        -_calculateBalanceAdjustment(old),
      );
    }
    // Reverse old destination (if was a transfer)
    if (old?.type == TransactionType.transfer && old?.toAccountId != null) {
      await _accountRepository.adjustBalance(
        old!.toAccountId!,
        -(old.amount - old.fee),
      );
    }

    // Apply new source
    if (updated.accountId != null) {
      await _accountRepository.adjustBalance(
        updated.accountId!,
        _calculateBalanceAdjustment(updated),
      );
    }
    // Apply new destination (if is a transfer)
    if (updated.type == TransactionType.transfer && updated.toAccountId != null) {
      await _accountRepository.adjustBalance(
        updated.toAccountId!,
        updated.amount - updated.fee,
      );
    }

    return Result.success(updated);
  }

  @override
  Future<Result<void>> deleteTransaction(String id) async {
    final t = await _dataSource.getTransactionById(id);
    await _dataSource.deleteTransaction(id);

    // Reverse source
    if (t?.accountId != null) {
      await _accountRepository.adjustBalance(
        t!.accountId!,
        -_calculateBalanceAdjustment(t),
      );
    }
    // Reverse destination (if was a transfer)
    if (t?.type == TransactionType.transfer && t?.toAccountId != null) {
      await _accountRepository.adjustBalance(
        t!.toAccountId!,
        -(t.amount - t.fee),
      );
    }

    return Result.success(null);
  }

  @override
  Future<Result<double>> getTotalIncome(
    DateTime startDate,
    DateTime endDate,
  ) async {
    final totalIncome = await _dataSource.getTotalIncome(startDate, endDate);
    return Result.success(totalIncome);
  }

  @override
  Future<Result<double>> getTotalExpenses(
    DateTime startDate,
    DateTime endDate,
  ) async {
    final totalExpenses = await _dataSource.getTotalExpenses(
      startDate,
      endDate,
    );
    return Result.success(totalExpenses);
  }

  /// Calculate the balance adjustment amount for a transaction
  /// Includes fees in the calculation:
  /// - Income: +amount - fee (you receive less due to platform/service fees)
  /// - Expense: -(amount + fee) (you pay the cost plus any taxes/fees)
  /// - Transfer: -(amount + fee) (source account pays transfer amount + fee)
  double _calculateBalanceAdjustment(Transaction transaction) {
    switch (transaction.type) {
      case TransactionType.income:
        // For income, fees are deducted (e.g., platform commission, bank fees)
        // You receive: amount - fee
        return transaction.amount - transaction.fee;
      case TransactionType.expense:
        // For expenses, fees add to the total cost (e.g., tax, service charge)
        // You pay: amount + fee
        return -(transaction.amount + transaction.fee);
      case TransactionType.transfer:
        // Source pays the full entered amount; fee is deducted from what
        // the destination receives (handled separately in createTransaction).
        return -transaction.amount;
    }
  }
}
