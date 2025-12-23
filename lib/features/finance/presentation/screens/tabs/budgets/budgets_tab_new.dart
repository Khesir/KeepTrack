import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../planned_payments/planned_payments_tab.dart';

/// Budgets Tab with Progress Tracking and Planned Payments Integration
class BudgetsTabNew extends StatefulWidget {
  const BudgetsTabNew({super.key});

  @override
  State<BudgetsTabNew> createState() => _BudgetsTabNewState();
}

class _BudgetsTabNewState extends State<BudgetsTabNew> {
  @override
  Widget build(BuildContext context) {
    // Calculate total budget stats
    final totalBudget = dummyBudgets.fold<double>(
      0,
      (sum, budget) => sum + budget.limit,
    );
    final totalSpent = dummyBudgets.fold<double>(
      0,
      (sum, budget) => sum + budget.spent,
    );
    final totalRemaining = totalBudget - totalSpent;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Monthly Summary Card
          _buildMonthlySummaryCard(totalBudget, totalSpent, totalRemaining),
          const SizedBox(height: 24),

          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Budget Categories',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                '${dummyBudgets.length} categories',
                style: TextStyle(
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withOpacity(0.6),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Budgets List
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: dummyBudgets.length,
            itemBuilder: (context, index) {
              final budget = dummyBudgets[index];
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _buildBudgetCard(budget),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildMonthlySummaryCard(
    double total,
    double spent,
    double remaining,
  ) {
    final percentSpent = (spent / total).clamp(0.0, 1.0);

    return Card(
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Theme.of(
                      context,
                    ).colorScheme.primary.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.pie_chart,
                    color: Theme.of(context).colorScheme.primary,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  DateFormat('MMMM yyyy').format(DateTime.now()),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Progress Bar
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Total Spent',
                      style: TextStyle(
                        fontSize: 13,
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withOpacity(0.6),
                      ),
                    ),
                    Text(
                      '${(percentSpent * 100).toInt()}%',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: _getProgressColor(percentSpent),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: percentSpent,
                    minHeight: 12,
                    backgroundColor: Colors.grey[200],
                    valueColor: AlwaysStoppedAnimation<Color>(
                      _getProgressColor(percentSpent),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Stats Row
            Row(
              children: [
                Expanded(
                  child: _buildSummaryStatItem(
                    'Budget',
                    NumberFormat.currency(
                      symbol: '₱',
                      decimalDigits: 0,
                    ).format(total),
                    Colors.blue[700]!,
                  ),
                ),
                Expanded(
                  child: _buildSummaryStatItem(
                    'Spent',
                    NumberFormat.currency(
                      symbol: '₱',
                      decimalDigits: 0,
                    ).format(spent),
                    Colors.red[700]!,
                  ),
                ),
                Expanded(
                  child: _buildSummaryStatItem(
                    'Remaining',
                    NumberFormat.currency(
                      symbol: '₱',
                      decimalDigits: 0,
                    ).format(remaining),
                    Colors.green[700]!,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryStatItem(String label, String value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildBudgetCard(BudgetItem budget) {
    final percentSpent = (budget.spent / budget.limit).clamp(0.0, 1.0);
    final remaining = budget.limit - budget.spent;
    final isOverBudget = budget.spent > budget.limit;

    // Find related planned payments
    final relatedPayments = dummyPlannedPayments.where((payment) {
      return _mapPaymentCategoryToBudget(payment.category) == budget.category;
    }).toList();

    final upcomingPaymentsTotal = relatedPayments
        .where((p) => p.status == PaymentStatus.active)
        .fold<double>(0, (sum, p) => sum + p.amount);

    return Card(
      elevation: 0,
      child: InkWell(
        onTap: () {
          // Navigate to budget detail
        },
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Budget Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: budget.color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(budget.icon, color: budget.color, size: 24),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          budget.category,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '${budget.transactionCount} transactions',
                          style: TextStyle(
                            fontSize: 12,
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurface.withOpacity(0.6),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (isOverBudget)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.red[50],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.warning, size: 14, color: Colors.red[700]),
                          const SizedBox(width: 4),
                          Text(
                            'Over',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: Colors.red[700],
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 20),

              // Spending Info
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    NumberFormat.currency(
                      symbol: '₱',
                      decimalDigits: 0,
                    ).format(budget.spent),
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: _getProgressColor(percentSpent),
                    ),
                  ),
                  Text(
                    'of ${NumberFormat.currency(symbol: '₱', decimalDigits: 0).format(budget.limit)}',
                    style: TextStyle(
                      fontSize: 14,
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withOpacity(0.6),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Progress Bar
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: percentSpent.clamp(0.0, 1.0),
                  minHeight: 10,
                  backgroundColor: budget.color.withOpacity(0.1),
                  valueColor: AlwaysStoppedAnimation<Color>(
                    _getProgressColor(percentSpent),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Stats Row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(
                        isOverBudget ? Icons.trending_up : Icons.trending_down,
                        size: 16,
                        color: isOverBudget
                            ? Colors.red[700]
                            : Colors.green[700],
                      ),
                      const SizedBox(width: 4),
                      Text(
                        isOverBudget
                            ? 'Over by ${NumberFormat.currency(symbol: '₱', decimalDigits: 0).format(remaining.abs())}'
                            : '${NumberFormat.currency(symbol: '₱', decimalDigits: 0).format(remaining)} left',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: isOverBudget
                              ? Colors.red[700]
                              : Colors.green[700],
                        ),
                      ),
                    ],
                  ),
                  Text(
                    '${(percentSpent * 100).toInt()}%',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: _getProgressColor(percentSpent),
                    ),
                  ),
                ],
              ),

              // Planned Payments Section
              if (relatedPayments.isNotEmpty) ...[
                const SizedBox(height: 16),
                const Divider(height: 1),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Icon(
                      Icons.event_repeat,
                      size: 14,
                      color: Colors.purple[700],
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Planned Payments',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.purple[700],
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '${relatedPayments.length} ${relatedPayments.length == 1 ? 'payment' : 'payments'}',
                      style: TextStyle(
                        fontSize: 11,
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withOpacity(0.6),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.purple[50],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Monthly recurring total',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.purple[900],
                          ),
                        ),
                      ),
                      Text(
                        NumberFormat.currency(
                          symbol: '₱',
                          decimalDigits: 0,
                        ).format(upcomingPaymentsTotal),
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.purple[700],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Color _getProgressColor(double percent) {
    if (percent >= 1.0) {
      return Colors.red[700]!;
    } else if (percent >= 0.8) {
      return Colors.orange[700]!;
    } else if (percent >= 0.5) {
      return Colors.blue[700]!;
    } else {
      return Colors.green[700]!;
    }
  }

  String _mapPaymentCategoryToBudget(PaymentCategory category) {
    switch (category) {
      case PaymentCategory.bills:
        return 'Utilities';
      case PaymentCategory.subscriptions:
        return 'Entertainment';
      case PaymentCategory.insurance:
        return 'Healthcare';
      case PaymentCategory.loan:
        return 'Transportation';
      case PaymentCategory.rent:
        return 'Utilities';
      case PaymentCategory.utilities:
        return 'Utilities';
      case PaymentCategory.other:
        return 'Shopping';
    }
  }
}

// Budget Data Class
class BudgetItem {
  final String id;
  final String category;
  final double limit;
  final double spent;
  final Color color;
  final IconData icon;
  final int transactionCount;

  BudgetItem({
    required this.id,
    required this.category,
    required this.limit,
    required this.spent,
    required this.color,
    required this.icon,
    this.transactionCount = 0,
  });
}

// Dummy Budget Data
final dummyBudgets = [
  BudgetItem(
    id: '1',
    category: 'Food & Dining',
    limit: 15000,
    spent: 12500,
    color: Colors.orange[700]!,
    icon: Icons.restaurant,
    transactionCount: 28,
  ),
  BudgetItem(
    id: '2',
    category: 'Transportation',
    limit: 5000,
    spent: 3200,
    color: Colors.blue[700]!,
    icon: Icons.directions_car,
    transactionCount: 15,
  ),
  BudgetItem(
    id: '3',
    category: 'Shopping',
    limit: 10000,
    spent: 11500,
    color: Colors.purple[700]!,
    icon: Icons.shopping_bag,
    transactionCount: 12,
  ),
  BudgetItem(
    id: '4',
    category: 'Entertainment',
    limit: 8000,
    spent: 4200,
    color: Colors.pink[700]!,
    icon: Icons.movie,
    transactionCount: 8,
  ),
  BudgetItem(
    id: '5',
    category: 'Utilities',
    limit: 6000,
    spent: 5800,
    color: Colors.teal[700]!,
    icon: Icons.electrical_services,
    transactionCount: 6,
  ),
  BudgetItem(
    id: '6',
    category: 'Healthcare',
    limit: 5000,
    spent: 1200,
    color: Colors.red[700]!,
    icon: Icons.medical_services,
    transactionCount: 3,
  ),
  BudgetItem(
    id: '7',
    category: 'Education',
    limit: 7000,
    spent: 6500,
    color: Colors.indigo[700]!,
    icon: Icons.school,
    transactionCount: 4,
  ),
];
