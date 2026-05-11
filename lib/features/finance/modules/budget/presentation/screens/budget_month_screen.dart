import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:keep_track/core/di/service_locator.dart';
import 'package:keep_track/core/state/stream_builder_widget.dart';
import 'package:keep_track/core/state/stream_state.dart';
import 'package:keep_track/core/theme/app_theme.dart';
import 'package:keep_track/core/ui/scoped_screen.dart';
import 'package:keep_track/features/finance/modules/budget/domain/entities/budget.dart';
import 'package:keep_track/features/finance/modules/budget/domain/entities/budget_category.dart';
import 'package:keep_track/features/finance/modules/budget/presentation/controllers/budget_month_controller.dart';
import 'package:keep_track/features/finance/modules/budget/presentation/helpers/currency_formatter.dart';
import 'package:keep_track/features/finance/modules/budget/presentation/sections/budget_screen_body.dart';
import 'package:keep_track/features/finance/modules/budget/presentation/state/budget_screen_data.dart';
import 'package:keep_track/features/finance/modules/debt/domain/entities/debt.dart';
import 'package:keep_track/features/finance/modules/planned_payment/domain/entities/payment_enums.dart';
import 'package:keep_track/features/finance/modules/planned_payment/domain/entities/planned_payment.dart';
import 'package:keep_track/features/finance/modules/transaction/domain/entities/transaction.dart';
import 'package:keep_track/features/finance/modules/account/domain/entities/account.dart';
import 'package:keep_track/features/finance/presentation/state/account_controller.dart';
import 'package:keep_track/features/finance/modules/budget/presentation/controllers/budget_controller.dart';
import 'package:keep_track/features/finance/modules/budget/domain/entities/month_plan.dart';
import 'package:keep_track/features/finance/presentation/state/month_plan_controller.dart';
import 'package:keep_track/features/finance/presentation/state/debt_controller.dart';
import 'package:keep_track/features/finance/presentation/state/finance_category_controller.dart';
import 'package:keep_track/features/finance/presentation/state/planned_payment_controller.dart';
import 'package:keep_track/features/finance/presentation/state/transaction_controller.dart';
import 'package:keep_track/core/network/api_client.dart';
import 'package:keep_track/features/finance/presentation/screens/transactions/create_transaction_screen.dart';
import 'package:keep_track/shared/infrastructure/supabase/supabase_service.dart';

import '../sections/budget_summary_bar.dart';
import '../sections/debt_section.dart';
import '../sheets/add_category_sheet.dart';
import '../sheets/add_debts_sheet.dart';
import '../sheets/category_detail_sheet.dart';
import '../sheets/commitment_sheet.dart';
import '../sheets/create_group_sheet.dart';
import '../sheets/edit_category_sheet.dart';
import '../sheets/edit_debt_sheet.dart';
import '../sheets/edit_group_sheet.dart';
import '../sheets/start_planning_sheet.dart';
import '../state/empty_budget_state.dart';
import '../widgets/budget_group_card.dart';
import '../widgets/debt_detail_content.dart';
import '../widgets/ghost_add_row.dart';
import '../widgets/month_header.dart';
import '../widgets/side_summary_panel.dart';

// Simple data class for a named group of categories
//endregion

class BudgetMonthScreen extends ScopedScreen {
  const BudgetMonthScreen({super.key});

  @override
  State<BudgetMonthScreen> createState() => _BudgetMonthScreenState();
}

class _BudgetMonthScreenState extends ScopedScreenState<BudgetMonthScreen> {
  late final BudgetMonthController _controller;

  DateTime _currentMonth = DateTime.now();
  Budget? _selectedGroup;
  BudgetCategory? _selectedCategory;
  Budget? _selectedCategoryGroup;
  Debt? _selectedDebt;

