import 'package:flutter_test/flutter_test.dart';
import 'package:keep_track/core/cache/memory_local_cache.dart';
import 'package:keep_track/features/finance/modules/budget/data/datasources/local/month_plan_datasource_local.dart';
import 'package:keep_track/features/finance/modules/budget/data/models/budget_category_model.dart';

void main() {
  group('MonthPlanDataSourceLocal.copyMonthPlan', () {
    test('a linked category keeps its link fields when copied to a new month', () async {
      final cache = MemoryLocalCache();
      final dataSource = MonthPlanDataSourceLocal(cache);

      // Seed a source month plan with one budget containing one linked category.
      await cache.put('month_plans', 'plan-1', {
        'id': 'plan-1',
        'month': '2026-01',
        'status': 'active',
        'budgetIds': ['budget-1'],
      });
      await cache.put('budgets', 'budget-1', {
        'id': 'budget-1',
        'month': '2026-01',
        'budgetType': 'expense',
        'status': 'active',
      });
      final linkedCategory = BudgetCategoryModel(
        id: 'cat-1',
        budgetId: 'budget-1',
        financeCategoryId: 'fc-subscriptions',
        targetAmount: 15.99,
        subscriptionId: 'sub-netflix',
        linkedEntityLabel: 'Netflix',
      );
      await cache.put('budget_categories', 'cat-1', linkedCategory.toJson());

      await dataSource.copyMonthPlan('2026-01', '2026-02');

      final copiedCategories = await cache.getAll('budget_categories');
      final copy = copiedCategories.singleWhere((c) => c['id'] != 'cat-1');

      expect(copy['subscriptionId'], 'sub-netflix');
      expect(copy['linkedEntityLabel'], 'Netflix');
      expect(copy['debtId'], isNull);
      expect(copy['goalId'], isNull);
      // The copy is a distinct row, re-parented to the new budget.
      expect(copy['id'], isNot('cat-1'));
      expect(copy['budgetId'], isNot('budget-1'));
    });

    test('a plain (unlinked) category copies forward with no link fields', () async {
      final cache = MemoryLocalCache();
      final dataSource = MonthPlanDataSourceLocal(cache);

      await cache.put('month_plans', 'plan-1', {
        'id': 'plan-1',
        'month': '2026-01',
        'status': 'active',
        'budgetIds': ['budget-1'],
      });
      await cache.put('budgets', 'budget-1', {
        'id': 'budget-1',
        'month': '2026-01',
        'budgetType': 'expense',
        'status': 'active',
      });
      final plainCategory = BudgetCategoryModel(
        id: 'cat-2',
        budgetId: 'budget-1',
        financeCategoryId: 'fc-groceries',
        targetAmount: 200,
      );
      await cache.put('budget_categories', 'cat-2', plainCategory.toJson());

      await dataSource.copyMonthPlan('2026-01', '2026-02');

      final copiedCategories = await cache.getAll('budget_categories');
      final copy = copiedCategories.singleWhere((c) => c['id'] != 'cat-2');

      expect(copy['financeCategoryId'], 'fc-groceries');
      expect(copy['targetAmount'], 200);
      expect(copy.containsKey('subscriptionId'), isFalse);
      expect(copy.containsKey('debtId'), isFalse);
      expect(copy.containsKey('goalId'), isFalse);
      expect(copy.containsKey('linkedEntityLabel'), isFalse);
    });
  });
}
