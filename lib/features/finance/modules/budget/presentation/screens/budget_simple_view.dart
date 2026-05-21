import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:keep_track/core/theme/app_theme.dart';
import 'package:keep_track/core/di/service_locator.dart';
import 'package:keep_track/core/state/stream_builder_widget.dart';
import 'package:keep_track/core/state/stream_state.dart';
import 'package:keep_track/features/finance/modules/budget/domain/entities/budget.dart';
import 'package:keep_track/features/finance/modules/budget/domain/entities/budget_category.dart';
import 'package:keep_track/features/finance/modules/budget/presentation/controllers/budget_controller.dart';
import 'package:keep_track/features/finance/modules/budget/presentation/helpers/budget_month_filter.dart';
import 'package:keep_track/features/finance/modules/budget/presentation/sheets/add_category_sheet.dart';
import 'package:keep_track/features/finance/modules/budget/presentation/sheets/add_debts_sheet.dart';
import 'package:keep_track/features/finance/modules/budget/presentation/sheets/add_subscription_sheet.dart';
import 'package:keep_track/features/finance/presentation/screens/configuration/goals/widgets/goals_management_dialog.dart';
import 'package:keep_track/features/auth/presentation/state/auth_controller.dart';
import 'package:keep_track/features/finance/modules/budget/presentation/sheets/create_group_sheet.dart';
import 'package:keep_track/features/finance/modules/budget/presentation/sheets/edit_category_sheet.dart';
import 'package:keep_track/features/finance/modules/budget/presentation/sheets/edit_group_sheet.dart';
import 'package:keep_track/features/finance/modules/debt/domain/entities/debt.dart';
import 'package:keep_track/features/finance/modules/goal/domain/entities/goal.dart';
import 'package:keep_track/features/finance/modules/subscriptions/domain/entities/subscription.dart';
import 'package:keep_track/features/finance/modules/transaction/domain/entities/transaction.dart';
import 'package:keep_track/features/finance/presentation/state/debt_controller.dart';
import 'package:keep_track/features/finance/modules/finance_category/domain/entities/finance_category_enums.dart';
import 'package:keep_track/features/finance/presentation/state/finance_category_controller.dart';
import 'package:keep_track/features/finance/presentation/state/goal_controller.dart';
import 'package:keep_track/features/finance/presentation/state/month_plan_controller.dart';
import 'package:keep_track/features/finance/presentation/state/savings_controller.dart';
import 'package:keep_track/features/finance/presentation/state/subscription_controller.dart';
import 'package:keep_track/features/finance/presentation/state/transaction_controller.dart';
import 'package:keep_track/features/finance/modules/budget/domain/entities/month_plan.dart';
import 'package:keep_track/features/finance/presentation/state/budget_profile_controller.dart';
import 'budget_simple_sections.dart';
import 'budget_simple_sheets.dart';
import '../sections/budget_overall_summary.dart';
import '../sheets/budget_settings_sheet.dart';
import '../sheets/profile_start_planning_sheet.dart';
import '../sheets/start_planning_sheet.dart';

class BudgetSimpleView extends StatefulWidget {
  final int selectedTab;
  final void Function(int)? onTabChange;
  final VoidCallback? onBack;
  final String? budgetProfileId;
  final String? profileName;
  final Color? profileAccentColor;
  final DateTime? profileStartDate;
  final DateTime? profileEndDate;
  final void Function(bool isIncome)? onAddProfileGroup;
  final VoidCallback? onToggleView;
  final VoidCallback? onOpenSettings;
  final bool profileIsMonthly;

  const BudgetSimpleView({
    super.key,
    this.selectedTab = 0,
    this.onTabChange,
    this.onBack,
    this.budgetProfileId,
    this.profileName,
    this.profileAccentColor,
    this.profileStartDate,
    this.profileEndDate,
    this.profileIsMonthly = false,
    this.onAddProfileGroup,
    this.onToggleView,
    this.onOpenSettings,
  });

  bool get _isProfileMode => budgetProfileId != null;

  @override
  State<BudgetSimpleView> createState() => _BudgetSimpleViewState();
}

class _BudgetSimpleViewState extends State<BudgetSimpleView> {
  late final BudgetController _budgetController;
  late final TransactionController _txController;
  late final DebtController _debtController;
  late final SubscriptionController _subController;
  late final GoalController _goalController;
  late final SavingsController _savingsController;
  late final FinanceCategoryController _categoryController;
  late final MonthPlanController _monthPlanController;
  DateTime _month = DateTime.now();

