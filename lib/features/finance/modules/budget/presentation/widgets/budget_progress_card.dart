import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:keep_track/core/theme/app_theme.dart';
import '../../domain/entities/budget.dart';
import '../helpers/month_formatter.dart';

class BudgetProgressCard extends StatelessWidget {
  final Budget budget;
  final Color color;
  final bool isDesktop;
  final VoidCallback onTap;

  const BudgetProgressCard({
    super.key,
    required this.budget,
    required this.color,
    required this.isDesktop,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final totalBudget = budget.budgetTarget;
    final totalSpent = budget.totalSpent;
    final totalRemaining = totalBudget - totalSpent;
    final percentSpent =
        totalBudget > 0 ? (totalSpent / totalBudget).clamp(0.0, 1.0) : 0.0;
    final isOver = percentSpent >= 1.0;
    final progressColor = isOver ? AppColors.error : color;

    return Card(
      elevation: 0,
      color: color.withValues(alpha: 0.05),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        side: BorderSide(color: color.withValues(alpha: 0.3)),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: Padding(
          padding: EdgeInsets.all(isDesktop ? AppSpacing.lg : AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _BudgetCardHeader(budget: budget, color: color, isDesktop: isDesktop),
              const SizedBox(height: AppSpacing.md),
              ClipRRect(
                borderRadius: BorderRadius.circular(AppRadius.sm),
                child: LinearProgressIndicator(
                  value: percentSpent,
                  minHeight: 12,
                  backgroundColor: AppColors.border,
                  valueColor: AlwaysStoppedAnimation<Color>(progressColor),
                ),
              ),
              const SizedBox(height: AppSpacing.sm + 4),
              _BudgetCardStats(
                totalSpent: totalSpent,
                totalBudget: totalBudget,
                totalRemaining: totalRemaining,
                isOver: isOver,
                color: color,
              ),
              const SizedBox(height: AppSpacing.sm + 4),
              _BudgetCardFooter(budget: budget, isDesktop: isDesktop),
            ],
          ),
        ),
      ),
    );
  }
}

class _BudgetCardHeader extends StatelessWidget {
  final Budget budget;
  final Color color;
  final bool isDesktop;

  const _BudgetCardHeader({
    required this.budget,
    required this.color,
    required this.isDesktop,
  });

  @override
  Widget build(BuildContext context) {
    final title = budget.title != null && budget.title!.isNotEmpty
        ? budget.title!
        : formatMonthDisplay(budget.month);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: isDesktop ? 18 : 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (budget.title != null && budget.title!.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  formatMonthDisplay(budget.month),
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(AppRadius.full),
          ),
          child: Text(
            budget.periodType.displayName,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ),
      ],
    );
  }
}

class _BudgetCardStats extends StatelessWidget {
  final double totalSpent;
  final double totalBudget;
  final double totalRemaining;
  final bool isOver;
  final Color color;

  const _BudgetCardStats({
    required this.totalSpent,
    required this.totalBudget,
    required this.totalRemaining,
    required this.isOver,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _StatColumn(
          label: 'Spent',
          amount: totalSpent,
          color: isOver ? AppColors.error : color,
        ),
        _StatColumn(label: 'Budget', amount: totalBudget, color: color),
        _StatColumn(
          label: 'Remaining',
          amount: totalRemaining,
          color: totalRemaining < 0 ? AppColors.error : AppColors.textSecondary,
          alignment: CrossAxisAlignment.end,
        ),
      ],
    );
  }
}

class _StatColumn extends StatelessWidget {
  final String label;
  final double amount;
  final Color color;
  final CrossAxisAlignment alignment;

  const _StatColumn({
    required this.label,
    required this.amount,
    required this.color,
    this.alignment = CrossAxisAlignment.start,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: alignment,
      children: [
        Text(
          label,
          style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
        ),
        const SizedBox(height: 4),
        Text(
          '₱${NumberFormat('#,##0').format(amount)}',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }
}

class _BudgetCardFooter extends StatelessWidget {
  final Budget budget;
  final bool isDesktop;

  const _BudgetCardFooter({required this.budget, required this.isDesktop});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(Icons.category, size: 14, color: AppColors.textSecondary),
        const SizedBox(width: 6),
        Text(
          '${budget.categories.length} categories',
          style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
        ),
        if (isDesktop) ...[
          const Spacer(),
          Icon(Icons.arrow_forward_ios, size: 14, color: AppColors.textTertiary),
        ],
      ],
    );
  }
}
