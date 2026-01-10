import 'package:flutter/material.dart';
import 'package:keep_track/core/settings/utils/currency_formatter.dart';
import 'package:intl/intl.dart';
import 'package:keep_track/core/di/service_locator.dart';
import 'package:keep_track/core/state/stream_builder_widget.dart';
import 'package:keep_track/core/utils/icon_helper.dart';
import 'package:keep_track/features/finance/modules/account/domain/entities/account.dart';
import 'package:keep_track/features/finance/modules/finance_category/domain/entities/finance_category.dart';
import 'package:keep_track/features/finance/modules/finance_category/domain/entities/finance_category_enums.dart';
import 'package:keep_track/features/finance/modules/goal/domain/entities/goal.dart';
import 'package:keep_track/features/finance/presentation/state/account_controller.dart';
import 'package:keep_track/features/finance/presentation/state/finance_category_controller.dart';
import 'package:keep_track/shared/infrastructure/supabase/supabase_service.dart';
import '../../../../../../core/theme/app_theme.dart';
import '../../../../../../core/ui/responsive/desktop_aware_screen.dart';
import '../../../state/goal_controller.dart';

/// Goals Tab - Track financial goals and savings targets
class GoalsTabNew extends StatefulWidget {
  const GoalsTabNew({super.key});

  @override
  State<GoalsTabNew> createState() => _GoalsTabNewState();
}

class _GoalsTabNewState extends State<GoalsTabNew> {
  late final GoalController _controller;
  late final AccountController _accountController;
  late final FinanceCategoryController _categoryController;
  late final SupabaseService _supabaseService;
  String _selectedFilter = 'All'; // All, Active, Completed, Paused

  @override
  void initState() {
    super.initState();
    _controller = locator.get<GoalController>();
    _accountController = locator.get<AccountController>();
    _categoryController = locator.get<FinanceCategoryController>();
    _supabaseService = locator.get<SupabaseService>();

    // Load accounts and categories
    _accountController.loadAccounts();
    _categoryController.loadCategories();
  }

