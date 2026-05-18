import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:keep_track/core/di/service_locator.dart';
import 'package:keep_track/core/state/stream_builder_widget.dart';
import 'package:keep_track/core/theme/app_theme.dart';
import 'package:keep_track/core/ui/app_layout_controller.dart';
import 'package:keep_track/core/ui/ui.dart';
import 'package:keep_track/features/finance/modules/budget/domain/entities/budget.dart';
import 'package:keep_track/features/finance/modules/budget/domain/entities/month_plan.dart';
import 'package:keep_track/features/finance/modules/budget/presentation/controllers/budget_controller.dart';
import 'package:keep_track/features/finance/modules/budget/presentation/helpers/budget_month_filter.dart';
import 'package:keep_track/features/finance/modules/debt/domain/entities/debt.dart';
import 'package:keep_track/features/finance/modules/savings/domain/entities/savings_bucket.dart';
import 'package:keep_track/features/finance/modules/subscriptions/domain/entities/subscription.dart';
import 'package:keep_track/features/finance/modules/transaction/domain/entities/transaction.dart';
import 'package:keep_track/features/finance/presentation/state/debt_controller.dart';
import 'package:keep_track/features/finance/presentation/state/month_plan_controller.dart';
import 'package:keep_track/features/finance/presentation/state/savings_controller.dart';
import 'package:keep_track/features/finance/presentation/state/subscription_controller.dart';
import 'package:keep_track/features/finance/presentation/state/transaction_controller.dart';
import 'profile_insight_sections.dart';

class ProfileScreen extends ScopedScreen {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ScopedScreenState<ProfileScreen> with AppLayoutControlled {
  late final MonthPlanController _monthPlanController;
  late final BudgetController _budgetController;
  late final TransactionController _txController;
  late final SavingsController _savingsController;
  late final DebtController _debtController;
  late final SubscriptionController _subController;
  int _selectedMonthIndex = 0;

  @override
  void registerServices() {
    _monthPlanController = locator.get<MonthPlanController>();
    _budgetController = locator.get<BudgetController>();
    _txController = locator.get<TransactionController>();
    _savingsController = locator.get<SavingsController>();
    _debtController = locator.get<DebtController>();
    _subController = locator.get<SubscriptionController>();
  }

  @override
  void onReady() {
    configureLayout(title: 'Insights', showBottomNav: true);
    _budgetController.loadBudgets();
    _savingsController.loadSavings();
    final now = DateTime.now();
    _txController.loadTransactionsByDateRange(
      DateTime(now.year, now.month, 1),
      DateTime(now.year, now.month + 1, 1),
    );
  }

