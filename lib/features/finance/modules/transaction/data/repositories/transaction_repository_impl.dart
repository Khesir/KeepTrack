import 'package:keep_track/core/error/result.dart';
import '../../domain/entities/transaction.dart';
import '../../domain/repositories/transaction_repository.dart';
import '../datasources/transaction_datasource.dart';

class TransactionRepositoryImpl implements TransactionRepository {
  final TransactionDataSource _dataSource;

  TransactionRepositoryImpl(this._dataSource);

  @override
  Future<Result<List<Transaction>>> getTransactions() async {
    final transactions = await _dataSource.getTransactions();
    return Result.success(transactions);
  }

  @override
  Future<Result<List<Transaction>>> getTransactionsByBudget(String budgetId) async {
    final transactions = await _dataSource.getTransactionsByBudget(budgetId);
    return Result.success(transactions);
  }

  @override
  Future<Result<List<Transaction>>> getTransactionsByCategory(String categoryId) async {
    final transactions = await _dataSource.getTransactionsByCategory(categoryId);
    return Result.success(transactions);
  }

  @override
  Future<Result<List<Transaction>>> getTransactionsByDateRange(DateTime startDate, DateTime endDate) async {
    final transactions = await _dataSource.getTransactionsByDateRange(startDate, endDate);
    return Result.success(transactions);
  }

  @override
  Future<Result<List<Transaction>>> getRecentTransactions({int limit = 10}) async {
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
    return Result.success(t);
  }

  @override
  Future<Result<Transaction>> updateTransaction(Transaction transaction) async {
    if (transaction.id == null) throw Exception('Cannot update transaction without an ID');
    final updated = await _dataSource.updateTransaction(transaction);
    return Result.success(updated);
  }

  @override
  Future<Result<void>> deleteTransaction(String id) async {
    await _dataSource.deleteTransaction(id);
    return Result.success(null);
  }

  @override
  Future<Result<double>> getTotalIncome(DateTime startDate, DateTime endDate) async {
    final total = await _dataSource.getTotalIncome(startDate, endDate);
    return Result.success(total);
  }

  @override
  Future<Result<double>> getTotalExpenses(DateTime startDate, DateTime endDate) async {
    final total = await _dataSource.getTotalExpenses(startDate, endDate);
    return Result.success(total);
  }
}
