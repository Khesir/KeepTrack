import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:persona_codex/core/di/service_locator.dart';
import 'package:persona_codex/core/routing/app_router.dart';
import 'package:persona_codex/core/state/stream_builder_widget.dart';
import 'package:persona_codex/features/finance/modules/transaction/domain/entities/transaction.dart';
import '../../../../modules/planned_payment/domain/entities/payment_enums.dart';
import '../../../../modules/planned_payment/domain/entities/planned_payment.dart';
import '../../../state/planned_payment_controller.dart';

/// Planned Payments Tab - Tracks recurring and scheduled payments
class PlannedPaymentsTabNew extends StatefulWidget {
  const PlannedPaymentsTabNew({super.key});

  @override
  State<PlannedPaymentsTabNew> createState() => _PlannedPaymentsTabNewState();
}

class _PlannedPaymentsTabNewState extends State<PlannedPaymentsTabNew> {
  late final PlannedPaymentController _controller;
  String _selectedFilter = 'All'; // All, Active, Upcoming, Paused

  @override
  void initState() {
    super.initState();
    _controller = locator.get<PlannedPaymentController>();
  }

  @override
  Widget build(BuildContext context) {
    return AsyncStreamBuilder<List<PlannedPayment>>(
      state: _controller,
      builder: (context, payments) {
        // Calculate monthly total
        final monthlyTotal = payments
            .where((p) => p.status == PaymentStatus.active)
            .fold<double>(0, (sum, payment) => sum + payment.amount);

        // Get upcoming payments (next 7 days)
        final upcomingPayments = payments
            .where((p) => p.isUpcoming && p.status == PaymentStatus.active)
            .toList();

        // Filter payments
        final filteredPayments = _getFilteredPayments(
          payments,
          upcomingPayments,
        );

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
                      '${payments.where((p) => p.status == PaymentStatus.active).length} active payments',
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildSummaryCard(
                      'Upcoming',
                      upcomingPayments.fold<double>(
                        0,
                        (sum, p) => sum + p.amount,
                      ),
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
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withOpacity(0.6),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Payments List
              if (filteredPayments.isEmpty)
                _buildEmptyState()
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
                'Error loading planned payments',
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
                onPressed: () => _controller.loadPlannedPayments(),
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<PlannedPayment> _getFilteredPayments(
    List<PlannedPayment> payments,
    List<PlannedPayment> upcomingPayments,
  ) {
    switch (_selectedFilter) {
      case 'Active':
        return payments.where((p) => p.status == PaymentStatus.active).toList();
      case 'Upcoming':
        return upcomingPayments;
      case 'Paused':
        return payments.where((p) => p.status == PaymentStatus.paused).toList();
      case 'All':
      default:
        return payments;
    }
  }

  Widget _buildEmptyState() {
    return Center(
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
                fontWeight: FontWeight.w500,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Track recurring bills and subscriptions here',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Colors.grey[500]),
            ),
          ],
        ),
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
              NumberFormat.currency(
                symbol: '₱',
                decimalDigits: 2,
              ).format(amount),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: const TextStyle(color: Colors.white70, fontSize: 11),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUpcomingAlert(List<PlannedPayment> upcomingPayments) {
    return Card(
      elevation: 0,
      color: Colors.orange[50],
      child: InkWell(
        onTap: () {
          setState(() {
            _selectedFilter = 'Upcoming';
          });
        },
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
                      style: TextStyle(fontSize: 12, color: Colors.orange[800]),
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

  Widget _buildPaymentCard(PlannedPayment payment) {
    final daysUntilPayment = payment.daysUntilPayment;
    final isUpcoming = payment.isUpcoming;
    final isOverdue = payment.isOverdue;

    return Card(
      elevation: 0,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          // Navigate to payment detail
          // context.push('/finance/planned-payments/${payment.id}');
        },
        child: Container(
          decoration: BoxDecoration(
            border: Border(
              left: BorderSide(color: payment.category.color, width: 4),
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
                        color: payment.category.color.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        payment.category.icon,
                        color: payment.category.color,
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
                              color: Theme.of(
                                context,
                              ).colorScheme.onSurface.withOpacity(0.6),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: _getStatusColor(payment.status).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        payment.status.displayName,
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
                              color: Theme.of(
                                context,
                              ).colorScheme.onSurface.withOpacity(0.6),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            NumberFormat.currency(
                              symbol: '₱',
                              decimalDigits: 2,
                            ).format(payment.amount),
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: payment.category.color,
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
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurface.withOpacity(0.6),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          DateFormat(
                            'MMM d, yyyy',
                          ).format(payment.nextPaymentDate),
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
                                : 'In ${daysUntilPayment.abs()} ${daysUntilPayment.abs() == 1 ? 'day' : 'days'}',
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
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.blue[50],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.repeat, size: 14, color: Colors.blue[700]),
                          const SizedBox(width: 4),
                          Text(
                            payment.frequency.displayName,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: Colors.blue[700],
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (payment.accountId != null) ...[
                      const SizedBox(width: 8),
                      Icon(
                        Icons.account_balance_wallet,
                        size: 14,
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withOpacity(0.5),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Account linked',
                        style: TextStyle(
                          fontSize: 12,
                          color: Theme.of(
                            context,
                          ).colorScheme.onSurface.withOpacity(0.6),
                        ),
                      ),
                    ],
                  ],
                ),

                // Last Payment
                if (payment.lastPaymentDate != null) ...[
                  const SizedBox(height: 12),
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
                          color: Theme.of(
                            context,
                          ).colorScheme.onSurface.withOpacity(0.5),
                        ),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 16),
                OutlinedButton.icon(
                  onPressed: payment.status == PaymentStatus.active
                      ? () {
                          context.goToTransactionCreate(
                            initialDescription:
                                "Paid Recurring Payment ${payment.name}",
                            initialType: TransactionType.expense,
                            initialAmount: payment.amount,
                            callback: () =>
                                _controller.recordPayment(payment.id!),
                          );
                        }
                      : null, // Disabled when not active
                  icon: Icon(
                    Icons.add,
                    size: 18,
                    color: payment.status == PaymentStatus.active
                        ? Colors.blue
                        : Colors.grey,
                  ),
                  label: Text(
                    'Create Transaction',
                    style: TextStyle(
                      color: payment.status == PaymentStatus.active
                          ? Colors.blue
                          : Colors.grey,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(
                      color: payment.status == PaymentStatus.active
                          ? Colors.blue
                          : Colors.grey,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Color _getStatusColor(PaymentStatus status) {
    switch (status) {
      case PaymentStatus.active:
        return Colors.green;
      case PaymentStatus.paused:
        return Colors.orange;
      case PaymentStatus.cancelled:
        return Colors.red;
      case PaymentStatus.closed:
        return Colors.grey;
    }
  }
}