  @override
  void initState() {
    super.initState();
    _budgetController = locator.get<BudgetController>();
    _txController = locator.get<TransactionController>();
    _debtController = locator.get<DebtController>();
    _subController = locator.get<SubscriptionController>();
    _goalController = locator.get<GoalController>();
    _savingsController = locator.get<SavingsController>();
    _categoryController = locator.get<FinanceCategoryController>();
    _monthPlanController = locator.get<MonthPlanController>();
    _budgetController.loadBudgets();
    _loadTx();
    // Always load — profile ID scopes the API query; null = all unattached items
    _debtController.loadDebts(budgetProfileId: widget.budgetProfileId);
    _subController.loadSubscriptions(budgetProfileId: widget.budgetProfileId);
    _goalController.loadGoals(budgetProfileId: widget.budgetProfileId);
  }

  void _loadTx() {
    if (widget._isProfileMode) {
      final start = widget.profileStartDate ?? DateTime(2000);
      final end = widget.profileEndDate ?? DateTime.now().add(const Duration(days: 365));
      _txController.loadTransactionsByDateRange(start, end);
    } else {
      _txController.loadTransactionsByDateRange(
        DateTime(_month.year, _month.month, 1),
        DateTime(_month.year, _month.month + 1, 1),
      );
    }
  }

  void _prevMonth() => setState(() { _month = DateTime(_month.year, _month.month - 1); _loadTx(); });
  void _nextMonth() => setState(() { _month = DateTime(_month.year, _month.month + 1); _loadTx(); });

  String get _monthKey => '${_month.year}-${_month.month.toString().padLeft(2, '0')}';
  String get _monthLabel => DateFormat('MMMM yyyy').format(_month);
  bool get _isCurrentMonth { final n = DateTime.now(); return _month.year == n.year && _month.month == n.month; }

  // ── Action methods ──────────────────────────────────────────────────────────

  Future<void> _startPlanningMonthly() async {
    try {
      await _monthPlanController.getOrCreateMonthPlan(_monthKey);
      await _budgetController.refreshBudgetsWithSpentAmounts();
    } catch (_) {}
  }

  Future<void> _startPlanningProfile() async {
    if (widget.budgetProfileId == null || !mounted) return;
    final profileCtrl = locator.get<BudgetProfileController>();
    final profiles = profileCtrl.data ?? [];
    final target = profiles.cast<dynamic>().firstWhere(
      (p) => p.id == widget.budgetProfileId, orElse: () => null);
    if (target == null || !mounted) return;
    final others = profiles.where((p) => p.id != widget.budgetProfileId).toList();
    final allBudgets = _budgetController.data ?? [];

    ProfileStartPlanningSheet.show(
      context,
      targetProfile: target,
      otherProfiles: others,
      allBudgets: allBudgets,
      budgetController: _budgetController,
      onPlanStarted: () async {
        await _monthPlanController.getOrCreatePlanForProfile(widget.budgetProfileId!);
        await _budgetController.loadBudgets();
        if (mounted) setState(() {});
      },
    );
  }

  void _showSettings(List<Budget> monthBudgets) {
    BudgetSettingsSheet.show(
      context,
      monthLabel: _monthLabel,
      onDeleteBudget: () => _confirmDeleteBudget(monthBudgets),
    );
  }

  Future<void> _confirmDeleteBudget(List<Budget> monthBudgets) async {
    if (monthBudgets.isEmpty) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Delete budget for $_monthLabel?'),
        content: Text(
          '${monthBudgets.length} group${monthBudgets.length == 1 ? '' : 's'} and all their categories will be permanently removed.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    for (final group in monthBudgets) {
      if (group.id != null) await _budgetController.deleteBudget(group.id!);
    }
  }

  void _showStartPlanning(List<Budget> allBudgets) {
    final prevMonth = DateTime(_month.year, _month.month - 1);
    final prevKey = '${prevMonth.year}-${prevMonth.month.toString().padLeft(2, '0')}';
    final prevLabel = DateFormat('MMMM yyyy').format(prevMonth);
    final hasPrev = allBudgets.any((b) => b.month == prevKey && b.status == BudgetStatus.active);
    showModalBottomSheet(
      context: context, isScrollControlled: true,
      builder: (_) => StartPlanningSheet(
        monthKey: _monthKey, monthLabel: _monthLabel,
        prevMonthKey: prevKey, prevMonthLabel: prevLabel,
        hasPrevBudgets: hasPrev,
        monthPlanController: _monthPlanController,
        budgetController: _budgetController,
      ),
    );
  }

  void _showCreateGroup(bool isIncome) {
    if (widget._isProfileMode && widget.onAddProfileGroup != null) {
      widget.onAddProfileGroup!(isIncome);
      return;
    }
    showModalBottomSheet(
      context: context, isScrollControlled: true,
      builder: (_) => CreateGroupSheet(
        monthKey: _monthKey, monthLabel: _monthLabel,
        budgetController: _budgetController,
        monthPlanController: _monthPlanController,
      ),
    );
  }

