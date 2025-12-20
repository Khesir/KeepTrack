import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Transactions Tab with Timeline View
class TransactionsTabNew extends StatefulWidget {
  const TransactionsTabNew({super.key});

  @override
  State<TransactionsTabNew> createState() => _TransactionsTabNewState();
}

class _TransactionsTabNewState extends State<TransactionsTabNew> {
  String _filterType = 'All'; // All, Income, Expense

  @override
  Widget build(BuildContext context) {
    final filteredTransactions = _filterType == 'All'
        ? dummyTransactions
        : dummyTransactions.where((t) => t.type == _filterType).toList();

    // Group transactions by date
    final groupedTransactions = _groupTransactionsByDate(filteredTransactions);

    return Column(
      children: [
        // Filter Chips
        _buildFilterChips(),

        // Transactions List
        Expanded(
          child: filteredTransactions.isEmpty
              ? _buildEmptyState()
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: groupedTransactions.length,
                  itemBuilder: (context, index) {
                    final entry = groupedTransactions.entries.elementAt(index);
                    return _buildDateGroup(entry.key, entry.value);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildFilterChips() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          _buildFilterChip('All'),
          const SizedBox(width: 8),
          _buildFilterChip('Income'),
          const SizedBox(width: 8),
          _buildFilterChip('Expense'),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label) {
    final isSelected = _filterType == label;
    Color? chipColor;

    if (label == 'Income') {
      chipColor = Colors.green[700];
    } else if (label == 'Expense') {
      chipColor = Colors.red[700];
    }

    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() => _filterType = label);
      },
      backgroundColor: isSelected && chipColor != null
          ? chipColor.withOpacity(0.1)
          : null,
      selectedColor: isSelected && chipColor != null
          ? chipColor.withOpacity(0.2)
          : Theme.of(context).colorScheme.primary.withOpacity(0.1),
      labelStyle: TextStyle(
        color: isSelected && chipColor != null
            ? chipColor
            : isSelected
                ? Theme.of(context).colorScheme.primary
                : Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
      ),
      checkmarkColor: chipColor,
      side: BorderSide(
        color: isSelected && chipColor != null
            ? chipColor
            : isSelected
                ? Theme.of(context).colorScheme.primary
                : Theme.of(context).colorScheme.outline.withOpacity(0.3),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.receipt_long,
            size: 64,
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.3),
          ),
          const SizedBox(height: 16),
          Text(
            'No transactions found',
            style: TextStyle(
              fontSize: 16,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
            ),
          ),
        ],
      ),
    );
  }

  Map<String, List<TransactionItem>> _groupTransactionsByDate(
      List<TransactionItem> transactions) {
    final Map<String, List<TransactionItem>> grouped = {};

    for (final transaction in transactions) {
      final dateKey = _getDateGroupKey(transaction.date);
      if (!grouped.containsKey(dateKey)) {
        grouped[dateKey] = [];
      }
      grouped[dateKey]!.add(transaction);
    }

    return grouped;
  }

  String _getDateGroupKey(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final transactionDate = DateTime(date.year, date.month, date.day);

    if (transactionDate == today) {
      return 'Today';
    } else if (transactionDate == yesterday) {
      return 'Yesterday';
    } else if (now.difference(date).inDays < 7) {
      return DateFormat('EEEE').format(date);
    } else if (date.year == now.year) {
      return DateFormat('MMMM d').format(date);
    } else {
      return DateFormat('MMM d, yyyy').format(date);
    }
  }

  Widget _buildDateGroup(String dateLabel, List<TransactionItem> transactions) {
    final totalForDay = transactions.fold<double>(
      0,
      (sum, t) => sum + (t.type == 'Income' ? t.amount : -t.amount),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Date Header
        Padding(
          padding: const EdgeInsets.only(bottom: 12, top: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                dateLabel,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                NumberFormat.currency(symbol: '₱', decimalDigits: 0).format(totalForDay.abs()),
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: totalForDay >= 0 ? Colors.green[700] : Colors.red[700],
                ),
              ),
            ],
          ),
        ),

        // Transactions for this date
        ...transactions.map((transaction) => _buildTransactionCard(transaction)),

        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildTransactionCard(TransactionItem transaction) {
    final isIncome = transaction.type == 'Income';
    final color = isIncome ? Colors.green[700]! : Colors.red[700]!;

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: () {
          // Show transaction details
          _showTransactionDetails(transaction);
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Icon
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  transaction.icon,
                  color: color,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),

              // Transaction Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            transaction.description,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        Text(
                          '${isIncome ? '+' : '-'}${NumberFormat.currency(symbol: '₱', decimalDigits: 0).format(transaction.amount)}',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: color,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            transaction.category,
                            style: TextStyle(
                              fontSize: 12,
                              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                            ),
                          ),
                        ),
                        Text(
                          DateFormat('HH:mm').format(transaction.date),
                          style: TextStyle(
                            fontSize: 12,
                            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                          ),
                        ),
                      ],
                    ),
                    if (transaction.account != null) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.account_balance_wallet,
                            size: 12,
                            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            transaction.account!,
                            style: TextStyle(
                              fontSize: 11,
                              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showTransactionDetails(TransactionItem transaction) {
    final isIncome = transaction.type == 'Income';
    final color = isIncome ? Colors.green[700]! : Colors.red[700]!;

    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    transaction.icon,
                    color: color,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        transaction.description,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        transaction.category,
                        style: TextStyle(
                          fontSize: 14,
                          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Amount
            Text(
              'Amount',
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '${isIncome ? '+' : '-'}${NumberFormat.currency(symbol: '₱', decimalDigits: 2).format(transaction.amount)}',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 24),

            // Details
            _buildDetailRow('Date', DateFormat('MMMM d, yyyy').format(transaction.date)),
            _buildDetailRow('Time', DateFormat('HH:mm').format(transaction.date)),
            if (transaction.account != null)
              _buildDetailRow('Account', transaction.account!),
            _buildDetailRow('Type', transaction.type),
            if (transaction.notes != null)
              _buildDetailRow('Notes', transaction.notes!),

            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

// Transaction Data Class
class TransactionItem {
  final String id;
  final String description;
  final String category;
  final double amount;
  final String type; // Income or Expense
  final DateTime date;
  final IconData icon;
  final String? account;
  final String? notes;

  TransactionItem({
    required this.id,
    required this.description,
    required this.category,
    required this.amount,
    required this.type,
    required this.date,
    required this.icon,
    this.account,
    this.notes,
  });
}

// Dummy Transaction Data
final dummyTransactions = [
  // Today
  TransactionItem(
    id: '1',
    description: 'Grocery Shopping',
    category: 'Food & Dining',
    amount: 2500,
    type: 'Expense',
    date: DateTime.now().subtract(const Duration(hours: 2)),
    icon: Icons.shopping_cart,
    account: 'Main Wallet',
    notes: 'Weekly groceries',
  ),
  TransactionItem(
    id: '2',
    description: 'Freelance Project Payment',
    category: 'Income',
    amount: 15000,
    type: 'Income',
    date: DateTime.now().subtract(const Duration(hours: 5)),
    icon: Icons.attach_money,
    account: 'Main Wallet',
  ),
  TransactionItem(
    id: '3',
    description: 'Lunch at Restaurant',
    category: 'Food & Dining',
    amount: 450,
    type: 'Expense',
    date: DateTime.now().subtract(const Duration(hours: 6)),
    icon: Icons.restaurant,
    account: 'Credit Card',
  ),

  // Yesterday
  TransactionItem(
    id: '4',
    description: 'Gas Station',
    category: 'Transportation',
    amount: 1200,
    type: 'Expense',
    date: DateTime.now().subtract(const Duration(days: 1, hours: 3)),
    icon: Icons.local_gas_station,
    account: 'Main Wallet',
  ),
  TransactionItem(
    id: '5',
    description: 'Online Shopping',
    category: 'Shopping',
    amount: 3500,
    type: 'Expense',
    date: DateTime.now().subtract(const Duration(days: 1, hours: 10)),
    icon: Icons.shopping_bag,
    account: 'Credit Card',
  ),

  // 2 days ago
  TransactionItem(
    id: '6',
    description: 'Salary',
    category: 'Income',
    amount: 45000,
    type: 'Income',
    date: DateTime.now().subtract(const Duration(days: 2)),
    icon: Icons.work,
    account: 'Savings Account',
  ),
  TransactionItem(
    id: '7',
    description: 'Electric Bill',
    category: 'Utilities',
    amount: 2800,
    type: 'Expense',
    date: DateTime.now().subtract(const Duration(days: 2, hours: 5)),
    icon: Icons.electrical_services,
    account: 'Main Wallet',
  ),

  // 3 days ago
  TransactionItem(
    id: '8',
    description: 'Movie Tickets',
    category: 'Entertainment',
    amount: 800,
    type: 'Expense',
    date: DateTime.now().subtract(const Duration(days: 3)),
    icon: Icons.movie,
    account: 'Credit Card',
  ),
  TransactionItem(
    id: '9',
    description: 'Coffee Shop',
    category: 'Food & Dining',
    amount: 250,
    type: 'Expense',
    date: DateTime.now().subtract(const Duration(days: 3, hours: 8)),
    icon: Icons.coffee,
    account: 'Main Wallet',
  ),

  // 5 days ago
  TransactionItem(
    id: '10',
    description: 'Pharmacy',
    category: 'Healthcare',
    amount: 1200,
    type: 'Expense',
    date: DateTime.now().subtract(const Duration(days: 5)),
    icon: Icons.medical_services,
    account: 'Main Wallet',
  ),
  TransactionItem(
    id: '11',
    description: 'Book Purchase',
    category: 'Education',
    amount: 850,
    type: 'Expense',
    date: DateTime.now().subtract(const Duration(days: 5, hours: 4)),
    icon: Icons.book,
    account: 'Credit Card',
  ),

  // 7 days ago
  TransactionItem(
    id: '12',
    description: 'Investment Dividend',
    category: 'Income',
    amount: 5000,
    type: 'Income',
    date: DateTime.now().subtract(const Duration(days: 7)),
    icon: Icons.trending_up,
    account: 'Investment Fund',
  ),
];