  Future<void> _showRecordPaymentDialog(Goal goal) async {
    final amountController = TextEditingController(
      text: goal.monthlyContribution > 0
          ? goal.monthlyContribution.toStringAsFixed(2)
          : '',
    );
    String? selectedAccountId;
    String? selectedCategoryId;

    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('Record Payment for ${goal.name}'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Amount Field
              TextField(
                controller: amountController,
                decoration: InputDecoration(
                  labelText: 'Amount',
                  prefixText: '₱',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                keyboardType: TextInputType.numberWithOptions(decimal: true),
              ),
              const SizedBox(height: 16),

              // Account Selector
              AsyncStreamBuilder<List<Account>>(
                state: _accountController,
                builder: (context, accounts) {
                  return DropdownButtonFormField<String>(
                    value: selectedAccountId,
                    decoration: InputDecoration(
                      labelText: 'Account',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    items: accounts
                        .map(
                          (account) => DropdownMenuItem(
                            value: account.id,
                            child: Text(account.name),
                          ),
                        )
                        .toList(),
                    onChanged: (value) => selectedAccountId = value,
                  );
                },
              ),
              const SizedBox(height: 16),

              // Category Selector (expense categories only)
              AsyncStreamBuilder<List<FinanceCategory>>(
                state: _categoryController,
                builder: (context, categories) {
                  final expenseCategories = categories
                      .where((c) => c.type == CategoryType.expense)
                      .toList();

                  return DropdownButtonFormField<String>(
                    value: selectedCategoryId,
                    decoration: InputDecoration(
                      labelText: 'Category',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    items: expenseCategories
                        .map(
                          (category) => DropdownMenuItem(
                            value: category.id,
                            child: Text(category.name),
                          ),
                        )
                        .toList(),
                    onChanged: (value) => selectedCategoryId = value,
                  );
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              final amount = double.tryParse(amountController.text);
              if (amount == null || amount <= 0) {
                ScaffoldMessenger.of(dialogContext).showSnackBar(
                  const SnackBar(content: Text('Please enter a valid amount')),
                );
                return;
              }

              if (selectedAccountId == null) {
                ScaffoldMessenger.of(dialogContext).showSnackBar(
                  const SnackBar(content: Text('Please select an account')),
                );
                return;
              }

              if (selectedCategoryId == null) {
                ScaffoldMessenger.of(dialogContext).showSnackBar(
                  const SnackBar(content: Text('Please select a category')),
                );
                return;
              }

              // Call RPC function
              try {
                await _supabaseService.client.rpc(
                  'create_goal_payment_transaction',
                  params: {
                    'p_user_id': _supabaseService.userId,
                    'p_account_id': selectedAccountId,
                    'p_finance_category_id': selectedCategoryId,
                    'p_amount': amount,
                    'p_type': 'expense',
                    'p_description': 'Goal: ${goal.name}',
                    'p_date': DateTime.now().toIso8601String(),
                    'p_notes': null,
                    'p_goal_id': goal.id,
                  },
                );

                // Reload goals
                _controller.loadGoals();

                if (dialogContext.mounted) {
                  Navigator.pop(dialogContext, true);
                }
              } catch (e) {
                if (dialogContext.mounted) {
                  ScaffoldMessenger.of(dialogContext).showSnackBar(
                    SnackBar(content: Text('Failed to record payment: $e')),
                  );
                }
              }
            },
            child: const Text('Record Payment'),
          ),
        ],
      ),
    );

    if (result == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Payment recorded successfully')),
      );
    }

    amountController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DesktopAwareScreen(
      builder: (context, isDesktop) {
        return Scaffold(
          backgroundColor: isDesktop ? AppColors.backgroundSecondary : null,
          body: AsyncStreamBuilder<List<Goal>>(
            state: _controller,
            builder: (context, goals) {
              // Calculate summary stats
              final activeGoals = goals
                  .where((g) => g.status == GoalStatus.active)
                  .toList();
              final totalTargetAmount = activeGoals.fold<double>(
                0,
                (sum, goal) => sum + goal.targetAmount,
              );
              final totalSavedAmount = activeGoals.fold<double>(
                0,
                (sum, goal) => sum + goal.currentAmount,
              );
              final overallProgress = totalTargetAmount > 0
                  ? totalSavedAmount / totalTargetAmount
                  : 0.0;

              // Filter goals
              final filteredGoals = _selectedFilter == 'All'
                  ? goals
                  : goals.where((g) {
                      switch (_selectedFilter) {
                        case 'Active':
                          return g.status == GoalStatus.active;
                        case 'Completed':
                          return g.status == GoalStatus.completed;
                        case 'Paused':
                          return g.status == GoalStatus.paused;
                        default:
                          return true;
                      }
                    }).toList();

              return SingleChildScrollView(
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
                        if (isDesktop)
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Financial Goals', style: AppTextStyles.h1),
                              ElevatedButton.icon(
                                onPressed: () {
                                  Navigator.pushNamed(
                                    context,
                                    '/goals-management',
                                  );
                                },
                                icon: const Icon(Icons.add, size: 20),
                                label: const Text('Manage Goals'),
                                style: ElevatedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 20,
                                    vertical: 12,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        if (isDesktop) SizedBox(height: AppSpacing.xl),

                        // Overall Progress Card
                        _buildOverallProgressCard(
                          totalTargetAmount,
                          totalSavedAmount,
                          overallProgress,
                          activeGoals.length,
                        ),
                        const SizedBox(height: 24),

                        // Filter Chips
                        Wrap(
                          spacing: 2,
                          runSpacing: 2,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            _buildFilterChip('All'),
                            const SizedBox(width: 8),
                            _buildFilterChip('Active'),
                            const SizedBox(width: 8),
                            _buildFilterChip('Completed'),
                            const SizedBox(width: 8),
                            _buildFilterChip('Paused'),
                            const SizedBox(width: 8),
                            Text(
                              '${filteredGoals.length} ${filteredGoals.length == 1 ? 'goal' : 'goals'}',
                              style: TextStyle(
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurface.withOpacity(0.6),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Goals List - Grid on Desktop
                        if (filteredGoals.isEmpty)
                          _buildEmptyState()
                        else if (isDesktop)
                          ResponsiveGrid(
                            spacing: AppSpacing.lg,
                            desktopChildAspectRatio: 1.5,
                            children: filteredGoals
                                .map((goal) => _buildGoalCard(goal))
                                .toList(),
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
                  ),
                ),
              );
            },
            loadingBuilder: (_) => const Center(
              child: Padding(
                padding: EdgeInsets.all(32.0),
                child: CircularProgressIndicator(),
              ),
            ),
            errorBuilder: (context, message) => Center(
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
                    const SizedBox(height: 16),
                    Text(
                      'Error loading goals',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      message,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withOpacity(0.6),
                      ),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: () => _controller.loadGoals(),
                      icon: const Icon(Icons.refresh),
                      label: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            ),
          ),
          floatingActionButton: isDesktop
              ? null
              : FloatingActionButton.extended(
                  onPressed: () {
                    Navigator.pushNamed(context, '/goals-management');
                  },
                  icon: const Icon(Icons.add),
                  label: const Text('Manage Goals'),
                ),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(48),
        child: Column(
          children: [
            Icon(Icons.flag_outlined, size: 64, color: Colors.grey[300]),
            const SizedBox(height: 16),
            Text(
              'No goals found',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Create your first financial goal to start tracking',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Colors.grey[500]),
            ),
          ],
        ),
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
                  style: TextStyle(color: Colors.white70, fontSize: 16),
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
                        style: TextStyle(color: Colors.white70, fontSize: 13),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        NumberFormat.currency(
                          symbol: currencyFormatter.currencySymbol,
                          decimalDigits: 0,
                        ).format(totalSaved),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'of ${NumberFormat.currency(symbol: currencyFormatter.currencySymbol, decimalDigits: 0).format(totalTarget)}',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
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

  Widget _buildGoalCard(Goal goal) {
    final progress = goal.progress;
    final remaining = goal.remainingAmount;
    final daysRemaining = goal.daysRemaining ?? 0;

    final color = goal.colorHex != null
        ? Color(int.parse(goal.colorHex!.replaceFirst('#', '0xFF')))
        : Colors.purple;

    final icon = IconHelper.fromString(goal.iconCodePoint);

    return Card(
      elevation: 0,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          // Navigate to goal detail
        },
        child: Container(
          decoration: BoxDecoration(
            border: Border(left: BorderSide(color: color, width: 4)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header - Compact
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
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            goal.name,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            goal.description,
                            style: TextStyle(
                              fontSize: 11,
                              color: Theme.of(
                                context,
                              ).colorScheme.onSurface.withOpacity(0.6),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: _getStatusColor(goal.status).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        goal.status.displayName,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: _getStatusColor(goal.status),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Amount Progress - Compact
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Current',
                            style: TextStyle(
                              fontSize: 10,
                              color: Theme.of(
                                context,
                              ).colorScheme.onSurface.withOpacity(0.6),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            NumberFormat.currency(
                              symbol: currencyFormatter.currencySymbol,
                              decimalDigits: 0,
                            ).format(goal.currentAmount),
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: color,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Target',
                          style: TextStyle(
                            fontSize: 10,
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurface.withOpacity(0.6),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          NumberFormat.currency(
                            symbol: currencyFormatter.currencySymbol,
                            decimalDigits: 0,
                          ).format(goal.targetAmount),
                          style: TextStyle(
                            fontSize: 14,
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurface.withOpacity(0.7),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Progress Bar - Compact
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Flexible(
                          child: Text(
                            remaining > 0
                                ? '${NumberFormat.currency(symbol: currencyFormatter.currencySymbol, decimalDigits: 0).format(remaining)} to go'
                                : 'Achieved!',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: remaining > 0
                                  ? Theme.of(
                                      context,
                                    ).colorScheme.onSurface.withOpacity(0.6)
                                  : Colors.green[700],
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Text(
                          '${(progress * 100).toStringAsFixed(0)}%',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: color,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: progress.clamp(0.0, 1.0),
                        backgroundColor: color.withOpacity(0.1),
                        valueColor: AlwaysStoppedAnimation<Color>(color),
                        minHeight: 6,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // Compact Bottom Info
                if (goal.targetDate != null)
                  Row(
                    children: [
                      Icon(
                        Icons.event,
                        size: 12,
                        color: daysRemaining < 30
                            ? Colors.orange[700]
                            : Theme.of(
                                context,
                              ).colorScheme.onSurface.withOpacity(0.5),
                      ),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          '${DateFormat('MMM d').format(goal.targetDate!)}${daysRemaining > 0 ? ' ($daysRemaining days)' : ''}',
                          style: TextStyle(
                            fontSize: 11,
                            color: daysRemaining < 30
                                ? Colors.orange[700]
                                : Theme.of(
                                    context,
                                  ).colorScheme.onSurface.withOpacity(0.5),
                            fontWeight: daysRemaining < 30
                                ? FontWeight.w600
                                : FontWeight.normal,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),

                const SizedBox(height: 12),

                // Action Button - Compact
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () => _showRecordPaymentDialog(goal),
                    icon: const Icon(Icons.add, size: 16),
                    label: const Text('Record', style: TextStyle(fontSize: 12)),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      side: const BorderSide(color: Colors.blue),
                      foregroundColor: Colors.blue,
                    ),
                  ),
                ),
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
}
