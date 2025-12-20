import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class FinanceLogsTab extends StatelessWidget {
  const FinanceLogsTab({super.key});

  @override
  Widget build(BuildContext context) {
    // Mock data - will be replaced with actual logs from database
    final logs = [
      FinanceLog(
        id: '1',
        action: 'Transaction Created',
        description: 'Groceries shopping',
        amount: -2500.00,
        timestamp: DateTime.now().subtract(const Duration(hours: 1)),
        icon: Icons.shopping_cart,
        color: Colors.red,
      ),
      FinanceLog(
        id: '2',
        action: 'Income Received',
        description: 'Salary payment',
        amount: 50000.00,
        timestamp: DateTime.now().subtract(const Duration(hours: 3)),
        icon: Icons.arrow_downward,
        color: Colors.green,
      ),
      FinanceLog(
        id: '3',
        action: 'Budget Created',
        description: 'Monthly budget for December',
        amount: null,
        timestamp: DateTime.now().subtract(const Duration(days: 1)),
        icon: Icons.account_balance,
        color: Colors.blue,
      ),
      FinanceLog(
        id: '4',
        action: 'Account Updated',
        description: 'Main wallet balance adjusted',
        amount: null,
        timestamp: DateTime.now().subtract(const Duration(days: 2)),
        icon: Icons.account_balance_wallet,
        color: Colors.orange,
      ),
    ];

    return logs.isEmpty
        ? Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.history_outlined,
                  size: 80,
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                ),
                const SizedBox(height: 16),
                Text(
                  'No financial activity yet',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Your financial activity will appear here',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withOpacity(0.6),
                      ),
                ),
              ],
            ),
          )
        : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: logs.length,
              itemBuilder: (context, index) {
                final log = logs[index];
                final isToday = _isToday(log.timestamp);
                final isYesterday = _isYesterday(log.timestamp);

                // Show date header
                bool showDateHeader = false;
                if (index == 0) {
                  showDateHeader = true;
                } else {
                  final prevLog = logs[index - 1];
                  if (!_isSameDay(log.timestamp, prevLog.timestamp)) {
                    showDateHeader = true;
                  }
                }

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (showDateHeader)
                      Padding(
                        padding: const EdgeInsets.only(top: 8, bottom: 12, left: 4),
                        child: Text(
                          isToday
                              ? 'Today'
                              : isYesterday
                                  ? 'Yesterday'
                                  : _formatDate(log.timestamp),
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurface
                                    .withOpacity(0.7),
                              ),
                        ),
                      ),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Card(
                        elevation: 0,
                        clipBehavior: Clip.antiAlias,
                        child: InkWell(
                          onTap: () {
                            // Navigate to log detail
                          },
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: log.color.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Icon(log.icon, color: log.color, size: 24),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Expanded(
                                            child: Text(
                                              log.action,
                                              style: const TextStyle(
                                                fontWeight: FontWeight.w600,
                                                fontSize: 15,
                                              ),
                                            ),
                                          ),
                                          if (log.amount != null)
                                            Text(
                                              NumberFormat.currency(
                                                      symbol: '₱', decimalDigits: 2)
                                                  .format(log.amount!.abs()),
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 16,
                                                color: log.amount! >= 0
                                                    ? Colors.green[700]
                                                    : Colors.red[700],
                                              ),
                                            ),
                                        ],
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        log.description,
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: Theme.of(context)
                                              .colorScheme
                                              .onSurface
                                              .withOpacity(0.7),
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        _formatTime(log.timestamp),
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Theme.of(context)
                                              .colorScheme
                                              .onSurface
                                              .withOpacity(0.5),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            );
  }

  bool _isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }

  bool _isYesterday(DateTime date) {
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    return date.year == yesterday.year &&
        date.month == yesterday.month &&
        date.day == yesterday.day;
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  String _formatDate(DateTime date) {
    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  String _formatTime(DateTime date) {
    final hour = date.hour > 12 ? date.hour - 12 : date.hour;
    final minute = date.minute.toString().padLeft(2, '0');
    final period = date.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $period';
  }
}

class FinanceLog {
  final String id;
  final String action;
  final String description;
  final double? amount;
  final DateTime timestamp;
  final IconData icon;
  final Color color;

  FinanceLog({
    required this.id,
    required this.action,
    required this.description,
    this.amount,
    required this.timestamp,
    required this.icon,
    required this.color,
  });
}
