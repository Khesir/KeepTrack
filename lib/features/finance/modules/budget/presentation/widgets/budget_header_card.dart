import 'package:flutter/material.dart';
import 'package:keep_track/core/theme/app_theme.dart';
import '../../domain/entities/budget.dart';
import '../helpers/month_formatter.dart';

class BudgetHeaderCard extends StatelessWidget {
  final Budget budget;
  final Color balanceColor;

  const BudgetHeaderCard({
    super.key,
    required this.budget,
    required this.balanceColor,
  });

  @override
  Widget build(BuildContext context) {
    final title = budget.title != null && budget.title!.isNotEmpty
        ? budget.title!
        : formatMonthDisplay(budget.month);
    final isActive = budget.status == BudgetStatus.active;
    final statusColor = isActive ? AppColors.success : AppColors.textTertiary;

    return Card(
      margin: const EdgeInsets.all(AppSpacing.md),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.xl),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      if (budget.title != null && budget.title!.isNotEmpty)
                        Text(
                          formatMonthDisplay(budget.month),
                          style: AppTextStyles.caption.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                    ],
                  ),
                ),
                _StatusBadge(label: budget.status.displayName, color: statusColor),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              '₱${budget.budgetTarget.toStringAsFixed(2)}',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: balanceColor,
              ),
            ),
            Text(
              budget.status == BudgetStatus.closed
                  ? (budget.surplusOrDeficit >= 0 ? 'Surplus' : 'Deficit')
                  : 'Budget Target',
              style: AppTextStyles.caption.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                _QuickStat(
                  label: budget.budgetType == BudgetType.income
                      ? 'Earned'
                      : 'Spent',
                  amount: budget.totalSpent,
                  color: balanceColor,
                ),
                const SizedBox(width: AppSpacing.md),
                _QuickStat(
                  label: 'Remaining',
                  amount: budget.remainingBudget.abs(),
                  color: budget.remainingBudget >= 0
                      ? AppColors.success
                      : AppColors.error,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}


class _StatusBadge extends StatelessWidget {
  final String label;
  final Color color;

  const _StatusBadge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(AppRadius.full),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          color: color,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

class _QuickStat extends StatelessWidget {
  final String label;
  final double amount;
  final Color color;

  const _QuickStat({
    required this.label,
    required this.amount,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '$label ',
          style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
        ),
        Text(
          '₱${amount.toStringAsFixed(0)}',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
      ],
    );
  }
}