  @override
  void initState() {
    super.initState();
    _controller = BudgetMonthController(
      budgetController: getService<BudgetController>(),
      monthPlanController: getService<MonthPlanController>(),
      debtController: getService<DebtController>(),
      plannedPaymentController: getService<PlannedPaymentController>(),
      transactionController: getService<TransactionController>(),
    );

    _controller.init();
    _loadMonthTransactions();
  }

  @override
  void onDispose() {
    _controller.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AsyncStreamBuilder<BudgetScreenData>(
        state: _controller,
        builder: (context, data) => BudgetScreenBody(
          data: data,
          currentMonth: _currentMonth,
          monthLabel: _monthLabel,
          monthKey: _monthKey,
          // Selection State
          selectedGroup: _selectedGroup,
          selectedCategory: _selectedCategory,
          selectedCategoryGroup: _selectedCategoryGroup,
          selectedDebt: _selectedDebt,
          // month nav
          onPrevMonth: _prevMonth,
          onNextMonth: _nextMonth,
          // selection callbacks
          onGroupSelect: (g) => setState(() => _selectedGroup = g),
          onDebtSelect: (d) => setState(() => _selectedDebt = d),
          onCategorySelect: (group, cat) => setState(() {
            _selectedCategory = cat;
            _selectedCategoryGroup = group;
          }),
          onClearCategory: () => setState(() {
            _selectedCategory = null;
            _selectedCategoryGroup = null;
          }),
          onClearGroup: () => setState(() {
            _selectedGroup = null;
            _selectedCategory = null;
            _selectedCategoryGroup = null;
          }),
          // action callbacks — wired to sheets/dialogs next
          onAddCategory: (group) {}, // TODO: _sheets.showAddCategory
          onEditCategory: (group, cat) {}, // TODO: _sheets.showEditCategory
          onEditGroup: (group) {}, // TODO: _sheets.showEditGroup
          onCreateGroup: () {}, // TODO: _sheets.showCreateGroup
          onStartPlanning: (budgets) {}, // TODO: _sheets.showStartPlanning
          onDeletePlan: (budgets) {}, // TODO: _sheets.showDeletePlan
          onShowCommitments: (payments) {}, // TODO: _sheets.showCommitments
          onDebtPay: (debt) {}, // TODO: _sheets.showDebtPayment
          onEditDebt: (debt) {}, // TODO: _sheets.showEditDebt
          onAddDebt: (isReceivable) {}, // TODO: _sheets.showAddDebt
          onUpdateAmount: (g, c, amt) => getService<BudgetController>()
              .updateCategory(g.id!, c.copyWith(targetAmount: amt)),
          onUpdateDebtPayment: (debt, amt) => getService<DebtController>()
              .updateDebt(debt.copyWith(monthlyPaymentAmount: amt)),
          onDebtDetailTap: (Debt debt, List<Transaction> transactions) {},
          onCategoryDetailTap:
              (
                Budget group,
                BudgetCategory cat,
                List<Transaction> transactions,
              ) {},
        ),
        loadingBuilder: (_) => const Center(child: CircularProgressIndicator()),
        errorBuilder: (_, msg) => Center(child: Text('Error: $msg')),
      ),
      floatingActionButton: _buildFab(),
    );
  }

  Widget _buildFab() {
    return FloatingActionButton.extended(
      onPressed: () async {
        await showDialog<void>(
          context: context,
          barrierDismissible: false,
          builder: (_) => Dialog(
            insetPadding: const EdgeInsets.all(16),
            clipBehavior: Clip.antiAlias,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520, maxHeight: 700),
              child: const CreateTransactionScreen(),
            ),
          ),
        );
        if (mounted) _loadMonthTransactions();
      },
      icon: const Icon(Icons.add),
      label: const Text('New Transaction'),
    );
  }

  Widget _buildBody({
    required List<MonthPlan> allMonthPlans,
    required List<Budget> allBudgets,
    required List<Transaction> allTransactions,
    required List<Debt> allDebts,
    required List<PlannedPayment> allPayments,
  }) {
    // Filter transactions strictly to the selected month
    final monthStart = DateTime(_currentMonth.year, _currentMonth.month, 1);
    final monthEnd = DateTime(_currentMonth.year, _currentMonth.month + 1, 1);
    final monthTransactions = allTransactions
        .where((t) => !t.date.isBefore(monthStart) && t.date.isBefore(monthEnd))
        .toList();

    // Build spent-per-financeCategoryId map from actual transactions
    final Map<String, double> spentByCategory = {};
    for (final t in monthTransactions) {
      if (t.financeCategoryId != null) {
        spentByCategory[t.financeCategoryId!] =
            (spentByCategory[t.financeCategoryId!] ?? 0.0) + t.amount;
      }
    }

    // month_plan is the authority — no plan means no budgets to show
    final monthPlan = allMonthPlans.cast<MonthPlan?>().firstWhere(
      (p) => p?.month == _monthKey,
      orElse: () => null,
    );
    final hasMonthPlan = monthPlan != null;

    // Only show budgets explicitly listed in the month_plan's budgetIds
    final allowedIds = monthPlan?.budgetIds.toSet() ?? {};
    final monthBudgets = hasMonthPlan
        ? (allBudgets
              .where((b) => b.id != null && allowedIds.contains(b.id))
              .toList()
            ..sort((a, b) {
              if (a.budgetType == b.budgetType) return 0;
              return a.budgetType == BudgetType.income ? -1 : 1;
            }))
        : <Budget>[];

    // Show a debt/receivable in this month if:
    // - It started on or before the end of this month (debt existed by this month)
    // - AND it was not settled before this month started
    //   (active = always show; settled = show only up through the month it was settled)
    bool debtVisibleThisMonth(Debt d) {
      if (d.startDate.isAfter(monthEnd))
        return false; // started after this month
      if (d.status == DebtStatus.active) return true;
      if (d.settledAt == null) return true; // treated as active
      return !d.settledAt!.isBefore(monthStart); // settled this month or later
    }

    final debts = allDebts
        .where((d) => d.type == DebtType.borrowing && debtVisibleThisMonth(d))
        .toList();
    final receivables = allDebts
        .where((d) => d.type == DebtType.lending && debtVisibleThisMonth(d))
        .toList();
    final activePayments = allPayments
        .where((p) => p.status == PaymentStatus.active)
        .toList();

    // Keep _selectedGroup in sync: clear if it no longer exists this month
    if (_selectedGroup != null &&
        !monthBudgets.any((b) => b.id == _selectedGroup!.id)) {
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => setState(() {
          _selectedGroup = null;
          _selectedCategory = null;
          _selectedCategoryGroup = null;
        }),
      );
    }
    // Sync selected group data from the latest stream snapshot
    final syncedSelected = _selectedGroup == null
        ? null
        : monthBudgets.firstWhere(
            (b) => b.id == _selectedGroup!.id,
            orElse: () => _selectedGroup!,
          );
    // Sync selected category from the latest stream snapshot
    Budget? syncedCategoryGroup;
    if (_selectedCategoryGroup != null) {
      final idx = monthBudgets.indexWhere(
        (b) => b.id == _selectedCategoryGroup!.id,
      );
      syncedCategoryGroup = idx >= 0 ? monthBudgets[idx] : null;
    }
    BudgetCategory? syncedCategory;
    if (_selectedCategory != null && syncedCategoryGroup != null) {
      final idx = syncedCategoryGroup.categories.indexWhere(
        (c) => c.id == _selectedCategory!.id,
      );
      syncedCategory = idx >= 0
          ? syncedCategoryGroup.categories[idx]
          : _selectedCategory;
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 600;

        Widget buildSummaryPanel() => SideSummaryPanel(
          selectedGroup: syncedSelected,
          selectedCategory: syncedCategory,
          selectedCategoryGroup: syncedCategoryGroup,
          selectedDebt: _selectedDebt,
          allBudgets: monthBudgets,
          allTransactions: monthTransactions,
          onClose: () => setState(() {
            _selectedGroup = null;
            _selectedCategory = null;
            _selectedCategoryGroup = null;
          }),
          onCategoryPanelClose: () => setState(() {
            _selectedCategory = null;
            _selectedCategoryGroup = null;
          }),
          onDebtClose: () => setState(() => _selectedDebt = null),
          onDebtPay: _showDebtPaymentDialog,
          onEditCategory: syncedCategory != null && syncedCategoryGroup != null
              ? () => _showEditCategorySheet(
                  syncedCategoryGroup!,
                  syncedCategory!,
                )
              : null,
          onEditDebt: _selectedDebt != null
              ? () => _showEditDebtSheet(_selectedDebt!)
              : null,
          onAddCategory: _showAddCategorySheet,
          onCategoryDetailTap: (cat) {
            if (syncedSelected != null) {
              _showCategoryDetail(syncedSelected, cat, monthTransactions);
            }
          },
          onUpdateAmount: _updateCategoryAmount,
        );

        Widget budgetCard = Card(
          margin: EdgeInsets.zero,
          elevation: 0,
          clipBehavior: Clip.antiAlias,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: AppColors.border),
          ),
          child: CustomScrollView(
            slivers: [
              // Budget totals summary
              SliverToBoxAdapter(
                child: BudgetSummaryBar(
                  monthBudgets: monthBudgets,
                  spentByCategory: spentByCategory,
                  activePayments: activePayments,
                  activeDebts: debts,
                  activeReceivables: receivables,
                  onCommitmentsTab: () => _showCommitmentsSheet(activePayments),
                ),
              ),

              if (!hasMonthPlan)
                SliverToBoxAdapter(
                  child: EmptyBudgetState(
                    monthLabel: _monthLabel,
                    onStart: () => _showStartPlanningSheet(allBudgets),
                  ),
                )
              else
                SliverList(
                  delegate: SliverChildBuilderDelegate((context, i) {
                    final group = monthBudgets[i];
                    return BudgetGroupCard(
                      group: group,
                      monthLabel: _monthLabel,
                      isSelected: _selectedGroup?.id == group.id,
                      spentByCategory: spentByCategory,
                      onSelect: () => setState(() {
                        _selectedGroup = _selectedGroup?.id == group.id
                            ? null
                            : group;
                      }),
                      onEditGroup: () => _showEditGroupSheet(group),
                      onAddRow: () => _showAddCategorySheet(group),
                      onCategoryEditTap: (cat) =>
                          _showEditCategorySheet(group, cat),
                      onCategoryDetailTap: (cat) {
                        if (isWide) {
                          setState(() {
                            _selectedCategory = cat;
                            _selectedCategoryGroup = group;
                          });
                        } else {
                          _showCategoryDetail(group, cat, monthTransactions);
                        }
                      },
                      onUpdateAmount: (cat, amount) =>
                          _updateCategoryAmount(group, cat, amount),
                    );
                  }, childCount: monthBudgets.length),
                ),

              SliverToBoxAdapter(
                child: GhostAddRow(
                  label: 'Add Budget Group',
                  onTap: _showCreateGroupSheet,
                ),
              ),

              const SliverToBoxAdapter(child: Divider(height: 1)),
              SliverToBoxAdapter(
                child: DebtSection(
                  title: 'DEBTS',
                  debts: debts,
                  isReceivable: false,
                  selectedDebt: _selectedDebt,
                  onAdd: () => _showAddDebtSheet(isReceivable: false),
                  onPay: _showDebtPaymentDialog,
                  onEdit: _showEditDebtSheet,
                  onUpdateMonthlyPayment: _updateDebtMonthlyPayment,
                  onSelect: (d) {
                    if (isWide) {
                      setState(
                        () => _selectedDebt = _selectedDebt?.id == d.id
                            ? null
                            : d,
                      );
                    } else {
                      _showDebtDetailSheet(d, monthTransactions);
                    }
                  },
                ),
              ),

              const SliverToBoxAdapter(child: Divider(height: 1)),
              SliverToBoxAdapter(
                child: DebtSection(
                  title: 'RECEIVABLES',
                  debts: receivables,
                  isReceivable: true,
                  selectedDebt: _selectedDebt,
                  onAdd: () => _showAddDebtSheet(isReceivable: true),
                  onPay: _showDebtPaymentDialog,
                  onEdit: _showEditDebtSheet,
                  onUpdateMonthlyPayment: _updateDebtMonthlyPayment,
                  onSelect: (d) {
                    if (isWide) {
                      setState(
                        () => _selectedDebt = _selectedDebt?.id == d.id
                            ? null
                            : d,
                      );
                    } else {
                      _showDebtDetailSheet(d, monthTransactions);
                    }
                  },
                ),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 80)),
            ],
          ),
        );

        return Column(
          children: [
            // Full-width month nav — fully outside both cards
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 4, 8, 0),
              child: MonthHeader(
                monthLabel: _monthLabel,
                onPrev: _prevMonth,
                onNext: _nextMonth,
                onSummaryTap: isWide
                    ? null
                    : () => _showSummarySheet(context, buildSummaryPanel()),
                onDelete: () => _confirmDeletePlan(monthBudgets),
              ),
            ),

            // Cards row
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
}

