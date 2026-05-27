import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:keep_track/core/theme/app_theme.dart';
import 'package:keep_track/features/finance/modules/budget/presentation/helpers/currency_formatter.dart';

import '../../../transaction/domain/entities/transaction.dart';

class TransactionMiniRow extends StatelessWidget {
  final Transaction transaction;

  const TransactionMiniRow({required this.transaction});

  @override
  Widget build(BuildContext context) {
    final isIncome = transaction.type == TransactionType.income;
    final amtColor = isIncome ? AppColors.success : AppColors.error;
    final sign = isIncome ? '+' : '-';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      child: Row(
        children: [
          Text(
            DateFormat('MMM d').format(transaction.date),
            style: AppTextStyles.caption.copyWith(
              color: AppColors.textTertiary,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              transaction.description ?? '—',
              style: AppTextStyles.caption.copyWith(
                color: AppColors.textPrimary,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Text(
            '$sign${formatCurrency(transaction.amount)}',
            style: AppTextStyles.caption.copyWith(
              color: amtColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
