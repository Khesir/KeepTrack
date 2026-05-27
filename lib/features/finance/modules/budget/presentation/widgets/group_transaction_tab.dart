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
      itemBuilder: (_, i) => TweenAnimationBuilder<double>(
        key: ValueKey(transactions[i].id),
        tween: Tween(begin: 0.0, end: 1.0),
        duration: const Duration(milliseconds: 400),
        curve: Interval(
          (i * 0.08).clamp(0.0, 0.6),
          (i * 0.08 + 0.4).clamp(0.0, 1.0),
          curve: Curves.easeOut,
        ),
        builder: (_, v, child) => Opacity(
          opacity: v,
          child: Transform.translate(offset: Offset(0, (1 - v) * 8), child: child),
        ),
        child: TransactionMiniRow(transaction: transactions[i]),
      ),
    );
  }
}
