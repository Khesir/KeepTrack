import 'package:keep_track/core/error/result.dart';
import '../entities/transaction.dart';

/// Transaction repository interface
abstract class TransactionRepository {
  /// Get all transactions
  Future<Result<List<Transaction>>> getTransactions();

  /// Get transactions for a specific account
  Future<Result<List<Transaction>>> getTransactionsByAccount(String accountId);

  /// Get transactions for a specific budget
  Future<Result<List<Transaction>>> getTransactionsByBudget(String budgetId);

  /// Get transactions for a specific category
  Future<Result<List<Transaction>>> getTransactionsByCategory(
    String categoryId,
  );

  /// Get transactions within a date range
  Future<Result<List<Transaction>>> getTransactionsByDateRange(
    DateTime startDate,
    DateTime endDate,
  );

  /// Get recent transactions (limited)
  Future<Result<List<Transaction>>> getRecentTransactions({int limit = 10});

  /// Get transaction by ID
  Future<Result<Transaction?>> getTransactionById(String id);

  /// Create a new transaction
  Future<Result<Transaction>> createTransaction(Transaction transaction);

  /// Update a transaction
  Future<Result<Transaction>> updateTransaction(Transaction transaction);

  /// Delete a transaction
  Future<Result<void>> deleteTransaction(String id);

  /// Get total income for a period
  Future<Result<double>> getTotalIncome(DateTime startDate, DateTime endDate);

  /// Get total expenses for a period
  Future<Result<double>> getTotalExpenses(DateTime startDate, DateTime endDate);
}
