import 'package:flutter/material.dart';
import 'package:keep_track/core/settings/utils/currency_formatter.dart';
import 'package:intl/intl.dart';
import 'package:keep_track/core/di/service_locator.dart';
import 'package:keep_track/core/routing/app_router.dart';
import 'package:keep_track/core/state/stream_builder_widget.dart';
import 'package:keep_track/core/state/stream_state.dart';
import '../../../../modules/budget/domain/entities/budget.dart';
import '../../../../modules/budget/domain/entities/budget_category.dart';
import '../../../../modules/finance_category/domain/entities/finance_category_enums.dart';
import '../../../state/budget_controller.dart';

/// Budgets Tab with Progress Tracking
class BudgetsTabNew extends StatefulWidget {
  const BudgetsTabNew({super.key});

  @override
  State<BudgetsTabNew> createState() => _BudgetsTabNewState();
}

class _BudgetsTabNewState extends State<BudgetsTabNew> {
  late final BudgetController _controller;

  @override
  void initState() {
    super.initState();
    _controller = locator.get<BudgetController>();
    _loadAndRefreshBudget();
  }

  Future<void> _loadAndRefreshBudget() async {
    // Load budgets with spent amounts already calculated
    await _controller.loadBudgetsWithSpentAmounts();
  }

  Future<void> _refreshBudget() async {
    await _loadAndRefreshBudget();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Budget refreshed!'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AsyncStreamBuilder<List<Budget>>(
        state: _controller,
        loadingBuilder: (_) => const Center(child: CircularProgressIndicator()),
        errorBuilder: (context, message) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text(
                'Error loading budgets',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Text(
                message,
                style: const TextStyle(color: Colors.grey),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
        builder: (context, budgets) {
          // Filter active budgets and separate by type
          final activeBudgets = budgets
              .where((b) => b.status == BudgetStatus.active)
              .toList()
            ..sort((a, b) => b.month.compareTo(a.month)); // Most recent first

          final incomeBudgets = activeBudgets
              .where((b) => b.budgetType == BudgetType.income)
              .toList();
          final expenseBudgets = activeBudgets
              .where((b) => b.budgetType == BudgetType.expense)
              .toList();

          if (incomeBudgets.isEmpty && expenseBudgets.isEmpty) {
            return _buildEmptyState();
          }

          return _buildBudgetContent(incomeBudgets, expenseBudgets);
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.pushNamed(context, '/budget-management');
        },
        icon: const Icon(Icons.add),
        label: const Text('Manage Budgets'),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.pie_chart_outline,
              size: 80,
              color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 24),
            Text(
              'No Active Budgets',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Create a budget to start tracking your finances',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBudgetContent(List<Budget> incomeBudgets, List<Budget> expenseBudgets) {
    return RefreshIndicator(
      onRefresh: _refreshBudget,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Text(
              'Active Budgets',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24),

            // Income Budgets Section
            if (incomeBudgets.isNotEmpty) ...[
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.green.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.arrow_downward, color: Colors.green, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Income Budgets',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.green.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${incomeBudgets.length}',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              ...incomeBudgets.map((budget) => Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: _buildBudgetCard(budget, Colors.green),
                  )),
              const SizedBox(height: 24),
            ],

            // Expense Budgets Section
            if (expenseBudgets.isNotEmpty) ...[
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.red.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.arrow_upward, color: Colors.red, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Expense Budgets',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.red.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${expenseBudgets.length}',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.red,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              ...expenseBudgets.map((budget) => Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: _buildBudgetCard(budget, Colors.red),
                  )),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildBudgetCard(Budget budget, Color color) {
    final totalBudget = budget.budgetTarget;
    final totalSpent = budget.totalSpent;
    final totalFees = budget.totalFees;
    final totalRemaining = totalBudget - totalSpent;
    final percentSpent = totalBudget > 0 ? (totalSpent / totalBudget).clamp(0.0, 1.0) : 0.0;

    return Card(
      elevation: 0,
      color: color.withValues(alpha: 0.05),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: color.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: InkWell(
        onTap: () {
          Navigator.pushNamed(
            context,
            AppRoutes.budgetDetail,
            arguments: budget,
          );
        },
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Budget Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Show title if available, otherwise show month
                      Text(
                        budget.title != null && budget.title!.isNotEmpty
                            ? budget.title!
                            : _formatMonthDisplay(budget.month),
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      // Show month as subtitle if title is present
                      if (budget.title != null && budget.title!.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          _formatMonthDisplay(budget.month),
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    budget.periodType.displayName,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Progress Bar
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: percentSpent,
                minHeight: 12,
                backgroundColor: Colors.grey[200],
                valueColor: AlwaysStoppedAnimation<Color>(
                  percentSpent > 1.0 ? Colors.red : color,
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Stats
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Spent',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '₱${NumberFormat('#,##0').format(totalSpent)}',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: percentSpent > 1.0 ? Colors.red : color,
                      ),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      'Budget',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '₱${NumberFormat('#,##0').format(totalBudget)}',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: color,
                      ),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'Remaining',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '₱${NumberFormat('#,##0').format(totalRemaining)}',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: totalRemaining < 0 ? Colors.red : Colors.grey[700],
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Categories count
            Row(
              children: [
                Icon(Icons.category, size: 14, color: Colors.grey[600]),
                const SizedBox(width: 6),
                Text(
                  '${budget.categories.length} categories',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      ),
    );
  }

  String _formatMonthDisplay(String monthStr) {
    try {
      final parts = monthStr.split('-');
      final year = parts[0];
      final month = int.parse(parts[1]);
      const monthNames = [
        'January',
        'February',
        'March',
        'April',
        'May',
        'June',
        'July',
        'August',
        'September',
        'October',
        'November',
        'December',
      ];
      return '${monthNames[month - 1]} $year';
    } catch (e) {
      return monthStr;
    }
  }
}
