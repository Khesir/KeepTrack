import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:keep_track/core/di/service_locator.dart';
import 'package:keep_track/core/settings/utils/currency_formatter.dart';
import 'package:keep_track/core/state/stream_builder_widget.dart';
import 'package:keep_track/core/theme/app_theme.dart';
import 'package:keep_track/core/ui/app_layout_controller.dart';
import 'package:keep_track/core/ui/responsive/desktop_aware_screen.dart';
import 'package:keep_track/core/ui/ui.dart';
import 'package:keep_track/core/routing/app_router.dart';
import 'package:keep_track/features/finance/modules/account/domain/entities/account.dart';
import 'package:keep_track/features/finance/modules/budget/domain/entities/budget.dart';
import 'package:keep_track/features/finance/modules/transaction/domain/entities/transaction.dart';
import 'package:keep_track/features/finance/presentation/state/account_controller.dart';
import 'package:keep_track/features/finance/presentation/state/budget_controller.dart';
import 'package:keep_track/features/finance/presentation/state/transaction_controller.dart';
import 'package:keep_track/features/home/widgets/admin_panel_widget.dart';

class HomeScreen extends ScopedScreen {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ScopedScreenState<HomeScreen>
    with AppLayoutControlled {
  late final AccountController _accountController;
  late final BudgetController _budgetController;
  late final TransactionController _transactionController;
  int _daysToShow = 15; // Adjustable days for bar graph
  Set<String> _selectedTypes = {'income', 'expense', 'transfer'};

  @override
  void registerServices() {
    _accountController = locator.get<AccountController>();
    _budgetController = locator.get<BudgetController>();
    _transactionController = locator.get<TransactionController>();
  }

  @override
  void onReady() {
    configureLayout(title: 'Home', showBottomNav: true);
    _accountController.loadAccounts();
    _budgetController.loadBudgets();
    _loadTransactionsForGraph();
  }

  void _loadTransactionsForGraph() {
    final endDate = DateTime.now();
    final startDate = endDate.subtract(Duration(days: _daysToShow));
    _transactionController.loadTransactionsByDateRange(startDate, endDate);
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning';
    if (hour < 17) return 'Good Afternoon';
    return 'Good Evening';
  }

  @override
  Widget build(BuildContext context) {
    return DesktopAwareScreen(
      builder: (context, isDesktop) {
        return Scaffold(
          backgroundColor: isDesktop
              ? (Theme.of(context).brightness == Brightness.dark
                    ? const Color(0xFF09090B)
                    : AppColors.backgroundSecondary)
              : null,

          body: SingleChildScrollView(
            padding: EdgeInsets.all(isDesktop ? AppSpacing.xl : AppSpacing.lg),
            child: Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: isDesktop ? 1400 : double.infinity,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Admin Panel (only visible for admin users)
                    const AdminPanelWidget(),

                    // Welcome Section
                    _buildWelcomeSection(isDesktop),
                    SizedBox(height: isDesktop ? AppSpacing.xl : AppSpacing.lg),

                    // Income/Expense Bar Graph
                    _buildIncomeExpenseGraph(isDesktop),
                    SizedBox(height: isDesktop ? AppSpacing.xl : AppSpacing.lg),

                    // Desktop: Two-column layout, Mobile: Single column
                    if (isDesktop)
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Left Column - Finance Snapshot
                          Expanded(
                            flex: 2,
                            child: _buildFinanceSnapshot(isDesktop),
                          ),
                          const SizedBox(width: AppSpacing.xl),
                          // Right Column - Quick Actions
                          Expanded(
                            flex: 1,
                            child: _buildQuickActions(context, isDesktop),
                          ),
                        ],
                      )
                    else ...[
                      // Mobile: Stack vertically
                      _buildFinanceSnapshot(isDesktop),
                      SizedBox(height: AppSpacing.xl),
                      _buildQuickActions(context, isDesktop),
                    ],

                    const SizedBox(height: AppSpacing.lg),

                    // Add extra bottom padding to account for FAB
                    if (!isDesktop) const SizedBox(height: 80),
                  ],
                ),
              ),
            ),
          ),
          floatingActionButton: isDesktop
              ? null
              : FloatingActionButton.extended(
                  onPressed: () {
                    Navigator.pushNamed(context, AppRoutes.transactionCreate);
                  },
                  icon: const Icon(Icons.add),
                  label: const Text('Add Transaction'),
                  backgroundColor: Colors.green,
                ),
        );
      },
    );
  }

  IconData _getGreetingIcon() {
    final hour = DateTime.now().hour;
    if (hour < 12) return Icons.wb_sunny;
    if (hour < 17) return Icons.wb_sunny_outlined;
    return Icons.nightlight_round;
  }

  Widget _buildIncomeExpenseGraph(bool isDesktop) {
    return AsyncStreamBuilder<List<Transaction>>(
      state: _transactionController,
      loadingBuilder: (_) => Card(
        elevation: 0,
        margin: EdgeInsets.zero,
        child: Container(
          height: isDesktop ? 350 : 300,
          alignment: Alignment.center,
          child: const CircularProgressIndicator(),
        ),
      ),
      errorBuilder: (context, message) => Card(
        elevation: 0,
        margin: EdgeInsets.zero,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Text('Error loading transactions: $message'),
        ),
      ),
      builder: (context, transactions) {
        // Process real transaction data into daily aggregates
        final List<DailyFinanceData> data = _processTransactionsToDaily(transactions);
        final maxAmount = data.fold<double>(
          0,
          (max, d) {
            final dayMax = [d.income, d.expense, d.transfer].reduce((a, b) => a > b ? a : b);
            return dayMax > max ? dayMax : max;
          },
        );

        return Card(
          elevation: 0,
          margin: EdgeInsets.zero,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header with title and days selector
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Daily Income & Expense',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    // Days selector
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: DropdownButton<int>(
                        value: _daysToShow,
                        isDense: true,
                        underline: const SizedBox(),
                        items: [7, 15, 30].map((days) {
                          return DropdownMenuItem<int>(
                            value: days,
                            child: Text(
                              '$days days',
                              style: const TextStyle(fontSize: 12),
                            ),
                          );
                        }).toList(),
                        onChanged: (value) {
                          if (value != null) {
                            setState(() {
                              _daysToShow = value;
                              _loadTransactionsForGraph();
                            });
                          }
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // Transaction type filter chips
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _buildFilterChip('income', 'Income', Colors.green),
                    _buildFilterChip('expense', 'Expense', Colors.red),
                    _buildFilterChip('transfer', 'Transfer', Colors.blue),
                  ],
                ),
                const SizedBox(height: 16),
                // Bar Graph
                SizedBox(
                  height: isDesktop ? 200 : 160,
                  child: data.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.bar_chart,
                                size: 48,
                                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.3),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'No transactions in this period',
                                style: TextStyle(
                                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                                ),
                              ),
                            ],
                          ),
                        )
                      : LayoutBuilder(
                          builder: (context, constraints) {
                            final barWidth = (constraints.maxWidth - (data.length - 1) * 6) / (data.length * 3);
                            final clampedBarWidth = barWidth.clamp(3.0, 16.0);

                            final selectedCount = _selectedTypes.length;
                            final adjustedBarWidth = selectedCount > 0
                                ? (constraints.maxWidth - (data.length - 1) * 6) / (data.length * selectedCount)
                                : clampedBarWidth;
                            final adjustedClampedBarWidth = adjustedBarWidth.clamp(3.0, 20.0);

                            return Row(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: data.map((dayData) {
                                final incomeHeight = maxAmount > 0 && _selectedTypes.contains('income')
                                    ? (dayData.income / maxAmount) * (isDesktop ? 160 : 120)
                                    : 0.0;
                                final expenseHeight = maxAmount > 0 && _selectedTypes.contains('expense')
                                    ? (dayData.expense / maxAmount) * (isDesktop ? 160 : 120)
                                    : 0.0;
                                final transferHeight = maxAmount > 0 && _selectedTypes.contains('transfer')
                                    ? (dayData.transfer / maxAmount) * (isDesktop ? 160 : 120)
                                    : 0.0;

                                final tooltipLines = <String>[DateFormat('MMM d').format(dayData.date)];
                                if (_selectedTypes.contains('income')) {
                                  tooltipLines.add('Income: ${currencyFormatter.currencySymbol}${NumberFormat('#,##0').format(dayData.income)}');
                                }
                                if (_selectedTypes.contains('expense')) {
                                  tooltipLines.add('Expense: ${currencyFormatter.currencySymbol}${NumberFormat('#,##0').format(dayData.expense)}');
                                }
                                if (_selectedTypes.contains('transfer')) {
                                  tooltipLines.add('Transfer: ${currencyFormatter.currencySymbol}${NumberFormat('#,##0').format(dayData.transfer)}');
                                }

                                return Tooltip(
                                  message: tooltipLines.join('\n'),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    children: [
                                      Row(
                                        crossAxisAlignment: CrossAxisAlignment.end,
                                        children: [
                                          // Income bar
                                          if (_selectedTypes.contains('income'))
                                            AnimatedContainer(
                                              duration: const Duration(milliseconds: 300),
                                              width: adjustedClampedBarWidth,
                                              height: incomeHeight,
                                              decoration: BoxDecoration(
                                                color: Colors.green.withValues(alpha: 0.8),
                                                borderRadius: const BorderRadius.vertical(
                                                  top: Radius.circular(3),
                                                ),
                                              ),
                                            ),
                                          if (_selectedTypes.contains('income') && _selectedTypes.length > 1)
                                            const SizedBox(width: 1),
                                          // Expense bar
                                          if (_selectedTypes.contains('expense'))
                                            AnimatedContainer(
                                              duration: const Duration(milliseconds: 300),
                                              width: adjustedClampedBarWidth,
                                              height: expenseHeight,
                                              decoration: BoxDecoration(
                                                color: Colors.red.withValues(alpha: 0.8),
                                                borderRadius: const BorderRadius.vertical(
                                                  top: Radius.circular(3),
                                                ),
                                              ),
                                            ),
                                          if (_selectedTypes.contains('expense') && _selectedTypes.contains('transfer'))
                                            const SizedBox(width: 1),
                                          // Transfer bar
                                          if (_selectedTypes.contains('transfer'))
                                            AnimatedContainer(
                                              duration: const Duration(milliseconds: 300),
                                              width: adjustedClampedBarWidth,
                                              height: transferHeight,
                                              decoration: BoxDecoration(
                                                color: Colors.blue.withValues(alpha: 0.8),
                                                borderRadius: const BorderRadius.vertical(
                                                  top: Radius.circular(3),
                                                ),
                                              ),
                                            ),
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      // Date label
                                      Text(
                                        DateFormat('d').format(dayData.date),
                                        style: TextStyle(
                                          fontSize: 9,
                                          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }).toList(),
                            );
                          },
                        ),
                ),
                const SizedBox(height: 12),
                // Summary row - only show selected types
                Row(
                  children: [
                    if (_selectedTypes.contains('income'))
                      Expanded(
                        child: _buildSummaryCard(
                          'Income',
                          data.fold<double>(0, (sum, d) => sum + d.income),
                          Colors.green,
                        ),
                      ),
                    if (_selectedTypes.contains('income') && _selectedTypes.length > 1)
                      const SizedBox(width: 8),
                    if (_selectedTypes.contains('expense'))
                      Expanded(
                        child: _buildSummaryCard(
                          'Expense',
                          data.fold<double>(0, (sum, d) => sum + d.expense),
                          Colors.red,
                        ),
                      ),
                    if (_selectedTypes.contains('expense') && _selectedTypes.contains('transfer'))
                      const SizedBox(width: 8),
                    if (_selectedTypes.contains('transfer'))
                      Expanded(
                        child: _buildSummaryCard(
                          'Transfer',
                          data.fold<double>(0, (sum, d) => sum + d.transfer),
                          Colors.blue,
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// Process transactions into daily income/expense/transfer aggregates
  List<DailyFinanceData> _processTransactionsToDaily(List<Transaction> transactions) {
    final Map<String, DailyFinanceData> dailyMap = {};

    // Initialize all days in the range with zero values
    for (int i = _daysToShow - 1; i >= 0; i--) {
      final date = DateTime.now().subtract(Duration(days: i));
      final dateKey = DateFormat('yyyy-MM-dd').format(date);
      dailyMap[dateKey] = DailyFinanceData(
        date: DateTime(date.year, date.month, date.day),
        income: 0,
        expense: 0,
        transfer: 0,
      );
    }

    // Aggregate transactions by day
    for (final transaction in transactions) {
      final dateKey = DateFormat('yyyy-MM-dd').format(transaction.date);
      if (dailyMap.containsKey(dateKey)) {
        final existing = dailyMap[dateKey]!;
        switch (transaction.type) {
          case TransactionType.income:
            dailyMap[dateKey] = DailyFinanceData(
              date: existing.date,
              income: existing.income + transaction.amount,
              expense: existing.expense,
              transfer: existing.transfer,
            );
            break;
          case TransactionType.expense:
            dailyMap[dateKey] = DailyFinanceData(
              date: existing.date,
              income: existing.income,
              expense: existing.expense + transaction.totalCost,
              transfer: existing.transfer,
            );
            break;
          case TransactionType.transfer:
            dailyMap[dateKey] = DailyFinanceData(
              date: existing.date,
              income: existing.income,
              expense: existing.expense,
              transfer: existing.transfer + transaction.amount,
            );
            break;
        }
      }
    }

    // Convert to sorted list
    final result = dailyMap.values.toList();
    result.sort((a, b) => a.date.compareTo(b.date));
    return result;
  }

  Widget _buildLegendIndicator(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.8),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
          ),
        ),
      ],
    );
  }

  Widget _buildFilterChip(String type, String label, Color color) {
    final isSelected = _selectedTypes.contains(type);
    return FilterChip(
      label: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          color: isSelected ? Colors.white : color,
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
        ),
      ),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          if (selected) {
            _selectedTypes.add(type);
          } else {
            if (_selectedTypes.length > 1) {
              _selectedTypes.remove(type);
            }
          }
        });
      },
      selectedColor: color,
      backgroundColor: color.withValues(alpha: 0.1),
      checkmarkColor: Colors.white,
      side: BorderSide(color: color.withValues(alpha: 0.3)),
      padding: const EdgeInsets.symmetric(horizontal: 4),
      visualDensity: VisualDensity.compact,
    );
  }

  Widget _buildSummaryCard(String title, double amount, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 11,
              color: color.withValues(alpha: 0.8),
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${currencyFormatter.currencySymbol}${NumberFormat('#,##0.00').format(amount)}',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  List<DailyFinanceData> _generateDummyFinanceData() {
    final random = DateTime.now().millisecondsSinceEpoch;
    final List<DailyFinanceData> data = [];

    for (int i = _daysToShow - 1; i >= 0; i--) {
      final date = DateTime.now().subtract(Duration(days: i));
      // Generate somewhat realistic dummy data
      final baseIncome = (random + i * 1000) % 500 + 100;
      final baseExpense = (random + i * 500) % 400 + 50;
      data.add(DailyFinanceData(
        date: date,
        income: baseIncome.toDouble() * (1 + (i % 3) * 0.3),
        expense: baseExpense.toDouble() * (1 + (i % 4) * 0.25),
      ));
    }

    return data;
  }

  Widget _buildFinanceSnapshot(bool isDesktop) {
    return AsyncStreamBuilder<List<Account>>(
      state: _accountController,
      loadingBuilder: (_) => Card(
        elevation: 0,
        margin: EdgeInsets.zero,
        child: Container(
          height: 250,
          alignment: Alignment.center,
          child: const CircularProgressIndicator(),
        ),
      ),
      errorBuilder: (context, message) => Card(
        elevation: 0,
        margin: EdgeInsets.zero,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Text('Error loading finance data: $message'),
        ),
      ),
      builder: (context, accounts) {
        final totalBalance = accounts.fold<double>(
          0.0,
          (sum, account) => sum + account.balance,
        );

        return AsyncStreamBuilder<List<Budget>>(
          state: _budgetController,
          loadingBuilder: (_) => Card(
            elevation: 0,
            margin: EdgeInsets.zero,
            child: Container(
              height: 250,
              alignment: Alignment.center,
              child: const CircularProgressIndicator(),
            ),
          ),
          errorBuilder: (context, message) =>
              _buildFinanceCard(totalBalance, accounts.length, []),
          builder: (context, budgets) {
            final activeBudgets =
                budgets.where((b) => b.status == BudgetStatus.active).toList()
                  ..sort((a, b) => b.month.compareTo(a.month));

            return _buildFinanceCard(
              totalBalance,
              accounts.length,
              activeBudgets,
            );
          },
        );
      },
    );
  }

  Widget _buildFinanceCard(
    double totalBalance,
    int accountCount,
    List<Budget> budgets,
  ) {
    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Finance Overview',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.account_balance_wallet,
                        size: 16,
                        color: Colors.green[700],
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '$accountCount Accounts',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.green[700],
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Account Balance
            Text(
              '${currencyFormatter.currencySymbol}${NumberFormat('#,##0.00').format(totalBalance)}',
              style: const TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.green,
              ),
            ),
            const Text(
              'Current Balance',
              style: TextStyle(color: Colors.grey, fontSize: 14),
            ),
            const SizedBox(height: 24),

            // Active Budgets Section
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Active Budgets',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.blue.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${budgets.length}',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue[700],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Budgets List or Empty State
            if (budgets.isEmpty)
              Container(
                height: 80,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'No active budgets\nCreate a budget to track spending',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
              )
            else
              ...budgets
                  .take(3)
                  .map((budget) => _buildBudgetSummaryCard(budget)),

            // View All Button
            if (budgets.length > 3)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: TextButton(
                  onPressed: () {
                    Navigator.pushNamed(context, AppRoutes.budgetList);
                  },
                  child: Text('View all ${budgets.length} budgets'),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildBudgetSummaryCard(Budget budget) {
    final spent = budget.totalSpent;
    final target = budget.budgetTarget;
    final percentage = target > 0 ? (spent / target).clamp(0.0, 1.0) : 0.0;
    final isOverBudget = spent > target;

    final color = budget.budgetType == BudgetType.income
        ? Colors.green
        : budget.budgetType == BudgetType.expense
        ? Colors.red
        : Colors.blue;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () {
          Navigator.pushNamed(
            context,
            AppRoutes.budgetDetail,
            arguments: budget,
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withValues(alpha: 0.2)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(
                        budget.budgetType == BudgetType.income
                            ? Icons.arrow_downward
                            : Icons.arrow_upward,
                        size: 16,
                        color: color,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        budget.title != null && budget.title!.isNotEmpty
                            ? budget.title!
                            : _formatMonthDisplay(budget.month),
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: color,
                        ),
                      ),
                    ],
                  ),
                  if (isOverBudget && budget.budgetType == BudgetType.expense)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.red.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        'Over',
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.red,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              TweenAnimationBuilder<double>(
                duration: const Duration(milliseconds: 800),
                curve: Curves.easeOutCubic,
                tween: Tween<double>(begin: 0, end: percentage),
                builder: (context, value, child) {
                  return LinearProgressIndicator(
                    value: value,
                    backgroundColor: Colors.grey[300],
                    valueColor: AlwaysStoppedAnimation(
                      isOverBudget && budget.budgetType == BudgetType.expense
                          ? Colors.red
                          : color,
                    ),
                    minHeight: 6,
                    borderRadius: BorderRadius.circular(3),
                  );
                },
              ),
              const SizedBox(height: 6),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${currencyFormatter.currencySymbol}${NumberFormat('#,##0').format(spent)} / ${currencyFormatter.currencySymbol}${NumberFormat('#,##0').format(target)}',
                    style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                  ),
                  Text(
                    '${(percentage * 100).toStringAsFixed(0)}%',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: color,
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

  @Deprecated("Unused function")
  // ignore: unused_element
  Widget _buildLegendItem(Color color, String label) {
    return Builder(
      builder: (context) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWelcomeSection(bool isDesktop) {
    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [const Color(0xFF6366F1), const Color(0xFF818CF8)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        padding: EdgeInsets.all(isDesktop ? AppSpacing.xl : AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(_getGreetingIcon(), color: Colors.white, size: 28),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _getGreeting(),
                        style: TextStyle(
                          fontSize: isDesktop ? 28 : 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      const Text(
                        'Welcome back!',
                        style: TextStyle(color: Colors.white70, fontSize: 14),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.today, color: Colors.white, size: 20),
                  const SizedBox(width: AppSpacing.sm),
                  Text(
                    DateFormat('EEEE, MMMM d, y').format(DateTime.now()),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
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

  Widget _buildQuickActions(BuildContext context, bool isDesktop) {
    final actions = [
      (
        'Add Transaction',
        Icons.add_circle,
        Colors.green,
        () {
          Navigator.pushNamed(context, AppRoutes.transactionCreate);
        },
      ),
      (
        'View Budget',
        Icons.account_balance,
        Colors.purple,
        () {
          Navigator.pushNamed(context, AppRoutes.budgetManagement);
        },
      ),
      (
        'Settings',
        Icons.settings,
        Colors.orange,
        () {
          Navigator.pushNamed(context, AppRoutes.settings);
        },
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Actions',
          style: TextStyle(
            fontSize: isDesktop ? 20 : 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: isDesktop ? 1 : 2,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: isDesktop ? 2.5 : 1.5,
          children: actions
              .map(
                (action) => _buildQuickActionButton(
                  label: action.$1,
                  icon: action.$2,
                  color: action.$3,
                  onTap: action.$4,
                  isDesktop: isDesktop,
                ),
              )
              .toList(),
        ),
      ],
    );
  }

  Widget _buildQuickActionButton({
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
    required bool isDesktop,
  }) {
    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withOpacity(0.2)),
          ),
          child: isDesktop
              ? Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(icon, color: color, size: 24),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        label,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                        ),
                      ),
                    ),
                    Icon(
                      Icons.arrow_forward_ios,
                      size: 16,
                      color: Colors.grey[400],
                    ),
                  ],
                )
              : Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(icon, color: color, size: 28),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      label,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}

// Data class for daily finance data
class DailyFinanceData {
  final DateTime date;
  final double income;
  final double expense;
  final double transfer;

  DailyFinanceData({
    required this.date,
    required this.income,
    required this.expense,
    this.transfer = 0,
  });
}
