import 'package:flutter/material.dart';
import '../../../../core/ui/scoped_screen.dart';
import '../../../../core/routing/app_router.dart';
import '../../domain/entities/budget.dart';
import '../../domain/repositories/budget_repository.dart';

/// Budget list screen - Shows all monthly budgets
class BudgetListScreen extends ScopedScreen {
  const BudgetListScreen({super.key});

  @override
  State<BudgetListScreen> createState() => _BudgetListScreenState();
}

class _BudgetListScreenState extends ScopedScreenState<BudgetListScreen> {
  late BudgetRepository _repository;
  List<Budget> _budgets = [];
  bool _isLoading = false;

  @override
  void onReady() {
    _repository = getService<BudgetRepository>();
    _loadBudgets();
  }

  Future<void> _loadBudgets() async {
    setState(() => _isLoading = true);

    try {
      final budgets = await _repository.getBudgets();
      setState(() {
        _budgets = budgets;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading budgets: $e')),
        );
      }
    }
  }

  void _createBudget() {
    context.goToBudgetCreate().then((_) => _loadBudgets());
  }

  void _openBudget(Budget budget) {
    context.goToBudgetDetail(budget).then((_) => _loadBudgets());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Budgets'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _budgets.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.account_balance_wallet,
                          size: 64, color: Colors.grey[400]),
                      const SizedBox(height: 16),
                      Text(
                        'No budgets yet',
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 8),
                      ElevatedButton.icon(
                        onPressed: _createBudget,
                        icon: const Icon(Icons.add),
                        label: const Text('Create Budget'),
                      ),
                    ],
                  ),
                )
              : Column(
                  children: [
                    // Summary Card
                    if (_budgets.isNotEmpty) _buildSummaryCard(),

                    // Budget List
                    Expanded(
                      child: RefreshIndicator(
                        onRefresh: _loadBudgets,
                        child: ListView.builder(
                          padding: const EdgeInsets.all(8),
                          itemCount: _budgets.length,
                          itemBuilder: (context, index) {
                            final budget = _budgets[index];
                            return _BudgetCard(
                              budget: budget,
                              onTap: () => _openBudget(budget),
                            );
                          },
                        ),
                      ),
                    ),
                  ],
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: _createBudget,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildSummaryCard() {
    final activeBudget =
        _budgets.where((b) => b.status == BudgetStatus.active).firstOrNull;

    if (activeBudget == null) {
      return const SizedBox.shrink();
    }

    final balanceColor = activeBudget.balance >= 0 ? Colors.green : Colors.red;

    return Card(
      margin: const EdgeInsets.all(16),
      color: balanceColor.withOpacity(0.1),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Current Month: ${activeBudget.month}',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildSummaryItem(
                  'Income',
                  activeBudget.totalActualIncome,
                  Colors.green,
                ),
                _buildSummaryItem(
                  'Expenses',
                  activeBudget.totalActualExpenses,
                  Colors.red,
                ),
                _buildSummaryItem(
                  'Balance',
                  activeBudget.balance,
                  balanceColor,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryItem(String label, double amount, Color color) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '\$${amount.toStringAsFixed(2)}',
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

  const _BudgetCard({
    required this.budget,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isOverBudget = budget.isOverBudget;
    final balanceColor = budget.balance >= 0 ? Colors.green : Colors.red;

    return Card(
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        budget.month,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        budget.status.displayName,
                        style: TextStyle(
                          fontSize: 12,
                          color: budget.status == BudgetStatus.active
                              ? Colors.green
                              : Colors.grey,
                        ),
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '\$${budget.balance.toStringAsFixed(2)}',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: balanceColor,
                        ),
                      ),
                      Text(
                        budget.balance >= 0 ? 'Surplus' : 'Deficit',
                        style: TextStyle(
                          fontSize: 12,
                          color: balanceColor,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Simple bar chart
              _buildProgressBar(
                'Income',
                budget.totalActualIncome,
                budget.totalBudgetedIncome,
                Colors.green,
              ),
              const SizedBox(height: 8),
              _buildProgressBar(
                'Expenses',
                budget.totalActualExpenses,
                budget.totalBudgetedExpenses,
                Colors.red,
              ),

              if (isOverBudget) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.warning, size: 16, color: Colors.red),
                      const SizedBox(width: 4),
                      const Text(
                        'Over budget',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.red,
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
            Text(
              label,
              style: const TextStyle(fontSize: 12),
            ),
            Text(
              '\$${actual.toStringAsFixed(0)} / \$${target.toStringAsFixed(0)}',
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