// ---- Helpers ----------
// ignore: library_private_types_in_public_api
extension BudgetMonthHelpers on _BudgetMonthScreenState {
  // ── Month helpers ─────────────────────────────────────────────────────────

  String get _monthKey =>
      '${_currentMonth.year}-${_currentMonth.month.toString().padLeft(2, '0')}';

  String get _monthLabel => DateFormat('MMMM yyyy').format(_currentMonth);

  DateTime get _prevMonthDate =>
      DateTime(_currentMonth.year, _currentMonth.month - 1);

  String get _prevMonthKey =>
      '${_prevMonthDate.year}-${_prevMonthDate.month.toString().padLeft(2, '0')}';

  String get _prevMonthLabel => DateFormat('MMMM yyyy').format(_prevMonthDate);

  void _prevMonth() {
    setState(() {
      _currentMonth = DateTime(_currentMonth.year, _currentMonth.month - 1);
      _selectedGroup = null;
      _selectedCategory = null;
      _selectedCategoryGroup = null;
      _selectedDebt = null;
    });
    _loadMonthTransactions();
  }

  void _nextMonth() {
    setState(() {
      _currentMonth = DateTime(_currentMonth.year, _currentMonth.month + 1);
      _selectedGroup = null;
      _selectedCategory = null;
      _selectedCategoryGroup = null;
      _selectedDebt = null;
    });
    _loadMonthTransactions();
  }