  void _showAddCategory(Budget group) {
    showModalBottomSheet(
      context: context, isScrollControlled: true,
      builder: (_) => AddCategorySheet(
        group: group, categoryController: _categoryController,
        onSave: (cat) => _budgetController.addCategory(group.id!, cat),
      ),
    );
  }

  void _showEditGroup(Budget group) {
    showModalBottomSheet(
      context: context, isScrollControlled: true,
      builder: (ctx) => EditGroupSheet(
        group: group, budgetController: _budgetController,
        onDelete: () async {
          Navigator.pop(ctx);
          if (group.id != null) await _budgetController.deleteBudget(group.id!);
        },
      ),
    );
  }

  void _showCategoryDetail(Budget group, BudgetCategory cat, double spent) {
    showModalBottomSheet(
      context: context, isScrollControlled: true, backgroundColor: Colors.transparent,
      builder: (_) => CategoryDetailSheet(
        group: group, cat: cat, spent: spent,
        onEdit: () { Navigator.pop(context); _showEditCategory(group, cat); },
      ),
    );
  }

  void _showEditCategory(Budget group, BudgetCategory cat) {
    showModalBottomSheet(
      context: context, isScrollControlled: true,
      builder: (ctx) => EditCategorySheet(
        group: group, category: cat,
        categoryController: _categoryController,
        budgetController: _budgetController,
        onDelete: () async {
          Navigator.pop(ctx);
          if (cat.id != null) await _budgetController.deleteCategory(group.id!, cat.id!);
        },
      ),
    );
  }

  void _skipSubscription(Subscription sub) {
    final next = sub.nextBillingDate;
    final advanced = switch (sub.billingCycle) {
      BillingCycle.weekly    => DateTime(next.year, next.month, next.day + 7),
      BillingCycle.monthly   => DateTime(next.year, next.month + 1, next.day),
      BillingCycle.quarterly => DateTime(next.year, next.month + 3, next.day),
      BillingCycle.annual    => DateTime(next.year + 1, next.month, next.day),
    };
    _subController.updateSubscription(sub.copyWith(nextBillingDate: advanced));
  }

  void _showAddSubscription() {
    showModalBottomSheet(
      context: context, isScrollControlled: true,
      builder: (_) => AddSubscriptionSheet(
        onSave: (sub) => _subController.createSubscription(
          widget._isProfileMode && widget.budgetProfileId != null
              ? sub.copyWith(budgetProfileId: widget.budgetProfileId)
              : sub,
        ),
      ),
    );
  }

  void _showAddDebt({required bool isReceivable}) {
    showModalBottomSheet(
      context: context, isScrollControlled: true,
      builder: (_) => AddDebtSheet(
        isReceivable: isReceivable,
        onSave: (debt, _) async => _debtController.createDebtOnly(
          widget._isProfileMode && widget.budgetProfileId != null
              ? debt.copyWith(budgetProfileId: widget.budgetProfileId)
              : debt,
        ),
      ),
    );
  }

  void _showSubDetail(Subscription sub) {
    showModalBottomSheet(
      context: context, isScrollControlled: true, backgroundColor: Colors.transparent,
      builder: (_) => SubDetailSheet(
        sub: sub,
        subController: _subController,
        month: _month,
        onPay: () async {
          final userId = locator.get<AuthController>().currentUser?.id ?? '';
          final categoryId = await locator.get<FinanceCategoryController>()
              .findOrCreate(name: 'Subscriptions', type: CategoryType.expense, userId: userId);
          await _txController.createTransaction(Transaction(
            amount: sub.amount,
            type: TransactionType.expense,
            date: DateTime.now(),
            subscriptionId: sub.id,
            financeCategoryId: categoryId,
            description: sub.name,
          ));
          await _subController.pay(sub.id!);
        },
        onUpdate: (updated) => _subController.updateSubscription(updated),
      ),
    );
  }

  void _showDebtDetail(Debt debt) {
    showModalBottomSheet(
      context: context, isScrollControlled: true, backgroundColor: Colors.transparent,
      builder: (_) => DebtDetailSheet(
        debt: debt,
        debtController: _debtController,
        // The backend payDebt endpoint handles transaction creation internally.
        onPay: (amount, fee) =>
            _debtController.payDebt(debt.id!, amount: amount, fee: fee),
        onUpdate: (updated) => _debtController.updateDebt(updated),
      ),
    );
  }



