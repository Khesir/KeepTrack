import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:keep_track/core/network/api_client.dart';
import 'package:keep_track/core/settings/utils/currency_formatter.dart';
import 'package:keep_track/core/di/service_locator.dart';
import 'package:keep_track/core/state/stream_builder_widget.dart';
import 'package:keep_track/core/utils/icon_helper.dart';
import 'package:keep_track/features/finance/modules/account/domain/entities/account.dart';
import 'package:keep_track/features/finance/modules/goal/domain/entities/goal.dart';
import 'package:keep_track/features/finance/presentation/screens/configuration/goals/widgets/goals_management_dialog.dart';
import 'package:keep_track/features/finance/presentation/state/account_controller.dart';
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
  late final SupabaseService _supabaseService;
  String _selectedFilter = 'All';
  Goal? _selectedGoal;

  @override
  void initState() {
    super.initState();
    _controller = locator.get<GoalController>();
    _accountController = locator.get<AccountController>();
    _supabaseService = locator.get<SupabaseService>();
    _accountController.loadAccounts();
  }

  void _showGoalDialog({Goal? goal}) {
    showDialog(
      context: context,
      builder: (_) => GoalsManagementDialog(
        goal: goal,
        userId: _supabaseService.userId!,
        onSave: (g) async {
          if (goal != null) {
            await _controller.updateGoal(g);
            if (_selectedGoal?.id == g.id) setState(() => _selectedGoal = g);
          } else {
            await _controller.createGoal(g);
          }
        },
      ),
    );
  }

  Future<void> _showRecordPaymentDialog(Goal goal) async {
    final amountController = TextEditingController(
      text: goal.monthlyContribution > 0 ? goal.monthlyContribution.toStringAsFixed(2) : '',
    );
    final feeController = TextEditingController();
    String? selectedAccountId;

    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (ctx, setDialogState) => Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Record Payment', style: AppTextStyles.h4),
                            const SizedBox(height: 2),
                            Text(goal.name,
                                style: AppTextStyles.bodySmall
                                    .copyWith(color: AppColors.textSecondary)),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, size: 18),
                        onPressed: () => Navigator.pop(dialogContext, false),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: amountController,
                    decoration: InputDecoration(
                      labelText: 'Amount',
                      prefixText: '${currencyFormatter.currencySymbol} ',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      contentPadding:
                          const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    ),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: feeController,
                    decoration: InputDecoration(
                      labelText: 'Fee (optional)',
                      prefixText: '${currencyFormatter.currencySymbol} ',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      contentPadding:
                          const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    ),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  ),
                  const SizedBox(height: 12),
                  AsyncStreamBuilder<List<Account>>(
                    state: _accountController,
                    builder: (context, accounts) {
                      return DropdownButtonFormField<String>(
                        initialValue: selectedAccountId,
                        decoration: InputDecoration(
                          labelText: 'Account',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                          contentPadding:
                              const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                        ),
                        items: accounts
                            .map((a) => DropdownMenuItem(value: a.id, child: Text(a.name)))
                            .toList(),
                        onChanged: (v) => setDialogState(() => selectedAccountId = v),
                      );
                    },
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(dialogContext, false),
                        child: const Text('Cancel'),
                      ),
                      const SizedBox(width: 8),
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
                          try {
                            final fee = double.tryParse(feeController.text) ?? 0;
                            await ApiClient.instance.post(
                              '/goals/${goal.id}/contribute',
                              data: {
                                'accountId': selectedAccountId,
                                'amount': amount,
                                if (fee > 0) 'fee': fee,
                              },
                            );
                            _controller.loadGoals();
                            if (dialogContext.mounted) Navigator.pop(dialogContext, true);
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
                ],
              ),
            ),
          ),
        ),
      ),
    );

    if (result == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Payment recorded successfully')),
      );
    }

    amountController.dispose();
    feeController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DesktopAwareScreen(
      builder: (context, isDesktop) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        final bg = isDark ? const Color(0xFF09090B) : AppColors.backgroundSecondary;

        return Scaffold(
          backgroundColor: isDesktop ? bg : null,
          body: AsyncStreamBuilder<List<Goal>>(
            state: _controller,
            builder: (context, goals) {
              final activeGoals = goals.where((g) => g.status == GoalStatus.active).toList();
              final completedGoals =
                  goals.where((g) => g.status == GoalStatus.completed).toList();
              final totalTarget =
                  activeGoals.fold<double>(0, (s, g) => s + g.targetAmount);
              final totalSaved =
                  activeGoals.fold<double>(0, (s, g) => s + g.currentAmount);
              final overallProgress = totalTarget > 0 ? totalSaved / totalTarget : 0.0;

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

              if (isDesktop) {
                return _DesktopLayout(
                  goals: filteredGoals,
                  allGoals: goals,
                  totalSaved: totalSaved,
                  totalTarget: totalTarget,
                  overallProgress: overallProgress,
                  activeCount: activeGoals.length,
                  completedCount: completedGoals.length,
                  selectedFilter: _selectedFilter,
                  onFilterChange: (f) => setState(() {
                    _selectedFilter = f;
                    _selectedGoal = null;
                  }),
                  selectedGoal: _selectedGoal,
                  onSelect: (g) => setState(() => _selectedGoal = g),
                  onAdd: () => _showGoalDialog(),
                  onEdit: (g) => _showGoalDialog(goal: g),
                  onRecord: _showRecordPaymentDialog,
                );
              }

              // Mobile: detail view or list view
              if (_selectedGoal != null) {
                return _MobileDetailView(
                  goal: _selectedGoal!,
                  onBack: () => setState(() => _selectedGoal = null),
                  onEdit: () => _showGoalDialog(goal: _selectedGoal),
                  onRecord: () => _showRecordPaymentDialog(_selectedGoal!),
                );
              }

              return _MobileListView(
                goals: filteredGoals,
                allGoals: goals,
                totalSaved: totalSaved,
                totalTarget: totalTarget,
                overallProgress: overallProgress,
                activeCount: activeGoals.length,
                completedCount: completedGoals.length,
                selectedFilter: _selectedFilter,
                onFilterChange: (f) => setState(() => _selectedFilter = f),
                onSelect: (g) => setState(() => _selectedGoal = g),
                onAdd: () => _showGoalDialog(),
              );
            },
            loadingBuilder: (_) => const Center(
              child: Padding(
                  padding: EdgeInsets.all(48), child: CircularProgressIndicator()),
            ),
            errorBuilder: (context, message) => Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline, size: 48, color: AppColors.error),
                    const SizedBox(height: 12),
                    Text('Failed to load goals', style: AppTextStyles.h4),
                    const SizedBox(height: 6),
                    Text(message,
                        textAlign: TextAlign.center,
                        style: AppTextStyles.bodySmall
                            .copyWith(color: AppColors.textSecondary)),
                    const SizedBox(height: 16),
                    OutlinedButton.icon(
                      onPressed: () => _controller.loadGoals(),
                      icon: const Icon(Icons.refresh, size: 16),
                      label: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

// ─── Desktop Layout ────────────────────────────────────────────────────────────

class _DesktopLayout extends StatelessWidget {
  final List<Goal> goals;
  final List<Goal> allGoals;
  final double totalSaved;
  final double totalTarget;
  final double overallProgress;
  final int activeCount;
  final int completedCount;
  final String selectedFilter;
  final ValueChanged<String> onFilterChange;
  final Goal? selectedGoal;
  final ValueChanged<Goal> onSelect;
  final VoidCallback onAdd;
  final ValueChanged<Goal> onEdit;
  final Future<void> Function(Goal) onRecord;

  const _DesktopLayout({
    required this.goals,
    required this.allGoals,
    required this.totalSaved,
    required this.totalTarget,
    required this.overallProgress,
    required this.activeCount,
    required this.completedCount,
    required this.selectedFilter,
    required this.onFilterChange,
    required this.selectedGoal,
    required this.onSelect,
    required this.onAdd,
    required this.onEdit,
    required this.onRecord,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final borderColor = isDark ? Colors.white12 : AppColors.border;
    final panelBg = isDark ? const Color(0xFF18181B) : AppColors.surface;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Left panel
        SizedBox(
          width: 320,
          child: Container(
            decoration: BoxDecoration(
              color: panelBg,
              border: Border(right: BorderSide(color: borderColor)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 16, 0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Goals', style: AppTextStyles.h4),
                      IconButton(
                        icon: const Icon(Icons.add, size: 20),
                        tooltip: 'Add Goal',
                        onPressed: onAdd,
                        style: IconButton.styleFrom(
                          backgroundColor: AppColors.accent.withValues(alpha: 0.08),
                          foregroundColor: AppColors.accent,
                          padding: const EdgeInsets.all(8),
                        ),
                      ),
                    ],
                  ),
                ),

                // Summary
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 10, 20, 4),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        currencyFormatter.format(totalSaved),
                        style: AppTextStyles.h2,
                      ),
                      if (totalTarget > 0)
                        Text(
                          'of ${currencyFormatter.format(totalTarget)}',
                          style: AppTextStyles.caption
                              .copyWith(color: AppColors.textSecondary),
                        ),
                    ],
                  ),
                ),

                if (totalTarget > 0)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: overallProgress.clamp(0.0, 1.0),
                        minHeight: 4,
                        backgroundColor: AppColors.accent.withValues(alpha: 0.1),
                        valueColor:
                            const AlwaysStoppedAnimation<Color>(AppColors.accent),
                      ),
                    ),
                  ),

                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
                  child: Wrap(
                    spacing: 6,
                    children: [
                      _Chip(label: '$activeCount active', color: AppColors.info),
                      if (completedCount > 0)
                        _Chip(
                            label: '$completedCount completed',
                            color: AppColors.success),
                    ],
                  ),
                ),

                // Filter chips
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        for (final f in ['All', 'Active', 'Completed', 'Paused']) ...[
                          _FilterChip(
                            label: f,
                            selected: selectedFilter == f,
                            onTap: () => onFilterChange(f),
                          ),
                          const SizedBox(width: 5),
                        ],
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 4),

                Divider(height: 1, color: borderColor),

                // Goal list
                Expanded(
                  child: goals.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.flag_outlined,
                                  size: 40, color: AppColors.textDisabled),
                              const SizedBox(height: 8),
                              Text('No goals',
                                  style: AppTextStyles.bodySmall
                                      .copyWith(color: AppColors.textSecondary)),
                            ],
                          ),
                        )
                      : ListView.separated(
                          padding: EdgeInsets.zero,
                          itemCount: goals.length,
                          separatorBuilder: (_, __) =>
                              Divider(height: 1, color: borderColor),
                          itemBuilder: (context, i) {
                            final g = goals[i];
                            return _GoalListRow(
                              goal: g,
                              isSelected: selectedGoal?.id == g.id,
                              onTap: () => onSelect(g),
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
        ),

        // Right panel — detail
        Expanded(
          child: selectedGoal == null
              ? _EmptyDetailPanel()
              : _GoalDetailPanel(
                  goal: selectedGoal!,
                  onEdit: () => onEdit(selectedGoal!),
                  onRecord: () => onRecord(selectedGoal!),
                ),
        ),
      ],
    );
  }
}

