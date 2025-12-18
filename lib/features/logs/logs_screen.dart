import 'package:flutter/material.dart';
import 'package:persona_codex/core/theme/gcash_theme.dart';
import 'package:persona_codex/core/ui/app_layout_controller.dart';
import 'package:persona_codex/core/ui/ui.dart';

class LogsScreen extends ScopedScreen {
  const LogsScreen({super.key});

  @override
  State<LogsScreen> createState() => _LogsScreenState();
}

class _LogsScreenState extends ScopedScreenState<LogsScreen>
    with AppLayoutControlled {
  String _selectedFilter = 'All';

  @override
  void registerServices() {
    // No services needed
  }

  @override
  void onReady() {
    configureLayout(title: 'Activity Logs', showBottomNav: true);
  }

  @override
  Widget build(BuildContext context) {
    // Mock data - will be replaced with actual logs from database
    final allLogs = _getMockLogs();

    // Filter logs based on selected filter
    final filteredLogs = _selectedFilter == 'All'
        ? allLogs
        : allLogs.where((log) => log.category == _selectedFilter).toList();

    // Sort by timestamp descending
    filteredLogs.sort((a, b) => b.timestamp.compareTo(a.timestamp));

    return Column(
      children: [
        // Filter chips
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          color: Colors.white,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildFilterChip('All'),
                const SizedBox(width: 8),
                _buildFilterChip('Tasks'),
                const SizedBox(width: 8),
                _buildFilterChip('Finance'),
              ],
            ),
          ),
        ),

        // Logs list
        Expanded(
          child: filteredLogs.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.history, size: 64, color: Colors.grey[400]),
                      const SizedBox(height: 16),
                      Text(
                        'No activity logs yet',
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Your activity will appear here',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: GCashSpacing.screenPadding,
                  itemCount: filteredLogs.length,
                  itemBuilder: (context, index) {
                    final log = filteredLogs[index];
                    final isToday = _isToday(log.timestamp);
                    final isYesterday = _isYesterday(log.timestamp);

                    // Show date header
                    bool showDateHeader = false;
                    if (index == 0) {
                      showDateHeader = true;
                    } else {
                      final prevLog = filteredLogs[index - 1];
                      if (!_isSameDay(log.timestamp, prevLog.timestamp)) {
                        showDateHeader = true;
                      }
                    }

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (showDateHeader)
                          Padding(
                            padding: const EdgeInsets.only(
                                top: 8, bottom: 12, left: 4),
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
                                    child: Row(
                                      children: [
                                        Text(
                                          log.action,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w600,
                                            fontSize: 14,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 2,
                                          ),
                                          decoration: BoxDecoration(
                                            color: log.category == 'Tasks'
                                                ? Colors.green.withOpacity(0.1)
                                                : Colors.blue.withOpacity(0.1),
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          child: Text(
                                            log.category,
                                            style: TextStyle(
                                              fontSize: 10,
                                              fontWeight: FontWeight.w600,
                                              color: log.category == 'Tasks'
                                                  ? Colors.green[700]
                                                  : Colors.blue[700],
                                            ),
                                          ),
                                        ),
                                      ],
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
        ),
      ],
    );
  }

  Widget _buildFilterChip(String label) {
    final isSelected = _selectedFilter == label;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedFilter = label;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? GCashColors.primary : Colors.grey[200],
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: isSelected ? Colors.white : Colors.grey[700],
          ),
        ),
      ),
    );
  }

  List<UnifiedLog> _getMockLogs() {
    return [
      // Task logs
      UnifiedLog(
        id: '1',
        category: 'Tasks',
        action: 'Created',
        description: 'Complete project proposal',
        timestamp: DateTime.now().subtract(const Duration(hours: 2)),
        icon: Icons.add_circle,
        color: Colors.green,
      ),
      UnifiedLog(
        id: '2',
        category: 'Tasks',
        action: 'Completed',
        description: 'Review documentation',
        timestamp: DateTime.now().subtract(const Duration(hours: 5)),
        icon: Icons.check_circle,
        color: Colors.blue,
      ),
      UnifiedLog(
        id: '3',
        category: 'Tasks',
        action: 'Updated',
        description: 'Design mockups',
        timestamp: DateTime.now().subtract(const Duration(days: 1)),
        icon: Icons.edit,
        color: Colors.orange,
      ),
      UnifiedLog(
        id: '4',
        category: 'Tasks',
        action: 'Deleted',
        description: 'Old meeting notes',
        timestamp: DateTime.now().subtract(const Duration(days: 2)),
        icon: Icons.delete,
        color: Colors.red,
      ),
      // Finance logs
      UnifiedLog(
        id: '5',
        category: 'Finance',
        action: 'Transaction Created',
        description: 'Groceries shopping',
        amount: -2500.00,
        timestamp: DateTime.now().subtract(const Duration(hours: 1)),
        icon: Icons.shopping_cart,
        color: Colors.red,
      ),
      UnifiedLog(
        id: '6',
        category: 'Finance',
        action: 'Income Received',
        description: 'Salary payment',
        amount: 50000.00,
        timestamp: DateTime.now().subtract(const Duration(hours: 3)),
        icon: Icons.arrow_downward,
        color: Colors.green,
      ),
      UnifiedLog(
        id: '7',
        category: 'Finance',
        action: 'Budget Created',
        description: 'Monthly budget for December',
        timestamp: DateTime.now().subtract(const Duration(days: 1)),
        icon: Icons.account_balance,
        color: Colors.blue,
      ),
      UnifiedLog(
        id: '8',
        category: 'Finance',
        action: 'Account Updated',
        description: 'Main wallet balance adjusted',
        timestamp: DateTime.now().subtract(const Duration(days: 2)),
        icon: Icons.account_balance_wallet,
        color: Colors.orange,
      ),
    ];
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
    final hour = date.hour > 12 ? date.hour - 12 : (date.hour == 0 ? 12 : date.hour);
    final minute = date.minute.toString().padLeft(2, '0');
    final period = date.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $period';
  }
}

class UnifiedLog {
  final String id;
  final String category; // 'Tasks' or 'Finance'
  final String action;
  final String description;
  final double? amount;
  final DateTime timestamp;
  final IconData icon;
  final Color color;

  UnifiedLog({
    required this.id,
    required this.category,
    required this.action,
    required this.description,
    this.amount,
    required this.timestamp,
    required this.icon,
    required this.color,
  });
}