  void _showGoalDetail(Goal goal) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => GoalDetailSheet(
        goal: goal,
        goalController: _goalController,
        onContribute: (currentGoal, amount) async {
          final userId =
              locator.get<AuthController>().currentUser?.id ?? '';
          final catCtrl =
              locator.get<FinanceCategoryController>();
          final categoryId =
              await catCtrl.findOrCreateSavingsCategory(userId);

          // 1. Create a reversible transaction record
          await _txController.createTransaction(Transaction(
            amount: amount,
            type: TransactionType.income,
            date: DateTime.now(),
            goalId: currentGoal.id,
            savingsId: currentGoal.savingsBucketId,
            financeCategoryId: categoryId,
            description: 'Contribution to ${currentGoal.name}',
          ));

          // 2. Update goal progress (optimistic + server)
          await _goalController.contributeToGoal(currentGoal.id!, amount);

          // 3. Sync linked savings bucket balance
          if (currentGoal.savingsBucketId != null) {
            final buckets = _savingsController.data ?? [];
            final bucket = buckets
                .where((b) => b.id == currentGoal.savingsBucketId)
                .firstOrNull;
            if (bucket != null) {
              await _savingsController.updateSavingsBucket(
                bucket.copyWith(balance: bucket.balance + amount),
              );
            }
          }
        },
        onUpdate: (updated) => _goalController.updateGoal(updated),
      ),
    );
  }

  void _showAddGoal() {
    GoalsManagementDialog.show(
      context,
      onSave: (goal) => _goalController.createGoal(
        widget._isProfileMode && widget.budgetProfileId != null
            ? goal.copyWith(budgetProfileId: widget.budgetProfileId)
            : goal,
      ),
    );
  }


  // ── Build ───────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return AsyncStreamBuilder<List<Budget>>(
      state: _budgetController,
      builder: (_, budgets) => AsyncStreamBuilder<List<Transaction>>(
        state: _txController,
        builder: (_, txs) => AsyncStreamBuilder<List<Debt>>(
          state: _debtController,
          builder: (_, debts) => AsyncStreamBuilder<List<Subscription>>(
            state: _subController,
            builder: (_, subs) => AsyncStreamBuilder<List<Goal>>(
              state: _goalController,
              builder: (_, goals) => _build(context, isDark, budgets, txs, debts, subs, goals),
              loadingBuilder: (_) => _build(context, isDark, budgets, txs, debts, subs, []),
              errorBuilder: (_, __) => _build(context, isDark, budgets, txs, debts, subs, []),
            ),
            loadingBuilder: (_) => _build(context, isDark, budgets, txs, debts, [], []),
            errorBuilder: (_, __) => _build(context, isDark, budgets, txs, debts, [], []),
          ),
          loadingBuilder: (_) => _build(context, isDark, budgets, txs, [], [], []),
          errorBuilder: (_, __) => _build(context, isDark, budgets, txs, [], [], []),
        ),
        loadingBuilder: (_) => _build(context, isDark, budgets, [], [], [], []),
        errorBuilder: (_, __) => _build(context, isDark, budgets, [], [], [], []),
      ),
      loadingBuilder: (_) => const Center(child: CircularProgressIndicator()),
      errorBuilder: (_, msg) => Center(child: Text(msg)),
    );
  }

  Widget _build(BuildContext ctx, bool isDark, List<Budget> budgets, List<Transaction> txs,
      List<Debt> debts, List<Subscription> subs, List<Goal> goals) {
    final spentByCategory = BudgetMonthFilter.buildSpentByCategory(txs);

    final paidThisMonthByDebt = <String, double>{};
    final contributedThisMonthByGoal = <String, double>{};
    for (final t in txs) {
      if (t.debtId != null) {
        paidThisMonthByDebt[t.debtId!] = (paidThisMonthByDebt[t.debtId!] ?? 0) + t.amount;
      }
      if (t.goalId != null) {
        contributedThisMonthByGoal[t.goalId!] = (contributedThisMonthByGoal[t.goalId!] ?? 0) + t.amount;
      }
    }
    final monthBudgets = widget._isProfileMode
        ? widget.profileIsMonthly
            ? budgets.where((b) => b.budgetProfileId == widget.budgetProfileId && b.month == _monthKey && b.status == BudgetStatus.active).toList()
            : budgets.where((b) => b.budgetProfileId == widget.budgetProfileId && b.status == BudgetStatus.active).toList()
        : budgets.where((b) => b.month == _monthKey && b.budgetProfileId == null && b.status == BudgetStatus.active).toList();
    final incomeGroups = monthBudgets.where((b) => b.budgetType == BudgetType.income).toList();
    final expenseGroups = monthBudgets.where((b) => b.budgetType == BudgetType.expense).toList();
    double sumSpent(List<Budget> gs) => gs.fold(0.0, (s, b) => s + b.categories.fold(0.0, (cs, c) => cs + (spentByCategory[c.financeCategoryId] ?? 0.0)));
    double sumPlanned(List<Budget> gs) => gs.fold(0.0, (s, b) => s + b.budgetTarget);
    final actualIncome = sumSpent(incomeGroups), plannedIncome = sumPlanned(incomeGroups);
    final actualExpenses = sumSpent(expenseGroups), plannedExpenses = sumPlanned(expenseGroups);
    final net = actualIncome - actualExpenses;
    final plannedNet = plannedIncome - plannedExpenses;

    // Filter subs/debts/goals by profile scope
    bool matchesProfile(String? itemProfileId) => widget._isProfileMode
        ? itemProfileId == widget.budgetProfileId
        : itemProfileId == null;

    int debtOrder(DebtStatus s) => s == DebtStatus.active ? 0 : 1;
    final sortedDebts = (debts.where((d) => d.type == DebtType.borrowing && matchesProfile(d.budgetProfileId)).toList()
      ..sort((a, b) => debtOrder(a.status).compareTo(debtOrder(b.status))));
    final sortedReceivables = (debts.where((d) => d.type == DebtType.lending && matchesProfile(d.budgetProfileId)).toList()
      ..sort((a, b) => debtOrder(a.status).compareTo(debtOrder(b.status))));
    final activeSubs = subs.where((s) => s.status != SubscriptionStatus.cancelled && matchesProfile(s.budgetProfileId)).toList();
    final monthStart = DateTime(_month.year, _month.month, 1);
    final monthEnd = DateTime(_month.year, _month.month + 1, 1);
    final monthSubs = activeSubs.where((s) {
      final paidThisMonth = s.lastBilledDate != null && s.lastBilledDate!.year == _month.year && s.lastBilledDate!.month == _month.month;
      final dueThisMonth = s.nextBillingDate.year == _month.year && s.nextBillingDate.month == _month.month;
      final overdue = !paidThisMonth && s.nextBillingDate.isAfter(monthStart.subtract(const Duration(days: 1))) && s.nextBillingDate.isBefore(monthEnd);
      return paidThisMonth || dueThisMonth || overdue;
    }).toList();
    int goalOrder(GoalStatus s) => switch (s) { GoalStatus.active => 0, GoalStatus.paused => 1, _ => 2 };
    final sortedGoals = (List.of(goals.where((g) => matchesProfile(g.budgetProfileId)))..sort((a, b) => goalOrder(a.status).compareTo(goalOrder(b.status))));

    final tab = widget.selectedTab;
    // Summary tab (0) has its own full content — no separate summary card needed
    // Tabs 1–5 each have a header card above the section list
    Widget summaryCard = switch (tab) {
      0 => const SizedBox.shrink(),  // summary tab: no card (content IS the summary)
      2 => SimpleSubsSummaryCard(isDark: isDark, subs: monthSubs, month: _month),
      3 => SimpleDebtSummaryCard(
          isDark: isDark,
          totalOwed: sortedDebts.where((d) => d.status == DebtStatus.active).fold(0.0, (s, d) => s + d.remainingAmount),
          totalReceivable: 0,
          debtCount: sortedDebts.where((d) => d.status == DebtStatus.active).length,
          receivableCount: 0,
        ),
      4 => SimpleDebtSummaryCard(
          isDark: isDark,
          totalOwed: 0,
          totalReceivable: sortedReceivables.where((d) => d.status == DebtStatus.active).fold(0.0, (s, d) => s + d.remainingAmount),
          debtCount: 0,
          receivableCount: sortedReceivables.where((d) => d.status == DebtStatus.active).length,
        ),
      5 => SimpleGoalsSummaryCard(isDark: isDark, goals: sortedGoals),
      _ => SimpleNetCard(isDark: isDark, net: net, plannedNet: plannedNet, actualIncome: actualIncome, plannedIncome: plannedIncome, actualExpenses: actualExpenses, plannedExpenses: plannedExpenses),
    };

    // ── Plan gate ─────────────────────────────────────────────────────────────
    final plans = _monthPlanController.data ?? [];
    final MonthPlan? monthPlan = widget._isProfileMode
        ? null
        : plans.cast<MonthPlan?>().firstWhere(
            (p) => p?.month == _monthKey, orElse: () => null);
    final MonthPlan? profilePlan = widget._isProfileMode
        ? plans.cast<MonthPlan?>().firstWhere(
            (p) => p?.budgetProfileId == widget.budgetProfileId, orElse: () => null)
        : null;
    final bool hasMonthPlan = widget._isProfileMode
        ? (profilePlan != null || monthBudgets.isNotEmpty)
        : monthPlan != null;

    // ── Shared header slivers ─────────────────────────────────────────────────
    final headerSlivers = <Widget>[
      if (!widget._isProfileMode && widget.onBack != null)
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
            child: GestureDetector(
              onTap: widget.onBack,
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(Icons.arrow_back_rounded, size: 16, color: AppColors.textSecondary),
                const SizedBox(width: 6),
                Text('Profiles', style: GoogleFonts.dmSans(fontSize: 13, color: AppColors.textSecondary, fontWeight: FontWeight.w500)),
              ]),
            ),
          ),
        ),
      if (widget._isProfileMode && !widget.profileIsMonthly)
        SliverToBoxAdapter(child: _ProfileHeader(
          isDark: isDark,
          name: widget.profileName ?? '',
          color: widget.profileAccentColor ?? AppColors.accent,
          onBack: widget.onBack,
          onToggleView: widget.onToggleView,
          onSettings: hasMonthPlan && widget.onOpenSettings != null ? () => widget.onOpenSettings!() : null,
        ))
      else if (widget._isProfileMode && widget.profileIsMonthly)
        SliverToBoxAdapter(child: _MonthlyProfileHeader(
          isDark: isDark,
          name: widget.profileName ?? '',
          color: widget.profileAccentColor ?? AppColors.accent,
          month: _month,
          onBack: widget.onBack,
          onPrev: _prevMonth,
          onNext: _isCurrentMonth ? null : _nextMonth,
          onToggleView: widget.onToggleView,
          onSettings: hasMonthPlan && widget.onOpenSettings != null ? () => widget.onOpenSettings!() : null,
        ))
      else
        SliverToBoxAdapter(child: SimpleMonthNav(
          month: _month, isDark: isDark, onPrev: _prevMonth, onNext: _isCurrentMonth ? null : _nextMonth,
          onToggleView: widget.onToggleView,
          onSettings: hasMonthPlan ? () => (widget.onOpenSettings ?? () => _showSettings(monthBudgets))() : null,
        )),
    ];

    // ── No plan: locked gate ──────────────────────────────────────────────────
    if (!hasMonthPlan) {
      return CustomScrollView(slivers: [
        ...headerSlivers,
        SliverFillRemaining(
          hasScrollBody: false,
          child: _NoPlanGate(
            isDark: isDark,
            label: widget._isProfileMode ? (widget.profileName ?? 'Custom Budget') : _monthLabel,
            isProfile: widget._isProfileMode,
            onStartPlanning: widget._isProfileMode
                ? _startPlanningProfile
                : _startPlanningMonthly,
          ),
        ),
      ]);
    }

    // ── Normal content ────────────────────────────────────────────────────────
    return CustomScrollView(slivers: [
      ...headerSlivers,
      SliverToBoxAdapter(child: BudgetSimpleTabBar(
        isDark: isDark,
        selected: tab,
        onSelect: widget.onTabChange ?? (_) {},
        // Tab 0 = Summary (no count), 1 = Budget, 2 = Subs, 3 = Debts, 4 = Receivables, 5 = Goals
        counts: [
          null,
          null,
          activeSubs.length,
          sortedDebts.where((d) => d.status == DebtStatus.active).length,
          sortedReceivables.where((d) => d.status == DebtStatus.active).length,
          sortedGoals.where((g) => g.status == GoalStatus.active).length,
        ],
      )),
      if (tab != 0)
        SliverToBoxAdapter(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 280),
            switchInCurve: Curves.easeOutCubic,
            switchOutCurve: Curves.easeInCubic,
            transitionBuilder: (child, animation) => FadeTransition(
              opacity: animation,
              child: SlideTransition(
                position: Tween<Offset>(begin: const Offset(0, 0.06), end: Offset.zero).animate(animation),
                child: child,
              ),
            ),
            child: KeyedSubtree(key: ValueKey(tab), child: summaryCard),
          ),
        ),
      // Tab 0: Overall summary
      if (tab == 0)
        SliverToBoxAdapter(
          child: BudgetOverallSummary(
            monthBudgets: monthBudgets,
            spentByCategory: spentByCategory,
            subscriptions: activeSubs,
            debts: sortedDebts,
            receivables: sortedReceivables,
            goals: sortedGoals,
            transactions: txs,
            currentMonth: _month,
            isDark: isDark,
          ),
        ),
      // Tab 1: Budget groups
      if (tab == 1) ...[
        SliverToBoxAdapter(child: SimpleBudgetSection(
          isDark: isDark, label: 'INCOME', groups: incomeGroups, spentByCategory: spentByCategory, isIncome: true,
          onAddGroup: () => _showCreateGroup(true), onAddCategory: _showAddCategory,
          onEditGroup: _showEditGroup, onCategoryTap: _showCategoryDetail,
        )),
        SliverToBoxAdapter(child: SimpleBudgetSection(
          isDark: isDark, label: 'EXPENSES', groups: expenseGroups, spentByCategory: spentByCategory, isIncome: false,
          onAddGroup: () => _showCreateGroup(false), onAddCategory: _showAddCategory,
          onEditGroup: _showEditGroup, onCategoryTap: _showCategoryDetail,
        )),
      ],
      if (tab == 2)
        SliverToBoxAdapter(child: SimpleSubscriptionsSection(
          isDark: isDark, subs: activeSubs, month: _month,
          onAdd: _showAddSubscription, onRowTap: _showSubDetail,
          onSkip: _skipSubscription,
        )),
      if (tab == 3)
        SliverToBoxAdapter(child: SimpleDebtsSection(
          isDark: isDark, debts: sortedDebts, receivables: const [],
          paidThisMonth: paidThisMonthByDebt,
          onAddDebt: () => _showAddDebt(isReceivable: false),
          onAddReceivable: () => _showAddDebt(isReceivable: false),
          onRowTap: _showDebtDetail,
        )),
      if (tab == 4)
        SliverToBoxAdapter(child: SimpleDebtsSection(
          isDark: isDark, debts: const [], receivables: sortedReceivables,
          paidThisMonth: paidThisMonthByDebt,
          onAddDebt: () => _showAddDebt(isReceivable: true),
          onAddReceivable: () => _showAddDebt(isReceivable: true),
          onRowTap: _showDebtDetail,
        )),
      if (tab == 5)
        SliverToBoxAdapter(child: SimpleGoalsSection(
          isDark: isDark, goals: sortedGoals, onAdd: _showAddGoal, onRowTap: _showGoalDetail,
          contributedThisMonth: contributedThisMonthByGoal,
        )),
      const SliverToBoxAdapter(child: SizedBox(height: 100)),
    ]);
  }
}

