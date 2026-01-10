import 'package:flutter/material.dart';
import 'package:keep_track/core/settings/utils/currency_formatter.dart';
import 'package:keep_track/core/theme/app_theme.dart';
import 'package:keep_track/core/ui/responsive/desktop_aware_screen.dart';
import 'package:intl/intl.dart';
import 'package:keep_track/core/di/service_locator.dart';
import 'package:keep_track/core/routing/app_router.dart';
import 'package:keep_track/core/state/stream_builder_widget.dart';
import '../../../../modules/budget/domain/entities/budget.dart';
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
    return DesktopAwareScreen(
      builder: (context, isDesktop) {
        return Scaffold(
          backgroundColor: isDesktop ? AppColors.backgroundSecondary : null,
          body: AsyncStreamBuilder<List<Budget>>(
            state: _controller,
            loadingBuilder: (_) =>
                const Center(child: CircularProgressIndicator()),
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
              final activeBudgets =
                  budgets.where((b) => b.status == BudgetStatus.active).toList()
                    ..sort((a, b) => b.month.compareTo(a.month));

              final incomeBudgets = activeBudgets
                  .where((b) => b.budgetType == BudgetType.income)
                  .toList();
              final expenseBudgets = activeBudgets
                  .where((b) => b.budgetType == BudgetType.expense)
                  .toList();

              if (incomeBudgets.isEmpty && expenseBudgets.isEmpty) {
                return _buildEmptyState(isDesktop);
              }

              return _buildBudgetContent(
                incomeBudgets,
                expenseBudgets,
                isDesktop,
              );
            },
          ),
          floatingActionButton: isDesktop
              ? null
              : FloatingActionButton.extended(
                  onPressed: () {
                    Navigator.pushNamed(context, '/budget-management');
                  },
                  icon: const Icon(Icons.add),
                  label: const Text('Manage Budgets'),
                ),
        );
      },
    );
  }

  Widget _buildEmptyState(bool isDesktop) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(isDesktop ? AppSpacing.xl : 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.pie_chart_outline,
              size: 80,
              color: Theme.of(
                context,
              ).colorScheme.primary.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 24),
            Text(
              'No Active Budgets',
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Create a budget to start tracking your finances',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            if (isDesktop) ...[
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.pushNamed(context, '/budget-management');
                },
                icon: const Icon(Icons.add),
                label: const Text('Create Budget'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 16,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildBudgetContent(
    List<Budget> incomeBudgets,
    List<Budget> expenseBudgets,
    bool isDesktop,
  ) {
    return RefreshIndicator(
      onRefresh: _refreshBudget,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.all(isDesktop ? AppSpacing.xl : 16),
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: isDesktop ? 1400 : double.infinity,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Active Budgets',
                      style: isDesktop
                          ? AppTextStyles.h1
                          : Theme.of(context).textTheme.headlineMedium
                                ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    if (isDesktop)
                      ElevatedButton.icon(
                        onPressed: () {
                          Navigator.pushNamed(context, '/budget-management');
                        },
                        icon: const Icon(Icons.add, size: 20),
                        label: const Text('Manage Budgets'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 12,
                          ),
                        ),
                      ),
                  ],
                ),
                SizedBox(height: isDesktop ? AppSpacing.xl : 24),

                // Income and Expense Budgets in columns on desktop
                if (isDesktop)
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Income Budgets Column
                      if (incomeBudgets.isNotEmpty)
                        Expanded(
                          child: _buildBudgetSection(
                            'Income Budgets',
                            incomeBudgets,
                            Colors.green,
                            Icons.arrow_downward,
                            isDesktop,
                          ),
                        ),
                      if (incomeBudgets.isNotEmpty && expenseBudgets.isNotEmpty)
                        const SizedBox(width: AppSpacing.xl),
                      // Expense Budgets Column
                      if (expenseBudgets.isNotEmpty)
                        Expanded(
                          child: _buildBudgetSection(
                            'Expense Budgets',
                            expenseBudgets,
                            Colors.red,
                            Icons.arrow_upward,
                            isDesktop,
                          ),
                        ),
                    ],
                  )
                else ...[
                  // Mobile: Stack vertically
                  if (incomeBudgets.isNotEmpty)
                    _buildBudgetSection(
                      'Income Budgets',
                      incomeBudgets,
                      Colors.green,
                      Icons.arrow_downward,
                      isDesktop,
                    ),
                  if (incomeBudgets.isNotEmpty && expenseBudgets.isNotEmpty)
                    const SizedBox(height: 24),
                  if (expenseBudgets.isNotEmpty)
                    _buildBudgetSection(
                      'Expense Budgets',
                      expenseBudgets,
                      Colors.red,
                      Icons.arrow_upward,
                      isDesktop,
                    ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBudgetSection(
    String title,
    List<Budget> budgets,
    Color color,
    IconData icon,
    bool isDesktop,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: isDesktop
                    ? AppTextStyles.h3
                    : Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${budgets.length}',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        ...budgets.map(
          (budget) => Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: _buildBudgetCard(budget, color, isDesktop),
          ),
        ),
      ],
    );
  }

  Widget _buildBudgetCard(Budget budget, Color color, bool isDesktop) {
    final totalBudget = budget.budgetTarget;
    final totalSpent = budget.totalSpent;
    final totalRemaining = totalBudget - totalSpent;
    final percentSpent = totalBudget > 0
        ? (totalSpent / totalBudget).clamp(0.0, 1.0)
        : 0.0;

    return Card(
      elevation: 0,
      color: color.withValues(alpha: 0.05),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: color.withValues(alpha: 0.3), width: 1),
      ),
      child: InkWell(
        onTap: () {
          Navigator.pushNamed(
            context,
            AppRoutes.budgetDetail,
            arguments: budget,
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: EdgeInsets.all(isDesktop ? 20 : 16),
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
                        Text(
                          budget.title != null && budget.title!.isNotEmpty
                              ? budget.title!
                              : _formatMonthDisplay(budget.month),
                          style: TextStyle(
                            fontSize: isDesktop ? 18 : 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (budget.title != null &&
                            budget.title!.isNotEmpty) ...[
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
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
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
                  _buildStatColumn(
                    'Spent',
                    totalSpent,
                    percentSpent > 1.0 ? Colors.red : color,
                  ),
                  _buildStatColumn('Budget', totalBudget, color),
                  _buildStatColumn(
                    'Remaining',
                    totalRemaining,
                    totalRemaining < 0 ? Colors.red : Colors.grey[700]!,
                    alignment: CrossAxisAlignment.end,
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
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                  if (isDesktop) ...[
                    const Spacer(),
                    Icon(
                      Icons.arrow_forward_ios,
                      size: 14,
                      color: Colors.grey[400],
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatColumn(
    String label,
    double amount,
    Color color, {
    CrossAxisAlignment alignment = CrossAxisAlignment.start,
  }) {
    return Column(
      crossAxisAlignment: alignment,
      children: [
        Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
        const SizedBox(height: 4),
        Text(
          '${currencyFormatter.currencySymbol}${NumberFormat('#,##0').format(amount)}',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
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