  void _selectMonth(int index, List<MonthPlan> plans) {
    setState(() => _selectedMonthIndex = index);
    final m = plans[index].month;
    if (m == null) return;
    final parts = m.split('-');
    if (parts.length != 2) return;
    final year = int.tryParse(parts[0]);
    final month = int.tryParse(parts[1]);
    if (year == null || month == null) return;
    _txController.loadTransactionsByDateRange(
      DateTime(year, month, 1),
      DateTime(year, month + 1, 1),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AsyncStreamBuilder<List<MonthPlan>>(
      state: _monthPlanController,
      builder: (_, plans) {
        if (plans.isEmpty) return _buildEmpty();
        final displayPlans = plans.take(6).toList();
        final idx = _selectedMonthIndex.clamp(0, displayPlans.length - 1);
        final selected = displayPlans[idx];

        return AsyncStreamBuilder<List<Budget>>(
          state: _budgetController,
          builder: (_, allBudgets) {
            final monthBudgets = allBudgets
                .where((b) => b.month == selected.month && b.status == BudgetStatus.active)
                .toList();

            return AsyncStreamBuilder<List<Transaction>>(
              state: _txController,
              builder: (_, txs) {
                final spent = BudgetMonthFilter.buildSpentByCategory(txs);
                return AsyncStreamBuilder<List<SavingsBucket>>(
                  state: _savingsController,
                  builder: (_, buckets) => AsyncStreamBuilder<List<Debt>>(
                    state: _debtController,
                    builder: (_, debts) => AsyncStreamBuilder<List<Subscription>>(
                      state: _subController,
                      builder: (_, subs) => _buildContent(displayPlans, idx, selected, monthBudgets, allBudgets, spent, buckets, debts, subs),
                      loadingBuilder: (_) => _buildContent(displayPlans, idx, selected, monthBudgets, allBudgets, spent, buckets, debts, []),
                      errorBuilder: (_, __) => _buildContent(displayPlans, idx, selected, monthBudgets, allBudgets, spent, buckets, debts, []),
                    ),
                    loadingBuilder: (_) => _buildContent(displayPlans, idx, selected, monthBudgets, allBudgets, spent, buckets, [], []),
                    errorBuilder: (_, __) => _buildContent(displayPlans, idx, selected, monthBudgets, allBudgets, spent, buckets, [], []),
                  ),
                  loadingBuilder: (_) => _buildContent(displayPlans, idx, selected, monthBudgets, allBudgets, spent, [], [], []),
                  errorBuilder: (_, __) => _buildContent(displayPlans, idx, selected, monthBudgets, allBudgets, spent, [], [], []),
                );
              },
              loadingBuilder: (_) => _buildContent(displayPlans, idx, selected, monthBudgets, allBudgets, {}, [], [], []),
              errorBuilder: (_, __) => _buildContent(displayPlans, idx, selected, monthBudgets, allBudgets, {}, [], [], []),
            );
          },
          loadingBuilder: (_) => const Center(child: CircularProgressIndicator()),
          errorBuilder: (_, __) => const Center(child: CircularProgressIndicator()),
        );
      },
      loadingBuilder: (_) => const Center(child: CircularProgressIndicator()),
      errorBuilder: (_, msg) => Center(child: Text(msg, style: AppTextStyles.bodyMedium.copyWith(color: AppColors.error))),
    );
  }

  Widget _buildContent(
    List<MonthPlan> plans,
    int idx,
    MonthPlan selected,
    List<Budget> monthBudgets,
    List<Budget> allBudgets,
    Map<String, double> spentByCategory,
    List<SavingsBucket> buckets,
    List<Debt> debts,
    List<Subscription> subs,
  ) {
    final totalSavings = buckets.fold(0.0, (s, b) => s + b.balance);
    final totalDebt = debts.where((d) => d.type == DebtType.borrowing).fold(0.0, (s, d) => s + d.remainingAmount);
    final totalReceivables = debts.where((d) => d.type == DebtType.lending).fold(0.0, (s, d) => s + d.remainingAmount);
    final activeSubs = subs.where((s) => s.status == SubscriptionStatus.active).toList();

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(child: _MonthSelector(
          plans: plans, selectedIndex: idx,
          onSelect: (i) => _selectMonth(i, plans),
        )),
        const SliverToBoxAdapter(child: _AiInsightCard()),
        if (monthBudgets.isNotEmpty) ...[
          SliverToBoxAdapter(child: InsightSpendingSection(allBudgets: monthBudgets, spentByCategory: spentByCategory)),
          SliverToBoxAdapter(child: InsightBudgetBarsSection(allBudgets: monthBudgets, spentByCategory: spentByCategory)),
        ],
        if (buckets.isNotEmpty)
          SliverToBoxAdapter(child: InsightSavingsSection(buckets: buckets, total: totalSavings)),
        if (plans.length > 1)
          SliverToBoxAdapter(child: InsightTrendSection(plans: plans, allBudgets: allBudgets)),
        if (debts.isNotEmpty)
          SliverToBoxAdapter(child: InsightDebtSection(
            debts: debts.where((d) => d.type == DebtType.borrowing && d.status == DebtStatus.active).toList(),
            receivables: debts.where((d) => d.type == DebtType.lending && d.status == DebtStatus.active).toList(),
            totalDebt: totalDebt, totalReceivables: totalReceivables,
          )),
        if (activeSubs.isNotEmpty)
          SliverToBoxAdapter(child: InsightSubscriptionsSection(subs: activeSubs)),
        const SliverToBoxAdapter(child: SizedBox(height: 32)),
      ],
    );
  }

  Widget _buildEmpty() => Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.bar_chart_outlined, size: 56, color: AppColors.textTertiary),
        const SizedBox(height: 16),
        Text('No data yet', style: AppTextStyles.h4),
        const SizedBox(height: 6),
        Text('Start planning a month to see insights',
            style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary)),
      ],
    ),
  );
}

// ─── Month Selector ───────────────────────────────────────────────────────────

class _MonthSelector extends StatelessWidget {
  final List<MonthPlan> plans;
  final int selectedIndex;
  final void Function(int) onSelect;

  const _MonthSelector({required this.plans, required this.selectedIndex, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        itemCount: plans.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final selected = i == selectedIndex;
          final planMonth = plans[i].month;
          final parts = planMonth?.split('-') ?? [];
          final label = parts.length == 2
              ? DateFormat('MMM yyyy').format(DateTime(int.parse(parts[0]), int.parse(parts[1])))
              : (planMonth ?? '');
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
              child: Text(label, style: AppTextStyles.caption.copyWith(
                color: selected ? AppColors.textOnPrimary : AppColors.textSecondary,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
              )),
            ),
          );
        },
      ),
    );
  }
}

// ─── AI Insight Placeholder ───────────────────────────────────────────────────

class _AiInsightCard extends StatelessWidget {
  const _AiInsightCard();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isDark
                ? [const Color(0xFF1E1B4B), const Color(0xFF312E81)]
                : [const Color(0xFF4F46E5), const Color(0xFF7C3AED)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.auto_awesome, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    const Text('AI Insights', style: TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 0.5)),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(20)),
                      child: const Text('Coming soon', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w600)),
                    ),
                  ]),
                  const SizedBox(height: 4),
                  const Text('Personalized financial insights powered by AI are on the way.',
                      style: TextStyle(color: Colors.white, fontSize: 13, height: 1.4)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
