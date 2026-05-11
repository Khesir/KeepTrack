import 'package:flutter/material.dart';
import 'package:keep_track/core/theme/app_theme.dart';
import 'package:keep_track/features/finance/modules/budget/domain/entities/budget.dart';
import 'package:keep_track/features/finance/modules/budget/domain/entities/budget_category.dart';
import 'package:keep_track/features/finance/modules/budget/domain/entities/month_plan.dart';
import 'package:keep_track/features/finance/modules/debt/domain/entities/debt.dart';
import 'package:keep_track/features/finance/modules/planned_payment/domain/entities/payment_enums.dart';
import 'package:keep_track/features/finance/modules/planned_payment/domain/entities/planned_payment.dart';
import 'package:keep_track/features/finance/modules/transaction/domain/entities/transaction.dart';

import '../helpers/budget_month_filter.dart';
import '../sections/budget_summary_bar.dart';
import '../sections/debt_section.dart';
import '../state/budget_screen_data.dart';
import '../state/empty_budget_state.dart';
import '../widgets/budget_group_card.dart';
import '../widgets/ghost_add_row.dart';
import '../widgets/month_header.dart';
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
  final VoidCallback onCreateGroup;
  final void Function(List<Budget> allBudgets) onStartPlanning;
  final void Function(List<Budget> monthBudgets) onDeletePlan;
  final void Function(List<PlannedPayment> payments) onShowCommitments;
  final void Function(Debt debt) onDebtPay;
  final void Function(Debt debt) onEditDebt;
  final void Function(bool isReceivable) onAddDebt;
  final Future<void> Function(Debt debt, double amount) onUpdateDebtPayment;
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
    required this.onCreateGroup,
    required this.onStartPlanning,
    required this.onDeletePlan,
    required this.onShowCommitments,
    required this.onDebtPay,
    required this.onEditDebt,
    required this.onAddDebt,
    required this.onUpdateDebtPayment,
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

    final monthPlan = data.monthPlans.cast<MonthPlan?>().firstWhere(
      (p) => p?.month == monthKey,
      orElse: () => null,
    );
    final hasMonthPlan = monthPlan != null;
    final monthBudgets = BudgetMonthFilter.filterBudgets(
      data.budgets,
      monthPlan,
    );

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

        // ── summary panel ─────────────────────────────────────────────────────
        Widget buildSummaryPanel() => SideSummaryPanel(
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

        // ── budget card ───────────────────────────────────────────────────────
        final budgetCard = Card(
          margin: EdgeInsets.zero,
          elevation: 0,
          clipBehavior: Clip.antiAlias,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: AppColors.border),
          ),
          child: CustomScrollView(
            slivers: [
              // summary bar
              SliverToBoxAdapter(
                child: BudgetSummaryBar(
                  monthBudgets: monthBudgets,
                  spentByCategory: spentByCategory,
                  activePayments: activePayments,
                  activeDebts: debts,
                  activeReceivables: receivables,
                  onCommitmentsTab: () => onShowCommitments(activePayments),
                ),
              ),

              // empty state or budget list
              if (!hasMonthPlan)
                SliverToBoxAdapter(
                  child: EmptyBudgetState(
                    monthLabel: monthLabel,
                    onStart: () => onStartPlanning(data.budgets),
                  ),
                )
              else
                SliverList(
                  delegate: SliverChildBuilderDelegate((context, i) {
                    final group = monthBudgets[i];
                    return BudgetGroupCard(
                      group: group,
                      monthLabel: monthLabel,
                      isSelected: selectedGroup?.id == group.id,
                      spentByCategory: spentByCategory,
                      onSelect: () => onGroupSelect(
                        selectedGroup?.id == group.id ? null : group,
                      ),
                      onEditGroup: () => onEditGroup(group),
                      onAddRow: () => onAddCategory(group),
                      onCategoryEditTap: (cat) => onEditCategory(group, cat),
                      onCategoryDetailTap: (cat) {
                        if (isWide) {
                          onCategorySelect(group, cat);
                        } else {
                          onCategoryDetailTap(group, cat, monthTransactions);
                        }
                      },
                      onUpdateAmount: (cat, amount) async =>
                          onUpdateAmount(group, cat, amount),
                    );
                  }, childCount: monthBudgets.length),
                ),

              // add group row
              SliverToBoxAdapter(
                child: GhostAddRow(
                  label: 'Add Budget Group',
                  onTap: onCreateGroup,
                ),
              ),

              // debts
              const SliverToBoxAdapter(child: Divider(height: 1)),
              SliverToBoxAdapter(
                child: DebtSection(
                  title: 'DEBTS',
                  debts: debts,
                  isReceivable: false,
                  selectedDebt: selectedDebt,
                  onAdd: () => onAddDebt(false),
                  onPay: onDebtPay,
                  onEdit: onEditDebt,
                  onUpdateMonthlyPayment: onUpdateDebtPayment,
                  onSelect: (d) {
                    if (isWide) {
                      onDebtSelect(selectedDebt?.id == d.id ? null : d);
                    } else {
                      onDebtDetailTap(d, monthTransactions);
                    }
                  },
                ),
              ),

              // receivables
              const SliverToBoxAdapter(child: Divider(height: 1)),
              SliverToBoxAdapter(
                child: DebtSection(
                  title: 'RECEIVABLES',
                  debts: receivables,
                  isReceivable: true,
                  selectedDebt: selectedDebt,
                  onAdd: () => onAddDebt(true),
                  onPay: onDebtPay,
                  onEdit: onEditDebt,
                  onUpdateMonthlyPayment: onUpdateDebtPayment,
                  onSelect: (d) {
                    if (isWide) {
                      onDebtSelect(selectedDebt?.id == d.id ? null : d);
                    } else {
                      onDebtDetailTap(d, monthTransactions);
                    }
                  },
                ),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 80)),
            ],
          ),
        );

        // ── layout ────────────────────────────────────────────────────────────
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 4, 8, 0),
              child: MonthHeader(
                monthLabel: monthLabel,
                onPrev: onPrevMonth,
                onNext: onNextMonth,
                onSummaryTap: isWide
                    ? null
                    : () => _showSummarySheet(context, buildSummaryPanel()),
                onDelete: () => onDeletePlan(monthBudgets),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
                child: isWide
                    ? Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(child: budgetCard),
                          const SizedBox(width: 8),
                          SizedBox(
                            width: 320,
                            child: Card(
                              margin: EdgeInsets.zero,
                              elevation: 0,
                              clipBehavior: Clip.antiAlias,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                                side: BorderSide(color: AppColors.border),
                              ),
                              child: buildSummaryPanel(),
                            ),
                          ),
                        ],
                      )
                    : budgetCard,
              ),
            ),
          ],
        );
      },
    );
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
