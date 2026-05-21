import 'package:flutter/material.dart';
import 'package:keep_track/core/theme/app_theme.dart';
import 'package:keep_track/features/finance/modules/budget/domain/entities/budget.dart';
import 'package:keep_track/features/finance/modules/budget/domain/entities/budget_category.dart';
import 'package:keep_track/features/finance/modules/budget/domain/entities/month_plan.dart';
import 'package:keep_track/features/finance/modules/debt/domain/entities/debt.dart';
import 'package:keep_track/features/finance/modules/planned_payment/domain/entities/payment_enums.dart';
import 'package:keep_track/features/finance/modules/planned_payment/domain/entities/planned_payment.dart';
import 'package:keep_track/features/finance/modules/goal/domain/entities/goal.dart';
import 'package:keep_track/features/finance/modules/subscriptions/domain/entities/subscription.dart';
import 'package:keep_track/features/finance/modules/transaction/domain/entities/transaction.dart';

import '../helpers/budget_month_filter.dart';
import '../sheets/budget_settings_sheet.dart';
import '../sections/budget_overall_summary.dart';
import '../sections/budget_summary_bar.dart';
import '../sections/debt_section.dart';
import '../sections/goal_section.dart';
import '../sections/subscription_section.dart';
import '../state/budget_section_type.dart'; // kSectionKeys
import '../state/budget_screen_data.dart';
import '../state/empty_budget_state.dart';
import '../widgets/budget_group_card.dart';
import '../widgets/ghost_add_row.dart';
import '../widgets/side_summary_panel.dart';

class BudgetScreenBody extends StatelessWidget {
  // data
  final BudgetScreenData data;
  final DateTime currentMonth;
  final String monthLabel;
  final String monthKey;

  // selection state
  final Budget? selectedGroup;
  final BudgetCategory? selectedCategory;
  final Budget? selectedCategoryGroup;
  final Debt? selectedDebt;

  // month nav
  final VoidCallback onPrevMonth;
  final VoidCallback onNextMonth;

  // selection callbacks
  final void Function(Budget? group) onGroupSelect;
  final void Function(Debt? debt) onDebtSelect;
  final void Function(Budget group, BudgetCategory cat) onCategorySelect;
  final VoidCallback onClearCategory;
  final VoidCallback onClearGroup;

  // action callbacks
  final void Function(Budget group) onAddCategory;
  final void Function(Budget group, BudgetCategory cat) onEditCategory;
  final void Function(Budget group) onEditGroup;
  final Future<void> Function(Budget group, BudgetCategory cat, double amount)
  onUpdateAmount;
  final Future<void> Function(Budget group, BudgetCategory cat, double amount)
  onCategoryPay;
  final VoidCallback onCreateGroup;
  final void Function(List<Budget> allBudgets) onStartPlanning;
  final void Function(List<Budget> monthBudgets) onDeletePlan;
  final void Function(List<PlannedPayment> payments) onShowCommitments;
  final void Function(Debt debt) onDebtPay;
  final void Function(Debt debt) onEditDebt;
  final void Function(bool isReceivable) onAddDebt;
  final Future<void> Function(Debt debt, double amount) onUpdateDebtPayment;
  final VoidCallback onAddSubscription;
  final Future<void> Function(Subscription) onPaySubscription;
  final VoidCallback onAddGoal;
  final void Function(Goal) onGoalTap;
  final int selectedTab;
  final void Function(int) onTabSelect;
  final List<String> itemOrder;
  final void Function(int oldIndex, int newIndex) onItemReorder;
  final VoidCallback? onToggleView;
  final VoidCallback? onOverrideSettings;
  final String? budgetProfileId;
  final void Function(Debt debt, List<Transaction> transactions)
  onDebtDetailTap;
  final void Function(
    Budget group,
    BudgetCategory cat,
    List<Transaction> transactions,
  )
  onCategoryDetailTap;