// ─── No Plan Gate ─────────────────────────────────────────────────────────────

class _NoPlanGate extends StatelessWidget {
  final bool isDark;
  final String label;
  final bool isProfile;
  final VoidCallback? onStartPlanning;

  const _NoPlanGate({required this.isDark, required this.label, required this.isProfile, this.onStartPlanning});

  @override
  Widget build(BuildContext context) {
    final textPrimary = isDark ? AppColors.primaryForeground : AppColors.textPrimary;
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
            width: 56, height: 56,
            decoration: BoxDecoration(color: AppColors.accent.withValues(alpha: 0.1), shape: BoxShape.circle),
            child: Icon(isProfile ? Icons.folder_outlined : Icons.edit_calendar_outlined, size: 26, color: AppColors.accent),
          ),
          const SizedBox(height: 18),
          Text(
            isProfile ? 'No plan for "$label"' : 'No plan for $label',
            style: GoogleFonts.dmSans(fontSize: 16, fontWeight: FontWeight.w700, color: textPrimary),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            isProfile
                ? 'Create your first budget group to start tracking this profile.'
                : 'Create a plan for this month to unlock all budget features.',
            style: GoogleFonts.dmSans(fontSize: 13, color: AppColors.textSecondary, height: 1.5),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 28),
          GestureDetector(
            onTap: onStartPlanning,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
              decoration: BoxDecoration(color: AppColors.accent, borderRadius: BorderRadius.circular(24)),
              child: Text('Start Planning', style: GoogleFonts.dmSans(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white)),
            ),
          ),
        ]),
      ),
    );
  }
}

