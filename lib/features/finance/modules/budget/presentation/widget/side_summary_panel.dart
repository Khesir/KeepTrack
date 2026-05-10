import 'package:flutter/material.dart';
import 'package:keep_track/core/theme/app_theme.dart';
import 'package:keep_track/core/ui/scoped_screen.dart';

import '../../../debt/domain/entities/debt.dart';
import '../../../transaction/domain/entities/transaction.dart';
import '../../domain/entities/budget.dart';
import '../../domain/entities/budget_category.dart';
import 'all_summary_tab.dart';
import 'all_transaction_tab.dart';
import 'category_detail_content.dart';
import 'debt_detail_content.dart';
import 'group_transaction_tab.dart';

class SideSummaryPanel extends ScopedScreen {
  final Budget? selectedGroup;
  final BudgetCategory? selectedCategory;
  final Budget? selectedCategoryGroup;
  final Debt? selectedDebt;
  final List<Budget> allBudgets;
  final List<Transaction> allTransactions;
  final VoidCallback onClose;
  final VoidCallback onCategoryPanelClose;
  final VoidCallback onDebtClose;
  final void Function(Debt) onDebtPay;
  final VoidCallback? onEditCategory;
  final VoidCallback? onEditDebt;

  final void Function(Budget) onAddCategory;
  final void Function(BudgetCategory) onCategoryDetailTap;
  final Future<void> Function(Budget, BudgetCategory, double) onUpdateAmount;

  const SideSummaryPanel(
    this.onEditCategory,
    this.onEditDebt, {
    super.key,
    required this.selectedGroup,
    required this.selectedCategory,
    required this.selectedCategoryGroup,
    required this.selectedDebt,
    required this.allBudgets,
    required this.allTransactions,
    required this.onClose,
    required this.onCategoryPanelClose,
    required this.onDebtClose,
    required this.onDebtPay,

    required this.onAddCategory,
    required this.onCategoryDetailTap,
    required this.onUpdateAmount,
  });

  @override
  State<SideSummaryPanel> createState() => _SideSummaryPanelState();
}