// ─── Mobile List View ──────────────────────────────────────────────────────────

class _MobileListView extends StatelessWidget {
  final List<Goal> goals;
  final List<Goal> allGoals;
  final double totalSaved;
  final double totalTarget;
  final double overallProgress;
  final int activeCount;
  final int completedCount;
  final String selectedFilter;
  final ValueChanged<String> onFilterChange;
  final ValueChanged<Goal> onSelect;
  final VoidCallback onAdd;

  const _MobileListView({
    required this.goals,
    required this.allGoals,
    required this.totalSaved,
    required this.totalTarget,
    required this.overallProgress,
    required this.activeCount,
    required this.completedCount,
    required this.selectedFilter,
    required this.onFilterChange,
    required this.onSelect,
    required this.onAdd,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final borderColor = isDark ? Colors.white12 : AppColors.border;
    final cardBg = isDark ? const Color(0xFF18181B) : AppColors.surface;

    return Stack(
      children: [
        SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 88),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Summary card
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: cardBg,
                  border: Border.all(color: borderColor),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.flag_outlined,
                            size: 14, color: AppColors.textSecondary),
                        const SizedBox(width: 6),
                        Text('Overall Progress',
                            style: AppTextStyles.caption
                                .copyWith(color: AppColors.textSecondary)),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(currencyFormatter.format(totalSaved),
                                  style: AppTextStyles.display),
                              if (totalTarget > 0)
                                Text('of ${currencyFormatter.format(totalTarget)}',
                                    style: AppTextStyles.bodySmall
                                        .copyWith(color: AppColors.textSecondary)),
                            ],
                          ),
                        ),
                        if (totalTarget > 0) ...[
                          const SizedBox(width: 12),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: AppColors.accent.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                  color: AppColors.accent.withValues(alpha: 0.2)),
                            ),
                            child: Text(
                              '${(overallProgress * 100).toStringAsFixed(0)}%',
                              style: AppTextStyles.h4.copyWith(color: AppColors.accent),
                            ),
                          ),
                        ],
                      ],
                    ),
                    if (totalTarget > 0) ...[
                      const SizedBox(height: 12),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: overallProgress.clamp(0.0, 1.0),
                          minHeight: 5,
                          backgroundColor: AppColors.accent.withValues(alpha: 0.1),
                          valueColor:
                              const AlwaysStoppedAnimation<Color>(AppColors.accent),
                        ),
                      ),
                    ],
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 6,
                      children: [
                        _Chip(label: '$activeCount active', color: AppColors.info),
                        if (completedCount > 0)
                          _Chip(
                              label: '$completedCount completed',
                              color: AppColors.success),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Filter row
              Row(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          for (final f in ['All', 'Active', 'Completed', 'Paused']) ...[
                            _FilterChip(
                              label: f,
                              selected: selectedFilter == f,
                              onTap: () => onFilterChange(f),
                            ),
                            const SizedBox(width: 6),
                          ],
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text('${goals.length}',
                      style: AppTextStyles.caption
                          .copyWith(color: AppColors.textSecondary)),
                ],
              ),
              const SizedBox(height: 12),

              if (goals.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 48),
                  child: Center(
                    child: Column(
                      children: [
                        const Icon(Icons.flag_outlined,
                            size: 48, color: AppColors.textDisabled),
                        const SizedBox(height: 10),
                        Text(
                          selectedFilter == 'All'
                              ? 'No goals yet'
                              : 'No $selectedFilter goals',
                          style: AppTextStyles.bodyMedium
                              .copyWith(color: AppColors.textSecondary),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          selectedFilter == 'All'
                              ? 'Tap + to create your first goal'
                              : 'Try changing the filter',
                          style: AppTextStyles.caption
                              .copyWith(color: AppColors.textTertiary),
                        ),
                      ],
                    ),
                  ),
                )
              else
                Container(
                  decoration: BoxDecoration(
                    color: cardBg,
                    border: Border.all(color: borderColor),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      for (int i = 0; i < goals.length; i++) ...[
                        if (i > 0) Divider(height: 1, color: borderColor),
                        _GoalListRow(
                          goal: goals[i],
                          isSelected: false,
                          onTap: () => onSelect(goals[i]),
                        ),
                      ],
                    ],
                  ),
                ),
            ],
          ),
        ),

        Positioned(
          bottom: 20,
          right: 16,
          child: FloatingActionButton.extended(
            onPressed: onAdd,
            icon: const Icon(Icons.add),
            label: const Text('Add Goal'),
          ),
        ),
      ],
    );
  }
}

