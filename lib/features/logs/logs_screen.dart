import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:keep_track/core/di/service_locator.dart';
import 'package:keep_track/core/settings/utils/currency_formatter.dart';
import 'package:keep_track/core/state/stream_builder_widget.dart';
import 'package:keep_track/core/state/state.dart';
import 'package:keep_track/core/theme/gcash_theme.dart';
import 'package:keep_track/core/ui/app_layout_controller.dart';
import 'package:keep_track/core/ui/ui.dart';
import '../finance/modules/transaction/domain/entities/transaction.dart';
import '../finance/modules/finance_category/domain/entities/finance_category.dart';
import '../finance/modules/finance_category/domain/entities/finance_category_enums.dart';
import '../finance/presentation/state/transaction_controller.dart';
import '../finance/presentation/state/finance_category_controller.dart';

class LogsScreen extends ScopedScreen {
  const LogsScreen({super.key});

  @override
  State<LogsScreen> createState() => _LogsScreenState();
}

class _LogsScreenState extends ScopedScreenState<LogsScreen>
    with AppLayoutControlled {
  late final TransactionController _controller;
  late final FinanceCategoryController _categoryController;
  Map<String, FinanceCategory> _categoriesMap = {};
  String _selectedTypeFilter = 'All'; // All, Income, Expense, Transfer
  int _limit = 50; // Default limit

  @override
  void initState() {
    super.initState();
    _controller = locator.get<TransactionController>();
    _categoryController = locator.get<FinanceCategoryController>();
    _categoryController.loadCategories();
    _loadTransactions();

    // Listen to category updates to build the map
    _categoryController.stream.listen((state) {
      if (state is AsyncData<List<FinanceCategory>>) {
        setState(() {
          _categoriesMap = {for (var cat in state.data) cat.id!: cat};
        });
      }
    });
  }

  Future<void> _loadTransactions() async {
    if (_limit == -1) {
      // Load all transactions
      await _controller.loadAllTransactions();
    } else {
      await _controller.loadRecentTransactions(limit: _limit);
    }
  }

  @override
  void registerServices() {
    // Services already registered in service locator
  }

  @override
  void onReady() {
    configureLayout(title: 'Transaction Logs', showBottomNav: true);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Type filter chips
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
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
        ),

        // Limit control
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          color: Theme.of(context).colorScheme.surface,
          child: Row(
            children: [
              Text(
                'Show:',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withOpacity(0.7),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: DropdownButton<int>(
                  value: _limit,
                  isExpanded: true,
                  underline: Container(
                    height: 1,
                    color: Theme.of(
                      context,
                    ).colorScheme.outline.withOpacity(0.3),
                  ),
                  items: const [
                    DropdownMenuItem(value: 10, child: Text('10 transactions')),
                    DropdownMenuItem(value: 50, child: Text('50 transactions')),
                    DropdownMenuItem(
                      value: 100,
                      child: Text('100 transactions'),
                    ),
                    DropdownMenuItem(
                      value: 500,
                      child: Text('500 transactions'),
                    ),
                    DropdownMenuItem(
                      value: -1,
                      child: Text('All transactions'),
                    ),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => _limit = value);
                      _loadTransactions();
                    }
                  },
                ),
              ),
            ],
          ),
        ),

        // Content based on selected category
        Expanded(child: _buildFinanceLogs()),
      ],
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
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withValues(alpha: 0.7),
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
                onPressed: _loadTransactions,
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
          Icon(
            Icons.history,
            size: 64,
            color: Theme.of(
              context,
            ).colorScheme.onSurface.withValues(alpha: 0.3),
          ),
          const SizedBox(height: 16),
          Text(
            'No transactions yet',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 8),
          Text(
            'Your transactions will appear here',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(
                context,
              ).colorScheme.onSurface.withValues(alpha: 0.6),
            ),
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
          Icon(
            Icons.filter_alt_off,
            size: 64,
            color: Theme.of(
              context,
            ).colorScheme.onSurface.withValues(alpha: 0.3),
          ),
          const SizedBox(height: 16),
          Text(
            'No $_selectedTypeFilter transactions',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 8),
          Text(
            'Try selecting a different filter',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(
                context,
              ).colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionCard(Transaction transaction) {
    // Get category from map
    final category = transaction.financeCategoryId != null
        ? _categoriesMap[transaction.financeCategoryId]
        : null;

    // Get category icon and name
    final categoryIcon = category?.type.icon ?? Icons.category;
    final categoryName = category?.name ?? 'Unknown';

    // Determine color based on transaction type
    final isIncome = transaction.type == TransactionType.income;
    final isExpense = transaction.type == TransactionType.expense;

    final color = isIncome
        ? Colors.green
        : isExpense
        ? Colors.red
        : Colors.blue;

    // Get display amount with sign
    final displayAmount = isExpense
        ? -transaction.totalCost
        : isIncome
        ? transaction.totalCost
        : transaction.amount;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Theme.of(context).colorScheme.surfaceContainer,
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
                // Category Icon
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(categoryIcon, color: color, size: 24),
                ),
                const SizedBox(width: 16),

                // Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Description as title (or category name as fallback)
                      Text(
                        transaction.description ?? categoryName,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      // Category name and type indicator
                      Row(
                        children: [
                          Icon(
                            isIncome
                                ? Icons.arrow_downward
                                : isExpense
                                ? Icons.arrow_upward
                                : Icons.swap_horiz,
                            size: 12,
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurface.withValues(alpha: 0.5),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            categoryName,
                            style: TextStyle(
                              fontSize: 13,
                              color: Theme.of(
                                context,
                              ).colorScheme.onSurface.withValues(alpha: 0.7),
                            ),
                          ),
                          if (transaction.hasFee) ...[
                            const SizedBox(width: 8),
                            Icon(
                              Icons.receipt,
                              size: 12,
                              color: Theme.of(
                                context,
                              ).colorScheme.primary.withValues(alpha: 0.7),
                            ),
                            const SizedBox(width: 2),
                            Text(
                              '+${currencyFormatter.currencySymbol}${transaction.fee.toStringAsFixed(2)} fee',
                              style: TextStyle(
                                fontSize: 11,
                                color: Theme.of(
                                  context,
                                ).colorScheme.primary.withValues(alpha: 0.7),
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Icon(
                            Icons.access_time,
                            size: 12,
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurface.withValues(alpha: 0.5),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            _formatDateTime(transaction.date),
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(
                                  color: Theme.of(context).colorScheme.onSurface
                                      .withValues(alpha: 0.6),
                                  fontSize: 11,
                                ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Amount (with fees included)
                Text(
                  '${isExpense
                      ? '-'
                      : isIncome
                      ? '+'
                      : ''}${currencyFormatter.currencySymbol}${displayAmount.abs().toStringAsFixed(2)}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: isIncome
                        ? Colors.green[700]
                        : isExpense
                        ? Colors.red[700]
                        : Colors.blue[700],
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

  String _formatDateTime(DateTime date) {
    return DateFormat('MMM d, y • h:mm a').format(date);
  }
}