// ─── Profile Header ──────────────────────────────────────────────────────────

class _ProfileHeader extends StatelessWidget {
  final bool isDark;
  final String name;
  final Color color;
  final VoidCallback? onBack;
  final VoidCallback? onToggleView;
  final VoidCallback? onSettings;

  const _ProfileHeader({required this.isDark, required this.name, required this.color, this.onBack, this.onToggleView, this.onSettings});

  @override
  Widget build(BuildContext context) {
    final textPrimary = isDark ? AppColors.primaryForeground : AppColors.textPrimary;
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 12, 4, 0),
      child: Row(children: [
        if (onBack != null)
          IconButton(
            icon: Icon(Icons.arrow_back_rounded, size: 20, color: textPrimary),
            onPressed: onBack,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
          ),
        Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 8),
        Expanded(child: Text(name, style: GoogleFonts.dmSans(fontSize: 16, fontWeight: FontWeight.w700, color: textPrimary), overflow: TextOverflow.ellipsis)),
        if (onToggleView != null)
          IconButton(icon: Icon(Icons.table_rows_outlined, size: 18, color: AppColors.textSecondary), onPressed: onToggleView, tooltip: 'Switch to Sheets', padding: EdgeInsets.zero, constraints: const BoxConstraints(minWidth: 36, minHeight: 36)),
        if (onSettings != null)
          IconButton(icon: Icon(Icons.more_vert_rounded, size: 20, color: AppColors.textSecondary), onPressed: onSettings, padding: EdgeInsets.zero, constraints: const BoxConstraints(minWidth: 36, minHeight: 36)),
      ]),
    );
  }
}

