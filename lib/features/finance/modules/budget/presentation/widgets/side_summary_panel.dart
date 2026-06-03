import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:keep_track/core/theme/app_theme.dart';
import 'package:keep_track/core/ui/scoped_screen.dart';

import '../../../debt/domain/entities/debt.dart';
import '../../../goal/domain/entities/goal.dart';
import '../../../subscriptions/domain/entities/subscription.dart';
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
  final List<Subscription> subscriptions;
  final List<Debt> debts;
  final List<Debt> receivables;
  final List<Goal> goals;
  final DateTime currentMonth;
  final VoidCallback onClose;
  final VoidCallback onCategoryPanelClose;
  final VoidCallback onDebtClose;
  final void Function(Debt) onDebtPay;
  final VoidCallback? onEditCategory;
  final VoidCallback? onEditDebt;

  final void Function(Budget) onAddCategory;
  final void Function(BudgetCategory) onCategoryDetailTap;
  final Future<void> Function(Budget, BudgetCategory, double) onUpdateAmount;

  // Top action bar buttons (shown in wide layout)
  final VoidCallback? onToggleView;
  final VoidCallback? onSettings;

  const SideSummaryPanel({
    super.key,
    required this.selectedGroup,
    required this.selectedCategory,
    required this.selectedCategoryGroup,
    required this.selectedDebt,
    required this.allBudgets,
    required this.allTransactions,
    required this.subscriptions,
    required this.debts,
    required this.receivables,
    required this.goals,
    required this.currentMonth,
    required this.onClose,
    required this.onCategoryPanelClose,
    required this.onDebtClose,
    required this.onDebtPay,

    required this.onAddCategory,
    required this.onCategoryDetailTap,
    required this.onUpdateAmount,
    this.onEditCategory,
    this.onEditDebt,
    this.onToggleView,
    this.onSettings,
  });

  @override
  State<SideSummaryPanel> createState() => _SideSummaryPanelState();
}

