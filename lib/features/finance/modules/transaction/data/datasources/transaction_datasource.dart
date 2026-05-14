import '../../domain/entities/transaction.dart';

abstract class TransactionDataSource {
  Future<List<Transaction>> getTransactions();
  Future<List<Transaction>> getTransactionsByBudget(String budgetId);
  Future<List<Transaction>> getTransactionsByCategory(String categoryId);
  Future<List<Transaction>> getTransactionsByDateRange(DateTime startDate, DateTime endDate);
  Future<List<Transaction>> getRecentTransactions({int limit = 10});
  Future<Transaction?> getTransactionById(String id);
  Future<Transaction> createTransaction(Transaction transaction);
  Future<Transaction> updateTransaction(Transaction transaction);
  Future<void> deleteTransaction(String id);
  Future<double> getTotalIncome(DateTime startDate, DateTime endDate);
  Future<double> getTotalExpenses(DateTime startDate, DateTime endDate);
}