  const BudgetScreenBody({
    super.key,
    required this.data,
    required this.currentMonth,
    required this.monthLabel,
    required this.monthKey,
    required this.selectedGroup,
    required this.selectedCategory,
    required this.selectedCategoryGroup,
    required this.selectedDebt,
    required this.onPrevMonth,
    required this.onNextMonth,
    required this.onGroupSelect,
    required this.onDebtSelect,
    required this.onCategorySelect,
    required this.onClearCategory,
    required this.onClearGroup,
    required this.onAddCategory,
    required this.onEditCategory,
    required this.onEditGroup,
    required this.onUpdateAmount,
    required this.onCategoryPay,
    required this.onCreateGroup,
    required this.onStartPlanning,
    required this.onDeletePlan,
    required this.onShowCommitments,
    required this.onDebtPay,
    required this.onEditDebt,
    required this.onAddDebt,
    required this.onUpdateDebtPayment,
    required this.onAddSubscription,
    required this.onPaySubscription,
    required this.onAddGoal,
    required this.onGoalTap,
    required this.selectedTab,
    required this.onTabSelect,
    required this.itemOrder,
    required this.onItemReorder,
    this.onToggleView,
    this.onOverrideSettings,
    this.budgetProfileId,
    required this.onDebtDetailTap,
    required this.onCategoryDetailTap,
  });