class _SideSummaryPanelState extends ScopedScreenState<SideSummaryPanel>
    with TickerProviderStateMixin {
  late TabController _tabController;
  late AnimationController _entranceAnim;
  late AnimationController _modeAnim;

  bool get _isCategoryMode => widget.selectedCategory != null;

  int get _tabCount => widget.selectedGroup != null ? 1 : 2;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: _isCategoryMode ? 1 : _tabCount,
      vsync: this,
    );
    _entranceAnim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 280),
    )..forward();
    _modeAnim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 220),
    )..value = 1.0;
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
        old.selectedGroup?.id != widget.selectedGroup?.id ||
        old.selectedDebt?.id != widget.selectedDebt?.id;

    if (modeChanged) {
      _tabController.dispose();
      _tabController = TabController(
        length: isCategory ? 1 : (isGroup ? 1 : 2),
        vsync: this,
      );
      _modeAnim.forward(from: 0.0);
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _entranceAnim.dispose();
    _modeAnim.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final headerBg = isDark ? AppColors.void_ : AppColors.background;
    final headerBorder = AppColors.border.withValues(alpha: isDark ? 0.15 : 0.5);

    final slideIn = Tween<Offset>(begin: const Offset(0.12, 0), end: Offset.zero)
        .animate(CurvedAnimation(parent: _entranceAnim, curve: Curves.easeOutCubic));

    return SlideTransition(
      position: slideIn,
      child: FadeTransition(
        opacity: _entranceAnim,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildTopBar(isDark, headerBorder),
            Expanded(
              child: AnimatedBuilder(
                animation: _modeAnim,
                builder: (context, _) => FadeTransition(
                  opacity: _modeAnim,
                  child: SlideTransition(
                    position: Tween<Offset>(begin: const Offset(0.06, 0), end: Offset.zero)
                        .animate(CurvedAnimation(parent: _modeAnim, curve: Curves.easeOutCubic)),
                    child: _buildModeBody(context, isDark, headerBg, headerBorder),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar(bool isDark, Color headerBorder) {
    final hasActions = widget.onToggleView != null || widget.onSettings != null;
    if (!hasActions) return const SizedBox.shrink();
    final textPrimary = isDark ? AppColors.primaryForeground : AppColors.textPrimary;
    return Container(
      height: 44,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF242422) : Colors.white,
        border: Border(bottom: BorderSide(color: headerBorder, width: 0.5)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: Row(
        children: [
          Icon(Icons.analytics_outlined, size: 14, color: AppColors.accent),
          const SizedBox(width: 6),
          Text(
            'Overview',
            style: GoogleFonts.dmSans(fontSize: 13, fontWeight: FontWeight.w700, color: textPrimary),
          ),
          const Spacer(),
          if (widget.onToggleView != null)
            IconButton(
              icon: Icon(Icons.view_list_outlined, size: 17, color: AppColors.textSecondary),
              onPressed: widget.onToggleView,
              tooltip: 'Switch to Simple view',
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 30, minHeight: 30),
            ),
          if (widget.onSettings != null)
            IconButton(
              icon: Icon(Icons.more_vert_rounded, size: 17, color: AppColors.textSecondary),
              onPressed: widget.onSettings,
              tooltip: 'Budget settings',
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 30, minHeight: 30),
            ),
        ],
      ),
    );
  }

  Widget _buildModeBody(BuildContext context, bool isDark, Color headerBg, Color headerBorder) {
    final debt = widget.selectedDebt;
    if (debt != null) return _buildDebtMode(debt, headerBg, headerBorder);

    final cat = widget.selectedCategory;
    if (cat != null) return _buildCategoryMode(cat, headerBg, headerBorder);

    return _buildGroupMode(headerBg, headerBorder);
  }

  Widget _buildDebtMode(Debt debt, Color headerBg, Color headerBorder) {
    final isReceivable = debt.type == DebtType.lending;
    final isDark = headerBg.computeLuminance() < 0.1;
    final textPrimary = isDark ? AppColors.primaryForeground : AppColors.textPrimary;
    final debtColor = isReceivable ? AppColors.success : AppColors.error;
    final debtTxns = widget.allTransactions.where((t) => t.debtId == debt.id).toList()
      ..sort((a, b) => b.date.compareTo(a.date));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          decoration: BoxDecoration(
            color: headerBg,
            border: Border(top: BorderSide(color: headerBorder, width: 0.5)),
          ),
          padding: const EdgeInsets.fromLTRB(12, 6, 8, 6),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: debtColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  isReceivable ? 'RECEIVABLE' : 'DEBT',
                  style: GoogleFonts.dmSans(
                    fontSize: 9, fontWeight: FontWeight.w700,
                    color: debtColor, letterSpacing: 0.5,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  debt.personName,
                  style: GoogleFonts.dmSans(fontSize: 13, fontWeight: FontWeight.w700, color: textPrimary),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (widget.onEditDebt != null)
                IconButton(
                  icon: const Icon(Icons.edit_outlined, size: 14),
                  padding: EdgeInsets.zero,
                  onPressed: widget.onEditDebt,
                  tooltip: 'Edit',
                  style: IconButton.styleFrom(minimumSize: Size.zero, tapTargetSize: MaterialTapTargetSize.shrinkWrap),
                ),
              TextButton(
                onPressed: () => widget.onDebtPay(debt),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  visualDensity: VisualDensity.compact,
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Text(isReceivable ? 'Collect' : 'Pay', style: const TextStyle(fontSize: 11)),
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
        Expanded(child: DebtDetailContent(debt: debt, transactions: debtTxns)),
      ],
    );
  }

  Widget _buildCategoryMode(BudgetCategory cat, Color headerBg, Color headerBorder) {
    final isDark = headerBg.computeLuminance() < 0.1;
    final textPrimary = isDark ? AppColors.primaryForeground : AppColors.textPrimary;
    final catTxns = widget.allTransactions
        .where((t) => t.financeCategoryId == cat.financeCategoryId)
        .toList()
      ..sort((a, b) => b.date.compareTo(a.date));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          decoration: BoxDecoration(
            color: headerBg,
            border: Border(top: BorderSide(color: headerBorder, width: 0.5)),
          ),
          padding: const EdgeInsets.fromLTRB(4, 4, 8, 4),
          child: Row(
            children: [
              IconButton(
                icon: Icon(Icons.arrow_back_ios_rounded, size: 14, color: AppColors.textSecondary),
                onPressed: widget.onCategoryPanelClose,
                visualDensity: VisualDensity.compact,
                padding: const EdgeInsets.all(6),
                constraints: const BoxConstraints(),
              ),
              Expanded(
                child: Text(
                  cat.financeCategory?.name ?? 'Category',
                  style: GoogleFonts.dmSans(fontSize: 13, fontWeight: FontWeight.w700, color: textPrimary),
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
            isIncomeGroup: widget.selectedCategoryGroup?.budgetType == BudgetType.income,
          ),
        ),
      ],
    );
  }

  Widget _buildGroupMode(Color headerBg, Color headerBorder) {
    final group = widget.selectedGroup;
    final isDark = headerBg == AppColors.void_ || headerBg.computeLuminance() < 0.1;
    final textPrimary = isDark ? AppColors.primaryForeground : AppColors.textPrimary;

    final tabLabelStyle = GoogleFonts.dmSans(fontSize: 12, fontWeight: FontWeight.w600);
    final tabUnselectedStyle = GoogleFonts.dmSans(fontSize: 12, fontWeight: FontWeight.w400);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          decoration: BoxDecoration(
            color: headerBg,
            border: Border(top: BorderSide(color: headerBorder, width: 0.5)),
          ),
          child: group == null
              ? TabBar(
                  controller: _tabController,
                  labelStyle: tabLabelStyle,
                  unselectedLabelStyle: tabUnselectedStyle,
                  indicatorColor: AppColors.accent,
                  indicatorWeight: 2,
                  labelColor: AppColors.accent,
                  unselectedLabelColor: AppColors.textSecondary,
                  tabs: const [Tab(text: 'Summary'), Tab(text: 'Transactions')],
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(14, 8, 8, 0),
                      child: Row(
                        children: [
                          Container(
                            width: 6, height: 6,
                            margin: const EdgeInsets.only(right: 7),
                            decoration: BoxDecoration(
                              color: group.budgetType == BudgetType.income ? AppColors.success : AppColors.accent,
                              shape: BoxShape.circle,
                            ),
                          ),
                          Expanded(
                            child: Text(
                              group.title ?? '',
                              style: GoogleFonts.dmSans(
                                fontSize: 13, fontWeight: FontWeight.w700, color: textPrimary,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          IconButton(
                            icon: Icon(Icons.close_rounded, size: 14, color: AppColors.textTertiary),
                            onPressed: widget.onClose,
                            visualDensity: VisualDensity.compact,
                            padding: const EdgeInsets.all(8),
                            constraints: const BoxConstraints(),
                          ),
                        ],
                      ),
                    ),
                    TabBar(
                      controller: _tabController,
                      labelStyle: tabLabelStyle,
                      unselectedLabelStyle: tabUnselectedStyle,
                      indicatorColor: AppColors.accent,
                      indicatorWeight: 2,
                      labelColor: AppColors.accent,
                      unselectedLabelColor: AppColors.textSecondary,
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
                      subscriptions: widget.subscriptions,
                      debts: widget.debts,
                      receivables: widget.receivables,
                      goals: widget.goals,
                      currentMonth: widget.currentMonth,
                    ),
                    AllTransactionsTab(transactions: widget.allTransactions),
                  ]
                : [
                    GroupTransactionsTab(
                      transactions: widget.allTransactions
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
