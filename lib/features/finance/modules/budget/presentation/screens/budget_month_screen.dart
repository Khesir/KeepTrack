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
import 'package:keep_track/features/finance/modules/planned_payment/domain/entities/planned_payment.dart';
import 'package:keep_track/features/finance/modules/transaction/domain/entities/transaction.dart';
import 'package:keep_track/features/finance/modules/budget/presentation/controllers/budget_controller.dart';
import 'package:keep_track/features/finance/modules/budget/domain/entities/month_plan.dart';
import 'package:keep_track/features/finance/presentation/state/month_plan_controller.dart';
import 'package:keep_track/features/finance/presentation/state/debt_controller.dart';
import 'package:keep_track/features/finance/presentation/state/finance_category_controller.dart';
import 'package:keep_track/features/finance/presentation/state/planned_payment_controller.dart';
import 'package:keep_track/features/finance/modules/budget/presentation/state/budget_section_type.dart';
import 'package:keep_track/features/finance/modules/goal/domain/entities/goal.dart';
import 'package:keep_track/features/finance/modules/subscriptions/domain/entities/subscription.dart';
import 'package:keep_track/features/finance/presentation/state/goal_controller.dart';
import 'package:keep_track/features/finance/presentation/state/subscription_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:keep_track/features/finance/presentation/state/transaction_controller.dart';
import 'package:keep_track/features/finance/presentation/screens/transactions/create_transaction_sheet.dart';
import '../sheets/add_category_sheet.dart';
import '../sheets/add_debts_sheet.dart';
import '../sheets/add_subscription_sheet.dart';
import 'package:keep_track/features/finance/presentation/screens/configuration/goals/widgets/goals_management_dialog.dart';
import 'package:keep_track/features/finance/modules/budget/presentation/screens/budget_simple_sheets.dart'
    show GoalDetailSheet;
import '../sheets/category_detail_sheet.dart';
import '../sheets/commitment_sheet.dart';
import '../sheets/create_group_sheet.dart';
import '../sheets/edit_category_sheet.dart';
import '../sheets/edit_debt_sheet.dart';
import '../sheets/edit_group_sheet.dart';
import '../sheets/start_planning_sheet.dart';
import '../widgets/debt_detail_content.dart';

class BudgetMonthScreen extends ScopedScreen {
  final VoidCallback? onToggleView;
  final VoidCallback? onOpenSettings;
  final String? budgetProfileId;

  const BudgetMonthScreen({super.key, this.onToggleView, this.onOpenSettings, this.budgetProfileId});

  @override
  State<BudgetMonthScreen> createState() => _BudgetMonthScreenState();
}

class _BudgetMonthScreenState extends ScopedScreenState<BudgetMonthScreen> {
  late final BudgetMonthController _controller;
  late final BudgetController _budgetController;
  late final MonthPlanController _monthPlanController;
  late final DebtController _debtController;
  late final PlannedPaymentController _plannedPaymentController;
  late final TransactionController _transactionController;
  late final FinanceCategoryController _categoryController;
  late final SubscriptionController _subscriptionController;
  late final GoalController _goalController;

  DateTime _currentMonth = DateTime.now();
  List<String> _itemOrder = [];
  int _selectedTab = 0;
  Budget? _selectedGroup;
  BudgetCategory? _selectedCategory;
  Budget? _selectedCategoryGroup;
  Debt? _selectedDebt;

  @override
  void registerServices() {
    _budgetController = locator.get<BudgetController>();
    _monthPlanController = locator.get<MonthPlanController>();
    _debtController = locator.get<DebtController>();
    _plannedPaymentController = locator.get<PlannedPaymentController>();
    _transactionController = locator.get<TransactionController>();
    _categoryController = locator.get<FinanceCategoryController>();
    _subscriptionController = locator.get<SubscriptionController>();
    _goalController = locator.get<GoalController>();

    _controller = BudgetMonthController(
      budgetController: _budgetController,
      monthPlanController: _monthPlanController,
      debtController: _debtController,
      plannedPaymentController: _plannedPaymentController,
      transactionController: _transactionController,
      subscriptionController: _subscriptionController,
      goalController: _goalController,
    );
  }

  @override
  void onReady() {
    _monthPlanController.loadMonthPlans();
    _debtController.loadDebts();
    _subscriptionController.loadSubscriptions();
    _goalController.loadGoals();
    _controller.init();
    _loadMonthTransactions();
    _loadSectionOrder();
  }

