import 'package:flutter/material.dart';
import 'package:keep_track/core/theme/app_theme.dart';

import '../../domain/entities/budget.dart';
import '../../domain/entities/budget_category.dart';
import '../helpers/currency_formatter.dart';
import 'category_row.dart';
import 'ghost_add_row.dart';

class BudgetGroupCard extends StatelessWidget {
  final Budget group;
  final String monthLabel;
  final bool isSelected;
  final Map<String, double> spentByCategory;
  final VoidCallback onSelect;
  final VoidCallback onEditGroup;
  final VoidCallback onAddRow;
  final void Function(BudgetCategory) onCategoryDetailTap;
  final void Function(BudgetCategory) onCategoryEditTap;
  final Future<void> Function(BudgetCategory, double) onUpdateAmount;
  final Future<void> Function(BudgetCategory, double)? onCategoryPay;
  final int? dragIndex;

  const BudgetGroupCard({
    super.key,
    required this.group,
    required this.monthLabel,
    required this.isSelected,
    required this.spentByCategory,
    required this.onSelect,
    required this.onEditGroup,
    required this.onAddRow,
    required this.onCategoryDetailTap,
    required this.onCategoryEditTap,
    required this.onUpdateAmount,
    this.onCategoryPay,
    this.dragIndex,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isIncome = group.budgetType == BudgetType.income;
    final totalPlanned = group.budgetTarget;
    final totalActual = group.categories.fold(
      0.0,
      (sum, cat) => sum + (spentByCategory[cat.financeCategoryId] ?? 0.0),
    );
    final diff = totalActual - totalPlanned; // positive = over/extra
    final progress = totalPlanned > 0
        ? (totalActual / totalPlanned).clamp(0.0, 1.0)
        : 0.0;
    // For income: over is good (green). For expense: over is bad (red).
    final isOverBudget = totalActual > totalPlanned;
    final overColor = isIncome ? AppColors.success : AppColors.error;
    final progressColor = isOverBudget
        ? overColor
        : progress > 0.85 && !isIncome
        ? AppColors.warning
        : AppColors.accent;

    // Pill label & color
    final pillLabel = isIncome
        ? diff > 0
              ? '${formatCurrency(diff)} Extra'
              : '${formatCurrency(-diff)} Left'
        : diff > 0
        ? '${formatCurrency(diff)} Over'
        : '${formatCurrency(-diff)} Left';
    final pillColor = isIncome
        ? diff > 0
              ? AppColors.success
              : AppColors.textSecondary
        : diff > 0
        ? AppColors.error
        : AppColors.success;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Divider(height: 1),
        InkWell(
          onTap: onSelect,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            color: isSelected
                ? theme.colorScheme.primary.withValues(alpha: 0.06)
                : Colors.transparent,
            padding: const EdgeInsets.fromLTRB(16, 12, 8, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    // Selection indicator
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      width: 3,
                      height: 16,
                      margin: const EdgeInsets.only(right: 10),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? theme.colorScheme.primary
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        group.title ?? monthLabel,
                        style: AppTextStyles.bodyMedium.copyWith(
                          fontWeight: FontWeight.w600,
                          color: isSelected
                              ? theme.colorScheme.primary
                              : AppColors.textPrimary,
                        ),
                      ),
                    ),
                    // Actual / Planned
                    Text(
                      formatCurrency(totalActual),
                      style: AppTextStyles.bodySmall.copyWith(
                        color: isOverBudget ? overColor : AppColors.textPrimary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      ' / ${formatCurrency(totalPlanned)}',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.textTertiary,
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Left / Extra / Over pill
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: pillColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        pillLabel,
                        style: AppTextStyles.caption.copyWith(
                          color: pillColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.edit_outlined, size: 15),
                      color: AppColors.textTertiary,
                      onPressed: onEditGroup,
                      visualDensity: VisualDensity.compact,
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      constraints: const BoxConstraints(),
                    ),
                    if (dragIndex != null)
                      ReorderableDragStartListener(
                        index: dragIndex!,
                        child: const MouseRegion(
                          cursor: SystemMouseCursors.grab,
                          child: Padding(
                            padding: EdgeInsets.symmetric(horizontal: 6),
                            child: Icon(Icons.drag_handle, size: 16, color: AppColors.textTertiary),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                // Progress bar
                ClipRRect(
                  borderRadius: BorderRadius.circular(2),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 3,
                    backgroundColor: AppColors.textTertiary.withValues(
                      alpha: 0.15,
                    ),
                    valueColor: AlwaysStoppedAnimation<Color>(progressColor),
                  ),
                ),
                const SizedBox(height: 10),
              ],
            ),
          ),
        ),

        // ── Category rows ────────────────────────────────────────────────
        if (group.categories.isNotEmpty)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            decoration: BoxDecoration(
              color: Theme.of(
                context,
              ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
              border: Border.symmetric(
                horizontal: BorderSide(color: AppColors.border, width: 0.5),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'CATEGORY',
                    style: TextStyle(
                      fontSize: 10,
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.6,
                    ),
                  ),
                ),
                SizedBox(
                  width: 80,
                  child: Text(
                    isIncome ? 'EXPECTED' : 'PLANNED',
                    textAlign: TextAlign.right,
                    style: TextStyle(
                      fontSize: 10,
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.6,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  width: 72,
                  child: Text(
                    isIncome ? 'RECEIVED' : 'SPENT',
                    textAlign: TextAlign.right,
                    style: TextStyle(
                      fontSize: 10,
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.6,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ...group.categories.map(
          (cat) => CategoryRow(
            key: ValueKey(cat.id ?? cat.financeCategoryId),
            category: cat,
            spentAmount: spentByCategory[cat.financeCategoryId] ?? 0.0,
            isIncomeGroup: isIncome,
            accentColor: AppColors.accent,
            onDetailTap: () => onCategoryDetailTap(cat),
            onEditTap: () => onCategoryEditTap(cat),
            onUpdateAmount: (amount) => onUpdateAmount(cat, amount),
            onPay: onCategoryPay != null ? (amount) => onCategoryPay!(cat, amount) : null,
          ),
        ),
        GhostAddRow(label: 'Add Category', onTap: onAddRow),
      ],
    );
  }
}
