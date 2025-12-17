import 'package:flutter/material.dart';
import 'package:persona_codex/core/theme/gcash_theme.dart';

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

    return Scaffold(
      backgroundColor: GCashColors.background,
      body: logs.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.history, size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    'No financial activity yet',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Your financial activity will appear here',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: GCashSpacing.screenPadding,
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
                          style: GCashTextStyles.h3.copyWith(
                            color: Colors.grey[700],
                          ),
                        ),
                      ),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Material(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        child: ListTile(
                          contentPadding: const EdgeInsets.all(16),
                          leading: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: log.color.withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(log.icon, color: log.color, size: 24),
                          ),
                          title: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  log.action,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                              if (log.amount != null)
                                Text(
                                  '₱${log.amount!.abs().toStringAsFixed(2)}',
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
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 4),
                              Text(
                                log.description,
                                style: const TextStyle(fontSize: 13),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _formatTime(log.timestamp),
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
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