// ─── Mobile Detail View ────────────────────────────────────────────────────────

class _MobileDetailView extends StatelessWidget {
  final Goal goal;
  final VoidCallback onBack;
  final VoidCallback onEdit;
  final VoidCallback onRecord;

  const _MobileDetailView({
    required this.goal,
    required this.onBack,
    required this.onEdit,
    required this.onRecord,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _GoalDetailHeader(goal: goal, onBack: onBack, onEdit: onEdit),
        Expanded(child: _GoalDetailContent(goal: goal, onRecord: onRecord)),
      ],
    );
  }
}

// ─── Desktop Detail Panel ──────────────────────────────────────────────────────

class _GoalDetailPanel extends StatelessWidget {
  final Goal goal;
  final VoidCallback onEdit;
  final VoidCallback onRecord;

  const _GoalDetailPanel({
    required this.goal,
    required this.onEdit,
    required this.onRecord,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _GoalDetailHeader(goal: goal, onBack: null, onEdit: onEdit),
        Expanded(child: _GoalDetailContent(goal: goal, onRecord: onRecord)),
      ],
    );
  }
}

class _EmptyDetailPanel extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.flag_outlined, size: 48, color: AppColors.textDisabled),
          const SizedBox(height: 12),
          Text('Select a goal',
              style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary)),
        ],
      ),
    );
  }
}

