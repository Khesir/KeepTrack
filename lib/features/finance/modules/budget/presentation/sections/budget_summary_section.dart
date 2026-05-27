import 'package:flutter/material.dart';
import 'package:keep_track/core/settings/utils/currency_formatter.dart';
import 'package:keep_track/core/theme/app_theme.dart';
import '../../domain/entities/budget.dart';
import '../helpers/month_formatter.dart';

class BudgetSummarySection extends StatelessWidget {
  final List<Budget> budgets;
  final VoidCallback onCreateBudget;
  final void Function(Budget) onOpenBudget;

  const BudgetSummarySection({
    super.key,
    required this.budgets,
    required this.onCreateBudget,
    required this.onOpenBudget,
  });

  @override
  Widget build(BuildContext context) {
    final currentMonth = currentMonthKey();
    final incomeBudget = budgets.cast<Budget?>().firstWhere(
      (b) => b?.month == currentMonth && b?.budgetType == BudgetType.income,
      orElse: () => null,
    );
    final expenseBudget = budgets.cast<Budget?>().firstWhere(
      (b) => b?.month == currentMonth && b?.budgetType == BudgetType.expense,
      orElse: () => null,
    );

    if (incomeBudget == null && expenseBudget == null) {
      return _CreateBudgetPrompt(
        currentMonth: currentMonth,
        onCreateBudget: onCreateBudget,
      );
    }

    return _CurrentBudgetSummary(
      currentMonth: currentMonth,
      incomeBudget: incomeBudget,
      expenseBudget: expenseBudget,
      onOpenBudget: onOpenBudget,
      onCreateBudget: onCreateBudget,
    );
  }
}

class _CreateBudgetPrompt extends StatelessWidget {
  final String currentMonth;
  final VoidCallback onCreateBudget;

  const _CreateBudgetPrompt({
    required this.currentMonth,
    required this.onCreateBudget,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(AppSpacing.md),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.xl),
      ),
      color: AppColors.infoLight,
      child: InkWell(
        onTap: onCreateBudget,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.sm + 4),
                    decoration: BoxDecoration(
                      color: AppColors.info.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(AppRadius.lg),
                    ),
                    child: const Icon(
                      Icons.calendar_today,
                      color: AppColors.info,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm + 4),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          formatMonthDisplay(currentMonth),
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Current Month',
                          style: AppTextStyles.caption.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              const Text('No budget found for the current month.'),
              const SizedBox(height: 4),
              Text(
                'Create a budget to start planning your finances',
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              FilledButton.icon(
                onPressed: onCreateBudget,
                icon: const Icon(Icons.add),
                label: const Text('Create Budget'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CurrentBudgetSummary extends StatelessWidget {
  final String currentMonth;
  final Budget? incomeBudget;
  final Budget? expenseBudget;
  final void Function(Budget) onOpenBudget;
  final VoidCallback onCreateBudget;

  const _CurrentBudgetSummary({
    required this.currentMonth,
    required this.incomeBudget,
    required this.expenseBudget,
    required this.onOpenBudget,
    required this.onCreateBudget,
  });

  @override
  Widget build(BuildContext context) {
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
            Text(
              formatMonthDisplay(currentMonth),
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              'Current Month Budgets',
              style: AppTextStyles.caption.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            if (incomeBudget != null) ...[
              _BudgetTypeRow(
                budget: incomeBudget!,
                color: AppColors.income,
                icon: Icons.arrow_downward,
                label: 'Income Budget',
                onTap: () => onOpenBudget(incomeBudget!),
              ),
              const SizedBox(height: AppSpacing.sm + 4),
            ] else
              _MissingBudgetRow(
                label: 'Income',
                icon: Icons.arrow_downward,
                onCreateBudget: onCreateBudget,
              ),
            if (expenseBudget != null)
              _BudgetTypeRow(
                budget: expenseBudget!,
                color: AppColors.expense,
                icon: Icons.arrow_upward,
                label: 'Expense Budget',
                onTap: () => onOpenBudget(expenseBudget!),
              )
            else
              _MissingBudgetRow(
                label: 'Expense',
                icon: Icons.arrow_upward,
                onCreateBudget: onCreateBudget,
              ),
          ],
        ),
      ),
    );
  }
}

class _BudgetTypeRow extends StatelessWidget {
  final Budget budget;
  final Color color;
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _BudgetTypeRow({
    required this.budget,
    required this.color,
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isActive = budget.status == BudgetStatus.active;
    final statusColor = isActive ? AppColors.success : AppColors.textTertiary;
    final spent = budget.totalSpent;
    final target = budget.budgetTarget;
    final percentage = target > 0 ? (spent / target).clamp(0.0, 1.0) : 0.0;
    final barColor = budget.isOverBudget ? AppColors.error : color;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.lg),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(AppSpacing.sm),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                  ),
                  child: Icon(icon, color: color, size: 16),
                ),
                const SizedBox(width: AppSpacing.sm + 4),
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(AppRadius.full),
                  ),
                  child: Text(
                    budget.status.displayName,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: statusColor,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm + 4),
            Container(
              height: 24,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(AppRadius.lg),
                border: Border.all(color: AppColors.borderLight),
              ),
              child: Stack(
                children: [
                  if (percentage > 0)
                    FractionallySizedBox(
                      widthFactor: percentage,
                      child: Container(
                        decoration: BoxDecoration(
                          color: barColor,
                          borderRadius: BorderRadius.circular(AppRadius.md),
                        ),
                      ),
                    ),
                  Center(
                    child: Text(
                      '${currencyFormatter.currencySymbol}${spent.toStringAsFixed(0)} / ${currencyFormatter.currencySymbol}${target.toStringAsFixed(0)}',
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textOnPrimary,
                        shadows: [Shadow(color: Colors.black54, blurRadius: 2)],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (budget.isOverBudget) ...[
              const SizedBox(height: 6),
              Row(
                children: [
                  Icon(Icons.warning_amber, size: 12, color: AppColors.error),
                  const SizedBox(width: 4),
                  Text(
                    'Over budget',
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.error,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _MissingBudgetRow extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onCreateBudget;

  const _MissingBudgetRow({
    required this.label,
    required this.icon,
    required this.onCreateBudget,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.muted,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.sm),
            decoration: BoxDecoration(
              color: AppColors.border,
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
            child: Icon(icon, color: AppColors.textTertiary, size: 16),
          ),
          const SizedBox(width: AppSpacing.sm + 4),
          Expanded(
            child: Text(
              'No $label Budget',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: AppColors.textTertiary,
              ),
            ),
          ),
          TextButton(
            onPressed: onCreateBudget,
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }
}
