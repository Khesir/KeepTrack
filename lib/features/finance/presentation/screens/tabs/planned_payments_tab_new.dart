import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Planned Payments Tab - Tracks recurring and scheduled payments
class PlannedPaymentsTabNew extends StatefulWidget {
  const PlannedPaymentsTabNew({super.key});

  @override
  State<PlannedPaymentsTabNew> createState() => _PlannedPaymentsTabNewState();
}

class _PlannedPaymentsTabNewState extends State<PlannedPaymentsTabNew> {
  String _selectedFilter = 'All'; // All, Active, Upcoming, Paused

  @override
  Widget build(BuildContext context) {
    // Calculate monthly total
    final monthlyTotal = dummyPlannedPayments
        .where((p) => p.status == PaymentStatus.active)
        .fold<double>(0, (sum, payment) => sum + payment.amount);

    // Get upcoming payments (next 7 days)
    final now = DateTime.now();
    final upcomingPayments = dummyPlannedPayments
        .where((p) =>
            p.status == PaymentStatus.active &&
            p.nextPaymentDate.isAfter(now) &&
            p.nextPaymentDate.isBefore(now.add(const Duration(days: 7))))
        .toList();

    // Filter payments
    final filteredPayments = _selectedFilter == 'All'
        ? dummyPlannedPayments
        : _selectedFilter == 'Active'
            ? dummyPlannedPayments
                .where((p) => p.status == PaymentStatus.active)
                .toList()
            : _selectedFilter == 'Upcoming'
                ? upcomingPayments
                : dummyPlannedPayments
                    .where((p) => p.status == PaymentStatus.paused)
                    .toList();

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
                  'Monthly Total',
                  monthlyTotal,
                  Colors.purple,
                  Icons.calendar_month,
                  '${dummyPlannedPayments.where((p) => p.status == PaymentStatus.active).length} active payments',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildSummaryCard(
                  'Upcoming',
                  upcomingPayments.fold<double>(
                      0, (sum, p) => sum + p.amount),
                  Colors.orange,
                  Icons.notifications_active,
                  '${upcomingPayments.length} in next 7 days',
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Upcoming Payments Alert
          if (upcomingPayments.isNotEmpty) ...[
            _buildUpcomingAlert(upcomingPayments),
            const SizedBox(height: 24),
          ],

          // Filter Chips
          Row(
            children: [
              _buildFilterChip('All'),
              const SizedBox(width: 8),
              _buildFilterChip('Active'),
              const SizedBox(width: 8),
              _buildFilterChip('Upcoming'),
              const SizedBox(width: 8),
              _buildFilterChip('Paused'),
              const Spacer(),
              Text(
                '${filteredPayments.length} ${filteredPayments.length == 1 ? 'payment' : 'payments'}',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Payments List
          if (filteredPayments.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(48),
                child: Column(
                  children: [
                    Icon(
                      Icons.event_available_outlined,
                      size: 64,
                      color: Colors.grey[300],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No planned payments found',
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
              itemCount: filteredPayments.length,
              itemBuilder: (context, index) {
                final payment = filteredPayments[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _buildPaymentCard(payment),
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
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
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
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUpcomingAlert(List<PlannedPaymentItem> upcomingPayments) {
    return Card(
      elevation: 0,
      color: Colors.orange[50],
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.orange[100],
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.notification_important,
                color: Colors.orange[700],
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Upcoming Payments',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.orange[900],
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'You have ${upcomingPayments.length} ${upcomingPayments.length == 1 ? 'payment' : 'payments'} due in the next 7 days',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.orange[800],
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: Colors.orange[700],
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

  Widget _buildPaymentCard(PlannedPaymentItem payment) {
    final daysUntilPayment = payment.nextPaymentDate.difference(DateTime.now()).inDays;
    final isUpcoming = daysUntilPayment >= 0 && daysUntilPayment <= 7;
    final isOverdue = daysUntilPayment < 0;

    return Card(
      elevation: 0,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          // Navigate to payment detail
        },
        child: Container(
          decoration: BoxDecoration(
            border: Border(
              left: BorderSide(
                color: _getCategoryColor(payment.category),
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
                        color: _getCategoryColor(payment.category).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        _getCategoryIcon(payment.category),
                        color: _getCategoryColor(payment.category),
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            payment.name,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            payment.payee,
                            style: TextStyle(
                              fontSize: 13,
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurface
                                  .withOpacity(0.6),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: _getStatusColor(payment.status).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        _getStatusText(payment.status),
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: _getStatusColor(payment.status),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Amount and Next Payment
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Amount',
                            style: TextStyle(
                              fontSize: 11,
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurface
                                  .withOpacity(0.6),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            NumberFormat.currency(symbol: '₱', decimalDigits: 2)
                                .format(payment.amount),
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: _getCategoryColor(payment.category),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          'Next Payment',
                          style: TextStyle(
                            fontSize: 11,
                            color: Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withOpacity(0.6),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          DateFormat('MMM d, yyyy').format(payment.nextPaymentDate),
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: isOverdue
                                ? Colors.red
                                : isUpcoming
                                    ? Colors.orange
                                    : Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                        if (isUpcoming || isOverdue)
                          Text(
                            isOverdue
                                ? 'Overdue!'
                                : 'In ${daysUntilPayment} ${daysUntilPayment == 1 ? 'day' : 'days'}',
                            style: TextStyle(
                              fontSize: 11,
                              color: isOverdue ? Colors.red : Colors.orange,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Frequency and Account
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.blue[50],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.repeat,
                            size: 14,
                            color: Colors.blue[700],
                          ),
                          const SizedBox(width: 4),
                          Text(
                            _getFrequencyText(payment.frequency),
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: Colors.blue[700],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(
                      Icons.account_balance_wallet,
                      size: 14,
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      payment.accountName,
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Last Payment
                if (payment.lastPaymentDate != null) ...[
                  const Divider(height: 1),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Icon(
                        Icons.check_circle,
                        size: 14,
                        color: Colors.green[600],
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Last paid: ${DateFormat('MMM d, yyyy').format(payment.lastPaymentDate!)}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Color _getCategoryColor(PaymentCategory category) {
    switch (category) {
      case PaymentCategory.bills:
        return Colors.blue;
      case PaymentCategory.subscriptions:
        return Colors.purple;
      case PaymentCategory.insurance:
        return Colors.green;
      case PaymentCategory.loan:
        return Colors.red;
      case PaymentCategory.rent:
        return Colors.orange;
      case PaymentCategory.utilities:
        return Colors.teal;
      case PaymentCategory.other:
        return Colors.grey;
    }
  }

  IconData _getCategoryIcon(PaymentCategory category) {
    switch (category) {
      case PaymentCategory.bills:
        return Icons.receipt;
      case PaymentCategory.subscriptions:
        return Icons.subscriptions;
      case PaymentCategory.insurance:
        return Icons.security;
      case PaymentCategory.loan:
        return Icons.account_balance;
      case PaymentCategory.rent:
        return Icons.home;
      case PaymentCategory.utilities:
        return Icons.bolt;
      case PaymentCategory.other:
        return Icons.more_horiz;
    }
  }

  Color _getStatusColor(PaymentStatus status) {
    switch (status) {
      case PaymentStatus.active:
        return Colors.green;
      case PaymentStatus.paused:
        return Colors.orange;
      case PaymentStatus.cancelled:
        return Colors.red;
    }
  }

  String _getStatusText(PaymentStatus status) {
    switch (status) {
      case PaymentStatus.active:
        return 'Active';
      case PaymentStatus.paused:
        return 'Paused';
      case PaymentStatus.cancelled:
        return 'Cancelled';
    }
  }

  String _getFrequencyText(PaymentFrequency frequency) {
    switch (frequency) {
      case PaymentFrequency.daily:
        return 'Daily';
      case PaymentFrequency.weekly:
        return 'Weekly';
      case PaymentFrequency.biweekly:
        return 'Bi-weekly';
      case PaymentFrequency.monthly:
        return 'Monthly';
      case PaymentFrequency.quarterly:
        return 'Quarterly';
      case PaymentFrequency.yearly:
        return 'Yearly';
    }
  }
}

// Payment Category Enum
enum PaymentCategory {
  bills,
  subscriptions,
  insurance,
  loan,
  rent,
  utilities,
  other,
}

// Payment Frequency Enum
enum PaymentFrequency {
  daily,
  weekly,
  biweekly,
  monthly,
  quarterly,
  yearly,
}

// Payment Status Enum
enum PaymentStatus {
  active,
  paused,
  cancelled,
}

// Planned Payment Data Class
class PlannedPaymentItem {
  final String id;
  final String name;
  final String payee;
  final double amount;
  final PaymentCategory category;
  final PaymentFrequency frequency;
  final DateTime nextPaymentDate;
  final DateTime? lastPaymentDate;
  final String accountName;
  final PaymentStatus status;
  final String? notes;

  PlannedPaymentItem({
    required this.id,
    required this.name,
    required this.payee,
    required this.amount,
    required this.category,
    required this.frequency,
    required this.nextPaymentDate,
    this.lastPaymentDate,
    required this.accountName,
    this.status = PaymentStatus.active,
    this.notes,
  });
}

// Dummy Planned Payment Data
final dummyPlannedPayments = [
  PlannedPaymentItem(
    id: '1',
    name: 'Electric Bill',
    payee: 'Meralco',
    amount: 3500.00,
    category: PaymentCategory.utilities,
    frequency: PaymentFrequency.monthly,
    nextPaymentDate: DateTime.now().add(const Duration(days: 3)),
    lastPaymentDate: DateTime.now().subtract(const Duration(days: 27)),
    accountName: 'Main Wallet',
    status: PaymentStatus.active,
  ),
  PlannedPaymentItem(
    id: '2',
    name: 'Netflix Subscription',
    payee: 'Netflix',
    amount: 549.00,
    category: PaymentCategory.subscriptions,
    frequency: PaymentFrequency.monthly,
    nextPaymentDate: DateTime.now().add(const Duration(days: 12)),
    lastPaymentDate: DateTime.now().subtract(const Duration(days: 18)),
    accountName: 'Credit Card',
    status: PaymentStatus.active,
  ),
  PlannedPaymentItem(
    id: '3',
    name: 'Apartment Rent',
    payee: 'Landlord',
    amount: 15000.00,
    category: PaymentCategory.rent,
    frequency: PaymentFrequency.monthly,
    nextPaymentDate: DateTime(2025, 1, 5),
    lastPaymentDate: DateTime(2024, 12, 5),
    accountName: 'Main Wallet',
    status: PaymentStatus.active,
  ),
  PlannedPaymentItem(
    id: '4',
    name: 'Car Insurance',
    payee: 'MAPFRE Insurance',
    amount: 12000.00,
    category: PaymentCategory.insurance,
    frequency: PaymentFrequency.quarterly,
    nextPaymentDate: DateTime(2025, 3, 1),
    lastPaymentDate: DateTime(2024, 12, 1),
    accountName: 'Savings Account',
    status: PaymentStatus.active,
  ),
  PlannedPaymentItem(
    id: '5',
    name: 'Internet Bill',
    payee: 'PLDT',
    amount: 1699.00,
    category: PaymentCategory.utilities,
    frequency: PaymentFrequency.monthly,
    nextPaymentDate: DateTime.now().add(const Duration(days: 5)),
    lastPaymentDate: DateTime.now().subtract(const Duration(days: 25)),
    accountName: 'Main Wallet',
    status: PaymentStatus.active,
  ),
  PlannedPaymentItem(
    id: '6',
    name: 'Spotify Premium',
    payee: 'Spotify',
    amount: 149.00,
    category: PaymentCategory.subscriptions,
    frequency: PaymentFrequency.monthly,
    nextPaymentDate: DateTime.now().add(const Duration(days: 20)),
    lastPaymentDate: DateTime.now().subtract(const Duration(days: 10)),
    accountName: 'Credit Card',
    status: PaymentStatus.active,
  ),
  PlannedPaymentItem(
    id: '7',
    name: 'Car Loan',
    payee: 'BDO Auto Loan',
    amount: 18500.00,
    category: PaymentCategory.loan,
    frequency: PaymentFrequency.monthly,
    nextPaymentDate: DateTime.now().add(const Duration(days: 1)),
    lastPaymentDate: DateTime.now().subtract(const Duration(days: 29)),
    accountName: 'Savings Account',
    status: PaymentStatus.active,
  ),
  PlannedPaymentItem(
    id: '8',
    name: 'Water Bill',
    payee: 'Manila Water',
    amount: 800.00,
    category: PaymentCategory.utilities,
    frequency: PaymentFrequency.monthly,
    nextPaymentDate: DateTime.now().add(const Duration(days: 8)),
    lastPaymentDate: DateTime.now().subtract(const Duration(days: 22)),
    accountName: 'Main Wallet',
    status: PaymentStatus.active,
  ),
  PlannedPaymentItem(
    id: '9',
    name: 'Gym Membership',
    payee: 'Fitness First',
    amount: 2500.00,
    category: PaymentCategory.subscriptions,
    frequency: PaymentFrequency.monthly,
    nextPaymentDate: DateTime.now().add(const Duration(days: 15)),
    lastPaymentDate: DateTime.now().subtract(const Duration(days: 15)),
    accountName: 'Main Wallet',
    status: PaymentStatus.paused,
  ),
  PlannedPaymentItem(
    id: '10',
    name: 'Phone Bill',
    payee: 'Globe Telecom',
    amount: 999.00,
    category: PaymentCategory.bills,
    frequency: PaymentFrequency.monthly,
    nextPaymentDate: DateTime.now().subtract(const Duration(days: 2)),
    lastPaymentDate: DateTime.now().subtract(const Duration(days: 32)),
    accountName: 'Main Wallet',
    status: PaymentStatus.active,
  ),
];
