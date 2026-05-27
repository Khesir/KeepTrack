import 'package:flutter/material.dart';
import 'package:keep_track/core/theme/app_theme.dart';
import 'package:keep_track/features/finance/modules/budget/presentation/helpers/currency_formatter.dart';

import '../../../debt/domain/entities/debt.dart';
import '../../../transaction/domain/entities/transaction.dart';
import 'stat_chip.dart';
import 'transaction_mini_row.dart';

class DebtDetailContent extends StatelessWidget {
  final Debt debt;
  final List<Transaction> transactions;
  final ScrollController? scrollController;
  final VoidCallback? onPay;

  const DebtDetailContent({
    required this.debt,
    required this.transactions,
    this.scrollController,
    this.onPay,
  });

  @override
  Widget build(BuildContext context) {
    final isReceivable = debt.type == DebtType.lending;
    final paid = debt.paidAmount;
    final progress = debt.progress;
    final progressColor = isReceivable ? AppColors.accent : AppColors.success;

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
                debt.description.isNotEmpty
                    ? debt.description
                    : debt.personName,
                style: AppTextStyles.h4,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  StatChip(
                    label: 'Original',
                    value: formatCurrency(debt.originalAmount),
                    color: AppColors.textSecondary,
                  ),
                  const SizedBox(width: 8),
                  StatChip(
                    label: isReceivable ? 'Collected' : 'Paid',
                    value: formatCurrency(paid),
                    color: paid > 0
                        ? AppColors.textPrimary
                        : AppColors.textTertiary,
                  ),
                  const SizedBox(width: 8),
                  StatChip(
                    label: 'Remaining',
                    value: formatCurrency(debt.remainingAmount),
                    color: debt.remainingAmount > 0
                        ? AppColors.error
                        : AppColors.success,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 6,
                  backgroundColor: AppColors.textTertiary.withValues(
                    alpha: 0.15,
                  ),
                  valueColor: AlwaysStoppedAnimation<Color>(progressColor),
                ),
              ),
              const SizedBox(height: 6),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${(progress * 100).toStringAsFixed(0)}% complete',
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.textTertiary,
                    ),
                  ),
                  if (debt.monthlyPaymentAmount > 0)
                    Text(
                      'Monthly: ${formatCurrency(debt.monthlyPaymentAmount)}',
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.textTertiary,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              const Divider(height: 1),
              const SizedBox(height: 8),
              Text(
                'PAYMENT HISTORY',
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
                    'No payments recorded yet',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.textTertiary,
                    ),
                  ),
                )
              : ListView.separated(
                  controller: scrollController,
                  padding: const EdgeInsets.fromLTRB(0, 4, 0, 24),
                  itemCount: transactions.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (_, i) =>
                      TransactionMiniRow(transaction: transactions[i]),
                ),
        ),
      ],
    );
  }
}
