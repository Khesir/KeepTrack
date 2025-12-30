import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../modules/transaction/domain/entities/transaction.dart' as finance_transaction;

/// Card widget displaying recent transactions
class RecentTransactionsCard extends StatelessWidget {
  final List<finance_transaction.Transaction> transactions;

  const RecentTransactionsCard({
    super.key,
    required this.transactions,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.receipt_long,
                      color: Theme.of(context).primaryColor,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Recent Transactions',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ],
                ),
                if (transactions.isNotEmpty)
                  TextButton(
                    onPressed: () {
                      // TODO: Navigate to full transaction list
                    },
                    child: const Text('View All'),
                  ),
              ],
            ),
          ),

          const Divider(height: 1),

          // Transactions list or empty state
          if (transactions.isEmpty)
            Padding(
              padding: const EdgeInsets.all(32.0),
              child: Center(
                child: Column(
                  children: [
                    Icon(
                      Icons.receipt_outlined,
                      size: 48,
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.3),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'No transactions yet',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: transactions.length,
              separatorBuilder: (context, index) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final transaction = transactions[index];
                return _buildTransactionTile(context, transaction);
              },
            ),
        ],
      ),
    );
  }

  Widget _buildTransactionTile(
    BuildContext context,
    finance_transaction.Transaction transaction,
  ) {
    final isIncome =
        transaction.type == finance_transaction.TransactionType.income;
    final isExpense =
        transaction.type == finance_transaction.TransactionType.expense;

    final hasFee = transaction.hasFee;
    final displayAmount = transaction.totalCost;

    return ListTile(
      leading: CircleAvatar(
        backgroundColor: isIncome
            ? Colors.green[100]
            : isExpense
                ? Colors.red[100]
                : Colors.blue[100],
        child: Icon(
          isIncome
              ? Icons.arrow_downward
              : isExpense
                  ? Icons.arrow_upward
                  : Icons.swap_horiz,
          color: isIncome
              ? Colors.green[700]
              : isExpense
                  ? Colors.red[700]
                  : Colors.blue[700],
          size: 20,
        ),
      ),
      title: Text(
        transaction.description ?? 'Transaction',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _formatDate(transaction.date),
            style: TextStyle(
              fontSize: 12,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
            ),
          ),
          if (hasFee)
            Text(
              '₱${transaction.amount.toStringAsFixed(2)} + ₱${transaction.fee.toStringAsFixed(2)} fee',
              style: TextStyle(
                fontSize: 11,
                color: Theme.of(context).colorScheme.primary.withOpacity(0.7),
                fontStyle: FontStyle.italic,
              ),
            ),
        ],
      ),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            '${isExpense ? '-' : isIncome ? '+' : ''}₱${displayAmount.toStringAsFixed(2)}',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: isIncome
                  ? Colors.green[700]
                  : isExpense
                      ? Colors.red[700]
                      : Colors.grey[700],
              fontSize: 16,
            ),
          ),
          if (hasFee)
            Text(
              transaction.feeDescription ?? 'Fee',
              style: TextStyle(
                fontSize: 10,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
              ),
            ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final transactionDate = DateTime(date.year, date.month, date.day);

    if (transactionDate == today) {
      return 'Today ${DateFormat('HH:mm').format(date)}';
    } else if (transactionDate == yesterday) {
      return 'Yesterday ${DateFormat('HH:mm').format(date)}';
    } else if (now.difference(date).inDays < 7) {
      return DateFormat('EEEE HH:mm').format(date);
    } else {
      return DateFormat('MMM dd, yyyy').format(date);
    }
  }
}