  void _loadMonthTransactions() {
    final start = DateTime(_currentMonth.year, _currentMonth.month, 1);
    final end = DateTime(
      _currentMonth.year,
      _currentMonth.month + 1,
      1,
    ).subtract(const Duration(microseconds: 1));
    _transactionController.loadTransactionsByDateRange(start, end);
  }

  // ── Show Summary Sheet ─────────────────────────────────────────────────────────

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

// ---- Dialogs ----------
// ignore: library_private_types_in_public_api
extension BudgetMonthDialogSheets on _BudgetMonthScreenState {
  void _showAddCategorySheet(Budget group) {
    if (group.id == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Budget group is still saving. Please wait a moment.'),
        ),
      );
      return;
    }
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => AddCategorySheet(
        group: group,
        categoryController: _categoryController,
        supabaseService: _supabaseService,
        onSave: (cat) => _budgetController.addCategory(group.id!, cat),
      ),
    );
  }

  void _showEditCategorySheet(Budget group, BudgetCategory cat) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (sheetCtx) => EditCategorySheet(
        group: group,
        category: cat,
        categoryController: _categoryController,
        budgetController: _budgetController,
        onDelete: () async {
          Navigator.pop(sheetCtx);
          await _confirmDeleteCategory(group, cat);
        },
      ),
    );
  }

  void _showEditGroupSheet(Budget group) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (sheetCtx) => EditGroupSheet(
        group: group,
        budgetController: _budgetController,
        onDelete: () async {
          Navigator.pop(sheetCtx);
          await _confirmDeleteGroup(group);
        },
      ),
    );
  }

  Future<void> _confirmDeleteGroup(Budget group) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Budget Group'),
        content: Text(
          'Delete "${group.title ?? 'this group'}" and all its categories?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'Delete',
              style: TextStyle(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
    if (ok == true && group.id != null) {
      await _budgetController.deleteBudget(group.id!);
    }
  }

  Future<void> _updateCategoryAmount(
    Budget group,
    BudgetCategory cat,
    double amount,
  ) async {
    await _budgetController.updateCategory(
      group.id!,
      cat.copyWith(targetAmount: amount),
    );
  }

  Future<void> _updateDebtMonthlyPayment(Debt debt, double amount) async {
    await _debtController.updateDebt(
      debt.copyWith(monthlyPaymentAmount: amount),
    );
  }

  void _showCreateGroupSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => CreateGroupSheet(
        monthKey: _monthKey,
        monthLabel: _monthLabel,
        budgetController: _budgetController,
        monthPlanController: _monthPlanController,
        supabaseService: _supabaseService,
      ),
    );
  }

  /// Shown when no budget exists for the month — creates the MonthPlan first,
  /// then offers "Copy from previous month" or "Start fresh".
  void _showStartPlanningSheet(List<Budget> allBudgets) {
    final prevBudgets = allBudgets
        .where(
          (b) =>
              b.month == _prevMonthKey &&
              b.periodType == BudgetPeriodType.monthly &&
              b.status == BudgetStatus.active,
        )
        .toList();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => StartPlanningSheet(
        monthKey: _monthKey,
        monthLabel: _monthLabel,
        prevMonthKey: _prevMonthKey,
        prevMonthLabel: _prevMonthLabel,
        hasPrevBudgets: prevBudgets.isNotEmpty,
        monthPlanController: _monthPlanController,
        budgetController: _budgetController,
        supabaseService: _supabaseService,
      ),
    );
  }

  Future<void> _confirmDeleteCategory(Budget group, BudgetCategory cat) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Category'),
        content: Text(
          'Remove "${cat.financeCategory?.name ?? 'category'}" from this group?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'Delete',
              style: TextStyle(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
    if (ok == true && cat.id != null) {
      await _budgetController.deleteCategory(group.id!, cat.id!);
    }
  }

  void _showCategoryDetail(
    Budget group,
    BudgetCategory cat,
    List<Transaction> allTransactions,
  ) {
    final catTxns =
        allTransactions
            .where((t) => t.financeCategoryId == cat.financeCategoryId)
            .toList()
          ..sort((a, b) => b.date.compareTo(a.date));

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => CategoryDetailSheet(
        category: cat,
        transactions: catTxns,
        isIncomeGroup: group.budgetType == BudgetType.income,
      ),
    );
  }

  Future<void> _showDebtPaymentDialog(Debt debt) async {
    final isReceivable = debt.type == DebtType.lending;
    final amountCtrl = TextEditingController(
      text: debt.monthlyPaymentAmount > 0
          ? debt.monthlyPaymentAmount.toStringAsFixed(2)
          : '',
    );
    final feeCtrl = TextEditingController();
    String? selectedAccountId;

    final result = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (dialogCtx, setDialogState) => AlertDialog(
          title: Text(
            isReceivable
                ? 'Collect from ${debt.personName}'
                : 'Pay ${debt.personName}',
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Remaining balance info
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.error.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Remaining balance',
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                      Text(
                        formatCurrency(debt.remainingAmount),
                        style: AppTextStyles.bodySmall.copyWith(
                          fontWeight: FontWeight.w600,
                          color: AppColors.error,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: amountCtrl,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: InputDecoration(
                    labelText: 'Payment Amount',
                    prefixText: '₱',
                    border: const OutlineInputBorder(),
                    helperText: debt.monthlyPaymentAmount > 0
                        ? 'Monthly: ${formatCurrency(debt.monthlyPaymentAmount)}'
                        : null,
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: feeCtrl,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: const InputDecoration(
                    labelText: 'Fee (optional)',
                    prefixText: '₱',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                AsyncStreamBuilder<List<Account>>(
                  state: _accountController,
                  builder: (_, accounts) => DropdownButtonFormField<String>(
                    initialValue: selectedAccountId,
                    decoration: const InputDecoration(
                      labelText: 'Account',
                      border: OutlineInputBorder(),
                    ),
                    items: accounts
                        .map(
                          (a) => DropdownMenuItem(
                            value: a.id,
                            child: Text(a.name),
                          ),
                        )
                        .toList(),
                    onChanged: (v) => selectedAccountId = v,
                  ),
                  loadingBuilder: (_) => const LinearProgressIndicator(),
                  errorBuilder: (_, m) => Text(m),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogCtx, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () async {
                final amount = double.tryParse(amountCtrl.text);
                if (amount == null || amount <= 0) {
                  ScaffoldMessenger.of(dialogCtx).showSnackBar(
                    const SnackBar(content: Text('Enter a valid amount')),
                  );
                  return;
                }
                if (amount > debt.remainingAmount) {
                  ScaffoldMessenger.of(dialogCtx).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Amount exceeds remaining balance of ${formatCurrency(debt.remainingAmount)}',
                      ),
                    ),
                  );
                  return;
                }
                if (selectedAccountId == null) {
                  ScaffoldMessenger.of(dialogCtx).showSnackBar(
                    const SnackBar(content: Text('Select an account')),
                  );
                  return;
                }
                try {
                  final fee = double.tryParse(feeCtrl.text) ?? 0.0;
                  await ApiClient.instance.post(
                    '/debts/${debt.id}/pay',
                    data: {
                      'accountId': selectedAccountId,
                      'amount': amount,
                      if (fee > 0) 'fee': fee,
                    },
                  );
                  // Adjust account balance (backend creates transaction directly,
                  // bypassing the frontend repo layer that normally handles this)
                  final balanceDelta = isReceivable
                      ? amount -
                            fee // income: receive amount minus fee
                      : -(amount + fee); // expense: pay amount plus fee
                  await _accountController.adjustBalance(
                    selectedAccountId!,
                    balanceDelta,
                  );
                  // Refresh debts, transactions, and budget spent amounts
                  _debtController.loadDebts();
                  _loadMonthTransactions();
                  _budgetController.refreshBudgetsWithSpentAmounts();
                  if (dialogCtx.mounted) Navigator.pop(dialogCtx, true);
                } catch (e) {
                  if (dialogCtx.mounted) {
                    ScaffoldMessenger.of(
                      dialogCtx,
                    ).showSnackBar(SnackBar(content: Text('Failed: $e')));
                  }
                }
              },
              child: Text(isReceivable ? 'Collect' : 'Pay'),
            ),
          ],
        ),
      ),
    );

    amountCtrl.dispose();
    feeCtrl.dispose();

    if (result == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isReceivable ? 'Collection recorded' : 'Payment recorded',
          ),
          backgroundColor: AppColors.success,
        ),
      );
    }
  }

  void _showDebtDetailSheet(Debt debt, List<Transaction> allTransactions) {
    final debtTxns = allTransactions.where((t) => t.debtId == debt.id).toList()
      ..sort((a, b) => b.date.compareTo(a.date));

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.4,
        maxChildSize: 0.9,
        expand: false,
        builder: (_, controller) => DebtDetailContent(
          debt: debt,
          transactions: debtTxns,
          scrollController: controller,
          onPay: () {
            Navigator.pop(context);
            _showDebtPaymentDialog(debt);
          },
        ),
      ),
    );
  }

  void _showAddDebtSheet({required bool isReceivable}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => AddDebtSheet(
        isReceivable: isReceivable,
        accountController: _accountController,
        categoryController: _categoryController,
        supabaseService: _supabaseService,
        onSave: (debt, categoryId) async {
          if (debt.accountId != null && categoryId != null) {
            await _debtController.createDebtWithCategory(debt, categoryId);
          } else {
            await _debtController.createDebtOnly(debt);
          }
        },
      ),
    );
  }

  void _showEditDebtSheet(Debt debt) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => EditDebtSheet(
        debt: debt,
        onSave: (updated) async {
          await _debtController.updateDebt(updated);
        },
      ),
    );
  }

  Future<void> _confirmDeletePlan(List<Budget> monthBudgets) async {
    // Look up the MonthPlan for the current month
    final planState = _monthPlanController.state;
    final plans = planState is AsyncData<List<MonthPlan>>
        ? planState.data
        : <MonthPlan>[];
    final plan = plans.cast<MonthPlan?>().firstWhere(
      (p) => p?.month == _monthKey,
      orElse: () => null,
    );

    // Nothing to delete if no plan and no budgets
    if (plan == null && monthBudgets.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No plan found for this month.')),
      );
      return;
    }

    bool deleteAll = false;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (dialogCtx, setDialogState) => AlertDialog(
          title: Text('Delete plan for $_monthLabel?'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('The month plan record will be removed.'),
              if (monthBudgets.isNotEmpty) ...[
                const SizedBox(height: 16),
                CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  value: deleteAll,
                  onChanged: (v) =>
                      setDialogState(() => deleteAll = v ?? false),
                  title: const Text(
                    'Also delete all budget groups and categories',
                  ),
                  subtitle: Text(
                    '${monthBudgets.length} group${monthBudgets.length == 1 ? '' : 's'} will be permanently removed',
                    style: TextStyle(color: AppColors.error, fontSize: 12),
                  ),
                  controlAffinity: ListTileControlAffinity.leading,
                ),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogCtx, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: AppColors.error),
              onPressed: () => Navigator.pop(dialogCtx, true),
              child: const Text('Delete'),
            ),
          ],
        ),
      ),
    );

    if (confirmed != true || !mounted) return;

    // Show loading dialog while deleting
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const PopScope(
        canPop: false,
        child: AlertDialog(
          content: Row(
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 20),
              Text('Deleting…'),
            ],
          ),
        ),
      ),
    );

    try {
      if (deleteAll && plan != null && plan.id != null) {
        await _monthPlanController.deleteMonthPlanWithBudgets(
          plan.id!,
          _monthKey,
        );
        await _budgetController.refreshBudgetsWithSpentAmounts();
      } else if (deleteAll && plan == null) {
        // No plan row, just delete the budgets directly
        for (final b in monthBudgets) {
          if (b.id != null) await _budgetController.deleteBudget(b.id!);
        }
      } else if (plan != null && plan.id != null) {
        await _monthPlanController.deleteMonthPlan(plan.id!);
      }

      if (mounted) {
        Navigator.pop(context); // close loading dialog
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              deleteAll
                  ? 'Plan and all budget groups deleted.'
                  : 'Plan deleted. Budget groups kept.',
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // close loading dialog
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  void _showCommitmentsSheet(List<PlannedPayment> payments) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => CommitmentsSheet(
        payments: payments,
        accountController: _accountController,
        categoryController: _categoryController,
        supabaseService: _supabaseService,
        plannedPaymentController: _plannedPaymentController,
      ),
    );
  }
}
