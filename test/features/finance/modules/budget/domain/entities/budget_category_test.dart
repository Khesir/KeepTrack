import 'package:flutter_test/flutter_test.dart';
import 'package:keep_track/features/finance/modules/budget/domain/entities/budget_category.dart';

BudgetCategory _category({
  String? subscriptionId,
  String? debtId,
  String? goalId,
  String? linkedEntityLabel,
}) {
  return BudgetCategory(
    budgetId: 'budget-1',
    financeCategoryId: 'fc-1',
    targetAmount: 100,
    subscriptionId: subscriptionId,
    debtId: debtId,
    goalId: goalId,
    linkedEntityLabel: linkedEntityLabel,
  );
}

void main() {
  group('BudgetCategory.isLinked / linkedEntityType', () {
    test('a plain category with no link fields is not linked', () {
      final cat = _category();

      expect(cat.isLinked, isFalse);
      expect(cat.linkedEntityType, isNull);
    });

    test('a subscription-linked category reports type subscription', () {
      final cat = _category(subscriptionId: 'sub-1');

      expect(cat.isLinked, isTrue);
      expect(cat.linkedEntityType, 'subscription');
    });

    test('a debt-linked category reports type debt_payment', () {
      final cat = _category(debtId: 'debt-1');

      expect(cat.isLinked, isTrue);
      expect(cat.linkedEntityType, 'debt_payment');
    });

    test('a goal-linked category reports type goal', () {
      final cat = _category(goalId: 'goal-1');

      expect(cat.isLinked, isTrue);
      expect(cat.linkedEntityType, 'goal');
    });
  });

  group('BudgetCategory.copyForNewBudget', () {
    test('carries forward category link, plan fields, and drops identity/spend data', () {
      final source = BudgetCategory(
        id: 'cat-aug',
        budgetId: 'budget-aug',
        financeCategoryId: 'fc-1',
        targetAmount: 15.99,
        spentAmount: 15.99,
        feeSpent: 1.5,
        userId: 'user-1',
        subscriptionId: 'sub-netflix',
        linkedEntityLabel: 'Netflix',
        createdAt: DateTime(2026, 8, 1),
        updatedAt: DateTime(2026, 8, 2),
      );

      final copy = source.copyForNewBudget(newBudgetId: 'budget-sep');

      expect(copy.budgetId, 'budget-sep');
      expect(copy.financeCategoryId, 'fc-1');
      expect(copy.targetAmount, 15.99);
      expect(copy.userId, 'user-1');
      expect(copy.subscriptionId, 'sub-netflix');
      expect(copy.linkedEntityLabel, 'Netflix');
      expect(copy.isLinked, isTrue);

      expect(copy.id, isNull);
      expect(copy.spentAmount, isNull);
      expect(copy.feeSpent, isNull);
      expect(copy.createdAt, isNull);
      expect(copy.updatedAt, isNull);
    });

    test('carries forward a plain (unlinked) category unchanged in link state', () {
      final source = _category().copyWith(id: 'cat-plain');

      final copy = source.copyForNewBudget(newBudgetId: 'budget-sep');

      expect(copy.isLinked, isFalse);
      expect(copy.financeCategoryId, source.financeCategoryId);
      expect(copy.targetAmount, source.targetAmount);
    });
  });
}