  Future<void> _loadSectionOrder() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getStringList('budget_item_order');
    if (saved != null && mounted) {
      setState(() => _itemOrder = saved);
    }
  }

  void _reconcileItemOrder(BudgetScreenData data) {
    final groupIds = data.budgets
        .where((g) => g.id != null)
        .map((g) => g.id!)
        .toSet();
    final allKeys = {...groupIds, ...kSectionKeys};

    List<String> next;
    if (_itemOrder.isEmpty) {
      next = [...groupIds, ...kSectionKeys];
    } else {
      final kept = _itemOrder.where((k) => allKeys.contains(k)).toList();
      final newItems = allKeys.difference(kept.toSet()).toList();
      final insertBefore = kept.indexWhere((k) => kSectionKeys.contains(k));
      final pos = insertBefore >= 0 ? insertBefore : kept.length;
      kept.insertAll(pos, newItems.where((k) => !kSectionKeys.contains(k)));
      kept.addAll(newItems.where((k) => kSectionKeys.contains(k)));
      next = kept;
    }

    if (next.join(',') != _itemOrder.join(',')) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() => _itemOrder = next);
      });
    }
  }

  Future<void> _reorderItems(int oldIndex, int newIndex) async {
    setState(() {
      if (newIndex > oldIndex) newIndex -= 1;
      final item = _itemOrder.removeAt(oldIndex);
      _itemOrder.insert(newIndex, item);
    });
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('budget_item_order', _itemOrder);
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
        builder: (context, data) {
          _reconcileItemOrder(data);
          return BudgetScreenBody(
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
          onAddCategory: _showAddCategorySheet,
          onEditCategory: _showEditCategorySheet,
          onEditGroup: _showEditGroupSheet,
          onCreateGroup: _showCreateGroupSheet,
          onToggleView: widget.onToggleView,
          onOverrideSettings: widget.onOpenSettings,
          budgetProfileId: widget.budgetProfileId,
          onStartPlanning: _showStartPlanningSheet,
          onDeletePlan: _confirmDeletePlan,
          onShowCommitments: _showCommitmentsSheet,
          onDebtPay: _showDebtPaymentDialog,
          onEditDebt: _showEditDebtSheet,
          onAddDebt: (isReceivable) => _showAddDebtSheet(isReceivable: isReceivable),
          onAddSubscription: _showAddSubscriptionSheet,
          onPaySubscription: _paySubscription,
          onAddGoal: _showAddGoalSheet,
          onGoalTap: _showGoalDetailSheet,
          selectedTab: _selectedTab,
          onTabSelect: (i) => setState(() => _selectedTab = i),
          itemOrder: _itemOrder,
          onItemReorder: _reorderItems,
          onUpdateAmount: (g, c, amt) =>
              _budgetController.updateCategory(g.id!, c.copyWith(targetAmount: amt)),
          onCategoryPay: _payCategoryAmount,
          onUpdateDebtPayment: (debt, amt) =>
              _debtController.updateDebt(debt.copyWith(monthlyPaymentAmount: amt)),
          onDebtDetailTap: _showDebtDetailSheet,
          onCategoryDetailTap: _showCategoryDetail,
        );
        },
        loadingBuilder: (_) => const Center(child: CircularProgressIndicator()),
        errorBuilder: (_, msg) => Center(child: Text('Error: $msg')),
      ),
      floatingActionButton: _buildFab(),
    );
  }

  Widget _buildFab() {
    return FloatingActionButton.extended(
      onPressed: () => CreateTransactionSheet.show(
        context,
        onCreated: _loadMonthTransactions,
      ),
      icon: const Icon(Icons.add),
      label: const Text('New Transaction'),
      backgroundColor: AppColors.accent,
      foregroundColor: Colors.white,
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

    final result = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
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
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
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
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'Fee (optional)',
                  prefixText: '₱',
                  border: OutlineInputBorder(),
                ),
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
              try {
                final fee = double.tryParse(feeCtrl.text) ?? 0.0;
                await _debtController.payDebt(
                  debt.id!,
                  amount: amount,
                  fee: fee > 0 ? fee : null,
                );
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
        onSave: (debt, _) async {
          await _debtController.createDebtOnly(
            debt.copyWith(budgetProfileId: widget.budgetProfileId),
          );
        },
      ),
    );
  }

  void _showAddSubscriptionSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => AddSubscriptionSheet(
        onSave: (sub) => _subscriptionController.createSubscription(
          sub.copyWith(budgetProfileId: widget.budgetProfileId),
        ),
      ),
    );
  }

  void _showAddGoalSheet() {
    GoalsManagementDialog.show(
      context,
      onSave: (goal) => _goalController.createGoal(
        goal.copyWith(budgetProfileId: widget.budgetProfileId),
      ),
    );
  }

  void _showGoalDetailSheet(Goal goal) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => GoalDetailSheet(
        goal: goal,
        goalController: _goalController,
        onContribute: (currentGoal, amount) =>
            _goalController.contributeToGoal(currentGoal.id!, amount),
        onUpdate: (updated) => _goalController.updateGoal(updated),
      ),
    );
  }

  Future<void> _payCategoryAmount(Budget group, BudgetCategory cat, double amount) async {
    final isIncome = group.budgetType == BudgetType.income;
    final tx = Transaction(
      amount: amount,
      type: isIncome ? TransactionType.income : TransactionType.expense,
      financeCategoryId: cat.financeCategoryId,
      budgetId: group.id,
      date: DateTime.now(),
      description: cat.financeCategory?.name,
    );
    await _transactionController.createTransaction(tx);
    _budgetController.refreshBudgetsWithSpentAmounts();
  }

  Future<void> _paySubscription(Subscription sub) async {
    try {
      await _subscriptionController.pay(sub.id!);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${sub.name} marked as paid')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed: $e')));
      }
    }
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
        plannedPaymentController: _plannedPaymentController,
      ),
    );
  }
}