// ─── Goal Detail Header ────────────────────────────────────────────────────────

class _GoalDetailHeader extends StatelessWidget {
  final Goal goal;
  final VoidCallback? onBack;
  final VoidCallback onEdit;

  const _GoalDetailHeader({required this.goal, required this.onBack, required this.onEdit});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final borderColor = isDark ? Colors.white12 : AppColors.border;
    final color = _parseColor(goal.colorHex);
    final icon = IconHelper.fromString(goal.iconCodePoint);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(border: Border(bottom: BorderSide(color: borderColor))),
      child: Row(
        children: [
          if (onBack != null) ...[
            IconButton(
              icon: const Icon(Icons.arrow_back, size: 20),
              onPressed: onBack,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
            const SizedBox(width: 12),
          ],
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(goal.name,
                    style: AppTextStyles.h4, maxLines: 1, overflow: TextOverflow.ellipsis),
                Text(goal.description,
                    style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
          const SizedBox(width: 8),
          _StatusBadge(status: goal.status),
          const SizedBox(width: 8),
          OutlinedButton.icon(
            onPressed: onEdit,
            icon: const Icon(Icons.edit_outlined, size: 14),
            label: const Text('Edit'),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: AppColors.border),
              foregroundColor: AppColors.textPrimary,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              textStyle: AppTextStyles.caption.copyWith(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Goal Detail Content ───────────────────────────────────────────────────────

class _GoalDetailContent extends StatelessWidget {
  final Goal goal;
  final VoidCallback onRecord;

  const _GoalDetailContent({required this.goal, required this.onRecord});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final borderColor = isDark ? Colors.white12 : AppColors.border;
    final cardBg = isDark ? const Color(0xFF18181B) : AppColors.surface;
    final color = _parseColor(goal.colorHex);
    final progress = goal.progress;
    final remaining = goal.remainingAmount;
    final daysLeft = goal.daysRemaining ?? 0;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Progress card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: cardBg,
              border: Border.all(color: borderColor),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Saved',
                              style: AppTextStyles.caption
                                  .copyWith(color: AppColors.textSecondary)),
                          const SizedBox(height: 2),
                          Text(
                            currencyFormatter.format(goal.currentAmount, decimalDigits: 2),
                            style: AppTextStyles.display.copyWith(color: color),
                          ),
                          Text('of ${currencyFormatter.format(goal.targetAmount, decimalDigits: 2)}',
                              style: AppTextStyles.bodySmall
                                  .copyWith(color: AppColors.textSecondary)),
                        ],
                      ),
                    ),
                    Container(
                      padding:
                          const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: color.withValues(alpha: 0.2)),
                      ),
                      child: Text(
                        '${(progress * 100).toStringAsFixed(0)}%',
                        style: AppTextStyles.h4.copyWith(color: color),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: progress.clamp(0.0, 1.0),
                    minHeight: 8,
                    backgroundColor: color.withValues(alpha: 0.1),
                    valueColor: AlwaysStoppedAnimation<Color>(color),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  remaining > 0
                      ? '${currencyFormatter.format(remaining, decimalDigits: 2)} to go'
                      : 'Goal achieved!',
                  style: AppTextStyles.caption.copyWith(
                    color: remaining <= 0 ? AppColors.success : AppColors.textSecondary,
                    fontWeight: remaining <= 0 ? FontWeight.w600 : FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Stats row
          Row(
            children: [
              if (goal.monthlyContribution > 0)
                Expanded(
                  child: _InfoCard(
                    label: 'Monthly',
                    value: currencyFormatter.formatCompact(goal.monthlyContribution),
                    icon: Icons.calendar_month_outlined,
                    color: AppColors.info,
                    borderColor: borderColor,
                    cardBg: cardBg,
                  ),
                ),
              if (goal.monthlyContribution > 0 &&
                  (goal.managementFeePercent > 0 || goal.targetDate != null))
                const SizedBox(width: 8),
              if (goal.managementFeePercent > 0)
                Expanded(
                  child: _InfoCard(
                    label: 'Mgmt Fee',
                    value: '${goal.managementFeePercent.toStringAsFixed(1)}%',
                    icon: Icons.percent_outlined,
                    color: AppColors.warning,
                    borderColor: borderColor,
                    cardBg: cardBg,
                  ),
                ),
              if (goal.managementFeePercent > 0 && goal.targetDate != null)
                const SizedBox(width: 8),
              if (goal.targetDate != null)
                Expanded(
                  child: _InfoCard(
                    label: 'Target Date',
                    value: DateFormat('MMM d, y').format(goal.targetDate!),
                    icon: Icons.event_outlined,
                    color: daysLeft < 30 ? AppColors.warning : AppColors.textSecondary,
                    borderColor: borderColor,
                    cardBg: cardBg,
                  ),
                ),
            ],
          ),

          if (goal.monthlyContribution > 0 ||
              goal.managementFeePercent > 0 ||
              goal.targetDate != null)
            const SizedBox(height: 12),

          if (goal.withdrawalFeePercent > 0) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.warning.withValues(alpha: 0.06),
                border: Border.all(color: AppColors.warning.withValues(alpha: 0.2)),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, size: 14, color: AppColors.warning),
                  const SizedBox(width: 8),
                  Text(
                    'Withdrawal fee: ${goal.withdrawalFeePercent.toStringAsFixed(1)}%',
                    style: AppTextStyles.caption.copyWith(color: AppColors.warning),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
          ],

          // Record payment button
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: onRecord,
              icon: const Icon(Icons.add, size: 16),
              label: const Text('Record Payment'),
              style: FilledButton.styleFrom(
                backgroundColor: color,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Goal List Row ─────────────────────────────────────────────────────────────

class _GoalListRow extends StatelessWidget {
  final Goal goal;
  final bool isSelected;
  final VoidCallback onTap;

  const _GoalListRow({required this.goal, required this.isSelected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final color = _parseColor(goal.colorHex);
    final icon = IconHelper.fromString(goal.iconCodePoint);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final selectedBg = isDark
        ? Colors.white.withValues(alpha: 0.04)
        : AppColors.accent.withValues(alpha: 0.04);

    return InkWell(
      onTap: onTap,
      child: Container(
        color: isSelected ? selectedBg : null,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 3,
              height: 36,
              decoration: BoxDecoration(
                color: isSelected ? color : color.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 10),
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(7),
              ),
              child: Icon(icon, color: color, size: 17),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(goal.name,
                      style: AppTextStyles.bodyMedium.copyWith(
                          fontWeight:
                              isSelected ? FontWeight.w700 : FontWeight.w600),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 3),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(2),
                    child: LinearProgressIndicator(
                      value: goal.progress.clamp(0.0, 1.0),
                      minHeight: 3,
                      backgroundColor: color.withValues(alpha: 0.1),
                      valueColor: AlwaysStoppedAnimation<Color>(color),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${(goal.progress * 100).toStringAsFixed(0)}%',
                  style: AppTextStyles.caption.copyWith(
                    color: color,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                _StatusBadge(status: goal.status),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Info Card ─────────────────────────────────────────────────────────────────

class _InfoCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final Color borderColor;
  final Color cardBg;

  const _InfoCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    required this.borderColor,
    required this.cardBg,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cardBg,
        border: Border.all(color: borderColor),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 13, color: color),
              const SizedBox(width: 4),
              Text(label,
                  style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary)),
            ],
          ),
          const SizedBox(height: 4),
          Text(value,
              style: AppTextStyles.bodySmall.copyWith(
                  fontWeight: FontWeight.w600, color: AppColors.textPrimary),
              maxLines: 1,
              overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }
}

// ─── Filter Chip ───────────────────────────────────────────────────────────────

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _FilterChip({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 5),
        decoration: BoxDecoration(
          color: selected ? AppColors.accent.withValues(alpha: 0.08) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
              color: selected
                  ? AppColors.accent.withValues(alpha: 0.4)
                  : AppColors.border),
        ),
        child: Text(
          label,
          style: AppTextStyles.caption.copyWith(
            color: selected ? AppColors.accent : AppColors.textSecondary,
            fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
          ),
        ),
      ),
    );
  }
}

// ─── Chips & Badges ────────────────────────────────────────────────────────────

class _Chip extends StatelessWidget {
  final String label;
  final Color color;
  const _Chip({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Text(label,
          style: AppTextStyles.caption.copyWith(color: color, fontWeight: FontWeight.w600)),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final GoalStatus status;
  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (status) {
      GoalStatus.active => ('Active', AppColors.info),
      GoalStatus.completed => ('Completed', AppColors.success),
      GoalStatus.paused => ('Paused', AppColors.warning),
    };
    return _Chip(label: label, color: color);
  }
}

// ─── Helpers ───────────────────────────────────────────────────────────────────

Color _parseColor(String? hex) {
  if (hex == null) return AppColors.accent;
  try {
    return Color(int.parse(hex.replaceFirst('#', '0xFF')));
  } catch (_) {
    return AppColors.accent;
  }
}
