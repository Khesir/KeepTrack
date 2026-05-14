import 'package:flutter/material.dart';
import 'package:keep_track/core/settings/utils/currency_formatter.dart';
import 'package:keep_track/core/theme/app_theme.dart';
import '../../domain/entities/budget.dart';
import '../helpers/month_formatter.dart';

class BudgetListCard extends StatelessWidget {
  final Budget budget;
  final VoidCallback onTap;

  const BudgetListCard({super.key, required this.budget, required this.onTap});

  String _displayTitle() {
    if (budget.title != null && budget.title!.isNotEmpty) {
      return budget.title!;
    }
    return formatMonthDisplay(budget.month, short: true);
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final typeColor = budget.budgetType == BudgetType.income
        ? AppColors.income
        : AppColors.expense;
    final isActive = budget.status == BudgetStatus.active;

    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm + 4),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.xl),
        side: BorderSide(color: colorScheme.outlineVariant),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _CardHeader(
                budget: budget,
                displayTitle: _displayTitle(),
                typeColor: typeColor,
                isActive: isActive,
              ),
              const SizedBox(height: AppSpacing.sm + 4),
              _BudgetMiniBar(budget: budget, typeColor: typeColor),
              if (isActive && budget.isOverBudget)
                _OverBudgetBadge(),
            ],
          ),
        ),
      ),
    );
  }
}

class _CardHeader extends StatelessWidget {
  final Budget budget;
  final String displayTitle;
  final Color typeColor;
  final bool isActive;

  const _CardHeader({
    required this.budget,
    required this.displayTitle,
    required this.typeColor,
    required this.isActive,
  });

  @override
  Widget build(BuildContext context) {
    final periodColor = budget.periodType == BudgetPeriodType.monthly
        ? AppColors.info
        : AppColors.accent;
    final statusColor = isActive ? AppColors.success : AppColors.textTertiary;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: typeColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: Icon(
                  budget.budgetType == BudgetType.income
                      ? Icons.arrow_downward
                      : Icons.arrow_upward,
                  color: typeColor,
                  size: 20,
                ),
              ),
              const SizedBox(width: AppSpacing.sm + 4),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      displayTitle,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        _Chip(
                          label: budget.periodType.displayName,
                          color: periodColor,
                        ),
                        const SizedBox(width: 4),
                        _Chip(
                          label: budget.status.displayName,
                          color: statusColor,
                        ),
                        if (budget.title != null && budget.title!.isNotEmpty) ...[
                          const SizedBox(width: 4),
                          Text(
                            formatMonthDisplay(budget.month, short: true),
                            style: AppTextStyles.caption.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '${currencyFormatter.currencySymbol}${budget.budgetTarget.toStringAsFixed(0)}',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: typeColor,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              'Target',
              style: AppTextStyles.caption.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final Color color;

  const _Chip({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}

class _BudgetMiniBar extends StatelessWidget {
  final Budget budget;
  final Color typeColor;

  const _BudgetMiniBar({required this.budget, required this.typeColor});

  @override
  Widget build(BuildContext context) {
    final spent = budget.totalSpent;
    final target = budget.budgetTarget;
    final percentage = target > 0 ? (spent / target).clamp(0.0, 1.0) : 0.0;
    final barColor = budget.isOverBudget ? AppColors.error : typeColor;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          height: 28,
          decoration: BoxDecoration(
            color: AppColors.border,
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(color: AppColors.borderLight, width: 1),
          ),
          child: Stack(
            children: [
              if (percentage > 0)
                FractionallySizedBox(
                  widthFactor: percentage,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          barColor.withValues(alpha: 0.8),
                          barColor,
                        ],
                      ),
                      borderRadius: BorderRadius.circular(AppRadius.md),
                      boxShadow: [
                        BoxShadow(
                          color: barColor.withValues(alpha: 0.3),
                          blurRadius: 4,
                        ),
                      ],
                    ),
                  ),
                ),
              Center(
                child: Text(
                  '${currencyFormatter.currencySymbol}${spent.toStringAsFixed(0)} / ${currencyFormatter.currencySymbol}${target.toStringAsFixed(0)}',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textOnPrimary,
                    shadows: [Shadow(color: Colors.black54, blurRadius: 2)],
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _LegendDot(
              color: budget.isOverBudget ? AppColors.error : typeColor,
              label: budget.budgetType == BudgetType.income ? 'Earned' : 'Spent',
            ),
            const SizedBox(width: AppSpacing.md),
            _LegendDot(color: AppColors.border, label: 'Remaining'),
          ],
        ),
      ],
    );
  }
}

class _OverBudgetBadge extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.sm + 4),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.errorLight,
          borderRadius: BorderRadius.circular(AppRadius.sm),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.warning_amber, size: 16, color: AppColors.error),
            const SizedBox(width: 6),
            Text(
              'Over budget',
              style: AppTextStyles.caption.copyWith(
                color: AppColors.error,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;

  const _LegendDot({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
        ),
      ],
    );
  }
}
