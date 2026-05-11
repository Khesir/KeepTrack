import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:keep_track/core/theme/app_theme.dart';
import 'package:keep_track/features/finance/modules/budget/presentation/helpers/currency_formatter.dart';

import '../../../transaction/domain/entities/transaction.dart';
import '../../domain/entities/budget_category.dart';
import 'stat_chip.dart';

class CategoryDetailContent extends StatelessWidget {
  final BudgetCategory category;
  final List<Transaction> transactions;
  final bool isIncomeGroup;
  final ScrollController? scrollController;

  const CategoryDetailContent({
    required this.category,
    required this.transactions,
    this.isIncomeGroup = false,
    this.scrollController,
  });

  @override
  Widget build(BuildContext context) {
    final planned = category.targetAmount;
    final actual = transactions.fold(0.0, (sum, t) => sum + t.amount);
    final diff = actual - planned; // positive = over/extra
    final isOver = diff > 0;
    // Income: over = green (good). Expense: over = red (bad).
    final overColor = isIncomeGroup ? AppColors.success : AppColors.error;
    final progressColor = isOver
        ? overColor
        : isIncomeGroup
        ? AppColors.accent
        : AppColors.success;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Stats header
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                category.financeCategory?.name ?? 'Category',
                style: AppTextStyles.h4,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  StatChip(
                    label: 'Planned',
                    value: formatCurrency(planned),
                    color: AppColors.textSecondary,
                  ),
                  const SizedBox(width: 8),
                  StatChip(
                    label: 'Actual',
                    value: formatCurrency(actual),
                    color: actual > 0
                        ? AppColors.textPrimary
                        : AppColors.textTertiary,
                  ),
                  const SizedBox(width: 8),
                  StatChip(
                    label: isIncomeGroup
                        ? (isOver ? 'Extra' : 'Pending')
                        : (isOver ? 'Over by' : 'Left'),
                    value: formatCurrency(diff.abs()),
                    color: isIncomeGroup
                        ? (isOver ? AppColors.success : AppColors.textSecondary)
                        : (isOver ? AppColors.error : AppColors.success),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: planned > 0 ? (actual / planned).clamp(0.0, 1.0) : 0.0,
                  minHeight: 6,
                  backgroundColor: AppColors.textTertiary.withValues(
                    alpha: 0.15,
                  ),
                  valueColor: AlwaysStoppedAnimation<Color>(progressColor),
                ),
              ),
              const SizedBox(height: 12),
              const Divider(height: 1),
              const SizedBox(height: 8),
              Text(
                'TRANSACTIONS',
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.6,
                ),
              ),
            ],
          ),
        ),

        // Transactions list
        Expanded(
          child: transactions.isEmpty
              ? Center(
                  child: Text(
                    'No transactions yet',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.textTertiary,
                    ),
                  ),
                )
              : ListView.separated(
                  controller: scrollController,
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                  itemCount: transactions.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (_, i) {
                    final t = transactions[i];
                    final isIncome = t.type == TransactionType.income;
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      child: Row(
                        children: [
                          Text(
                            DateFormat('MMM d').format(t.date),
                            style: AppTextStyles.caption.copyWith(
                              color: AppColors.textTertiary,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              t.description ?? '—',
                              style: AppTextStyles.bodySmall.copyWith(
                                color: AppColors.textPrimary,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Text(
                            '${isIncome ? '+' : '-'}${formatCurrency(t.amount)}',
                            style: AppTextStyles.bodySmall.copyWith(
                              fontWeight: FontWeight.w600,
                              color: isIncome
                                  ? AppColors.success
                                  : AppColors.error,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}
