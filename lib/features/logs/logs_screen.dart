import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:persona_codex/core/di/service_locator.dart';
import 'package:persona_codex/core/state/stream_builder_widget.dart';
import 'package:persona_codex/core/theme/gcash_theme.dart';
import 'package:persona_codex/core/ui/app_layout_controller.dart';
import 'package:persona_codex/core/ui/ui.dart';
import '../finance/modules/transaction/domain/entities/transaction.dart';
import '../finance/presentation/state/transaction_controller.dart';

class LogsScreen extends ScopedScreen {
  const LogsScreen({super.key});

  @override
  State<LogsScreen> createState() => _LogsScreenState();
}

class _LogsScreenState extends ScopedScreenState<LogsScreen>
    with AppLayoutControlled {
  late final TransactionController _controller;
  String _selectedCategory = 'All'; // All, Tasks, Finance
  String _selectedTypeFilter =
      'All'; // All, Income, Expense, Transfer (only for Finance)

  @override
  void initState() {
    super.initState();
    _controller = locator.get<TransactionController>();
  }

  @override
  void registerServices() {
    // Services already registered in service locator
  }

  @override
  void onReady() {
    configureLayout(title: 'Activity Logs', showBottomNav: true);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Category filter chips
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          color: Colors.white,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildCategoryChip('All'),
                const SizedBox(width: 8),
                _buildCategoryChip('Tasks'),
                const SizedBox(width: 8),
                _buildCategoryChip('Finance'),
              ],
            ),
          ),
        ),

        // Type filter chips (only show for Finance category)
        if (_selectedCategory == 'Finance')
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: Colors.grey[50],
            child: Row(
              children: [
                _buildTypeFilterChip('All'),
                const SizedBox(width: 8),
                _buildTypeFilterChip('Income'),
                const SizedBox(width: 8),
                _buildTypeFilterChip('Expense'),
                const SizedBox(width: 8),
                _buildTypeFilterChip('Transfer'),
              ],
            ),
          ),

        // Content based on selected category
        Expanded(
          child: _selectedCategory == 'Tasks'
              ? _buildComingSoon('Tasks', Icons.task_alt)
              : _buildFinanceLogs(),
        ),
      ],
    );
  }

  Widget _buildCategoryChip(String label) {
    final isSelected = _selectedCategory == label;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedCategory = label;
          // Reset type filter when changing category
          _selectedTypeFilter = 'All';
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

  Widget _buildTypeFilterChip(String label) {
    final isSelected = _selectedTypeFilter == label;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _selectedTypeFilter = label;
        });
      },
      selectedColor: Theme.of(context).colorScheme.primary.withOpacity(0.2),
      checkmarkColor: Theme.of(context).colorScheme.primary,
      labelStyle: TextStyle(
        color: isSelected
            ? Theme.of(context).colorScheme.primary
            : Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        fontSize: 13,
      ),
    );
  }

  Widget _buildComingSoon(String feature, IconData icon) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: GCashColors.primary.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 64, color: GCashColors.primary),
          ),
          const SizedBox(height: 24),
          Text(
            '$feature Logs',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Coming Soon',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: GCashColors.primary,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.orange[50],
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.construction, size: 18, color: Colors.orange[700]),
                const SizedBox(width: 8),
                Text(
                  'Under Development',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.orange[700],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFinanceLogs() {
    return AsyncStreamBuilder<List<Transaction>>(
      state: _controller,
      builder: (context, transactions) {
        // Filter by transaction type
        final filteredTransactions = _getFilteredTransactions(transactions);

        if (transactions.isEmpty) {
          return _buildEmptyState();
        }

        // Sort by date descending
        final sortedTransactions = List<Transaction>.from(filteredTransactions)
          ..sort((a, b) => b.date.compareTo(a.date));

        if (sortedTransactions.isEmpty) {
          return _buildEmptyFilterState();
        }

        return ListView.builder(
          padding: GCashSpacing.screenPadding,
          itemCount: sortedTransactions.length,
          itemBuilder: (context, index) {
            final transaction = sortedTransactions[index];
            final isToday = _isToday(transaction.date);
            final isYesterday = _isYesterday(transaction.date);

            // Show date header
            bool showDateHeader = false;
            if (index == 0) {
              showDateHeader = true;
            } else {
              final prevTransaction = sortedTransactions[index - 1];
              if (!_isSameDay(transaction.date, prevTransaction.date)) {
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
                          : _formatDate(transaction.date),
                      style: GCashTextStyles.h3.copyWith(
                        color: Colors.grey[700],
                      ),
                    ),
                  ),
                _buildTransactionCard(transaction),
              ],
            );
          },
        );
      },
      loadingBuilder: (_) => const Center(
        child: Padding(
          padding: EdgeInsets.all(32.0),
          child: CircularProgressIndicator(),
        ),
      ),
      errorBuilder: (context, message) => Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
              const SizedBox(height: 16),
              Text(
                'Error loading transactions',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Text(
                message,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withOpacity(0.6),
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () => _controller.loadRecentTransactions(),
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<Transaction> _getFilteredTransactions(List<Transaction> transactions) {
    switch (_selectedTypeFilter) {
      case 'Income':
        return transactions
            .where((t) => t.type == TransactionType.income)
            .toList();
      case 'Expense':
        return transactions
            .where((t) => t.type == TransactionType.expense)
            .toList();
      case 'Transfer':
        return transactions
            .where((t) => t.type == TransactionType.transfer)
            .toList();
      case 'All':
      default:
        return transactions;
    }
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.history, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'No transactions yet',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Your transactions will appear here',
            style: TextStyle(color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyFilterState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.filter_alt_off, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'No $_selectedTypeFilter transactions',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Try selecting a different filter',
            style: TextStyle(color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionCard(Transaction transaction) {
    // Determine icon and color based on transaction type
    IconData icon;
    Color color;

    switch (transaction.type) {
      case TransactionType.income:
        icon = Icons.arrow_downward;
        color = Colors.green;
        break;
      case TransactionType.expense:
        icon = Icons.shopping_cart;
        color = Colors.red;
        break;
      case TransactionType.transfer:
        icon = Icons.swap_horiz;
        color = Colors.blue;
        break;
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: () {
            // Navigate to transaction detail
          },
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Icon
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: color, size: 24),
                ),
                const SizedBox(width: 16),

                // Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            transaction.type.displayName,
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
                              color: Colors.blue.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              'Finance',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: Colors.blue[700],
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      if (transaction.description != null)
                        Text(
                          transaction.description!,
                          style: const TextStyle(fontSize: 13),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      const SizedBox(height: 4),
                      Text(
                        _formatTime(transaction.date),
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),

                // Amount
                Text(
                  '₱${transaction.amount.abs().toStringAsFixed(2)}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: transaction.type == TransactionType.income
                        ? Colors.green[700]
                        : Colors.red[700],
                  ),
                ),
              ],
            ),
          ),
        ),
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
    return DateFormat('MMM d, y').format(date);
  }

  String _formatTime(DateTime date) {
    return DateFormat('h:mm a').format(date);
  }
}
