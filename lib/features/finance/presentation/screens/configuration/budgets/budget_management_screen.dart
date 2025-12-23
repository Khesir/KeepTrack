import 'package:flutter/material.dart';
import 'package:persona_codex/core/state/stream_builder_widget.dart';
import 'package:persona_codex/core/ui/app_layout_controller.dart';
import '../../../../../../core/ui/scoped_screen.dart';
import '../../../../../../core/routing/app_router.dart';
import '../../../../modules/budget/domain/entities/budget.dart';
import '../../../../modules/budget/domain/repositories/budget_repository.dart';
import '../../../../modules/budget/domain/usecases/create_budget_usecase.dart';
import '../../../../modules/budget/domain/usecases/get_budgets_usecase.dart';
import '../../../state/budget_list_controller.dart';

/// Budget list screen - Shows all monthly budgets
class BudgetManagementScreen extends ScopedScreen {
  const BudgetManagementScreen({super.key});

  @override
  State<BudgetManagementScreen> createState() => _BudgetManagementScreenState();
}

class _BudgetManagementScreenState
    extends ScopedScreenState<BudgetManagementScreen>
    with AppLayoutControlled {
  late BudgetListController _controller;
  BudgetStatus? _filterStatus;

  @override
  void registerServices() {
    // Uses global repository
  }

  @override
  void initState() {
    super.initState();

    final budgetRepo = getService<BudgetRepository>();

    // Create controller without DI (as requested)
    _controller = BudgetListController(
      getBudgetsUseCase: GetBudgetsUseCase(budgetRepo),
      createBudgetUseCase: CreateBudgetUseCase(budgetRepo),
    );
  }

  @override
  void onReady() {
    // Only UI configuration here (if needed)
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

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Manage Budgets'), elevation: 0),
      body: AsyncStreamBuilder<List<Budget>>(
        state: _controller,
        builder: (context, budgets) {
          // Apply filter
          final filteredBudgets = _filterStatus == null
              ? budgets
              : budgets.where((b) => b.status == _filterStatus).toList();

          if (budgets.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.pie_chart_outline,
                    size: 64,
                    color: colorScheme.primary.withValues(alpha: 0.5),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No budgets yet',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Create your first monthly budget',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            );
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
                    ? Center(
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
                            TextButton(
                              onPressed: () =>
                                  setState(() => _filterStatus = null),
                              child: const Text('Clear Filter'),
                            ),
                          ],
                        ),
                      )
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
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 16),
              Text(message),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => _controller.loadBudgets(),
                child: const Text('Retry'),
              ),
            ],
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

  Widget _buildSummaryCard(List<Budget> budgets) {
    // Get current month
    final now = DateTime.now();
    final currentMonth = '${now.year}-${now.month.toString().padLeft(2, '0')}';

    // Check if budget exists for current month
    final currentBudget = budgets.firstWhere(
      (b) => b.month == currentMonth,
      orElse: () => Budget(month: ''),
    );

    final hasCurrentBudget = currentBudget.month.isNotEmpty;

    if (!hasCurrentBudget) {
      // Show create budget prompt
      return Card(
        margin: const EdgeInsets.all(16),
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        color: Colors.blue.withValues(alpha: 0.1),
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
                  Text(
                    _formatMonthDisplay(currentMonth),
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Text(
                'No budget found for the current month.',
                style: TextStyle(fontSize: 15),
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
      );
    }

    // Show existing budget summary (budgeted amounts only)
    final balanceColor = currentBudget.budgetedBalance >= 0
        ? Colors.green
        : Colors.red;

    return Card(
      margin: const EdgeInsets.all(16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: balanceColor.withValues(alpha: 0.1),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: balanceColor.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.pie_chart_rounded,
                        color: balanceColor,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      _formatMonthDisplay(currentMonth),
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
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
                    'Current',
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
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildSummaryItem(
                  'Budgeted',
                  currentBudget.totalBudgetedIncome,
                  Colors.green,
                ),
                _buildSummaryItem(
                  'Planned',
                  currentBudget.totalBudgetedExpenses,
                  Colors.red,
                ),
                _buildSummaryItem(
                  'Balance',
                  currentBudget.budgetedBalance,
                  balanceColor,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Center(
              child: Text(
                'Tap to view actual transactions',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatMonthDisplay(String monthStr) {
    try {
      final parts = monthStr.split('-');
      final year = parts[0];
      final month = int.parse(parts[1]);
      final monthNames = [
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

  Widget _buildSummaryItem(String label, double amount, Color color) {
    return Column(
      children: [
        Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
        const SizedBox(height: 4),
        Text(
          '₱${amount.toStringAsFixed(2)}',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
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

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    // Showing budgeted amounts - actual amounts in detail screen
    final balanceColor = budget.budgetedBalance >= 0
        ? Colors.green
        : Colors.red;

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
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: balanceColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          Icons.pie_chart,
                          color: balanceColor,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            budget.month,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color:
                                  (budget.status == BudgetStatus.active
                                          ? Colors.green
                                          : Colors.grey)
                                      .withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              budget.status.displayName,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: budget.status == BudgetStatus.active
                                    ? Colors.green
                                    : Colors.grey,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '₱${budget.budgetedBalance.toStringAsFixed(2)}',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: balanceColor,
                        ),
                      ),
                      Text(
                        budget.budgetedBalance >= 0 ? 'Surplus' : 'Deficit',
                        style: TextStyle(
                          fontSize: 11,
                          color: balanceColor,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Budgeted amounts display
              _buildProgressBar(
                'Income',
                budget.totalBudgetedIncome,
                budget.totalBudgetedIncome,
                Colors.green,
              ),
              const SizedBox(height: 12),
              _buildProgressBar(
                'Expenses',
                budget.totalBudgetedExpenses,
                budget.totalBudgetedIncome > 0
                    ? budget.totalBudgetedIncome
                    : budget.totalBudgetedExpenses,
                Colors.red,
              ),

              if (budget.budgetedBalance < 0) ...[
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

  Widget _buildProgressBar(
    String label,
    double actual,
    double target,
    Color color,
  ) {
    final percentage = target > 0 ? (actual / target).clamp(0.0, 1.0) : 0.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(fontSize: 12)),
            Text(
              '₱${actual.toStringAsFixed(0)} / ₱${target.toStringAsFixed(0)}',
              style: const TextStyle(fontSize: 12),
            ),
          ],
        ),
        const SizedBox(height: 4),
        LinearProgressIndicator(
          value: percentage,
          backgroundColor: Colors.grey[300],
          valueColor: AlwaysStoppedAnimation(color),
        ),
      ],
    );
  }
}