  @override
  Widget build(BuildContext context) {
    // ── filtering ────────────────────────────────────────────────────────────
    final monthStart = DateTime(currentMonth.year, currentMonth.month, 1);
    final monthEnd = DateTime(currentMonth.year, currentMonth.month + 1, 1);

    final monthTransactions = BudgetMonthFilter.filterTransactions(
      data.transactions,
      currentMonth,
    );
    final spentByCategory = BudgetMonthFilter.buildSpentByCategory(
      monthTransactions,
    );

    final paidThisMonthByDebt = <String, double>{};
    final contributedThisMonthByGoal = <String, double>{};
    for (final t in monthTransactions) {
      if (t.debtId != null) {
        paidThisMonthByDebt[t.debtId!] = (paidThisMonthByDebt[t.debtId!] ?? 0) + t.amount;
      }
      if (t.goalId != null) {
        contributedThisMonthByGoal[t.goalId!] = (contributedThisMonthByGoal[t.goalId!] ?? 0) + t.amount;
      }
    }

    // Monthly plan (month key match — only for non-profile mode)
    final monthPlan = data.monthPlans.cast<MonthPlan?>().firstWhere(
      (p) => p?.month == monthKey,
      orElse: () => null,
    );

    // Profile plan (budgetProfileId match — profile plans have month: null)
    final profilePlan = budgetProfileId != null
        ? data.monthPlans.cast<MonthPlan?>().firstWhere(
            (p) => p?.budgetProfileId == budgetProfileId,
            orElse: () => null,
          )
        : null;

    final monthBudgets = budgetProfileId != null
        ? data.budgets.where((b) => b.budgetProfileId == budgetProfileId && b.status == BudgetStatus.active).toList()
        : BudgetMonthFilter.filterBudgets(data.budgets, monthPlan);

    // Profile mode: plan exists OR budget groups already exist (started without creating plan first)
    // Monthly mode: a month-keyed plan must exist
    final hasMonthPlan = budgetProfileId != null
        ? (profilePlan != null || monthBudgets.isNotEmpty)
        : monthPlan != null;

    final debts = data.debts
        .where(
          (d) =>
              d.type == DebtType.borrowing &&
              BudgetMonthFilter.debtVisibleInMonth(d, monthStart, monthEnd),
        )
        .toList();

    final receivables = data.debts
        .where(
          (d) =>
              d.type == DebtType.lending &&
              BudgetMonthFilter.debtVisibleInMonth(d, monthStart, monthEnd),
        )
        .toList();

    final activePayments = data.payments
        .where((p) => p.status == PaymentStatus.active)
        .toList();

    final monthSubscriptions = data.subscriptions
        .where((s) =>
            s.status == SubscriptionStatus.active &&
            (s.nextBillingDate.year == currentMonth.year &&
                    s.nextBillingDate.month == currentMonth.month ||
                s.nextBillingDate.isBefore(monthStart)))
        .toList()
      ..sort((a, b) => a.nextBillingDate.compareTo(b.nextBillingDate));

    // ── sync selection ────────────────────────────────────────────────────────
    final syncedSelected = selectedGroup == null
        ? null
        : monthBudgets.firstWhere(
            (b) => b.id == selectedGroup!.id,
            orElse: () => selectedGroup!,
          );

    Budget? syncedCategoryGroup;
    if (selectedCategoryGroup != null) {
      final idx = monthBudgets.indexWhere(
        (b) => b.id == selectedCategoryGroup!.id,
      );
      syncedCategoryGroup = idx >= 0 ? monthBudgets[idx] : null;
    }

    BudgetCategory? syncedCategory;
    if (selectedCategory != null && syncedCategoryGroup != null) {
      final idx = syncedCategoryGroup.categories.indexWhere(
        (c) => c.id == selectedCategory!.id,
      );
      syncedCategory = idx >= 0
          ? syncedCategoryGroup.categories[idx]
          : selectedCategory;
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 600;
        final isDark = Theme.of(context).brightness == Brightness.dark;

        // ── summary panel ─────────────────────────────────────────────────────
        void settings() => (onOverrideSettings ?? () => BudgetSettingsSheet.show(
          context,
          monthLabel: monthLabel,
          onEditBudget: null,
          onDeleteBudget: () => onDeletePlan(monthBudgets),
        ))();

        Widget buildSummaryPanel({bool withActions = false}) => SideSummaryPanel(
          onToggleView: withActions ? onToggleView : null,
          onSettings: withActions ? settings : null,
          selectedGroup: syncedSelected,
          selectedCategory: syncedCategory,
          selectedCategoryGroup: syncedCategoryGroup,
          selectedDebt: selectedDebt,
          allBudgets: monthBudgets,
          allTransactions: monthTransactions,
          onClose: onClearGroup,
          onCategoryPanelClose: onClearCategory,
          onDebtClose: () => onDebtSelect(null),
          onDebtPay: onDebtPay,
          onEditCategory: syncedCategory != null && syncedCategoryGroup != null
              ? () => onEditCategory(syncedCategoryGroup!, syncedCategory!)
              : null,
          onEditDebt: selectedDebt != null
              ? () => onEditDebt(selectedDebt!)
              : null,
          onAddCategory: onAddCategory,
          onCategoryDetailTap: (cat) {
            if (syncedSelected != null) {
              onCategoryDetailTap(syncedSelected, cat, monthTransactions);
            }
          },
          onUpdateAmount: onUpdateAmount,
        );

        // Gray scroll area so white group cards pop (Every Dollar style)
        final bg = isDark ? const Color(0xFF1A1A18) : AppColors.background;
        final panelBg = isDark ? const Color(0xFF2C2C2A) : Colors.white;
        final divColor = AppColors.border.withValues(alpha: isDark ? 0.15 : 0.4);

        // ── budget group order (tab 0 only) ──────────────────────────────────
        final budgetGroupKeys = itemOrder.where((k) => !kSectionKeys.contains(k)).toList();

        void onBudgetGroupReorder(int filteredOld, int filteredNew) {
          if (filteredNew > filteredOld) filteredNew -= 1;
          final fullOld = itemOrder.indexOf(budgetGroupKeys[filteredOld]);
          final fullNew = itemOrder.indexOf(budgetGroupKeys[filteredNew]);
          onItemReorder(fullOld, fullNew);
        }

        // ── scrollable main content ───────────────────────────────────────────
        List<Widget> contentSlivers;

        if (selectedTab == 0) {
          // Summary tab: full financial overview
          contentSlivers = [
            const SliverToBoxAdapter(child: SizedBox(height: 24)),
            SliverToBoxAdapter(
              child: BudgetOverallSummary(
                monthBudgets: monthBudgets,
                spentByCategory: spentByCategory,
                subscriptions: monthSubscriptions,
                debts: debts,
                receivables: receivables,
                goals: data.goals,
                transactions: monthTransactions,
                currentMonth: currentMonth,
                isDark: isDark,
              ),
            ),
          ];
        } else if (selectedTab == 1) {
          // Budget tab: reorderable budget groups only
          contentSlivers = [
            const SliverToBoxAdapter(child: SizedBox(height: 16)),
            if (!hasMonthPlan)
              SliverToBoxAdapter(
                child: EmptyBudgetState(
                  monthLabel: monthLabel,
                  onStart: () => onStartPlanning(data.budgets),
                ),
              ),
            SliverReorderableList(
              itemCount: budgetGroupKeys.length,
              onReorder: onBudgetGroupReorder,
              proxyDecorator: (child, index, animation) => Material(
                elevation: 4,
                color: Colors.transparent,
                child: child,
              ),
              itemBuilder: (context, index) {
                final key = budgetGroupKeys[index];
                return KeyedSubtree(
                  key: ValueKey(key),
                  child: _buildItem(
                    context,
                    key: key,
                    dragIndex: index,
                    debts: debts,
                    receivables: receivables,
                    monthSubscriptions: monthSubscriptions,
                    monthBudgets: monthBudgets,
                    monthLabel: monthLabel,
                    spentByCategory: spentByCategory,
                    paidThisMonthByDebt: paidThisMonthByDebt,
                    contributedThisMonthByGoal: contributedThisMonthByGoal,
                    selectedGroup: syncedSelected,
                    selectedDebt: selectedDebt,
                    isWide: isWide,
                    monthTransactions: monthTransactions,
                    divColor: divColor,
                  ),
                );
              },
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
                child: GhostAddRow(label: 'Add Budget Group', onTap: onCreateGroup),
              ),
            ),
          ];
        } else {
          // Single section tab (tabs 2-5 after adding summary at 0)
          final sectionKey = switch (selectedTab) {
            2 => 'subscriptions',
            3 => 'debts',
            4 => 'receivables',
            5 => 'goals',
            _ => '',
          };
          final sectionDragIndex = itemOrder.indexOf(sectionKey);
          contentSlivers = [
            const SliverToBoxAdapter(child: SizedBox(height: 16)),
            SliverToBoxAdapter(
              child: _buildItem(
                context,
                key: sectionKey,
                dragIndex: sectionDragIndex >= 0 ? sectionDragIndex : 0,
                debts: debts,
                receivables: receivables,
                monthSubscriptions: monthSubscriptions,
                monthBudgets: monthBudgets,
                monthLabel: monthLabel,
                spentByCategory: spentByCategory,
                paidThisMonthByDebt: paidThisMonthByDebt,
                contributedThisMonthByGoal: contributedThisMonthByGoal,
                selectedGroup: syncedSelected,
                selectedDebt: selectedDebt,
                isWide: isWide,
                monthTransactions: monthTransactions,
                divColor: divColor,
              ),
            ),
          ];
        }

        final mainScroll = CustomScrollView(
          slivers: [
            ...contentSlivers,
            const SliverToBoxAdapter(child: SizedBox(height: 100)),
          ],
        );

        // ── Shared summary bar widget ─────────────────────────────────────────
        Widget summaryBar({bool narrowActions = false}) => Container(
          color: panelBg,
          child: BudgetSummaryBar(
            monthLabel: monthLabel,
            onPrev: onPrevMonth,
            onNext: onNextMonth,
            // On narrow, show actions in the bar; on wide, they're in the side panel
            onToggleView: narrowActions ? onToggleView : null,
            onSummaryTap: narrowActions ? () => _showSummarySheet(context, buildSummaryPanel()) : null,
            onSettings: narrowActions ? settings : null,
            monthBudgets: monthBudgets,
            spentByCategory: spentByCategory,
            activePayments: activePayments,
            activeDebts: debts,
            activeReceivables: receivables,
            onCommitmentsTab: () => onShowCommitments(activePayments),
            selectedTab: selectedTab,
            onTabSelect: onTabSelect,
            budgetGroupCount: monthBudgets.length,
            subsCount: monthSubscriptions.length,
            debtsCount: debts.length,
            receivablesCount: receivables.length,
            goalsCount: data.goals.length,
          ),
        );

        // ── layout ────────────────────────────────────────────────────────────
        if (isWide) {
          // Wide: side panel covers FULL HEIGHT (including header row)
          return Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Left column: header + scrollable content
              Expanded(
                child: Column(
                  children: [
                    summaryBar(),
                    Expanded(child: ColoredBox(color: bg, child: mainScroll)),
                  ],
                ),
              ),
              // Right: full-height sticky side panel with actions in its top bar
              Container(
                width: 300,
                decoration: BoxDecoration(
                  color: panelBg,
                  border: Border(left: BorderSide(color: divColor, width: 0.5)),
                ),
                child: buildSummaryPanel(withActions: true),
              ),
            ],
          );
        }

        // Narrow: header full-width, then scrollable content below
        return Column(
          children: [
            summaryBar(narrowActions: true),
            Expanded(child: ColoredBox(color: bg, child: mainScroll)),
          ],
        );
      },
    );
  }

  // ── item builder ──────────────────────────────────────────────────────────
  Widget _buildItem(
    BuildContext context, {
    required String key,
    required int dragIndex,
    required List<Debt> debts,
    required List<Debt> receivables,
    required List<Subscription> monthSubscriptions,
    required List<Budget> monthBudgets,
    required String monthLabel,
    required Map<String, double> spentByCategory,
    required Map<String, double> paidThisMonthByDebt,
    required Map<String, double> contributedThisMonthByGoal,
    required Budget? selectedGroup,
    required Debt? selectedDebt,
    required bool isWide,
    required List<Transaction> monthTransactions,
    required Color divColor,
  }) {
    // Budget group item
    if (!kSectionKeys.contains(key)) {
      final group = monthBudgets.where((g) => g.id == key).firstOrNull;
      if (group == null) return const SizedBox.shrink();
      return BudgetGroupCard(
            group: group,
            monthLabel: monthLabel,
            isSelected: selectedGroup?.id == group.id,
            spentByCategory: spentByCategory,
            dragIndex: dragIndex,
            onSelect: () => onGroupSelect(selectedGroup?.id == group.id ? null : group),
            onEditGroup: () => onEditGroup(group),
            onAddRow: () => onAddCategory(group),
            onCategoryEditTap: (cat) => onEditCategory(group, cat),
            onCategoryDetailTap: (cat) {
              if (isWide) { onCategorySelect(group, cat); }
              else { onCategoryDetailTap(group, cat, monthTransactions); }
            },
            onUpdateAmount: (cat, amount) async => onUpdateAmount(group, cat, amount),
            onCategoryPay: (cat, amount) => onCategoryPay(group, cat, amount),
          );
    }

    // Section items — each is now a self-contained card with its own margin
    return switch (key) {
      'debts' => DebtSection(
          title: 'Debts',
          debts: debts,
          isReceivable: false,
          selectedDebt: selectedDebt,
          paidThisMonth: paidThisMonthByDebt,
          dragIndex: dragIndex,
          onAdd: () => onAddDebt(false),
          onPay: onDebtPay,
          onEdit: onEditDebt,
          onUpdateMonthlyPayment: onUpdateDebtPayment,
          onSelect: (d) {
            if (isWide) { onDebtSelect(selectedDebt?.id == d.id ? null : d); }
            else { onDebtDetailTap(d, monthTransactions); }
          },
        ),
      'receivables' => DebtSection(
          title: 'Receivables',
          debts: receivables,
          isReceivable: true,
          selectedDebt: selectedDebt,
          paidThisMonth: paidThisMonthByDebt,
          dragIndex: dragIndex,
          onAdd: () => onAddDebt(true),
          onPay: onDebtPay,
          onEdit: onEditDebt,
          onUpdateMonthlyPayment: onUpdateDebtPayment,
          onSelect: (d) {
            if (isWide) { onDebtSelect(selectedDebt?.id == d.id ? null : d); }
            else { onDebtDetailTap(d, monthTransactions); }
          },
        ),
      'subscriptions' => SubscriptionSection(
          subscriptions: monthSubscriptions,
          dragIndex: dragIndex,
          onAdd: onAddSubscription,
          onPay: onPaySubscription,
        ),
      'goals' => GoalSection(
          goals: data.goals,
          contributedThisMonth: contributedThisMonthByGoal,
          dragIndex: dragIndex,
          onAdd: onAddGoal,
          onGoalTap: onGoalTap,
        ),
      _ => const SizedBox.shrink(),
    };
  }

  // ── helpers ───────────────────────────────────────────────────────────────
  void _showSummarySheet(BuildContext context, Widget content) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.55,
        maxChildSize: 0.9,
        minChildSize: 0.35,
        builder: (_, __) => Card(
          margin: EdgeInsets.zero,
          elevation: 4,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
          ),
          child: Column(
            children: [
              const SizedBox(height: 8),
              Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.textTertiary.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 4),
              Expanded(child: content),
            ],
          ),
        ),
      ),
    );
  }
}
