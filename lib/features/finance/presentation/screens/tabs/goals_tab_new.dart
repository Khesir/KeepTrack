import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Goals Tab - Track financial goals and savings targets
class GoalsTabNew extends StatefulWidget {
  const GoalsTabNew({super.key});

  @override
  State<GoalsTabNew> createState() => _GoalsTabNewState();
}

class _GoalsTabNewState extends State<GoalsTabNew> {
  String _selectedFilter = 'All'; // All, Active, Completed, Paused

  @override
  Widget build(BuildContext context) {
    // Calculate summary stats
    final activeGoals = dummyGoals.where((g) => g.status == GoalStatus.active).toList();
    final totalTargetAmount = activeGoals.fold<double>(0, (sum, goal) => sum + goal.targetAmount);
    final totalSavedAmount = activeGoals.fold<double>(0, (sum, goal) => sum + goal.currentAmount);
    final overallProgress = totalTargetAmount > 0 ? totalSavedAmount / totalTargetAmount : 0.0;

    // Filter goals
    final filteredGoals = _selectedFilter == 'All'
        ? dummyGoals
        : dummyGoals.where((g) =>
            _selectedFilter == 'Active'
              ? g.status == GoalStatus.active
              : _selectedFilter == 'Completed'
                ? g.status == GoalStatus.completed
                : g.status == GoalStatus.paused
          ).toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Overall Progress Card
          _buildOverallProgressCard(totalTargetAmount, totalSavedAmount, overallProgress, activeGoals.length),
          const SizedBox(height: 24),

          // Filter Chips
          Row(
            children: [
              _buildFilterChip('All'),
              const SizedBox(width: 8),
              _buildFilterChip('Active'),
              const SizedBox(width: 8),
              _buildFilterChip('Completed'),
              const SizedBox(width: 8),
              _buildFilterChip('Paused'),
              const Spacer(),
              Text(
                '${filteredGoals.length} ${filteredGoals.length == 1 ? 'goal' : 'goals'}',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Goals List
          if (filteredGoals.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(48),
                child: Column(
                  children: [
                    Icon(
                      Icons.flag_outlined,
                      size: 64,
                      color: Colors.grey[300],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No goals found',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: filteredGoals.length,
              itemBuilder: (context, index) {
                final goal = filteredGoals[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _buildGoalCard(goal),
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildOverallProgressCard(
    double totalTarget,
    double totalSaved,
    double progress,
    int activeCount,
  ) {
    return Card(
      elevation: 0,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.purple[700]!, Colors.purple[500]!],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.track_changes,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Overall Progress',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Total Saved',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        NumberFormat.currency(symbol: '₱', decimalDigits: 0).format(totalSaved),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'of ${NumberFormat.currency(symbol: '₱', decimalDigits: 0).format(totalTarget)}',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    children: [
                      Text(
                        '${(progress * 100).toStringAsFixed(0)}%',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '$activeCount active',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: progress.clamp(0.0, 1.0),
                minHeight: 8,
                backgroundColor: Colors.white.withOpacity(0.3),
                valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label) {
    final isSelected = _selectedFilter == label;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _selectedFilter = label;
        });
      },
      selectedColor: Theme.of(context).colorScheme.primary.withOpacity(0.2),
      checkmarkColor: Theme.of(context).colorScheme.primary,
      labelStyle: TextStyle(
        color: isSelected
          ? Theme.of(context).colorScheme.primary
          : Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
    );
  }

  Widget _buildGoalCard(GoalItem goal) {
    final progress = goal.targetAmount > 0 ? goal.currentAmount / goal.targetAmount : 0.0;
    final remaining = goal.targetAmount - goal.currentAmount;
    final daysRemaining = goal.targetDate?.difference(DateTime.now()).inDays ?? 0;

    return Card(
      elevation: 0,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          // Navigate to goal detail
        },
        child: Container(
          decoration: BoxDecoration(
            border: Border(
              left: BorderSide(
                color: goal.color,
                width: 4,
              ),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: goal.color.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        goal.icon,
                        color: goal.color,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            goal.name,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            goal.description,
                            style: TextStyle(
                              fontSize: 13,
                              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: _getStatusColor(goal.status).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        _getStatusText(goal.status),
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: _getStatusColor(goal.status),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Amount Progress
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Current',
                            style: TextStyle(
                              fontSize: 11,
                              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            NumberFormat.currency(symbol: '₱', decimalDigits: 0)
                                .format(goal.currentAmount),
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: goal.color,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          'Target',
                          style: TextStyle(
                            fontSize: 11,
                            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          NumberFormat.currency(symbol: '₱', decimalDigits: 0)
                              .format(goal.targetAmount),
                          style: TextStyle(
                            fontSize: 16,
                            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Progress Bar
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          remaining > 0
                            ? '${NumberFormat.currency(symbol: '₱', decimalDigits: 0).format(remaining)} to go'
                            : 'Goal Achieved!',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: remaining > 0
                              ? Theme.of(context).colorScheme.onSurface.withOpacity(0.6)
                              : Colors.green[700],
                          ),
                        ),
                        Text(
                          '${(progress * 100).toStringAsFixed(0)}%',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: goal.color,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: progress.clamp(0.0, 1.0),
                        backgroundColor: goal.color.withOpacity(0.1),
                        valueColor: AlwaysStoppedAnimation<Color>(goal.color),
                        minHeight: 8,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Target Date and Days Remaining
                Row(
                  children: [
                    if (goal.targetDate != null) ...[
                      Icon(
                        Icons.event,
                        size: 14,
                        color: daysRemaining < 30
                          ? Colors.orange[700]
                          : Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Target: ${DateFormat('MMM d, yyyy').format(goal.targetDate!)}',
                        style: TextStyle(
                          fontSize: 12,
                          color: daysRemaining < 30
                            ? Colors.orange[700]
                            : Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                          fontWeight: daysRemaining < 30 ? FontWeight.w600 : FontWeight.normal,
                        ),
                      ),
                      if (daysRemaining > 0) ...[
                        const SizedBox(width: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: daysRemaining < 30
                              ? Colors.orange[50]
                              : Colors.blue[50],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '$daysRemaining days left',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: daysRemaining < 30
                                ? Colors.orange[700]
                                : Colors.blue[700],
                            ),
                          ),
                        ),
                      ],
                    ],
                  ],
                ),

                // Monthly contribution
                if (goal.monthlyContribution > 0) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.green[50],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.autorenew,
                          size: 16,
                          color: Colors.green[700],
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Monthly contribution: ',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.green[900],
                          ),
                        ),
                        Text(
                          NumberFormat.currency(symbol: '₱', decimalDigits: 0)
                              .format(goal.monthlyContribution),
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.green[700],
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
      ),
    );
  }

  Color _getStatusColor(GoalStatus status) {
    switch (status) {
      case GoalStatus.active:
        return Colors.blue;
      case GoalStatus.completed:
        return Colors.green;
      case GoalStatus.paused:
        return Colors.orange;
    }
  }

  String _getStatusText(GoalStatus status) {
    switch (status) {
      case GoalStatus.active:
        return 'Active';
      case GoalStatus.completed:
        return 'Completed';
      case GoalStatus.paused:
        return 'Paused';
    }
  }
}

// Goal Status Enum
enum GoalStatus { active, completed, paused }

// Goal Data Class
class GoalItem {
  final String id;
  final String name;
  final String description;
  final double targetAmount;
  final double currentAmount;
  final DateTime? targetDate;
  final Color color;
  final IconData icon;
  final GoalStatus status;
  final double monthlyContribution;

  GoalItem({
    required this.id,
    required this.name,
    required this.description,
    required this.targetAmount,
    required this.currentAmount,
    this.targetDate,
    required this.color,
    required this.icon,
    this.status = GoalStatus.active,
    this.monthlyContribution = 0,
  });
}

// Dummy Goals Data
final dummyGoals = [
  GoalItem(
    id: '1',
    name: 'Emergency Fund',
    description: '6 months of expenses',
    targetAmount: 150000,
    currentAmount: 95000,
    targetDate: DateTime(2025, 6, 30),
    color: Colors.red[700]!,
    icon: Icons.emergency,
    status: GoalStatus.active,
    monthlyContribution: 10000,
  ),
  GoalItem(
    id: '2',
    name: 'New Car',
    description: 'Down payment for new vehicle',
    targetAmount: 200000,
    currentAmount: 75000,
    targetDate: DateTime(2025, 12, 31),
    color: Colors.blue[700]!,
    icon: Icons.directions_car,
    status: GoalStatus.active,
    monthlyContribution: 15000,
  ),
  GoalItem(
    id: '3',
    name: 'Vacation Fund',
    description: 'Japan trip 2025',
    targetAmount: 80000,
    currentAmount: 45000,
    targetDate: DateTime(2025, 10, 15),
    color: Colors.orange[700]!,
    icon: Icons.flight_takeoff,
    status: GoalStatus.active,
    monthlyContribution: 5000,
  ),
  GoalItem(
    id: '4',
    name: 'House Down Payment',
    description: 'Save for new home',
    targetAmount: 500000,
    currentAmount: 180000,
    targetDate: DateTime(2026, 12, 31),
    color: Colors.green[700]!,
    icon: Icons.home,
    status: GoalStatus.active,
    monthlyContribution: 20000,
  ),
  GoalItem(
    id: '5',
    name: 'Laptop Upgrade',
    description: 'MacBook Pro M3',
    targetAmount: 120000,
    currentAmount: 120000,
    targetDate: DateTime(2024, 11, 30),
    color: Colors.purple[700]!,
    icon: Icons.laptop_mac,
    status: GoalStatus.completed,
    monthlyContribution: 0,
  ),
  GoalItem(
    id: '6',
    name: 'Education Fund',
    description: 'Masters degree tuition',
    targetAmount: 300000,
    currentAmount: 85000,
    targetDate: DateTime(2026, 6, 1),
    color: Colors.indigo[700]!,
    icon: Icons.school,
    status: GoalStatus.active,
    monthlyContribution: 12000,
  ),
  GoalItem(
    id: '7',
    name: 'Investment Portfolio',
    description: 'Build diversified portfolio',
    targetAmount: 250000,
    currentAmount: 60000,
    targetDate: DateTime(2027, 1, 1),
    color: Colors.teal[700]!,
    icon: Icons.trending_up,
    status: GoalStatus.active,
    monthlyContribution: 8000,
  ),
  GoalItem(
    id: '8',
    name: 'Fitness Equipment',
    description: 'Home gym setup',
    targetAmount: 50000,
    currentAmount: 22000,
    color: Colors.pink[700]!,
    icon: Icons.fitness_center,
    status: GoalStatus.paused,
    monthlyContribution: 0,
  ),
];
