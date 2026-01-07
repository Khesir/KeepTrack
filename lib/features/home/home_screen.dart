import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:keep_track/core/di/service_locator.dart';
import 'package:keep_track/core/settings/utils/currency_formatter.dart';
import 'package:keep_track/core/state/stream_builder_widget.dart';
import 'package:keep_track/core/ui/app_layout_controller.dart';
import 'package:keep_track/core/ui/ui.dart';
import 'package:keep_track/core/routing/app_router.dart';
import 'package:keep_track/features/finance/modules/account/domain/entities/account.dart';
import 'package:keep_track/features/finance/modules/budget/domain/entities/budget.dart';
import 'package:keep_track/features/finance/presentation/state/account_controller.dart';
import 'package:keep_track/features/finance/presentation/state/budget_controller.dart';
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

  @override
  void registerServices() {
    _accountController = locator.get<AccountController>();
    _budgetController = locator.get<BudgetController>();
  }

  @override
  void onReady() {
    configureLayout(title: 'Home', showBottomNav: true);
    _accountController.loadAccounts();
    _budgetController.loadBudgets();
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning';
    if (hour < 17) return 'Good Afternoon';
    return 'Good Evening';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Admin Panel (only visible for admin users)
            const AdminPanelWidget(),

            // Welcome Section
            _buildWelcomeSection(),
            const SizedBox(height: 24),

            // Finance Snapshot
            _buildFinanceSnapshot(),
            const SizedBox(height: 24),

            // Quick Actions
            _buildQuickActions(context),
            const SizedBox(height: 24),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.pushNamed(context, AppRoutes.transactionCreate);
        },
        icon: const Icon(Icons.add),
        label: const Text('Add Transaction'),
        backgroundColor: Colors.green,
      ),
    );
  }

  Widget _buildWelcomeSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue[700]!, Colors.blue[500]!],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(_getGreetingIcon(), color: Colors.white, size: 28),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _getGreeting(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Text(
                      'Welcome back!',
                      style: TextStyle(color: Colors.white70, fontSize: 14),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                const Icon(Icons.today, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                Text(
                  DateTime.now().toString().split(' ')[0],
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
    );
  }

  IconData _getGreetingIcon() {
    final hour = DateTime.now().hour;
    if (hour < 12) return Icons.wb_sunny;
    if (hour < 17) return Icons.wb_sunny_outlined;
    return Icons.nightlight_round;
  }

  Widget _buildFinanceSnapshot() {
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
        // Calculate total balance across all accounts
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
            // Get all active budgets, sorted by month descending
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
              LinearProgressIndicator(
                value: percentage,
                backgroundColor: Colors.grey[300],
                valueColor: AlwaysStoppedAnimation(
                  isOverBudget && budget.budgetType == BudgetType.expense
                      ? Colors.red
                      : color,
                ),
                minHeight: 6,
                borderRadius: BorderRadius.circular(3),
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

  Widget _buildQuickActions(BuildContext context) {
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
        const Text(
          'Quick Actions',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 1.5,
          children: actions
              .map(
                (action) => _buildQuickActionButton(
                  label: action.$1,
                  icon: action.$2,
                  color: action.$3,
                  onTap: action.$4,
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
          child: Column(
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
