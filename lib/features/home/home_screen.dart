import 'package:flutter/material.dart';
import 'package:persona_codex/core/ui/app_layout_controller.dart';
import 'package:persona_codex/core/ui/ui.dart';
import 'package:persona_codex/core/routing/app_router.dart';
import 'package:persona_codex/features/home/widgets/admin_panel_widget.dart';

class HomeScreen extends ScopedScreen {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ScopedScreenState<HomeScreen>
    with AppLayoutControlled {
  @override
  void registerServices() {
    // No services needed for now
  }

  @override
  void onReady() {
    configureLayout(title: 'Home', showBottomNav: true);
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
    // Mock data
    const mainAccountBalance = 45000.0;
    const budgetAmount = 60000.0;
    const plannedExpenses = 35000.0;
    const actualSpent = 15000.0;

    final plannedPercentage = (plannedExpenses / budgetAmount).clamp(0.0, 1.0);
    final actualPercentage = (actualSpent / budgetAmount).clamp(0.0, 1.0);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
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
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.account_balance_wallet,
                         size: 16, color: Colors.green[700]),
                    const SizedBox(width: 4),
                    Text(
                      'Main Wallet',
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
            '₱${mainAccountBalance.toStringAsFixed(2)}',
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
          const Text(
            'Monthly Budget',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
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
            child: Stack(
              children: [
                // Planned background (yellow/orange)
                if (plannedPercentage > 0)
                  FractionallySizedBox(
                    widthFactor: plannedPercentage,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.orange[300],
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                // Actual spent (red)
                if (actualPercentage > 0)
                  FractionallySizedBox(
                    widthFactor: actualPercentage,
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.red[400]!, Colors.red[600]!],
                        ),
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.red.withOpacity(0.3),
                            blurRadius: 4,
                          ),
                        ],
                      ),
                    ),
                  ),
                // Amount text overlay
                Center(
                  child: Text(
                    '₱${actualSpent.toStringAsFixed(0)} / ₱${budgetAmount.toStringAsFixed(0)}',
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
            ),
          ),
          const SizedBox(height: 12),

          // Legend
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildLegendItem(Colors.red[500]!, 'Spent'),
              const SizedBox(width: 16),
              _buildLegendItem(Colors.orange[300]!, 'Planned'),
              const SizedBox(width: 16),
              _buildLegendItem(Colors.grey[300]!, 'Remaining'),
            ],
          ),
        ],
      ),
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
          style: const TextStyle(fontSize: 12, color: Colors.grey),
        ),
      ],
    );
  }

  Widget _buildStatusSnapshots() {
    return Row(
      children: [
        Expanded(
          child: _buildStatusCard(
            title: 'Tasks',
            icon: Icons.task_alt,
            color: Colors.blue,
            mainStat: '12',
            mainLabel: 'Active',
            subStats: [
              ('3', 'Urgent'),
              ('5', 'Due Today'),
            ],
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildStatusCard(
            title: 'Money',
            icon: Icons.account_balance_wallet,
            color: Colors.green,
            mainStat: '₱45K',
            mainLabel: 'Available',
            subStats: [
              ('3', 'Accounts'),
              ('₱15K', 'Spent'),
            ],
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
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
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
            style: const TextStyle(
              color: Colors.grey,
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
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
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
    );
  }

  Widget _buildTodaysTasks() {
    // Mock data
    final todayTasks = [
      ('Complete project proposal', true, Colors.red),
      ('Team meeting at 2 PM', false, Colors.orange),
      ('Review code changes', false, Colors.blue),
    ];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
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
                  // Navigate to tasks
                },
                child: const Text('View All'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (todayTasks.isEmpty)
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
            ...todayTasks.map((task) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    children: [
                      Container(
                        width: 4,
                        height: 40,
                        decoration: BoxDecoration(
                          color: task.$3,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          task.$1,
                          style: TextStyle(
                            fontSize: 14,
                            decoration: task.$2
                                ? TextDecoration.lineThrough
                                : null,
                            color: task.$2 ? Colors.grey : null,
                          ),
                        ),
                      ),
                      Checkbox(
                        value: task.$2,
                        onChanged: (value) {},
                      ),
                    ],
                  ),
                )),
        ],
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    final actions = [
      ('New Task', Icons.add_task, Colors.blue, () {
        Navigator.pushNamed(context, AppRoutes.taskCreate);
      }),
      ('Add Transaction', Icons.add_circle, Colors.green, () {
        // Navigate to create transaction
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
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      elevation: 2,
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