// ─── Monthly Profile Header ───────────────────────────────────────────────────

class _MonthlyProfileHeader extends StatelessWidget {
  final bool isDark;
  final String name;
  final Color color;
  final DateTime month;
  final VoidCallback? onBack;
  final VoidCallback? onPrev;
  final VoidCallback? onNext;
  final VoidCallback? onToggleView;
  final VoidCallback? onSettings;

  const _MonthlyProfileHeader({
    required this.isDark, required this.name, required this.color,
    required this.month, this.onBack, this.onPrev, this.onNext,
    this.onToggleView, this.onSettings,
  });

  @override
  Widget build(BuildContext context) {
    final textPrimary = isDark ? AppColors.primaryForeground : AppColors.textPrimary;
    final monthLabel = DateFormat('MMMM yyyy').format(month);
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 12, 4, 0),
      child: Row(children: [
        if (onBack != null)
          IconButton(
            icon: Icon(Icons.arrow_back_rounded, size: 20, color: textPrimary),
            onPressed: onBack,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
          ),
        Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 8),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(name, style: GoogleFonts.dmSans(fontSize: 14, fontWeight: FontWeight.w700, color: textPrimary), overflow: TextOverflow.ellipsis),
            Row(mainAxisSize: MainAxisSize.min, children: [
              if (onPrev != null)
                GestureDetector(
                  onTap: onPrev,
                  child: Icon(Icons.chevron_left_rounded, size: 14, color: AppColors.textSecondary),
                ),
              Text(monthLabel, style: GoogleFonts.dmSans(fontSize: 11, color: AppColors.textSecondary)),
              if (onNext != null)
                GestureDetector(
                  onTap: onNext,
                  child: Icon(Icons.chevron_right_rounded, size: 14, color: AppColors.textSecondary),
                ),
            ]),
          ]),
        ),
        if (onToggleView != null)
          IconButton(icon: Icon(Icons.table_rows_outlined, size: 18, color: AppColors.textSecondary), onPressed: onToggleView, padding: EdgeInsets.zero, constraints: const BoxConstraints(minWidth: 36, minHeight: 36)),
        if (onSettings != null)
          IconButton(icon: Icon(Icons.more_vert_rounded, size: 20, color: AppColors.textSecondary), onPressed: onSettings, padding: EdgeInsets.zero, constraints: const BoxConstraints(minWidth: 36, minHeight: 36)),
      ]),
    );
  }
}

