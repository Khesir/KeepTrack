import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:persona_codex/core/di/service_locator.dart';
import 'package:persona_codex/core/state/stream_builder_widget.dart';
import 'package:persona_codex/core/ui/app_layout_controller.dart';
import 'package:persona_codex/core/ui/ui.dart';
import 'package:persona_codex/core/routing/app_router.dart';
import 'package:persona_codex/features/finance/modules/account/domain/entities/account.dart';
import 'package:persona_codex/features/finance/modules/budget/domain/entities/budget.dart';
import 'package:persona_codex/features/finance/presentation/state/account_controller.dart';
import 'package:persona_codex/features/finance/presentation/state/budget_controller.dart';
import 'package:persona_codex/features/home/widgets/admin_panel_widget.dart';
import 'package:persona_codex/features/tasks/modules/tasks/domain/entities/task.dart';
import 'package:persona_codex/features/tasks/presentation/state/task_controller.dart';

class HomeScreen extends ScopedScreen {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ScopedScreenState<HomeScreen>
    with AppLayoutControlled {
  late final AccountController _accountController;
  late final BudgetController _budgetController;
  late final TaskController _taskController;

  @override
  void registerServices() {
    _accountController = locator.get<AccountController>();
    _budgetController = locator.get<BudgetController>();
    _taskController = locator.get<TaskController>();
  }

  @override
  void onReady() {
    configureLayout(title: 'Home', showBottomNav: true);
    _accountController.loadAccounts();
    _budgetController.loadBudgets();
    _taskController.loadTasks();
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning';
    if (hour < 17) return 'Good Afternoon';
    return 'Good Evening';
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
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

          // Status Snapshots (Tasks & Money)
          _buildStatusSnapshots(),
          const SizedBox(height: 24),

          // Today's Tasks/Focus
          _buildTodaysTasks(),
          const SizedBox(height: 24),

          // Quick Actions
          _buildQuickActions(context),
          const SizedBox(height: 24),
        ],
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
              Icon(
                _getGreetingIcon(),
                color: Colors.white,
                size: 28,
              ),
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
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
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
          errorBuilder: (context, message) => _buildFinanceCard(
            totalBalance,
            accounts.length,
            null,
          ),
          builder: (context, budgets) {
            // Get current month budget
            final currentMonth = DateFormat('yyyy-MM').format(DateTime.now());
            Budget? currentBudget;
            try {
              currentBudget = budgets.firstWhere(
                (b) => b.month == currentMonth && b.status == BudgetStatus.active,
              );
            } catch (e) {
              currentBudget = null;
            }

            return _buildFinanceCard(totalBalance, accounts.length, currentBudget);
          },
        );
      },
    );
  }

  Widget _buildFinanceCard(double totalBalance, int accountCount, Budget? budget) {
    final budgetTarget = budget?.budgetTarget ?? 0.0;
    final actualSpent = budget?.totalSpent ?? 0.0;

    final actualPercentage = budgetTarget > 0
        ? (actualSpent / budgetTarget).clamp(0.0, 1.0)
        : 0.0;

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
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.account_balance_wallet,
                          size: 16, color: Colors.green[700]),
                      const SizedBox(width: 4),
                      Text(
                        'All Accounts',
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
              '₱${NumberFormat('#,##0.00').format(totalBalance)}',
              style: const TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.green,
              ),
            ),
            const Text(
              'Current Balance',
              style: TextStyle(
                color: Colors.grey,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 24),

            // Budget HP Bar
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Monthly Budget',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                if (budget == null)
                  Text(
                    'No active budget',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                      fontStyle: FontStyle.italic,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),

            // HP-style bar
            Container(
              height: 32,
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey[300]!, width: 2),
              ),
              child: budget != null
                  ? Stack(
                      children: [
                        // Actual spent
                        if (actualPercentage > 0)
                          FractionallySizedBox(
                            widthFactor: actualPercentage,
                            child: Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: budget.isOverBudget
                                      ? [Colors.red[400]!, Colors.red[600]!]
                                      : [Colors.blue[400]!, Colors.blue[600]!],
                                ),
                                borderRadius: BorderRadius.circular(14),
                                boxShadow: [
                                  BoxShadow(
                                    color: (budget.isOverBudget
                                            ? Colors.red
                                            : Colors.blue)
                                        .withOpacity(0.3),
                                    blurRadius: 4,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        // Amount text overlay
                        Center(
                          child: Text(
                            '₱${actualSpent.toStringAsFixed(0)} / ₱${budgetTarget.toStringAsFixed(0)}',
                            style: const TextStyle(
                              fontSize: 12,
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
                    )
                  : const Center(
                      child: Text(
                        'Create a budget to track spending',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey,
                        ),
                      ),
                    ),
            ),
            const SizedBox(height: 12),

            // Legend
            if (budget != null)
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
        ),
      ),
    );
  }

  Widget _buildLegendItem(Color color, String label) {
    return Builder(
      builder: (context) => Row(
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
            style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6)),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusSnapshots() {
    return Row(
      children: [
        Expanded(
          child: AsyncStreamBuilder<List<Task>>(
            state: _taskController,
            loadingBuilder: (_) => Card(
              elevation: 0,
              margin: EdgeInsets.zero,
              child: Container(
                height: 150,
                alignment: Alignment.center,
                child: const CircularProgressIndicator(),
              ),
            ),
            errorBuilder: (context, message) => _buildStatusCard(
              title: 'Tasks',
              icon: Icons.task_alt,
              color: Colors.blue,
              mainStat: 'Error',
              mainLabel: 'Loading failed',
              subStats: [],
            ),
            builder: (context, tasks) {
              // Calculate task statistics
              final activeTasks = tasks.where((t) =>
                t.status != TaskStatus.completed &&
                t.status != TaskStatus.cancelled &&
                !t.archived
              ).toList();

              final urgentTasks = tasks.where((t) =>
                t.priority == TaskPriority.urgent &&
                t.status != TaskStatus.completed &&
                !t.archived
              ).length;

              final today = DateTime.now();
              final todayStart = DateTime(today.year, today.month, today.day);
              final todayEnd = todayStart.add(const Duration(days: 1));

              final dueToday = tasks.where((t) =>
                t.dueDate != null &&
                t.dueDate!.isAfter(todayStart) &&
                t.dueDate!.isBefore(todayEnd) &&
                t.status != TaskStatus.completed &&
                !t.archived
              ).length;

              return _buildStatusCard(
                title: 'Tasks',
                icon: Icons.task_alt,
                color: Colors.blue,
                mainStat: '${activeTasks.length}',
                mainLabel: 'Active',
                subStats: [
                  ('$urgentTasks', 'Urgent'),
                  ('$dueToday', 'Due Today'),
                ],
              );
            },
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: AsyncStreamBuilder<List<Account>>(
            state: _accountController,
            loadingBuilder: (_) => Card(
              elevation: 0,
              margin: EdgeInsets.zero,
              child: Container(
                height: 150,
                alignment: Alignment.center,
                child: const CircularProgressIndicator(),
              ),
            ),
            errorBuilder: (context, message) => _buildStatusCard(
              title: 'Money',
              icon: Icons.account_balance_wallet,
              color: Colors.green,
              mainStat: 'Error',
              mainLabel: 'Loading failed',
              subStats: [],
            ),
            builder: (context, accounts) {
              final totalBalance = accounts.fold<double>(
                0.0,
                (sum, account) => sum + account.balance,
              );

              // Format balance for loading/error states
              final balanceKFormatted = totalBalance >= 1000
                  ? '₱${(totalBalance / 1000).toStringAsFixed(1)}K'
                  : '₱${totalBalance.toStringAsFixed(0)}';

              return AsyncStreamBuilder<List<Budget>>(
                state: _budgetController,
                loadingBuilder: (_) => _buildStatusCard(
                  title: 'Money',
                  icon: Icons.account_balance_wallet,
                  color: Colors.green,
                  mainStat: balanceKFormatted,
                  mainLabel: 'Available',
                  subStats: [
                    ('${accounts.length}', accounts.length == 1 ? 'Account' : 'Accounts'),
                    ('--', 'Spent'),
                  ],
                ),
                errorBuilder: (context, message) => _buildStatusCard(
                  title: 'Money',
                  icon: Icons.account_balance_wallet,
                  color: Colors.green,
                  mainStat: balanceKFormatted,
                  mainLabel: 'Available',
                  subStats: [
                    ('${accounts.length}', accounts.length == 1 ? 'Account' : 'Accounts'),
                    ('--', 'Spent'),
                  ],
                ),
                builder: (context, budgets) {
                  // Get current month budget
                  final currentMonth = DateFormat('yyyy-MM').format(DateTime.now());
                  Budget? currentBudget;
                  try {
                    currentBudget = budgets.firstWhere(
                      (b) => b.month == currentMonth && b.status == BudgetStatus.active,
                    );
                  } catch (e) {
                    currentBudget = null;
                  }

                  final spent = currentBudget?.totalSpent ?? 0.0;

                  // Format balance in K format
                  final balanceK = totalBalance >= 1000
                      ? '₱${(totalBalance / 1000).toStringAsFixed(1)}K'
                      : '₱${totalBalance.toStringAsFixed(0)}';

                  // Format spent in K format
                  final spentK = spent >= 1000
                      ? '₱${(spent / 1000).toStringAsFixed(1)}K'
                      : '₱${spent.toStringAsFixed(0)}';

                  return _buildStatusCard(
                    title: 'Money',
                    icon: Icons.account_balance_wallet,
                    color: Colors.green,
                    mainStat: balanceK,
                    mainLabel: 'Available',
                    subStats: [
                      ('${accounts.length}', accounts.length == 1 ? 'Account' : 'Accounts'),
                      (spentK, 'Spent'),
                    ],
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildStatusCard({
    required String title,
    required IconData icon,
    required Color color,
    required String mainStat,
    required String mainLabel,
    required List<(String, String)> subStats,
  }) {
    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            mainStat,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            mainLabel,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 12),
          const Divider(height: 1),
          const SizedBox(height: 8),
          ...subStats.map((stat) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      stat.$2,
                      style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6)),
                    ),
                    Text(
                      stat.$1,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              )),
        ],
        ),
      ),
    );
  }

  Widget _buildTodaysTasks() {
    return AsyncStreamBuilder<List<Task>>(
      state: _taskController,
      loadingBuilder: (_) => Card(
        elevation: 0,
        margin: EdgeInsets.zero,
        child: Container(
          height: 200,
          alignment: Alignment.center,
          child: const CircularProgressIndicator(),
        ),
      ),
      errorBuilder: (context, message) => Card(
        elevation: 0,
        margin: EdgeInsets.zero,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Text('Error loading tasks: $message'),
        ),
      ),
      builder: (context, tasks) {
        // Get today's date range
        final today = DateTime.now();
        final todayStart = DateTime(today.year, today.month, today.day);
        final todayEnd = todayStart.add(const Duration(days: 1));

        // Filter tasks: due today, overdue, or high/urgent priority
        final focusTasks = tasks.where((t) {
          // Skip completed, cancelled, or archived tasks
          if (t.status == TaskStatus.completed ||
              t.status == TaskStatus.cancelled ||
              t.archived) {
            return false;
          }

          // Include if due today
          if (t.dueDate != null &&
              t.dueDate!.isAfter(todayStart) &&
              t.dueDate!.isBefore(todayEnd)) {
            return true;
          }

          // Include if overdue
          if (t.isOverdue) {
            return true;
          }

          // Include if high or urgent priority
          if (t.priority == TaskPriority.urgent ||
              t.priority == TaskPriority.high) {
            return true;
          }

          return false;
        }).take(5).toList(); // Limit to 5 tasks

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
                      'Today\'s Focus',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.pushNamed(context, AppRoutes.taskList);
                      },
                      child: const Text('View All'),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                if (focusTasks.isEmpty)
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        children: [
                          Icon(Icons.check_circle_outline,
                              size: 48, color: Colors.grey[400]),
                          const SizedBox(height: 8),
                          Text(
                            'No tasks for today',
                            style: TextStyle(color: Colors.grey[600]),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  ...focusTasks.map((task) {
                    // Determine color based on priority and status
                    Color indicatorColor;
                    if (task.isOverdue) {
                      indicatorColor = Colors.red;
                    } else if (task.priority == TaskPriority.urgent) {
                      indicatorColor = Colors.red;
                    } else if (task.priority == TaskPriority.high) {
                      indicatorColor = Colors.orange;
                    } else {
                      indicatorColor = Colors.blue;
                    }

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: InkWell(
                        onTap: () {
                          // Navigate to task list
                          Navigator.pushNamed(context, AppRoutes.taskList);
                        },
                        borderRadius: BorderRadius.circular(8),
                        child: Padding(
                          padding: const EdgeInsets.all(4),
                          child: Row(
                            children: [
                              Container(
                                width: 4,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: indicatorColor,
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      task.title,
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                        decoration: task.status == TaskStatus.completed
                                            ? TextDecoration.lineThrough
                                            : null,
                                        color: task.status == TaskStatus.completed
                                            ? Colors.grey
                                            : null,
                                      ),
                                    ),
                                    if (task.dueDate != null || task.priority != TaskPriority.low)
                                      const SizedBox(height: 4),
                                    if (task.dueDate != null || task.priority != TaskPriority.low)
                                      Row(
                                        children: [
                                          if (task.isOverdue)
                                            Container(
                                              padding: const EdgeInsets.symmetric(
                                                horizontal: 6,
                                                vertical: 2,
                                              ),
                                              decoration: BoxDecoration(
                                                color: Colors.red.withOpacity(0.1),
                                                borderRadius: BorderRadius.circular(4),
                                              ),
                                              child: const Text(
                                                'Overdue',
                                                style: TextStyle(
                                                  fontSize: 10,
                                                  color: Colors.red,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                            ),
                                          if (task.isOverdue && task.priority != TaskPriority.low)
                                            const SizedBox(width: 6),
                                          if (task.priority != TaskPriority.low)
                                            Container(
                                              padding: const EdgeInsets.symmetric(
                                                horizontal: 6,
                                                vertical: 2,
                                              ),
                                              decoration: BoxDecoration(
                                                color: indicatorColor.withOpacity(0.1),
                                                borderRadius: BorderRadius.circular(4),
                                              ),
                                              child: Text(
                                                task.priority.displayName,
                                                style: TextStyle(
                                                  fontSize: 10,
                                                  color: indicatorColor,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                            ),
                                        ],
                                      ),
                                  ],
                                ),
                              ),
                              Checkbox(
                                value: task.status == TaskStatus.completed,
                                onChanged: (value) async {
                                  if (value == true) {
                                    await _taskController.updateTask(
                                      task.copyWith(
                                        status: TaskStatus.completed,
                                        completedAt: DateTime.now(),
                                      ),
                                    );
                                  } else {
                                    await _taskController.updateTask(
                                      task.copyWith(
                                        status: TaskStatus.todo,
                                        completedAt: null,
                                      ),
                                    );
                                  }
                                },
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    final actions = [
      ('New Task', Icons.add_task, Colors.blue, () {
        Navigator.pushNamed(context, AppRoutes.taskCreate);
      }),
      ('Add Transaction', Icons.add_circle, Colors.green, () {
        Navigator.pushNamed(context, AppRoutes.transactionCreate);
      }),
      ('View Budget', Icons.account_balance, Colors.purple, () {
        Navigator.pushNamed(context, AppRoutes.budgetList);
      }),
      ('Settings', Icons.settings, Colors.orange, () {
        Navigator.pushNamed(context, AppRoutes.settings);
      }),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Quick Actions',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
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
              .map((action) => _buildQuickActionButton(
                    label: action.$1,
                    icon: action.$2,
                    color: action.$3,
                    onTap: action.$4,
                  ))
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
