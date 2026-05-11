import 'package:flutter/material.dart';

import '../../../../../../core/theme/app_theme.dart';
import '../../../transaction/domain/entities/transaction.dart';
import 'transaction_mini_row.dart';

class GroupTransactionsTab extends StatelessWidget {
  final List<Transaction> transactions;

  const GroupTransactionsTab({required this.transactions});

  @override
  Widget build(BuildContext context) {
    if (transactions.isEmpty) {
      return Center(
        child: Text(
          'No transactions for this group.',
          style: AppTextStyles.bodySmall.copyWith(
            color: AppColors.textTertiary,
          ),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.symmetric(vertical: 4),
      itemCount: transactions.length,
      separatorBuilder: (_, __) => const Divider(height: 1, indent: 16),
      itemBuilder: (_, i) => TransactionMiniRow(transaction: transactions[i]),
    );
  }
}
