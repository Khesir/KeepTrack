import '../../domain/entities/transaction.dart';

/// Transaction data source interface
abstract class TransactionDataSource {
  /// Get all transactions
  Future<List<Transaction>> getTransactions();

  /// Get transactions for a specific account
  Future<List<Transaction>> getTransactionsByAccount(String accountId);

  /// Get transactions for a specific budget
  Future<List<Transaction>> getTransactionsByBudget(String budgetId);

  /// Get transactions for a specific category
  Future<List<Transaction>> getTransactionsByCategory(String categoryId);

  /// Get transactions within a date range
  Future<List<Transaction>> getTransactionsByDateRange(
    DateTime startDate,
    DateTime endDate,
  );

  /// Get recent transactions (limited)
  Future<List<Transaction>> getRecentTransactions({int limit = 10});

  /// Get transaction by ID
  Future<Transaction?> getTransactionById(String id);

  /// Create a new transaction
  Future<Transaction> createTransaction(Transaction transaction);

  /// Update a transaction
  Future<Transaction> updateTransaction(Transaction transaction);

  /// Delete a transaction
  Future<void> deleteTransaction(String id);

  /// Get total income for a period
  Future<double> getTotalIncome(DateTime startDate, DateTime endDate);

  /// Get total expenses for a period
  Future<double> getTotalExpenses(DateTime startDate, DateTime endDate);
}
