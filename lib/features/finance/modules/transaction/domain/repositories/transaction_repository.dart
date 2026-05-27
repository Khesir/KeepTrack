import 'package:keep_track/core/error/result.dart';
import '../entities/transaction.dart';

abstract class TransactionRepository {
  Future<Result<List<Transaction>>> getTransactions();
  Future<Result<List<Transaction>>> getTransactionsByBudget(String budgetId);
  Future<Result<List<Transaction>>> getTransactionsBySavings(String savingsId);
  Future<Result<List<Transaction>>> getTransactionsByCategory(String categoryId);
  Future<Result<List<Transaction>>> getTransactionsByDateRange(DateTime startDate, DateTime endDate);
  Future<Result<List<Transaction>>> getRecentTransactions({int limit = 10});
  Future<Result<Transaction?>> getTransactionById(String id);
  Future<Result<Transaction>> createTransaction(Transaction transaction);
  Future<Result<Transaction>> updateTransaction(Transaction transaction);
  Future<Result<void>> deleteTransaction(String id);
  Future<Result<double>> getTotalIncome(DateTime startDate, DateTime endDate);
  Future<Result<double>> getTotalExpenses(DateTime startDate, DateTime endDate);
}
