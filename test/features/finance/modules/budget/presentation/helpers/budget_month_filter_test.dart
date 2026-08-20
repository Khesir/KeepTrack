import 'package:flutter_test/flutter_test.dart';
import 'package:keep_track/features/finance/modules/budget/domain/entities/budget_category.dart';
import 'package:keep_track/features/finance/modules/budget/presentation/helpers/budget_month_filter.dart';
import 'package:keep_track/features/finance/modules/transaction/domain/entities/transaction.dart';

Transaction _tx({
  required double amount,
  String? subscriptionId,
  String? debtId,
  String? goalId,
}) {
  return Transaction(
    amount: amount,
    type: TransactionType.expense,
    date: DateTime(2026, 8, 1),
    subscriptionId: subscriptionId,
    debtId: debtId,
    goalId: goalId,
  );
}

BudgetCategory _linkedCategory({String? subscriptionId, String? debtId, String? goalId}) {
  return BudgetCategory(
    budgetId: 'budget-1',
    financeCategoryId: 'fc-1',
    targetAmount: 100,
    subscriptionId: subscriptionId,
    debtId: debtId,
    goalId: goalId,
  );
}

void main() {
  group('BudgetMonthFilter.buildLinkedSpend', () {
    test('sums only transactions matching the linked subscription id', () {
      final category = _linkedCategory(subscriptionId: 'sub-netflix');
      final transactions = [
        _tx(amount: 15.99, subscriptionId: 'sub-netflix'),
        _tx(amount: 9.99, subscriptionId: 'sub-spotify'),
        _tx(amount: 3.0, subscriptionId: null),
      ];

      final spent = BudgetMonthFilter.buildLinkedSpend(category, transactions);

      expect(spent, 15.99);
    });

    test('sums only transactions matching the linked debt id', () {
      final category = _linkedCategory(debtId: 'debt-car');
      final transactions = [
        _tx(amount: 200, debtId: 'debt-car'),
        _tx(amount: 50, debtId: 'debt-house'),
      ];

      final spent = BudgetMonthFilter.buildLinkedSpend(category, transactions);

      expect(spent, 200);
    });

    test('sums only transactions matching the linked goal id', () {
      final category = _linkedCategory(goalId: 'goal-emergency');
      final transactions = [
        _tx(amount: 500, goalId: 'goal-emergency'),
        _tx(amount: 100, goalId: 'goal-vacation'),
      ];

      final spent = BudgetMonthFilter.buildLinkedSpend(category, transactions);

      expect(spent, 500);
    });

    test('returns 0 for an unlinked category regardless of transactions', () {
      final category = _linkedCategory();
      final transactions = [
        _tx(amount: 15.99, subscriptionId: 'sub-netflix'),
      ];

      final spent = BudgetMonthFilter.buildLinkedSpend(category, transactions);

      expect(spent, 0.0);
    });

    test('sums multiple matching transactions for the same linked entity', () {
      final category = _linkedCategory(subscriptionId: 'sub-netflix');
      final transactions = [
        _tx(amount: 15.99, subscriptionId: 'sub-netflix'),
        _tx(amount: 15.99, subscriptionId: 'sub-netflix'),
      ];

      final spent = BudgetMonthFilter.buildLinkedSpend(category, transactions);

      expect(spent, 31.98);
    });
  });

  group('BudgetMonthFilter.linkedEntityIds', () {
    test('collects subscription, debt, and goal ids across a mixed list of categories', () {
      final categories = [
        _linkedCategory(subscriptionId: 'sub-netflix'),
        _linkedCategory(debtId: 'debt-car'),
        _linkedCategory(goalId: 'goal-emergency'),
        _linkedCategory(), // unlinked, should be ignored
      ];

      final ids = BudgetMonthFilter.linkedEntityIds(categories);

      expect(ids, {'sub-netflix', 'debt-car', 'goal-emergency'});
    });

    test('returns an empty set when nothing is linked', () {
      final categories = [_linkedCategory(), _linkedCategory()];

      final ids = BudgetMonthFilter.linkedEntityIds(categories);

      expect(ids, isEmpty);
    });

    test('returns an empty set for an empty category list', () {
      final ids = BudgetMonthFilter.linkedEntityIds(const []);

      expect(ids, isEmpty);
    });
  });
}
