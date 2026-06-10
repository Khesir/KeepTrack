import 'package:flutter/material.dart';
import 'package:keep_track/core/state/stream_state.dart';
import 'package:keep_track/features/finance/modules/budget/presentation/controllers/budget_controller.dart';
import 'package:keep_track/features/finance/modules/budget/presentation/helpers/finance_category.dart';
import 'package:keep_track/features/finance/modules/finance_category/domain/entities/finance_category.dart';
import 'package:keep_track/features/finance/modules/finance_category/domain/entities/finance_category_enums.dart';
import 'package:keep_track/features/finance/modules/transaction/domain/entities/transaction.dart';
import 'package:keep_track/features/finance/presentation/helpers/split_entry.dart';
import 'package:keep_track/features/finance/presentation/state/finance_category_controller.dart';

Future<FinanceCategory?> pickSplitEntryCategory(
  BuildContext context,
  SplitEntry entry,
  FinanceCategoryController catController,
  BudgetController budgetController,
) {
  final monthKey =
      '${DateTime.now().year}-${DateTime.now().month.toString().padLeft(2, '0')}';
  final groups = buildGroupedCategories(
    allCategories: catController.data ?? [],
    allBudgets: budgetController.data ?? [],
    targetType: entry.type == TransactionType.income
        ? CategoryType.income
        : CategoryType.expense,
    monthKey: monthKey,
  );
  return showGroupedCategoryDialog(
    context,
    groups: groups,
    selectedId: entry.category?.id,
  );
}
