import 'package:flutter_test/flutter_test.dart';
import 'package:keep_track/features/finance/modules/budget/data/models/budget_category_model.dart';

void main() {
  group('BudgetCategoryModel local JSON round-trip', () {
    test('a linked category survives toJson -> fromJson without losing link fields', () {
      final model = BudgetCategoryModel(
        id: 'cat-1',
        budgetId: 'budget-1',
        financeCategoryId: 'fc-1',
        targetAmount: 15.99,
        subscriptionId: 'sub-netflix',
        linkedEntityLabel: 'Netflix',
      );

      final roundTripped = BudgetCategoryModel.fromJson(model.toJson());

      expect(roundTripped.subscriptionId, 'sub-netflix');
      expect(roundTripped.debtId, isNull);
      expect(roundTripped.goalId, isNull);
      expect(roundTripped.linkedEntityLabel, 'Netflix');
      expect(roundTripped.isLinked, isTrue);
    });

    test('a plain (unlinked) category round-trips with no link fields', () {
      final model = BudgetCategoryModel(
        id: 'cat-2',
        budgetId: 'budget-1',
        financeCategoryId: 'fc-2',
        targetAmount: 50,
      );

      final roundTripped = BudgetCategoryModel.fromJson(model.toJson());

      expect(roundTripped.isLinked, isFalse);
      expect(roundTripped.subscriptionId, isNull);
      expect(roundTripped.debtId, isNull);
      expect(roundTripped.goalId, isNull);
      expect(roundTripped.linkedEntityLabel, isNull);
    });

    test('a debt-linked category survives fromEntity as well as JSON round-trip', () {
      final model = BudgetCategoryModel(
        budgetId: 'budget-1',
        financeCategoryId: 'fc-3',
        targetAmount: 200,
        debtId: 'debt-1',
        linkedEntityLabel: 'Car Loan',
      );
      final fromEntity = BudgetCategoryModel.fromEntity(model);

      expect(fromEntity.debtId, 'debt-1');
      expect(fromEntity.linkedEntityLabel, 'Car Loan');

      final roundTripped = BudgetCategoryModel.fromJson(fromEntity.toJson());
      expect(roundTripped.debtId, 'debt-1');
      expect(roundTripped.linkedEntityLabel, 'Car Loan');
    });
  });
}
