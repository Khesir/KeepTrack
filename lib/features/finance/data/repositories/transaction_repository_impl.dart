import '../../domain/entities/transaction.dart';
import '../../domain/repositories/transaction_repository.dart';
import '../../domain/repositories/account_repository.dart';
import '../datasources/transaction_datasource.dart';

/// Transaction repository implementation
class TransactionRepositoryImpl implements TransactionRepository {
  final TransactionDataSource _dataSource;
  final AccountRepository _accountRepository;

  TransactionRepositoryImpl(this._dataSource, this._accountRepository);

  @override
  Future<List<Transaction>> getTransactions() async {
    try {
      return await _dataSource.getTransactions();
    } catch (e) {
      throw Exception('Failed to get transactions: $e');
    }
  }

  @override
  Future<List<Transaction>> getTransactionsByAccount(String accountId) async {
    try {
      return await _dataSource.getTransactionsByAccount(accountId);
    } catch (e) {
      throw Exception('Failed to get transactions for account: $e');
    }
  }

  @override
  Future<List<Transaction>> getTransactionsByBudget(String budgetId) async {
    try {
      return await _dataSource.getTransactionsByBudget(budgetId);
    } catch (e) {
      throw Exception('Failed to get transactions for budget: $e');
    }
  }

  @override
  Future<List<Transaction>> getTransactionsByCategory(String categoryId) async {
    try {
      return await _dataSource.getTransactionsByCategory(categoryId);
    } catch (e) {
      throw Exception('Failed to get transactions for category: $e');
    }
  }

  @override
  Future<List<Transaction>> getTransactionsByDateRange(
    DateTime startDate,
    DateTime endDate,
  ) async {
    try {
      return await _dataSource.getTransactionsByDateRange(startDate, endDate);
    } catch (e) {
      throw Exception('Failed to get transactions by date range: $e');
    }
  }

  @override
  Future<List<Transaction>> getRecentTransactions({int limit = 10}) async {
    try {
      return await _dataSource.getRecentTransactions(limit: limit);
    } catch (e) {
      throw Exception('Failed to get recent transactions: $e');
    }
  }

  @override
  Future<Transaction?> getTransactionById(String id) async {
    try {
      return await _dataSource.getTransactionById(id);
    } catch (e) {
      throw Exception('Failed to get transaction: $e');
    }
  }

  @override
  Future<Transaction> createTransaction(Transaction transaction) async {
    try {
      final createdTransaction = await _dataSource.createTransaction(transaction);

      // Automatically adjust account balance if accountId is present
      if (createdTransaction.accountId != null) {
        final adjustmentAmount = _calculateBalanceAdjustment(createdTransaction);
        await _accountRepository.adjustBalance(
          createdTransaction.accountId!,
          adjustmentAmount,
        );
      }

      return createdTransaction;
    } catch (e) {
      throw Exception('Failed to create transaction: $e');
    }
  }

  @override
  Future<Transaction> updateTransaction(Transaction transaction) async {
    try {
      if (transaction.id == null) {
        throw Exception('Cannot update transaction without an ID');
      }

      // Get the old transaction to reverse its balance effect
      final oldTransaction = await _dataSource.getTransactionById(transaction.id!);

      final updatedTransaction = await _dataSource.updateTransaction(transaction);

      // Handle account balance adjustments
      if (oldTransaction?.accountId != null || updatedTransaction.accountId != null) {
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
          final adjustmentAmount = _calculateBalanceAdjustment(updatedTransaction);
          await _accountRepository.adjustBalance(
            updatedTransaction.accountId!,
            adjustmentAmount,
          );
        }
      }

      return updatedTransaction;
    } catch (e) {
      throw Exception('Failed to update transaction: $e');
    }
  }

  @override
  Future<void> deleteTransaction(String id) async {
    try {
      // Get the transaction to reverse its balance effect
      final transaction = await _dataSource.getTransactionById(id);

      await _dataSource.deleteTransaction(id);

      // Reverse the balance effect if accountId exists
      if (transaction?.accountId != null) {
        final reverseAmount = -_calculateBalanceAdjustment(transaction!);
        await _accountRepository.adjustBalance(
          transaction.accountId!,
          reverseAmount,
        );
      }
    } catch (e) {
      throw Exception('Failed to delete transaction: $e');
    }
  }

  @override
  Future<double> getTotalIncome(DateTime startDate, DateTime endDate) async {
    try {
      return await _dataSource.getTotalIncome(startDate, endDate);
    } catch (e) {
      throw Exception('Failed to get total income: $e');
    }
  }

  @override
  Future<double> getTotalExpenses(DateTime startDate, DateTime endDate) async {
    try {
      return await _dataSource.getTotalExpenses(startDate, endDate);
    } catch (e) {
      throw Exception('Failed to get total expenses: $e');
    }
  }

  /// Calculate the balance adjustment amount for a transaction
  /// Income: +amount (adds to balance)
  /// Expense: -amount (subtracts from balance)
  /// Transfer: -amount (treated as expense for source account)
  double _calculateBalanceAdjustment(Transaction transaction) {
    switch (transaction.type) {
      case TransactionType.income:
        return transaction.amount; // Add to balance
      case TransactionType.expense:
        return -transaction.amount; // Subtract from balance
      case TransactionType.transfer:
        return -transaction.amount; // Subtract from source account
    }
  }
}
