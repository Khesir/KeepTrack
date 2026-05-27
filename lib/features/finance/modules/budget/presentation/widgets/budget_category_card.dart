import 'package:flutter/material.dart';
import 'package:keep_track/core/theme/app_theme.dart';
import 'package:keep_track/features/finance/modules/finance_category/domain/entities/finance_category_enums.dart';
import '../../domain/entities/budget.dart';
import '../../domain/entities/budget_category.dart';

class BudgetCategoryCard extends StatelessWidget {
  final BudgetCategory category;
  final BudgetType budgetType;
  final bool isSelected;
  final VoidCallback onTap;

  const BudgetCategoryCard({
    super.key,
    required this.category,
    required this.budgetType,
    required this.isSelected,
    required this.onTap,
  });

  Color _categoryColor(CategoryType? type) {
    return switch (type) {
      CategoryType.income => AppColors.income,
      CategoryType.savings => AppColors.warning,
      CategoryType.investment => AppColors.accent,
      _ => AppColors.expense,
    };
  }

  @override
  Widget build(BuildContext context) {
    final spent = category.spentAmount ?? 0.0;
    final feeSpent = category.feeSpent ?? 0.0;
    final totalSpent = category.totalSpent;
    final target = category.targetAmount;
    final remaining = target - totalSpent;
    final percentage = target > 0 ? (totalSpent / target).clamp(0.0, 1.0) : 0.0;
    final isOverBudget = totalSpent > target;
    final hasFees = feeSpent > 0;
    final categoryType = category.financeCategory?.type;
    final color = _categoryColor(categoryType);
    final borderColor = isSelected ? color : Colors.transparent;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.lg),
      child: Card(
        elevation: isSelected ? 4 : 1,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          side: BorderSide(color: borderColor, width: isSelected ? 2 : 0),
        ),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _CategoryCardHeader(
                category: category,
                color: color,
                isSelected: isSelected,
                isOverBudget: isOverBudget,
              ),
              const SizedBox(height: AppSpacing.sm + 4),
              _CategoryCardAmounts(
                totalSpent: totalSpent,
                feeSpent: feeSpent,
                remaining: remaining,
                categoryType: categoryType,
                color: color,
                isOverBudget: isOverBudget,
                hasFees: hasFees,
              ),
              const SizedBox(height: AppSpacing.sm),
              TweenAnimationBuilder<double>(
                duration: const Duration(milliseconds: 800),
                curve: Curves.easeOutCubic,
                tween: Tween<double>(begin: 0, end: percentage),
                builder: (_, value, __) => LinearProgressIndicator(
                  value: value,
                  backgroundColor: AppColors.border,
                  valueColor: AlwaysStoppedAnimation(
                    isOverBudget ? AppColors.error : color,
                  ),
                  minHeight: 6,
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
              ),
              if (percentage > 0)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    '${(percentage * 100).toStringAsFixed(0)}% of ₱${target.toStringAsFixed(0)}',
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.textTertiary,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CategoryCardHeader extends StatelessWidget {
  final BudgetCategory category;
  final Color color;
  final bool isSelected;
  final bool isOverBudget;

  const _CategoryCardHeader({
    required this.category,
    required this.color,
    required this.isSelected,
    required this.isOverBudget,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Row(
            children: [
              if (isSelected)
                Padding(
                  padding: const EdgeInsets.only(right: AppSpacing.sm),
                  child: Icon(Icons.filter_alt, size: 16, color: color),
                ),
              Expanded(
                child: Text(
                  category.financeCategory?.name ?? 'Unknown',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: isSelected ? color : null,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
        if (isOverBudget)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: AppColors.errorLight,
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
            child: Text(
              'Over',
              style: AppTextStyles.caption.copyWith(
                color: AppColors.error,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
      ],
    );
  }
}

class _CategoryCardAmounts extends StatelessWidget {
  final double totalSpent;
  final double feeSpent;
  final double remaining;
  final CategoryType? categoryType;
  final Color color;
  final bool isOverBudget;
  final bool hasFees;

  const _CategoryCardAmounts({
    required this.totalSpent,
    required this.feeSpent,
    required this.remaining,
    required this.categoryType,
    required this.color,
    required this.isOverBudget,
    required this.hasFees,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              categoryType == CategoryType.income ? 'Earned' : 'Spent',
              style: AppTextStyles.caption.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            Text(
              '₱${totalSpent.toStringAsFixed(0)}',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: isOverBudget ? AppColors.error : color,
              ),
            ),
            if (hasFees)
              Text(
                '+₱${feeSpent.toStringAsFixed(0)} fees',
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.textTertiary,
                  fontStyle: FontStyle.italic,
                ),
              ),
          ],
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              'Left',
              style: AppTextStyles.caption.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            Text(
              '₱${remaining.abs().toStringAsFixed(0)}',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: remaining >= 0 ? AppColors.success : AppColors.error,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
