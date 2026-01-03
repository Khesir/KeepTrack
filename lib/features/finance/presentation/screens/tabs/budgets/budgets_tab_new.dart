import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:persona_codex/core/di/service_locator.dart';
import 'package:persona_codex/core/state/stream_builder_widget.dart';
import 'package:persona_codex/core/state/stream_state.dart';
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
    await _controller.loadBudgets();

    // Auto-refresh current month's budget if it exists
    final currentMonth = DateFormat('yyyy-MM').format(DateTime.now());
    final budgets = _controller.state is AsyncData<List<Budget>>
        ? (_controller.state as AsyncData<List<Budget>>).data
        : <Budget>[];

    try {
      final activeBudget = budgets.firstWhere(
        (b) => b.month == currentMonth && b.status == BudgetStatus.active,
      );

      if (activeBudget.id != null) {
        await _controller.manualRecalculateBudgetSpent(activeBudget.id!);
      }
    } catch (e) {
      // No active budget for current month, that's okay
    }
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
    return AsyncStreamBuilder<List<Budget>>(
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
        // Find active budget for current month
        final currentMonth = DateFormat('yyyy-MM').format(DateTime.now());
        Budget? activeBudget;
        try {
          activeBudget = budgets.firstWhere(
            (b) => b.month == currentMonth && b.status == BudgetStatus.active,
          );
        } catch (e) {
          activeBudget = null;
        }

        if (activeBudget == null || activeBudget.categories.isEmpty) {
          return _buildEmptyState(currentMonth);
        }

        return _buildBudgetContent(activeBudget);
      },
    );
  }

  Widget _buildEmptyState(String currentMonth) {
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
              'No budget for ${_formatMonthDisplay(currentMonth)}',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Create a budget to start tracking your spending',
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

  Widget _buildBudgetContent(Budget budget) {
    // Calculate total budget stats from categories
    final totalBudget = budget.budgetTarget;
    final totalSpent = budget.totalSpent;
    final totalFees = budget.totalFees;
    final totalRemaining = totalBudget - totalSpent;

    return RefreshIndicator(
      onRefresh: _refreshBudget,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Monthly Summary Card
          _buildMonthlySummaryCard(totalBudget, totalSpent, totalFees, totalRemaining),
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
                '${budget.categories.length} categories',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Categories List
          ...budget.categories.map((category) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _buildCategoryCard(category),
            );
          }),
        ],
        ),
      ),
    );
  }

  Widget _buildMonthlySummaryCard(
    double total,
    double spent,
    double fees,
    double remaining,
  ) {
    final percentSpent = total > 0 ? (spent / total).clamp(0.0, 1.0) : 0.0;

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
                    color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
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
                        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
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
                    NumberFormat.currency(symbol: '₱', decimalDigits: 0).format(total),
                    Colors.blue[700]!,
                  ),
                ),
                Expanded(
                  child: _buildSummaryStatItemWithFees(
                    'Spent',
                    spent,
                    fees,
                    Colors.red[700]!,
                  ),
                ),
                Expanded(
                  child: _buildSummaryStatItem(
                    'Remaining',
                    NumberFormat.currency(symbol: '₱', decimalDigits: 0).format(remaining),
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
            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
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

  Widget _buildSummaryStatItemWithFees(String label, double amount, double fees, Color color) {
    final hasFees = fees > 0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          NumberFormat.currency(symbol: '₱', decimalDigits: 0).format(amount + fees),
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        if (hasFees) ...[
          const SizedBox(height: 2),
          Text(
            '(incl. ₱${NumberFormat('#,##0.00').format(fees)} fees)',
            style: TextStyle(
              fontSize: 10,
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildCategoryCard(BudgetCategory category) {
    final limit = category.targetAmount;
    final spent = category.spentAmount ?? 0.0;
    final feeSpent = category.feeSpent ?? 0.0;
    final totalSpent = category.totalSpent;
    final percentSpent = limit > 0 ? (totalSpent / limit).clamp(0.0, 1.0) : 0.0;
    final remaining = limit - totalSpent;
    final isOverBudget = totalSpent > limit;
    final hasFees = feeSpent > 0;

    final financeCategory = category.financeCategory;
    final String categoryName;
    final Color categoryColor;
    final IconData categoryIcon;
    final String categoryTypeName;

    if (financeCategory != null) {
      categoryName = financeCategory.name;
      categoryColor = financeCategory.type.color;
      categoryIcon = financeCategory.type.icon;
      categoryTypeName = financeCategory.type.displayName;
    } else {
      categoryName = 'Unknown';
      categoryColor = Colors.grey;
      categoryIcon = Icons.category;
      categoryTypeName = '';
    }

    return Card(
      elevation: 0,
      child: InkWell(
        onTap: () {
          // Navigate to category detail if needed
        },
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Category Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: categoryColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(categoryIcon, color: categoryColor, size: 24),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          categoryName,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          categoryTypeName,
                          style: TextStyle(
                            fontSize: 12,
                            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
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
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        NumberFormat.currency(symbol: '₱', decimalDigits: 0).format(totalSpent),
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: _getProgressColor(percentSpent),
                        ),
                      ),
                      if (hasFees) ...[
                        const SizedBox(height: 4),
                        Text(
                          '₱${NumberFormat('#,##0.00').format(spent)} + ₱${NumberFormat('#,##0.00').format(feeSpent)} fees',
                          style: TextStyle(
                            fontSize: 12,
                            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                    ],
                  ),
                  Text(
                    'of ${NumberFormat.currency(symbol: '₱', decimalDigits: 0).format(limit)}',
                    style: TextStyle(
                      fontSize: 14,
                      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
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
                  backgroundColor: categoryColor.withValues(alpha: 0.1),
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
                        color: isOverBudget ? Colors.red[700] : Colors.green[700],
                      ),
                      const SizedBox(width: 4),
                      Text(
                        isOverBudget
                            ? 'Over by ${NumberFormat.currency(symbol: '₱', decimalDigits: 0).format(remaining.abs())}'
                            : '${NumberFormat.currency(symbol: '₱', decimalDigits: 0).format(remaining)} left',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: isOverBudget ? Colors.red[700] : Colors.green[700],
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
