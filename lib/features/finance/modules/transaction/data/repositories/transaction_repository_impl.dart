import 'package:persona_codex/core/error/result.dart';

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
    final createdTransaction = await _dataSource.createTransaction(transaction);

    if (createdTransaction.accountId != null) {
      final adjustmentAmount = _calculateBalanceAdjustment(createdTransaction);
      await _accountRepository.adjustBalance(
        createdTransaction.accountId!,
        adjustmentAmount,
      );
    }

    return Result.success(createdTransaction);
  }

  @override
  Future<Result<Transaction>> updateTransaction(Transaction transaction) async {
    if (transaction.id == null) {
      throw Exception('Cannot update transaction without an ID');
    }

    final oldTransaction = await _dataSource.getTransactionById(
      transaction.id!,
    );
    final updatedTransaction = await _dataSource.updateTransaction(transaction);

    if (oldTransaction?.accountId != null ||
        updatedTransaction.accountId != null) {
      // Reverse old transaction effect
      if (oldTransaction?.accountId != null) {
        final reverseAmount = -_calculateBalanceAdjustment(oldTransaction!);
        await _accountRepository.adjustBalance(
          oldTransaction.accountId!,
          reverseAmount,
        );
      }
      // Apply new transaction effect
      if (updatedTransaction.accountId != null) {
        final adjustmentAmount = _calculateBalanceAdjustment(
          updatedTransaction,
        );
        await _accountRepository.adjustBalance(
          updatedTransaction.accountId!,
          adjustmentAmount,
        );
      }
    }

    return Result.success(updatedTransaction);
  }

  @override
  Future<Result<void>> deleteTransaction(String id) async {
    final transaction = await _dataSource.getTransactionById(id);

    await _dataSource.deleteTransaction(id);

    if (transaction?.accountId != null) {
      final reverseAmount = -_calculateBalanceAdjustment(transaction!);
      await _accountRepository.adjustBalance(
        transaction.accountId!,
        reverseAmount,
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
  /// Income: +amount (adds to balance)
  /// Expense: -amount (subtracts from balance)
  /// Transfer: -amount (treated as expense for source account)
  double _calculateBalanceAdjustment(Transaction transaction) {
    switch (transaction.type) {
      case TransactionType.income:
        return transaction.amount;
      case TransactionType.expense:
        return -transaction.amount;
      case TransactionType.transfer:
        return -transaction.amount;
    }
  }
}
