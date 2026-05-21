import 'package:keep_track/features/finance/modules/transaction/data/datasources/transaction_datasource.dart';
import 'package:keep_track/features/finance/modules/transaction/domain/entities/transaction.dart';

final _transactions = <Transaction>[
  Transaction(id: 'tx-01', amount: 5000,  type: TransactionType.income,  description: 'Monthly Salary',       date: DateTime(2026, 5,  1), financeCategoryId: 'cat-salary',       budgetId: 'budget-inc-1'),
  Transaction(id: 'tx-02', amount: 180,   type: TransactionType.expense, description: 'Weekly Groceries',     date: DateTime(2026, 5,  3), financeCategoryId: 'cat-food',          budgetId: 'budget-exp-1'),
  Transaction(id: 'tx-03', amount: 35,    type: TransactionType.expense, description: 'Grab to Office',       date: DateTime(2026, 5,  5), financeCategoryId: 'cat-transport',     budgetId: 'budget-exp-1'),
  Transaction(id: 'tx-04', amount: 80,    type: TransactionType.expense, description: 'Dinner Out',           date: DateTime(2026, 5,  6), financeCategoryId: 'cat-food',          budgetId: 'budget-exp-1'),
  Transaction(id: 'tx-05', amount: 1200,  type: TransactionType.expense, description: 'Apartment Rent',       date: DateTime(2026, 5,  8), financeCategoryId: 'cat-housing',       budgetId: 'budget-exp-1'),
  Transaction(id: 'tx-06', amount: 60,    type: TransactionType.expense, description: 'Bus Card Top-Up',      date: DateTime(2026, 5,  9), financeCategoryId: 'cat-transport',     budgetId: 'budget-exp-1'),
  Transaction(id: 'tx-07', amount: 1200,  type: TransactionType.income,  description: 'Freelance — Client A', date: DateTime(2026, 5, 10), financeCategoryId: 'cat-freelance',     budgetId: 'budget-inc-1'),
  Transaction(id: 'tx-08', amount: 210,   type: TransactionType.expense, description: 'Groceries Mid-Month',  date: DateTime(2026, 5, 12), financeCategoryId: 'cat-food',          budgetId: 'budget-exp-1'),
  Transaction(id: 'tx-09', amount: 130,   type: TransactionType.expense, description: 'Electricity Bill',     date: DateTime(2026, 5, 13), financeCategoryId: 'cat-utilities',     budgetId: 'budget-exp-1'),
  Transaction(id: 'tx-10', amount: 380,   type: TransactionType.expense, description: 'Online Shopping',      date: DateTime(2026, 5, 14), financeCategoryId: 'cat-shopping',      budgetId: 'budget-exp-1'),
  Transaction(id: 'tx-11', amount: 50,    type: TransactionType.expense, description: 'Cinema Tickets',       date: DateTime(2026, 5, 15), financeCategoryId: 'cat-entertainment', budgetId: 'budget-exp-1'),
  Transaction(id: 'tx-12', amount: 45,    type: TransactionType.expense, description: 'Weekend Grab',         date: DateTime(2026, 5, 17), financeCategoryId: 'cat-transport',     budgetId: 'budget-exp-1'),
  Transaction(id: 'tx-13', amount: 90,    type: TransactionType.expense, description: 'Team Lunch',           date: DateTime(2026, 5, 19), financeCategoryId: 'cat-food',          budgetId: 'budget-exp-1'),
  Transaction(id: 'tx-14', amount: 120,   type: TransactionType.expense, description: 'Concert Tickets',      date: DateTime(2026, 5, 20), financeCategoryId: 'cat-entertainment', budgetId: 'budget-exp-1'),
  Transaction(id: 'tx-15', amount: 160,   type: TransactionType.expense, description: 'Grocery Run',          date: DateTime(2026, 5, 22), financeCategoryId: 'cat-food',          budgetId: 'budget-exp-1'),
  Transaction(id: 'tx-16', amount: 70,    type: TransactionType.expense, description: 'Family Dinner',        date: DateTime(2026, 5, 23), financeCategoryId: 'cat-food',          budgetId: 'budget-exp-1'),
  Transaction(id: 'tx-17', amount: 25,    type: TransactionType.expense, description: 'MRT Trips',            date: DateTime(2026, 5, 24), financeCategoryId: 'cat-transport',     budgetId: 'budget-exp-1'),
  Transaction(id: 'tx-18', amount: 70,    type: TransactionType.expense, description: 'Bar Night',            date: DateTime(2026, 5, 26), financeCategoryId: 'cat-entertainment', budgetId: 'budget-exp-1'),
  Transaction(id: 'tx-19', amount: 130,   type: TransactionType.expense, description: 'New Shoes',            date: DateTime(2026, 5, 27), financeCategoryId: 'cat-shopping',      budgetId: 'budget-exp-1'),
  Transaction(id: 'tx-20', amount: 110,   type: TransactionType.expense, description: 'End-of-Month Market',  date: DateTime(2026, 5, 29), financeCategoryId: 'cat-food',          budgetId: 'budget-exp-1'),
  Transaction(id: 'tx-21', amount: 500,   type: TransactionType.expense, description: 'Savings Transfer',     date: DateTime(2026, 5, 30), financeCategoryId: 'cat-savings-c',     savingsId: 'savings-emergency'),
];

class TransactionDataSourceMock implements TransactionDataSource {
  @override
  Future<List<Transaction>> getTransactions() async => _transactions;

  @override
  Future<List<Transaction>> getTransactionsByBudget(String budgetId) async =>
      _transactions.where((t) => t.budgetId == budgetId).toList();

  @override
  Future<List<Transaction>> getTransactionsBySavings(String savingsId) async =>
      _transactions.where((t) => t.savingsId == savingsId).toList();

  @override
  Future<List<Transaction>> getTransactionsByCategory(String categoryId) async =>
      _transactions.where((t) => t.financeCategoryId == categoryId).toList();

  @override
  Future<List<Transaction>> getTransactionsByDateRange(DateTime startDate, DateTime endDate) async =>
      _transactions.where((t) => !t.date.isBefore(startDate) && !t.date.isAfter(endDate)).toList();

  @override
  Future<List<Transaction>> getRecentTransactions({int limit = 10}) async =>
      (_transactions.toList()..sort((a, b) => b.date.compareTo(a.date))).take(limit).toList();

  @override
  Future<Transaction?> getTransactionById(String id) async =>
      _transactions.where((t) => t.id == id).firstOrNull;

  @override
  Future<Transaction> createTransaction(Transaction transaction) async => transaction;

  @override
  Future<Transaction> updateTransaction(Transaction transaction) async => transaction;

  @override
  Future<void> deleteTransaction(String id) async {}

  @override
  Future<double> getTotalIncome(DateTime startDate, DateTime endDate) async =>
      _transactions
          .where((t) => t.type == TransactionType.income && !t.date.isBefore(startDate) && !t.date.isAfter(endDate))
          .fold<double>(0.0, (sum, t) => sum + t.amount);

  @override
  Future<double> getTotalExpenses(DateTime startDate, DateTime endDate) async =>
      _transactions
          .where((t) => t.type == TransactionType.expense && !t.date.isBefore(startDate) && !t.date.isAfter(endDate))
          .fold<double>(0.0, (sum, t) => sum + t.amount);
}
