import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:persona_codex/core/di/service_locator.dart';
import 'package:persona_codex/core/state/stream_builder_widget.dart';
import 'package:persona_codex/core/state/state.dart';
import '../../../modules/transaction/domain/entities/transaction.dart' as finance_transaction;
import '../../../modules/finance_category/domain/entities/finance_category.dart';
import '../../../modules/finance_category/domain/entities/finance_category_enums.dart';
import '../../state/transaction_controller.dart';
import '../../state/finance_category_controller.dart';

class FinanceLogsTab extends StatefulWidget {
  const FinanceLogsTab({super.key});

  @override
  State<FinanceLogsTab> createState() => _FinanceLogsTabState();
}

class _FinanceLogsTabState extends State<FinanceLogsTab> {
  late final TransactionController _transactionController;
  late final FinanceCategoryController _categoryController;
  Map<String, FinanceCategory> _categoriesMap = {};

  @override
  void initState() {
    super.initState();
    _transactionController = locator.get<TransactionController>();
    _categoryController = locator.get<FinanceCategoryController>();
    _transactionController.loadRecentTransactions();
    _categoryController.loadCategories();

    // Listen to category updates to build the map
    _categoryController.stream.listen((state) {
      if (state is AsyncData<List<FinanceCategory>>) {
        setState(() {
          _categoriesMap = {
            for (var cat in state.data) cat.id!: cat
          };
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return AsyncStreamBuilder<List<finance_transaction.Transaction>>(
      state: _transactionController,
      loadingBuilder: (context) => const Center(
        child: CircularProgressIndicator(),
      ),
      errorBuilder: (context, message) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red.withOpacity(0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'Error loading transactions',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.error,
                  ),
            ),
          ],
        ),
      ),
      builder: (context, transactions) {
        if (transactions.isEmpty) {
          return _buildEmptyState(context);
        }

        return _buildTransactionList(context, transactions);
      },
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
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
            'No transactions yet',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Your transaction history will appear here',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionList(
    BuildContext context,
    List<finance_transaction.Transaction> transactions,
  ) {
    // Sort by date descending (newest first)
    final sortedTransactions = List<finance_transaction.Transaction>.from(transactions)
      ..sort((a, b) => b.date.compareTo(a.date));

    return ListView.builder(
      padding: const EdgeInsets.all(16),
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

        // Get transaction type info
        final isIncome = transaction.type == finance_transaction.TransactionType.income;
        final isExpense = transaction.type == finance_transaction.TransactionType.expense;

        // Determine colors
        final color = isIncome
            ? Colors.green
            : isExpense
                ? Colors.red
                : Colors.blue;

        // Get category from map
        final category = transaction.financeCategoryId != null
            ? _categoriesMap[transaction.financeCategoryId]
            : null;

        // Get category icon and name
        final categoryIcon = category?.type.icon ?? Icons.category;
        final categoryName = category?.name ?? 'Unknown';

        // Get display amount with sign
        final displayAmount = isExpense
            ? -transaction.totalCost
            : isIncome
                ? transaction.totalCost
                : transaction.amount;

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
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
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
                    // Navigate to transaction detail if needed
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        // Category icon
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: color.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(categoryIcon, color: color, size: 24),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  // Description as title
                                  Expanded(
                                    child: Text(
                                      transaction.description ?? categoryName,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 15,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  // Amount
                                  Text(
                                    NumberFormat.currency(
                                      symbol: '₱',
                                      decimalDigits: 2,
                                    ).format(displayAmount.abs()),
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
                              const SizedBox(height: 6),
                              // Category name as subtitle
                              Row(
                                children: [
                                  Icon(
                                    isIncome
                                        ? Icons.arrow_downward
                                        : isExpense
                                            ? Icons.arrow_upward
                                            : Icons.swap_horiz,
                                    size: 12,
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurface
                                        .withOpacity(0.5),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    categoryName,
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurface
                                          .withOpacity(0.7),
                                    ),
                                  ),
                                  if (transaction.hasFee) ...[
                                    const SizedBox(width: 8),
                                    Icon(
                                      Icons.receipt,
                                      size: 12,
                                      color: Theme.of(context)
                                          .colorScheme
                                          .primary
                                          .withOpacity(0.7),
                                    ),
                                    const SizedBox(width: 2),
                                    Text(
                                      '+₱${transaction.fee.toStringAsFixed(2)} fee',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: Theme.of(context)
                                            .colorScheme
                                            .primary
                                            .withOpacity(0.7),
                                        fontStyle: FontStyle.italic,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                              const SizedBox(height: 4),
                              // Time
                              Text(
                                _formatTime(transaction.date),
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
    final hour = date.hour == 0 ? 12 : (date.hour > 12 ? date.hour - 12 : date.hour);
    final minute = date.minute.toString().padLeft(2, '0');
    final period = date.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $period';
  }
}
