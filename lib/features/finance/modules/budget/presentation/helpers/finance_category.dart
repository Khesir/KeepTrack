import 'package:flutter/material.dart';

import '../../../finance_category/domain/entities/finance_category.dart';
import '../../../finance_category/domain/entities/finance_category_enums.dart';
import '../../domain/entities/budget.dart';

class CategoryGroup {
  final String name;
  final List<FinanceCategory> categories;
  const CategoryGroup(this.name, this.categories);
}

/// Builds grouped category list: one group per active budget in [monthKey],
/// then an "Other" group for any categories not assigned to a budget.
List<CategoryGroup> buildGroupedCategories({
  required List<FinanceCategory> allCategories,
  required List<Budget> allBudgets,
  required CategoryType targetType,
  required String monthKey,
}) {
  final targetBudgetType = targetType == CategoryType.income
      ? BudgetType.income
      : BudgetType.expense;

  final monthBudgets = allBudgets
      .where(
        (b) =>
            b.month == monthKey &&
            b.periodType == BudgetPeriodType.monthly &&
            b.status == BudgetStatus.active &&
            b.budgetType == targetBudgetType,
      )
      .toList();

  final typedCats = allCategories.where((c) => c.type == targetType).toList();
  final seenIds = <String>{};
  final groups = <CategoryGroup>[];

  for (final budget in monthBudgets) {
    final groupCats = <FinanceCategory>[];
    for (final bc in budget.categories) {
      final cat = typedCats.firstWhere(
        (c) => c.id == bc.financeCategoryId,
        orElse: () => FinanceCategory(name: '', type: targetType),
      );
      if (cat.id != null && !seenIds.contains(cat.id)) {
        groupCats.add(cat);
        seenIds.add(cat.id!);
      }
    }
    if (groupCats.isNotEmpty) {
      groups.add(CategoryGroup(budget.title ?? 'Untitled', groupCats));
    }
  }

  // Only show unbudgeted categories in "Other" when a plan exists for this
  // month — avoids dumping all finance_categories as "Other" when there is
  // no month plan yet.
  if (monthBudgets.isNotEmpty) {
    final others = typedCats
        .where((c) => c.id != null && !seenIds.contains(c.id))
        .toList();
    if (others.isNotEmpty) {
      groups.add(CategoryGroup('Other', others));
    }
  }

  return groups;
}

/// Shows a scrollable grouped category picker dialog.
/// Returns the selected [FinanceCategory] or null (cancelled).
Future<FinanceCategory?> showGroupedCategoryDialog(
  BuildContext context, {
  required List<CategoryGroup> groups,
  required String? selectedId,
}) {
  final theme = Theme.of(context);
  final colorScheme = theme.colorScheme;
  return showDialog<FinanceCategory>(
    context: context,
    builder: (dialogCtx) => Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      clipBehavior: Clip.antiAlias,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.65,
          maxWidth: 420,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
              child: Text('Select Category', style: theme.textTheme.titleLarge),
            ),
            const Divider(height: 1),
            Flexible(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (final group in groups) ...[
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 14, 16, 4),
                        child: Text(
                          group.name.toUpperCase(),
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: colorScheme.primary,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.8,
                          ),
                        ),
                      ),
                      for (final cat in group.categories)
                        ListTile(
                          leading: Icon(
                            cat.type.icon,
                            size: 20,
                            color: cat.type.color,
                          ),
                          title: Text(cat.name),
                          selected: selectedId == cat.id,
                          selectedTileColor: colorScheme.primaryContainer
                              .withValues(alpha: 0.3),
                          trailing: selectedId == cat.id
                              ? Icon(
                                  Icons.check,
                                  size: 18,
                                  color: colorScheme.primary,
                                )
                              : null,
                          onTap: () => Navigator.of(dialogCtx).pop(cat),
                        ),
                    ],
                    const SizedBox(height: 8),
                  ],
                ),
              ),
            ),
            const Divider(height: 1),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () => Navigator.of(dialogCtx).pop(),
                child: const Text('Cancel'),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