// ─── Simple Tab Bar ───────────────────────────────────────────────────────────

class BudgetSimpleTabBar extends StatelessWidget {
  final bool isDark;
  final int selected;
  final void Function(int) onSelect;
  final List<int?> counts;

  const BudgetSimpleTabBar({
    super.key,
    required this.isDark,
    required this.selected,
    required this.onSelect,
    required this.counts,
  });

  static const _items = [
    (icon: Icons.dashboard_outlined, activeIcon: Icons.dashboard_rounded, label: 'Summary'),
    (icon: Icons.calendar_month_outlined, activeIcon: Icons.calendar_month, label: 'Budget'),
    (icon: Icons.autorenew_outlined, activeIcon: Icons.autorenew, label: 'Subs'),
    (icon: Icons.arrow_upward_rounded, activeIcon: Icons.arrow_upward_rounded, label: 'Debts'),
    (icon: Icons.arrow_downward_rounded, activeIcon: Icons.arrow_downward_rounded, label: 'Receivables'),
    (icon: Icons.flag_outlined, activeIcon: Icons.flag, label: 'Goals'),
  ];

  Widget _buildPill(int i, bool narrow) {
    final item = _items[i];
    final isSelected = i == selected;
    final count = i < counts.length ? counts[i] : null;
    final label = (count != null && count > 0) ? '${item.label} ($count)' : item.label;
    final fg = isSelected
        ? Colors.white
        : (isDark ? AppColors.primaryForeground : AppColors.textPrimary);

    Widget pill = AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      padding: EdgeInsets.symmetric(horizontal: narrow ? 10 : 14, vertical: 8),
      decoration: BoxDecoration(
        color: isSelected
            ? AppColors.accent
            : (isDark ? Colors.white.withValues(alpha: 0.08) : Colors.white),
        borderRadius: BorderRadius.circular(20),
        border: isSelected
            ? null
            : Border.all(
                color: isDark ? AppColors.border.withValues(alpha: 0.35) : AppColors.border,
                width: 1,
              ),
        boxShadow: isSelected
            ? [BoxShadow(color: AppColors.accent.withValues(alpha: 0.25), blurRadius: 8, offset: const Offset(0, 2))]
            : null,
      ),
      child: Row(mainAxisSize: MainAxisSize.min, mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(isSelected ? item.activeIcon : item.icon, size: 13, color: fg),
        const SizedBox(width: 5),
        Text(label, style: GoogleFonts.dmSans(fontSize: 12, fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500, color: fg)),
      ]),
    );

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(onTap: () => onSelect(i), child: pill),
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final narrow = constraints.maxWidth < 520;

        if (narrow) {
          // Wrap — pills flow to next row if they don't fit
          return Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Wrap(
              spacing: 6,
              runSpacing: 6,
              children: List.generate(_items.length, (i) => _buildPill(i, true)),
            ),
          );
        }

        // Wide — horizontal scroll
        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: List.generate(
                _items.length,
                (i) => Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: _buildPill(i, false),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