class _SideSummaryPanelState extends ScopedScreenState<SideSummaryPanel>
    with TickerProviderStateMixin {
  late TabController _tabController;

  bool get _isCategoryMode => widget.selectedCategory != null;

  int get _tabCount => widget.selectedGroup != null ? 1 : 2;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: _isCategoryMode ? 1 : _tabCount,
      vsync: this,
    );
  }

  @override
  void didUpdateWidget(SideSummaryPanel old) {
    super.didUpdateWidget(old);
    final wasCategory = old.selectedCategory != null;
    final isCategory = widget.selectedCategory != null;
    final wasGroup = old.selectedGroup != null;
    final isGroup = widget.selectedGroup != null;

    final modeChanged =
        wasCategory != isCategory ||
        old.selectedCategory?.id != widget.selectedCategory?.id ||
        wasGroup != isGroup ||
        old.selectedGroup?.id != widget.selectedGroup?.id;

    if (modeChanged) {
      _tabController.dispose();
      _tabController = TabController(
        length: isCategory ? 1 : (isGroup ? 1 : 2),
        vsync: this,
      );
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cat = widget.selectedCategory;
    final group = widget.selectedGroup;

    // ── Debt detail mode ────────────────────────────────────────────────
    final debt = widget.selectedDebt;
    if (debt != null) {
      final isReceivable = debt.type == DebtType.lending;
      final debtTxns =
          widget.allTransactions.where((t) => t.debtId == debt.id).toList()
            ..sort((a, b) => b.date.compareTo(a.date));

      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest.withValues(
                alpha: 0.4,
              ),
              border: Border(top: BorderSide(color: theme.dividerColor)),
            ),
            padding: const EdgeInsets.fromLTRB(8, 4, 8, 4),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: (isReceivable ? AppColors.success : AppColors.error)
                        .withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    isReceivable ? 'RECEIVABLE' : 'DEBT',
                    style: AppTextStyles.caption.copyWith(
                      color: isReceivable ? AppColors.success : AppColors.error,
                      fontWeight: FontWeight.w700,
                      fontSize: 9,
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    debt.personName,
                    style: AppTextStyles.bodySmall.copyWith(
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.primary,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),

                // Edit button
                if (widget.onEditDebt != null)
                  IconButton(
                    icon: const Icon(Icons.edit_outlined, size: 14),
                    padding: EdgeInsets.zero,
                    onPressed: widget.onEditDebt,
                    tooltip: 'Edit',
                    style: IconButton.styleFrom(
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ),
                TextButton(
                  onPressed: () => widget.onDebtPay(debt),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    visualDensity: VisualDensity.compact,
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: Text(
                    isReceivable ? 'Collect' : 'Pay',
                    style: const TextStyle(fontSize: 11),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, size: 15),
                  onPressed: widget.onDebtClose,
                  color: AppColors.textTertiary,
                  visualDensity: VisualDensity.compact,
                  padding: const EdgeInsets.all(6),
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
          ),
          Expanded(
            child: DebtDetailContent(debt: debt, transactions: debtTxns),
          ),
        ],
      );
    }

    // ── Category detail mode ───────────────────────────────────────────
    if (cat != null) {
      final catTxns =
          widget.allTransactions
              .where((t) => t.financeCategoryId == cat.financeCategoryId)
              .toList()
            ..sort((a, b) => b.date.compareTo(a.date));

      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header bar with back button
          Container(
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest.withValues(
                alpha: 0.4,
              ),
              border: Border(top: BorderSide(color: theme.dividerColor)),
            ),
            padding: const EdgeInsets.fromLTRB(8, 4, 8, 4),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back, size: 16),
                  onPressed: widget.onCategoryPanelClose,
                  color: AppColors.textSecondary,
                  visualDensity: VisualDensity.compact,
                  padding: const EdgeInsets.all(6),
                  constraints: const BoxConstraints(),
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    cat.financeCategory?.name ?? 'Category',
                    style: AppTextStyles.bodySmall.copyWith(
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.primary,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (widget.onEditCategory != null)
                  IconButton(
                    icon: const Icon(Icons.edit_outlined, size: 15),
                    onPressed: widget.onEditCategory,
                    color: AppColors.textTertiary,
                    visualDensity: VisualDensity.compact,
                    padding: const EdgeInsets.all(6),
                    constraints: const BoxConstraints(),
                    tooltip: 'Edit category',
                  ),
                IconButton(
                  icon: const Icon(Icons.close, size: 15),
                  onPressed: widget.onClose,
                  color: AppColors.textTertiary,
                  visualDensity: VisualDensity.compact,
                  padding: const EdgeInsets.all(6),
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
          ),
          Expanded(
            child: CategoryDetailContent(
              category: cat,
              transactions: catTxns,
              isIncomeGroup:
                  widget.selectedCategoryGroup?.budgetType == BudgetType.income,
            ),
          ),
        ],
      );
    }

    // ── Group / default mode ───────────────────────────────────────────
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest.withValues(
              alpha: 0.4,
            ),
            border: Border(top: BorderSide(color: theme.dividerColor)),
          ),
          child: group == null
              ? TabBar(
                  controller: _tabController,
                  labelStyle: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                  unselectedLabelStyle: const TextStyle(fontSize: 12),
                  tabs: const [
                    Tab(text: 'Summary'),
                    Tab(text: 'Transactions'),
                  ],
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 8, 0),
                      child: Row(
                        children: [
                          Icon(
                            Icons.folder_outlined,
                            size: 13,
                            color: theme.colorScheme.primary,
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              group.title ?? '',
                              style: AppTextStyles.bodySmall.copyWith(
                                color: theme.colorScheme.primary,
                                fontWeight: FontWeight.w600,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close, size: 15),
                            onPressed: widget.onClose,
                            color: AppColors.textTertiary,
                            visualDensity: VisualDensity.compact,
                            padding: const EdgeInsets.all(8),
                            constraints: const BoxConstraints(),
                          ),
                        ],
                      ),
                    ),
                    TabBar(
                      controller: _tabController,
                      labelStyle: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                      unselectedLabelStyle: const TextStyle(fontSize: 12),
                      tabs: const [Tab(text: 'Transactions')],
                    ),
                  ],
                ),
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: group == null
                ? [
                    AllSummaryTab(
                      budgets: widget.allBudgets,
                      transactions: widget.allTransactions,
                    ),
                    AllTransactionsTab(transactions: widget.allTransactions),
                  ]
                : [
                    GroupTransactionsTab(
                      transactions:
                          widget.allTransactions
                              .where((t) => t.budgetId == group.id)
                              .toList()
                            ..sort((a, b) => b.date.compareTo(a.date)),
                    ),
                  ],
          ),
        ),
      ],
    );
  }
}
