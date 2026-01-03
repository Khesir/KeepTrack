import 'package:flutter/material.dart';
import 'package:persona_codex/core/di/service_locator.dart';
import 'package:persona_codex/core/state/stream_builder_widget.dart';
import 'package:persona_codex/core/state/stream_state.dart';
import 'package:persona_codex/core/ui/app_layout_controller.dart';
import '../../../../../../core/ui/scoped_screen.dart';
import '../../../../../../core/routing/app_router.dart';
import '../../../../modules/budget/domain/entities/budget.dart';
import '../../../state/budget_controller.dart';

/// Budget list screen - Shows all monthly budgets
class BudgetManagementScreen extends ScopedScreen {
  const BudgetManagementScreen({super.key});

  @override
  State<BudgetManagementScreen> createState() => _BudgetManagementScreenState();
}

class _BudgetManagementScreenState
    extends ScopedScreenState<BudgetManagementScreen>
    with AppLayoutControlled {
  late final BudgetController _controller;
  BudgetStatus? _filterStatus;

  @override
  void registerServices() {
    _controller = locator.get<BudgetController>();
  }

  @override
  void initState() {
    super.initState();
  }

  @override
  void onReady() {
    // Load budgets when screen is ready
    _controller.loadBudgets();
  }

  @override
  void onDispose() {
    _controller.dispose();
  }

  void _createBudget() {
    context.goToBudgetCreate().then((_) => _controller.loadBudgets());
  }

  void _openBudget(Budget budget) {
    context.goToBudgetDetail(budget).then((_) => _controller.loadBudgets());
  }

  Future<void> _refreshAllBudgets() async {
    final budgets = _controller.state is AsyncData<List<Budget>>
        ? (_controller.state as AsyncData<List<Budget>>).data
        : <Budget>[];

    for (final budget in budgets) {
      if (budget.id != null && budget.status == BudgetStatus.active) {
        try {
          await _controller.manualRecalculateBudgetSpent(budget.id!);
        } catch (e) {
          // Continue with next budget even if one fails
          print('Error refreshing budget ${budget.id}: $e');
        }
      }
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('All budgets refreshed!'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Budgets'),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh All Budgets',
            onPressed: _refreshAllBudgets,
          ),
          if (_filterStatus != null)
            IconButton(
              icon: const Icon(Icons.filter_list_off),
              tooltip: 'Clear Filter',
              onPressed: () => setState(() => _filterStatus = null),
            ),
          PopupMenuButton<BudgetStatus?>(
            icon: const Icon(Icons.filter_list),
            tooltip: 'Filter Budgets',
            onSelected: (status) => setState(() => _filterStatus = status),
            itemBuilder: (context) => [
              const PopupMenuItem(value: null, child: Text('All Budgets')),
              const PopupMenuDivider(),
              PopupMenuItem(
                value: BudgetStatus.active,
                child: Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: Colors.green,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Text('Active'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: BudgetStatus.closed,
                child: Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: Colors.grey,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Text('Closed'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: AsyncStreamBuilder<List<Budget>>(
        state: _controller,
        builder: (context, budgets) {
          // Apply filter
          final filteredBudgets = _filterStatus == null
              ? budgets
              : budgets.where((b) => b.status == _filterStatus).toList();

          if (budgets.isEmpty) {
            return _buildEmptyState(colorScheme);
          }

          return Column(
            children: [
              // Summary Card (always shows all budgets, not filtered)
              _buildSummaryCard(budgets),

              // Filter indicator
              if (_filterStatus != null)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  color: Colors.blue.withValues(alpha: 0.1),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.filter_list,
                        size: 16,
                        color: Colors.blue,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Showing ${_filterStatus!.displayName} budgets (${filteredBudgets.length})',
                        style: const TextStyle(fontSize: 14),
                      ),
                      const Spacer(),
                      TextButton(
                        onPressed: () => setState(() => _filterStatus = null),
                        child: const Text('Clear Filter'),
                      ),
                    ],
                  ),
                ),

              // Budget List
              Expanded(
                child: filteredBudgets.isEmpty
                    ? _buildFilteredEmptyState(colorScheme)
                    : RefreshIndicator(
                        onRefresh: _controller.loadBudgets,
                        child: ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: filteredBudgets.length,
                          itemBuilder: (context, index) {
                            final budget = filteredBudgets[index];
                            return _BudgetCard(
                              budget: budget,
                              onTap: () => _openBudget(budget),
                            );
                          },
                        ),
                      ),
              ),
            ],
          );
        },
        loadingBuilder: (context) =>
            const Center(child: CircularProgressIndicator()),
        errorBuilder: (context, message) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
                const SizedBox(height: 16),
                Text(
                  'Failed to Load Budgets',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: () => _controller.loadBudgets(),
                  icon: const Icon(Icons.refresh),
                  label: const Text('Retry'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _createBudget,
        icon: const Icon(Icons.add),
        label: const Text('Create Budget'),
      ),
    );
  }

  Widget _buildEmptyState(ColorScheme colorScheme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.pie_chart_outline,
              size: 80,
              color: colorScheme.primary.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 24),
            Text(
              'No budgets yet',
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Create your first monthly budget to start\ntracking your income and expenses',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: _createBudget,
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
        ),
      ),
    );
  }

  Widget _buildFilteredEmptyState(ColorScheme colorScheme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.filter_list_off,
              size: 64,
              color: colorScheme.primary.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'No ${_filterStatus?.displayName.toLowerCase() ?? ''} budgets',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              'Try adjusting your filter',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 24),
            TextButton.icon(
              onPressed: () => setState(() => _filterStatus = null),
              icon: const Icon(Icons.clear),
              label: const Text('Clear Filter'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCard(List<Budget> budgets) {
    // Get current month
    final now = DateTime.now();
    final currentMonth = '${now.year}-${now.month.toString().padLeft(2, '0')}';

    // Check if budget exists for current month
    Budget? currentBudget;
    try {
      currentBudget = budgets.firstWhere((b) => b.month == currentMonth);
    } catch (e) {
      currentBudget = null;
    }

    if (currentBudget == null) {
      return _buildCreateBudgetPrompt(currentMonth);
    }

    return _buildCurrentBudgetSummary(currentMonth, currentBudget);
  }

  Widget _buildCreateBudgetPrompt(String currentMonth) {
    return Card(
      margin: const EdgeInsets.all(16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: Colors.blue.withValues(alpha: 0.1),
      child: InkWell(
        onTap: _createBudget,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.calendar_today,
                      color: Colors.blue,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _formatMonthDisplay(currentMonth),
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Current Month',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Text(
                'No budget found for the current month.',
                style: TextStyle(fontSize: 15),
              ),
              const SizedBox(height: 4),
              Text(
                'Create a budget to start planning your finances',
                style: TextStyle(fontSize: 13, color: Colors.grey[600]),
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: _createBudget,
                icon: const Icon(Icons.add),
                label: const Text('Create Budget'),
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCurrentBudgetSummary(String currentMonth, Budget currentBudget) {
    return Card(
      margin: const EdgeInsets.all(16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: () => _openBudget(currentBudget),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _formatMonthDisplay(currentMonth),
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Current Month Budget',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.green.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      'Active',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.green,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Income and Expense Targets
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Income Target',
                          style: TextStyle(
                            color: Colors.grey,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '₱${currentBudget.totalBudgetedIncome.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Expense Target',
                          style: TextStyle(
                            color: Colors.grey,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '₱${currentBudget.totalBudgetedExpenses.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.red,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // HP Bar
              _buildBudgetVisualBar(currentBudget),

              const SizedBox(height: 12),
              Center(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.touch_app, size: 14, color: Colors.grey[600]),
                    const SizedBox(width: 6),
                    Text(
                      'Tap to view details',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ),
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

  Widget _buildBudgetVisualBar(Budget budget) {
    final spent = budget.totalSpent;
    final target = budget.budgetTarget;

    final spentPercentage = target > 0 ? (spent / target).clamp(0.0, 1.0) : 0.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // HP-style bar
        Container(
          height: 28,
          decoration: BoxDecoration(
            color: Colors.grey[200],
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.grey[300]!, width: 2),
          ),
          child: Stack(
            children: [
              // Actual spent (gradient based on if over budget)
              if (spentPercentage > 0)
                FractionallySizedBox(
                  widthFactor: spentPercentage,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: budget.isOverBudget
                            ? [Colors.red[400]!, Colors.red[600]!]
                            : [Colors.blue[400]!, Colors.blue[600]!],
                      ),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: (budget.isOverBudget ? Colors.red : Colors.blue)
                              .withValues(alpha: 0.3),
                          blurRadius: 4,
                        ),
                      ],
                    ),
                  ),
                ),
              // Amount text overlay
              Center(
                child: Text(
                  '₱${spent.toStringAsFixed(0)} / ₱${target.toStringAsFixed(0)}',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    shadows: [
                      Shadow(
                        color: Colors.black54,
                        blurRadius: 2,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        // Legend
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildLegendItem(
              budget.isOverBudget ? Colors.red[500]! : Colors.blue[500]!,
              'Spent',
            ),
            const SizedBox(width: 16),
            _buildLegendItem(Colors.grey[300]!, 'Remaining'),
          ],
        ),
      ],
    );
  }

  Widget _buildLegendItem(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }
}

class _BudgetCard extends StatelessWidget {
  final Budget budget;
  final VoidCallback onTap;

  const _BudgetCard({required this.budget, required this.onTap});

  String _formatMonthDisplay(String monthStr) {
    try {
      final parts = monthStr.split('-');
      final year = parts[0];
      final month = int.parse(parts[1]);
      const monthNames = [
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
        'Dec',
      ];
      return '${monthNames[month - 1]} $year';
    } catch (e) {
      return monthStr;
    }
  }

  String _getDisplayTitle() {
    if (budget.title != null && budget.title!.isNotEmpty) {
      return budget.title!;
    }
    return _formatMonthDisplay(budget.month);
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: colorScheme.outlineVariant, width: 1),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with title/month and status
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: (budget.budgetType == BudgetType.income
                                    ? Colors.green
                                    : Colors.red)
                                .withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            budget.budgetType == BudgetType.income
                                ? Icons.arrow_downward
                                : Icons.arrow_upward,
                            color: budget.budgetType == BudgetType.income
                                ? Colors.green
                                : Colors.red,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _getDisplayTitle(),
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: (budget.periodType ==
                                                  BudgetPeriodType.monthly
                                              ? Colors.blue
                                              : Colors.purple)
                                          .withValues(alpha: 0.2),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      budget.periodType.displayName,
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w600,
                                        color: budget.periodType ==
                                                BudgetPeriodType.monthly
                                            ? Colors.blue
                                            : Colors.purple,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: (budget.status ==
                                                  BudgetStatus.active
                                              ? Colors.green
                                              : Colors.grey)
                                          .withValues(alpha: 0.2),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      budget.status.displayName,
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w600,
                                        color:
                                            budget.status == BudgetStatus.active
                                                ? Colors.green
                                                : Colors.grey,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    _formatMonthDisplay(budget.month),
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Income/Expense summary
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.arrow_downward, size: 12, color: Colors.green),
                          const SizedBox(width: 4),
                          Text(
                            '₱${budget.totalBudgetedIncome.toStringAsFixed(0)}',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Colors.green,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.arrow_upward, size: 12, color: Colors.red),
                          const SizedBox(width: 4),
                          Text(
                            '₱${budget.totalBudgetedExpenses.toStringAsFixed(0)}',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Colors.red,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _buildBudgetVisualBar(budget),
              const SizedBox(height: 4),
              if (budget.status == BudgetStatus.active && budget.isOverBudget) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.warning_amber,
                        size: 16,
                        color: Colors.red,
                      ),
                      const SizedBox(width: 6),
                      const Text(
                        'Over budget',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.red,
                          fontWeight: FontWeight.w500,
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

  Widget _buildBudgetVisualBar(Budget budget) {
    final spent = budget.totalSpent;
    final target = budget.budgetTarget;

    final spentPercentage = target > 0 ? (spent / target).clamp(0.0, 1.0) : 0.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // HP-style bar
        Container(
          height: 28,
          decoration: BoxDecoration(
            color: Colors.grey[200],
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.grey[300]!, width: 2),
          ),
          child: Stack(
            children: [
              // Actual spent (gradient based on if over budget)
              if (spentPercentage > 0)
                FractionallySizedBox(
                  widthFactor: spentPercentage,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: budget.isOverBudget
                            ? [Colors.red[400]!, Colors.red[600]!]
                            : [Colors.blue[400]!, Colors.blue[600]!],
                      ),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: (budget.isOverBudget ? Colors.red : Colors.blue)
                              .withValues(alpha: 0.3),
                          blurRadius: 4,
                        ),
                      ],
                    ),
                  ),
                ),
              // Amount text overlay
              Center(
                child: Text(
                  '₱${spent.toStringAsFixed(0)} / ₱${target.toStringAsFixed(0)}',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    shadows: [
                      Shadow(
                        color: Colors.black54,
                        blurRadius: 2,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        // Legend
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildLegendItem(
              budget.isOverBudget ? Colors.red[500]! : Colors.blue[500]!,
              'Spent',
            ),
            const SizedBox(width: 16),
            _buildLegendItem(Colors.grey[300]!, 'Remaining'),
          ],
        ),
      ],
    );
  }

  Widget _buildLegendItem(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }
}
