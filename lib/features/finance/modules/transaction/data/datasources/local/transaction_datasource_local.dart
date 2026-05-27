import 'package:keep_track/core/cache/local_cache.dart';
import 'package:keep_track/features/finance/modules/transaction/data/models/transaction_model.dart';
import 'package:keep_track/features/finance/modules/transaction/domain/entities/transaction.dart';
import 'package:uuid/uuid.dart';
import '../transaction_datasource.dart';

class TransactionDataSourceLocal implements TransactionDataSource {
  final LocalCache _cache;
  final _uuid = const Uuid();

  static const _box = 'transactions';

  TransactionDataSourceLocal(this._cache);

  Future<List<TransactionModel>> _getAll() async {
    final entries = await _cache.getAll(_box);
    return entries.map((e) => TransactionModel.fromJson(e)).toList();
  }

  @override
  Future<List<Transaction>> getTransactions() async => _getAll();

  @override
  Future<List<Transaction>> getTransactionsByBudget(String budgetId) async {
    final all = await _getAll();
    return all.where((t) => t.budgetId == budgetId).toList();
  }

  @override
  Future<List<Transaction>> getTransactionsBySavings(String savingsId) async {
    final all = await _getAll();
    return all.where((t) => t.savingsId == savingsId).toList();
  }

  @override
  Future<List<Transaction>> getTransactionsByCategory(String categoryId) async {
    final all = await _getAll();
    return all.where((t) => t.financeCategoryId == categoryId).toList();
  }

  @override
  Future<List<Transaction>> getTransactionsByDateRange(
    DateTime startDate,
    DateTime endDate,
  ) async {
    final all = await _getAll();
    return all
        .where((t) =>
            !t.date.isBefore(startDate) && !t.date.isAfter(endDate))
        .toList();
  }

  @override
  Future<List<Transaction>> getRecentTransactions({int limit = 10}) async {
    final all = await _getAll();
    all.sort((a, b) => b.date.compareTo(a.date));
    return all.take(limit).toList();
  }

  @override
  Future<Transaction?> getTransactionById(String id) async {
    final data = await _cache.get(_box, id);
    if (data == null) return null;
    return TransactionModel.fromJson(data);
  }

  @override
  Future<Transaction> createTransaction(Transaction transaction) async {
    final id = transaction.id ?? _uuid.v4();
    final model = TransactionModel.fromEntity(transaction);
    final json = {...TransactionModel.fromEntity(model).toJson(), 'id': id};
    await _cache.put(_box, id, json);
    return TransactionModel.fromJson(json);
  }

  @override
  Future<Transaction> updateTransaction(Transaction transaction) async {
    final model = TransactionModel.fromEntity(transaction);
    await _cache.put(_box, transaction.id!, model.toJson());
    return model;
  }

  @override
  Future<void> deleteTransaction(String id) async {
    await _cache.delete(_box, id);
  }

  @override
  Future<double> getTotalIncome(DateTime startDate, DateTime endDate) async {
    final all = await _getAll();
    return all
        .where((t) =>
            t.type == TransactionType.income &&
            !t.date.isBefore(startDate) &&
            !t.date.isAfter(endDate))
        .fold<double>(0.0, (sum, t) => sum + t.amount);
  }

  @override
  Future<double> getTotalExpenses(DateTime startDate, DateTime endDate) async {
    final all = await _getAll();
    return all
        .where((t) =>
            t.type == TransactionType.expense &&
            !t.date.isBefore(startDate) &&
            !t.date.isAfter(endDate))
        .fold<double>(0.0, (sum, t) => sum + t.amount);
  }
}
