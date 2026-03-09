import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:keep_track/core/di/service_locator.dart';
import 'package:keep_track/core/state/stream_builder_widget.dart';
import 'package:keep_track/core/theme/app_theme.dart';
import 'package:keep_track/core/ui/app_layout_controller.dart';
import 'package:keep_track/core/ui/ui.dart';
import 'package:keep_track/features/finance/modules/budget/domain/entities/budget.dart';
import 'package:keep_track/features/finance/modules/budget/domain/entities/month_plan.dart';
import 'package:keep_track/features/finance/presentation/state/month_plan_controller.dart';

String _fmtI(double v) => '₱${NumberFormat('#,##0').format(v)}';
String _fmtD(double v) => '₱${NumberFormat('#,##0.00').format(v)}';

class ProfileScreen extends ScopedScreen {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ScopedScreenState<ProfileScreen>
    with AppLayoutControlled {
  late final MonthPlanController _monthPlanController;
  int _selectedMonthIndex = 0;

  @override
  void registerServices() {
    _monthPlanController = locator.get<MonthPlanController>();
  }

  @override
  void onReady() {
    configureLayout(title: 'Insights', showBottomNav: true);
  }

  @override
  Widget build(BuildContext context) {
    return AsyncStreamBuilder<List<MonthPlan>>(
      state: _monthPlanController,
      builder: (context, plans) {
        if (plans.isEmpty) return _buildEmpty();

        // Plans are sorted newest first from the controller
        final displayPlans = plans.take(6).toList();
        final selected = displayPlans[_selectedMonthIndex.clamp(0, displayPlans.length - 1)];

        return CustomScrollView(
          slivers: [
            // Month selector
            SliverToBoxAdapter(
              child: _MonthSelector(
                plans: displayPlans,
                selectedIndex: _selectedMonthIndex,
                onSelect: (i) => setState(() => _selectedMonthIndex = i),
              ),
            ),

            // Summary cards
            SliverToBoxAdapter(
              child: _SummarySection(plan: selected),
            ),

            // Budget group breakdown
            SliverToBoxAdapter(
              child: _GroupBreakdownSection(plan: selected),
            ),

            // Month trend
            SliverToBoxAdapter(
              child: _MonthTrendSection(plans: displayPlans),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 24)),
          ],
        );
      },
      loadingBuilder: (_) => const Center(child: CircularProgressIndicator()),
      errorBuilder: (_, msg) => Center(
        child: Text(msg, style: AppTextStyles.bodyMedium.copyWith(color: AppColors.error)),
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.bar_chart_outlined, size: 56, color: AppColors.textTertiary),
          const SizedBox(height: 16),
          Text('No budget data yet', style: AppTextStyles.h4),
          const SizedBox(height: 6),
          Text(
            'Start planning a month to see insights',
            style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}

// ─── Month Selector ───────────────────────────────────────────────────────────

class _MonthSelector extends StatelessWidget {
  final List<MonthPlan> plans;
  final int selectedIndex;
  final void Function(int) onSelect;

  const _MonthSelector({
    required this.plans,
    required this.selectedIndex,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        itemCount: plans.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          final label = _monthLabel(plans[i].month);
          final selected = i == selectedIndex;
          return GestureDetector(
            onTap: () => onSelect(i),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: selected ? AppColors.primary : AppColors.muted,
                borderRadius: BorderRadius.circular(20),
              ),
              alignment: Alignment.center,
              child: Text(
                label,
                style: AppTextStyles.caption.copyWith(
                  color: selected ? AppColors.textOnPrimary : AppColors.textSecondary,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  String _monthLabel(String month) {
    final parts = month.split('-');
    if (parts.length != 2) return month;
    final dt = DateTime(int.parse(parts[0]), int.parse(parts[1]));
    return DateFormat('MMM yyyy').format(dt);
  }
}

// ─── Summary Section ──────────────────────────────────────────────────────────

class _SummarySection extends StatelessWidget {
  final MonthPlan plan;
  const _SummarySection({required this.plan});

  @override
  Widget build(BuildContext context) {
    final allBudgets = plan.budgets.where((b) => b.status == BudgetStatus.active).toList();
    final totalPlannedIncome = allBudgets
        .where((b) => b.budgetType == BudgetType.income)
        .fold(0.0, (s, b) => s + b.budgetTarget);
    final totalPlannedExpenses = allBudgets
        .where((b) => b.budgetType == BudgetType.expense)
        .fold(0.0, (s, b) => s + b.budgetTarget);
    final totalActualIncome = allBudgets
        .where((b) => b.budgetType == BudgetType.income)
        .fold(0.0, (s, b) => s + b.totalSpent);
    final totalActualExpenses = allBudgets
        .where((b) => b.budgetType == BudgetType.expense)
        .fold(0.0, (s, b) => s + b.totalSpent);
    final balance = totalActualIncome - totalActualExpenses;
    final isPositive = balance >= 0;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Balance hero
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
            decoration: BoxDecoration(
              color: isPositive
                  ? AppColors.success.withValues(alpha: 0.08)
                  : AppColors.error.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isPositive
                    ? AppColors.success.withValues(alpha: 0.2)
                    : AppColors.error.withValues(alpha: 0.2),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Net Balance',
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${isPositive ? '+' : ''}${_fmtD(balance)}',
                        style: AppTextStyles.h2.copyWith(
                          color: isPositive ? AppColors.success : AppColors.error,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  isPositive ? Icons.trending_up : Icons.trending_down,
                  color: isPositive ? AppColors.success : AppColors.error,
                  size: 32,
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Income / Expense tiles
          Row(
            children: [
              Expanded(
                child: _StatTile(
                  label: 'Income',
                  actual: totalActualIncome,
                  planned: totalPlannedIncome,
                  color: AppColors.success,
                  icon: Icons.arrow_downward,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _StatTile(
                  label: 'Expenses',
                  actual: totalActualExpenses,
                  planned: totalPlannedExpenses,
                  color: AppColors.error,
                  icon: Icons.arrow_upward,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  final String label;
  final double actual;
  final double planned;
  final Color color;
  final IconData icon;

  const _StatTile({
    required this.label,
    required this.actual,
    required this.planned,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final progress = planned > 0 ? (actual / planned).clamp(0.0, 1.0) : 0.0;
    final over = planned > 0 && actual > planned;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 13, color: color),
              const SizedBox(width: 5),
              Text(label, style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary)),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            _fmtI(actual),
            style: AppTextStyles.bodyMedium.copyWith(
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            'of ${_fmtI(planned)}',
            style: AppTextStyles.caption.copyWith(color: AppColors.textTertiary),
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(2),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 3,
              backgroundColor: AppColors.border,
              valueColor: AlwaysStoppedAnimation<Color>(over ? AppColors.warning : color),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Group Breakdown ──────────────────────────────────────────────────────────

class _GroupBreakdownSection extends StatelessWidget {
  final MonthPlan plan;
  const _GroupBreakdownSection({required this.plan});

  @override
  Widget build(BuildContext context) {
    final budgets = plan.budgets
        .where((b) => b.status == BudgetStatus.active && b.categories.isNotEmpty)
        .toList()
      ..sort((a, b) => b.totalSpent.compareTo(a.totalSpent));

    if (budgets.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Budget Groups', style: AppTextStyles.h4),
          const SizedBox(height: 12),
          ...budgets.map((b) => _BudgetGroupRow(budget: b)),
        ],
      ),
    );
  }
}

class _BudgetGroupRow extends StatelessWidget {
  final Budget budget;
  const _BudgetGroupRow({required this.budget});

  @override
  Widget build(BuildContext context) {
    final isIncome = budget.budgetType == BudgetType.income;
    final planned = budget.budgetTarget;
    final actual = budget.totalSpent;
    final over = actual > planned && planned > 0;
    final progress = planned > 0 ? (actual / planned).clamp(0.0, 1.0) : 0.0;
    final color = isIncome ? AppColors.success : AppColors.accent;
    final progressColor = over ? AppColors.warning : color;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Container(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.border),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    budget.title ?? 'Untitled',
                    style: AppTextStyles.bodySmall.copyWith(fontWeight: FontWeight.w600),
                  ),
                ),
                Text(
                  _fmtI(actual),
                  style: AppTextStyles.bodySmall.copyWith(
                    fontWeight: FontWeight.w600,
                    color: over ? AppColors.warning : AppColors.textPrimary,
                  ),
                ),
                Text(
                  ' / ${_fmtI(planned)}',
                  style: AppTextStyles.caption.copyWith(color: AppColors.textTertiary),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(2),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 4,
                backgroundColor: AppColors.border,
                valueColor: AlwaysStoppedAnimation<Color>(progressColor),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Month Trend ──────────────────────────────────────────────────────────────

class _MonthTrendSection extends StatelessWidget {
  final List<MonthPlan> plans;
  const _MonthTrendSection({required this.plans});

  @override
  Widget build(BuildContext context) {
    // Show last 6 months in chronological order (oldest first)
    final ordered = plans.reversed.toList();

    // Find max value for scaling
    double maxVal = 0;
    for (final p in ordered) {
      final income = p.budgets.where((b) => b.budgetType == BudgetType.income).fold(0.0, (s, b) => s + b.totalSpent);
      final expense = p.budgets.where((b) => b.budgetType == BudgetType.expense).fold(0.0, (s, b) => s + b.totalSpent);
      if (income > maxVal) maxVal = income;
      if (expense > maxVal) maxVal = expense;
    }
    if (maxVal == 0) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('6-Month Trend', style: AppTextStyles.h4),
          const SizedBox(height: 4),
          Row(
            children: [
              _LegendDot(color: AppColors.success, label: 'Income'),
              const SizedBox(width: 12),
              _LegendDot(color: AppColors.error, label: 'Expenses'),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 120,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: ordered.map((p) {
                final income = p.budgets.where((b) => b.budgetType == BudgetType.income).fold(0.0, (s, b) => s + b.totalSpent);
                final expense = p.budgets.where((b) => b.budgetType == BudgetType.expense).fold(0.0, (s, b) => s + b.totalSpent);
                return Expanded(
                  child: _BarGroup(
                    month: _shortMonth(p.month),
                    incomeRatio: income / maxVal,
                    expenseRatio: expense / maxVal,
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  String _shortMonth(String month) {
    final parts = month.split('-');
    if (parts.length != 2) return month;
    final dt = DateTime(int.parse(parts[0]), int.parse(parts[1]));
    return DateFormat('MMM').format(dt);
  }
}

class _BarGroup extends StatelessWidget {
  final String month;
  final double incomeRatio;
  final double expenseRatio;

  const _BarGroup({
    required this.month,
    required this.incomeRatio,
    required this.expenseRatio,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 3),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _Bar(ratio: incomeRatio, color: AppColors.success),
              const SizedBox(width: 2),
              _Bar(ratio: expenseRatio, color: AppColors.error),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            month,
            style: AppTextStyles.caption.copyWith(
              fontSize: 9,
              color: AppColors.textTertiary,
            ),
          ),
        ],
      ),
    );
  }
}

class _Bar extends StatelessWidget {
  final double ratio;
  final Color color;
  const _Bar({required this.ratio, required this.color});

  @override
  Widget build(BuildContext context) {
    final h = (ratio * 90).clamp(2.0, 90.0);
    return Container(
      width: 10,
      height: h,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.8),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(2)),
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;
  const _LegendDot({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 4),
        Text(label, style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary)),
      ],
    );
  }
}
