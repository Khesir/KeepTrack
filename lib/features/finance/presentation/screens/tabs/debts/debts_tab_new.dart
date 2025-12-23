import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Debts Tab - Tracks Lending (money lent out) and Borrowing (money owed)
class DebtsTabNew extends StatefulWidget {
  const DebtsTabNew({super.key});

  @override
  State<DebtsTabNew> createState() => _DebtsTabNewState();
}

class _DebtsTabNewState extends State<DebtsTabNew> {
  String _selectedFilter = 'All'; // All, Lending, Borrowing

  @override
  Widget build(BuildContext context) {
    // Calculate totals
    final totalLending = dummyDebts
        .where((d) => d.type == DebtType.lending)
        .fold<double>(0, (sum, debt) => sum + debt.remainingAmount);

    final totalBorrowing = dummyDebts
        .where((d) => d.type == DebtType.borrowing)
        .fold<double>(0, (sum, debt) => sum + debt.remainingAmount);

    // Filter debts
    final filteredDebts = _selectedFilter == 'All'
        ? dummyDebts
        : dummyDebts.where((d) =>
            _selectedFilter == 'Lending'
              ? d.type == DebtType.lending
              : d.type == DebtType.borrowing
          ).toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Summary Cards Row
          Row(
            children: [
              Expanded(
                child: _buildSummaryCard(
                  'Lending',
                  totalLending,
                  Colors.green,
                  Icons.arrow_upward,
                  'Money you lent',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildSummaryCard(
                  'Borrowing',
                  totalBorrowing,
                  Colors.red,
                  Icons.arrow_downward,
                  'Money you owe',
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Net Balance Card
          _buildNetBalanceCard(totalLending - totalBorrowing),
          const SizedBox(height: 24),

          // Filter Chips
          Row(
            children: [
              _buildFilterChip('All'),
              const SizedBox(width: 8),
              _buildFilterChip('Lending'),
              const SizedBox(width: 8),
              _buildFilterChip('Borrowing'),
              const Spacer(),
              Text(
                '${filteredDebts.length} ${filteredDebts.length == 1 ? 'debt' : 'debts'}',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Debts List
          if (filteredDebts.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(48),
                child: Column(
                  children: [
                    Icon(
                      Icons.receipt_long_outlined,
                      size: 64,
                      color: Colors.grey[300],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No debts found',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: filteredDebts.length,
              itemBuilder: (context, index) {
                final debt = filteredDebts[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _buildDebtCard(debt),
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(
    String title,
    double amount,
    Color color,
    IconData icon,
    String subtitle,
  ) {
    return Card(
      elevation: 0,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [color.withOpacity(0.7), color],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: Colors.white, size: 18),
                ),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              NumberFormat.currency(symbol: '₱', decimalDigits: 2).format(amount),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNetBalanceCard(double netBalance) {
    final isPositive = netBalance >= 0;
    return Card(
      elevation: 0,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isPositive
              ? [Colors.blue[700]!, Colors.blue[500]!]
              : [Colors.orange[700]!, Colors.orange[500]!],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(
                isPositive ? Icons.trending_up : Icons.trending_down,
                color: Colors.white,
                size: 28,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Net Balance',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    NumberFormat.currency(symbol: '₱', decimalDigits: 2).format(netBalance.abs()),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    isPositive ? 'You are owed more' : 'You owe more',
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label) {
    final isSelected = _selectedFilter == label;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _selectedFilter = label;
        });
      },
      selectedColor: Theme.of(context).colorScheme.primary.withOpacity(0.2),
      checkmarkColor: Theme.of(context).colorScheme.primary,
      labelStyle: TextStyle(
        color: isSelected
          ? Theme.of(context).colorScheme.primary
          : Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
    );
  }

  Widget _buildDebtCard(DebtItem debt) {
    final isLending = debt.type == DebtType.lending;
    final color = isLending ? Colors.green : Colors.red;
    final progress = debt.originalAmount > 0
      ? (debt.originalAmount - debt.remainingAmount) / debt.originalAmount
      : 0.0;

    return Card(
      elevation: 0,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          // Navigate to debt detail
        },
        child: Container(
          decoration: BoxDecoration(
            border: Border(
              left: BorderSide(
                color: color,
                width: 4,
              ),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        isLending ? Icons.call_made : Icons.call_received,
                        color: color,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            debt.personName,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            debt.description,
                            style: TextStyle(
                              fontSize: 13,
                              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: _getStatusColor(debt.status).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        _getStatusText(debt.status),
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: _getStatusColor(debt.status),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Amount Info
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Remaining',
                            style: TextStyle(
                              fontSize: 11,
                              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            NumberFormat.currency(symbol: '₱', decimalDigits: 2)
                                .format(debt.remainingAmount),
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: color,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          'Original',
                          style: TextStyle(
                            fontSize: 11,
                            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          NumberFormat.currency(symbol: '₱', decimalDigits: 2)
                              .format(debt.originalAmount),
                          style: TextStyle(
                            fontSize: 16,
                            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Progress Bar
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Repayment Progress',
                          style: TextStyle(
                            fontSize: 11,
                            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                          ),
                        ),
                        Text(
                          '${(progress * 100).toStringAsFixed(0)}%',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: color,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: progress,
                        backgroundColor: color.withOpacity(0.1),
                        valueColor: AlwaysStoppedAnimation<Color>(color),
                        minHeight: 6,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Details Row
                Row(
                  children: [
                    Icon(
                      Icons.calendar_today,
                      size: 14,
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Started: ${DateFormat('MMM d, yyyy').format(debt.startDate)}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                      ),
                    ),
                    if (debt.dueDate != null) ...[
                      const SizedBox(width: 16),
                      Icon(
                        Icons.event,
                        size: 14,
                        color: _getDueDateColor(debt.dueDate!),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Due: ${DateFormat('MMM d, yyyy').format(debt.dueDate!)}',
                        style: TextStyle(
                          fontSize: 12,
                          color: _getDueDateColor(debt.dueDate!),
                          fontWeight: _isOverdue(debt.dueDate!) ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Color _getStatusColor(DebtStatus status) {
    switch (status) {
      case DebtStatus.active:
        return Colors.blue;
      case DebtStatus.overdue:
        return Colors.red;
      case DebtStatus.settled:
        return Colors.green;
    }
  }

  String _getStatusText(DebtStatus status) {
    switch (status) {
      case DebtStatus.active:
        return 'Active';
      case DebtStatus.overdue:
        return 'Overdue';
      case DebtStatus.settled:
        return 'Settled';
    }
  }

  Color _getDueDateColor(DateTime dueDate) {
    if (_isOverdue(dueDate)) {
      return Colors.red;
    }
    final daysUntilDue = dueDate.difference(DateTime.now()).inDays;
    if (daysUntilDue <= 7) {
      return Colors.orange;
    }
    return Theme.of(context).colorScheme.onSurface.withOpacity(0.5);
  }

  bool _isOverdue(DateTime dueDate) {
    return dueDate.isBefore(DateTime.now());
  }
}

// Debt Type Enum
enum DebtType { lending, borrowing }

// Debt Status Enum
enum DebtStatus { active, overdue, settled }

// Debt Data Class
class DebtItem {
  final String id;
  final DebtType type;
  final String personName;
  final String description;
  final double originalAmount;
  final double remainingAmount;
  final DateTime startDate;
  final DateTime? dueDate;
  final DebtStatus status;
  final String? notes;

  DebtItem({
    required this.id,
    required this.type,
    required this.personName,
    required this.description,
    required this.originalAmount,
    required this.remainingAmount,
    required this.startDate,
    this.dueDate,
    this.status = DebtStatus.active,
    this.notes,
  });
}

// Dummy Debt Data
final dummyDebts = [
  DebtItem(
    id: '1',
    type: DebtType.lending,
    personName: 'Juan Dela Cruz',
    description: 'Emergency loan',
    originalAmount: 15000.00,
    remainingAmount: 10000.00,
    startDate: DateTime(2024, 11, 1),
    dueDate: DateTime(2025, 3, 1),
    status: DebtStatus.active,
  ),
  DebtItem(
    id: '2',
    type: DebtType.borrowing,
    personName: 'Maria Santos',
    description: 'Business capital',
    originalAmount: 50000.00,
    remainingAmount: 35000.00,
    startDate: DateTime(2024, 10, 15),
    dueDate: DateTime(2025, 4, 15),
    status: DebtStatus.active,
  ),
  DebtItem(
    id: '3',
    type: DebtType.lending,
    personName: 'Pedro Garcia',
    description: 'Personal loan',
    originalAmount: 8000.00,
    remainingAmount: 2000.00,
    startDate: DateTime(2024, 9, 20),
    dueDate: DateTime(2024, 12, 20),
    status: DebtStatus.active,
  ),
  DebtItem(
    id: '4',
    type: DebtType.borrowing,
    personName: 'Bank Loan',
    description: 'Car loan installment',
    originalAmount: 200000.00,
    remainingAmount: 150000.00,
    startDate: DateTime(2024, 6, 1),
    dueDate: DateTime(2026, 6, 1),
    status: DebtStatus.active,
  ),
  DebtItem(
    id: '5',
    type: DebtType.lending,
    personName: 'Ana Reyes',
    description: 'School tuition help',
    originalAmount: 12000.00,
    remainingAmount: 12000.00,
    startDate: DateTime(2024, 11, 15),
    dueDate: DateTime(2024, 12, 15),
    status: DebtStatus.overdue,
  ),
  DebtItem(
    id: '6',
    type: DebtType.borrowing,
    personName: 'Credit Card',
    description: 'Outstanding balance',
    originalAmount: 25000.00,
    remainingAmount: 18000.00,
    startDate: DateTime(2024, 10, 1),
    dueDate: DateTime(2025, 1, 31),
    status: DebtStatus.active,
  ),
  DebtItem(
    id: '7',
    type: DebtType.lending,
    personName: 'Roberto Cruz',
    description: 'Startup investment',
    originalAmount: 30000.00,
    remainingAmount: 0.00,
    startDate: DateTime(2024, 7, 1),
    dueDate: DateTime(2024, 11, 1),
    status: DebtStatus.settled,
  ),
];
