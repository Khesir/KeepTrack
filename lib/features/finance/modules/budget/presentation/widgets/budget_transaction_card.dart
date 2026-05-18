import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:keep_track/core/theme/app_theme.dart';
import 'package:keep_track/features/finance/modules/budget/domain/entities/budget_category.dart';
import 'package:keep_track/features/finance/modules/finance_category/domain/entities/finance_category_enums.dart';
import 'package:keep_track/features/finance/modules/transaction/domain/entities/transaction.dart';

class BudgetTransactionCard extends StatelessWidget {
  final Transaction transaction;
  final BudgetCategory? budgetCategory;

  const BudgetTransactionCard({
    super.key,
    required this.transaction,
    this.budgetCategory,
  });

  @override
  Widget build(BuildContext context) {
    final isIncome = transaction.type == TransactionType.income;
    final isExpense = transaction.type == TransactionType.expense;
    final color = isIncome
        ? AppColors.income
        : isExpense
        ? AppColors.expense
        : AppColors.info;

    final displayAmount = isExpense
        ? -transaction.totalCost
        : isIncome
        ? transaction.totalCost
        : transaction.amount;

    final category = budgetCategory?.financeCategory;
    final sign = isExpense ? '-' : isIncome ? '+' : '';

    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(AppSpacing.sm),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            category?.type.icon ?? Icons.category,
            color: color,
            size: 20,
          ),
        ),
        title: Text(
          transaction.description ?? category?.name ?? 'Transaction',
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: _TransactionSubtitle(
          transaction: transaction,
          categoryName: category?.name,
          isIncome: isIncome,
          isExpense: isExpense,
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '$sign₱${displayAmount.abs().toStringAsFixed(2)}',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 15,
                color: isIncome
                    ? AppColors.income
                    : isExpense
                    ? AppColors.expense
                    : AppColors.info,
              ),
            ),
            Text(
              DateFormat('MMM d').format(transaction.date),
              style: AppTextStyles.caption.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TransactionSubtitle extends StatelessWidget {
  final Transaction transaction;
  final String? categoryName;
  final bool isIncome;
  final bool isExpense;

  const _TransactionSubtitle({
    required this.transaction,
    required this.categoryName,
    required this.isIncome,
    required this.isExpense,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          isIncome
              ? Icons.arrow_downward
              : isExpense
              ? Icons.arrow_upward
              : Icons.swap_horiz,
          size: 12,
          color: AppColors.textSecondary,
        ),
        const SizedBox(width: 4),
        Expanded(
          child: Text(
            categoryName ?? 'Unknown',
            style: AppTextStyles.caption.copyWith(
              color: AppColors.textSecondary,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        if (transaction.hasFee) ...[
          const SizedBox(width: AppSpacing.sm),
          Icon(Icons.receipt, size: 12, color: AppColors.textSecondary),
          const SizedBox(width: 2),
          Text(
            '+₱${transaction.fee.toStringAsFixed(2)}',
            style: AppTextStyles.caption.copyWith(
              color: AppColors.textTertiary,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ],
    );
  }
}
