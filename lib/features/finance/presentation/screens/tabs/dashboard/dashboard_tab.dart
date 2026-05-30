import 'dart:math' show max;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:keep_track/core/di/service_locator.dart';
import 'package:keep_track/core/settings/utils/currency_formatter.dart';
import 'package:keep_track/core/state/stream_builder_widget.dart';
import 'package:keep_track/core/theme/app_theme.dart';
import 'package:keep_track/features/finance/modules/budget/domain/entities/budget.dart';
import 'package:keep_track/features/finance/modules/budget/presentation/controllers/budget_controller.dart';
import 'package:keep_track/features/finance/modules/budget/presentation/helpers/budget_month_filter.dart';
import 'package:keep_track/features/finance/modules/budget_profile/domain/entities/budget_profile.dart';
import 'package:keep_track/features/finance/modules/debt/domain/entities/debt.dart';
import 'package:keep_track/features/finance/modules/savings/domain/entities/savings_bucket.dart';
import 'package:keep_track/features/finance/modules/subscriptions/domain/entities/subscription.dart';
import 'package:keep_track/features/finance/modules/transaction/domain/entities/transaction.dart';
import 'package:keep_track/features/finance/presentation/state/budget_profile_controller.dart';
import 'package:keep_track/features/finance/presentation/state/debt_controller.dart';
import 'package:keep_track/features/finance/presentation/state/savings_controller.dart';
import 'package:keep_track/features/finance/modules/planned_payment/domain/entities/payment_enums.dart';
import 'package:keep_track/features/finance/modules/planned_payment/domain/entities/planned_payment.dart';
import 'package:keep_track/features/finance/presentation/state/planned_payment_controller.dart';
import 'package:keep_track/features/finance/presentation/state/subscription_controller.dart';
import 'package:keep_track/features/finance/presentation/screens/tabs/dashboard/dashboard_insights.dart';
import 'package:keep_track/features/finance/modules/transaction_plan/domain/entities/transaction_plan.dart';
import 'package:keep_track/features/finance/presentation/state/transaction_controller.dart';
import 'package:keep_track/features/finance/presentation/state/transaction_plan_controller.dart';

class DashboardTab extends StatefulWidget {
  const DashboardTab({super.key});

  @override
  State<DashboardTab> createState() => _DashboardTabState();
}

class _DashboardTabState extends State<DashboardTab> {
  late final SavingsController _savingsController;
  late final BudgetController _budgetController;
  late final TransactionController _txController;
  late final SubscriptionController _subController;
  late final DebtController _debtController;
  late final BudgetProfileController _budgetProfileController;
  late final PlannedPaymentController _plannedPaymentController;
  late final TransactionPlanController _txPlanController;

  String? _selectedProfileId;
  bool _showingInsights = false;

  @override
  void initState() {
    super.initState();
    _savingsController = locator.get<SavingsController>();
    _budgetController = locator.get<BudgetController>();
    _txController = locator.get<TransactionController>();
    _subController = locator.get<SubscriptionController>();
    _debtController = locator.get<DebtController>();
    _budgetProfileController = locator.get<BudgetProfileController>();
    _plannedPaymentController = locator.get<PlannedPaymentController>();
    _txPlanController = locator.get<TransactionPlanController>();
    _savingsController.loadSavings();
    _budgetController.loadBudgets();
    _txController.loadAllTransactions();
  }

  String get _monthKey {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AsyncStreamBuilder<List<BudgetProfile>>(
      state: _budgetProfileController,
      builder: (_, profiles) => _buildWithProfiles(context, isDark, profiles),
      loadingBuilder: (_) => _buildWithProfiles(context, isDark, []),
      errorBuilder: (_, __) => _buildWithProfiles(context, isDark, []),
    );
  }

  Widget _buildWithProfiles(BuildContext context, bool isDark, List<BudgetProfile> profiles) {
    final effectiveProfileId = _selectedProfileId ??
        (profiles.isEmpty
            ? null
            : (profiles.where((p) => p.isMain).firstOrNull ?? profiles.first).id);
    // Keep BudgetProfileController in sync so the global FAB knows the current profile
    if (effectiveProfileId != null &&
        _budgetProfileController.selectedProfileId != effectiveProfileId) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _budgetProfileController.selectedProfileId = effectiveProfileId;
      });
    }
    return AsyncStreamBuilder<List<SavingsBucket>>(
      state: _savingsController,
      builder: (_, buckets) => AsyncStreamBuilder<List<Budget>>(
        state: _budgetController,
        builder: (_, budgets) => AsyncStreamBuilder<List<Transaction>>(
          state: _txController,
          builder: (_, txs) => AsyncStreamBuilder<List<Debt>>(
            state: _debtController,
            builder: (_, debts) => AsyncStreamBuilder<List<Subscription>>(
              state: _subController,
              builder: (_, subs) => AsyncStreamBuilder<List<PlannedPayment>>(
                state: _plannedPaymentController,
                builder: (_, payments) => AsyncStreamBuilder<List<TransactionPlan>>(
                  state: _txPlanController,
                  builder: (_, plans) => _buildDashboard(context, isDark, profiles, effectiveProfileId, buckets, budgets, txs, debts, subs, payments, plans),
                  loadingBuilder: (_) => _buildDashboard(context, isDark, profiles, effectiveProfileId, buckets, budgets, txs, debts, subs, payments, []),
                  errorBuilder: (_, __) => _buildDashboard(context, isDark, profiles, effectiveProfileId, buckets, budgets, txs, debts, subs, payments, []),
                ),
                loadingBuilder: (_) => _buildDashboard(context, isDark, profiles, effectiveProfileId, buckets, budgets, txs, debts, subs, [], []),
                errorBuilder: (_, __) => _buildDashboard(context, isDark, profiles, effectiveProfileId, buckets, budgets, txs, debts, subs, [], []),
              ),
              loadingBuilder: (_) => _buildDashboard(context, isDark, profiles, effectiveProfileId, buckets, budgets, txs, debts, [], [], []),
              errorBuilder: (_, __) => _buildDashboard(context, isDark, profiles, effectiveProfileId, buckets, budgets, txs, debts, [], [], []),
            ),
            loadingBuilder: (_) => _buildDashboard(context, isDark, profiles, effectiveProfileId, buckets, budgets, txs, [], [], [], []),
            errorBuilder: (_, __) => _buildDashboard(context, isDark, profiles, effectiveProfileId, buckets, budgets, txs, [], [], [], []),
          ),
          loadingBuilder: (_) => _buildDashboard(context, isDark, profiles, effectiveProfileId, buckets, budgets, [], [], [], [], []),
          errorBuilder: (_, __) => _buildDashboard(context, isDark, profiles, effectiveProfileId, buckets, budgets, [], [], [], [], []),
        ),
        loadingBuilder: (_) => _buildDashboard(context, isDark, profiles, effectiveProfileId, buckets, [], [], [], [], [], []),
        errorBuilder: (_, __) => _buildDashboard(context, isDark, profiles, effectiveProfileId, buckets, [], [], [], [], [], []),
      ),
      loadingBuilder: (_) => const Center(child: CircularProgressIndicator()),
      errorBuilder: (_, __) => const Center(child: CircularProgressIndicator()),
    );
  }

  Widget _buildDashboard(
    BuildContext context, bool isDark,
    List<BudgetProfile> profiles, String? selectedProfileId,
    List<SavingsBucket> buckets, List<Budget> budgets,
    List<Transaction> txs, List<Debt> debts, List<Subscription> subs,
    List<PlannedPayment> plannedPayments, List<TransactionPlan> txPlans,
  ) {
    final monthBudgets = budgets.where((b) => b.month == _monthKey && b.status == BudgetStatus.active && b.budgetProfileId == selectedProfileId).toList();
    final profileTxs = txs.where((t) => t.budgetProfileId == selectedProfileId).toList();
    final now = DateTime.now();
    final currentMonthTxs = profileTxs.where((t) => t.date.year == now.year && t.date.month == now.month).toList();
    final spentByCategory = BudgetMonthFilter.buildSpentByCategory(currentMonthTxs);
    final totalSavings = buckets.fold(0.0, (s, b) => s + b.balance);
    final totalDebt = debts.where((d) => d.type == DebtType.borrowing && d.status == DebtStatus.active).fold(0.0, (s, d) => s + d.remainingAmount);
    final totalReceivables = debts.where((d) => d.type == DebtType.lending && d.status == DebtStatus.active).fold(0.0, (s, d) => s + d.remainingAmount);
    final plannedIncome = monthBudgets.where((b) => b.budgetType == BudgetType.income).fold(0.0, (s, b) => s + b.budgetTarget);
    final plannedExpenses = monthBudgets.where((b) => b.budgetType == BudgetType.expense).fold(0.0, (s, b) => s + b.budgetTarget);
    final actualIncome = monthBudgets.where((b) => b.budgetType == BudgetType.income).fold(0.0, (s, b) => s + b.categories.fold(0.0, (cs, c) => cs + (spentByCategory[c.financeCategoryId] ?? 0.0)));
    final actualExpenses = monthBudgets.where((b) => b.budgetType == BudgetType.expense).fold(0.0, (s, b) => s + b.categories.fold(0.0, (cs, c) => cs + (spentByCategory[c.financeCategoryId] ?? 0.0)));
    final activeSubs = subs.where((s) => s.status == SubscriptionStatus.active).toList();
    final upcomingSubs = activeSubs.where((s) => s.isUpcoming || s.isOverdue).toList()
      ..sort((a, b) => a.nextBillingDate.compareTo(b.nextBillingDate));
    final overdueDebts = debts.where((d) => d.isOverdue).toList();
    final upcomingPayments = plannedPayments
        .where((p) => p.status == PaymentStatus.active && (p.isUpcoming || p.isOverdue))
        .toList()
      ..sort((a, b) => a.nextPaymentDate.compareTo(b.nextPaymentDate));
    final upcomingTxPlans = txPlans
        .where((p) => p.isPending && (p.isDueToday || p.isOverdue ||
            p.plannedDate.difference(DateTime.now()).inDays <= 7))
        .toList()
      ..sort((a, b) => a.plannedDate.compareTo(b.plannedDate));

    final profileBudgets = budgets.where((b) => b.budgetProfileId == selectedProfileId).toList();

    // ── Insights view ──────────────────────────────────────────────────────────
    if (_showingInsights) {
      return CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: _InsightsHeader(
              isDark: isDark,
              onBack: () => setState(() => _showingInsights = false),
            ),
          ),
          SliverToBoxAdapter(
            child: DashboardInsights(
              isDark: isDark,
              transactions: profileTxs,
              budgets: profileBudgets,
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 40)),
        ],
      );
    }

    // ── Normal dashboard ───────────────────────────────────────────────────────
    return CustomScrollView(
      slivers: [
        if (profiles.isNotEmpty)
          SliverToBoxAdapter(child: _ProfilePills(
            profiles: profiles,
            selectedId: selectedProfileId,
            onSelect: (id) {
              setState(() => _selectedProfileId = id);
              _budgetProfileController.selectedProfileId = id;
            },
            isDark: isDark,
          )),
        SliverToBoxAdapter(child: _MonthOverviewCard(
          isDark: isDark,
          totalSavings: totalSavings,
          netDebt: totalReceivables - totalDebt,
          actualIncome: actualIncome, plannedIncome: plannedIncome,
          actualExpenses: actualExpenses, plannedExpenses: plannedExpenses,
          hasBudgets: monthBudgets.isNotEmpty,
        )),
        SliverToBoxAdapter(child: _SpendingChart(transactions: currentMonthTxs, isDark: isDark)),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: SizedBox(
              height: 280,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: _RecentTransactionsCard(
                      isDark: isDark,
                      transactions: (List.of(currentMonthTxs)..sort((a, b) => b.date.compareTo(a.date))).take(5).toList(),
                      profileNames: {for (final p in profiles) if (p.id != null) p.id!: p.name},
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _UpcomingCard(
                      isDark: isDark,
                      subs: upcomingSubs.take(2).toList(),
                      overdueDebts: overdueDebts.take(2).toList(),
                      plannedPayments: upcomingPayments.take(2).toList(),
                      txPlans: upcomingTxPlans.take(2).toList(),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: _InsightsEntryCard(
            isDark: isDark,
            hasBudgets: profileBudgets.isNotEmpty,
            transactionCount: profileTxs.length,
            monthLabel: DateFormat('MMMM yyyy').format(DateTime.now()),
            onTap: () => setState(() => _showingInsights = true),
          ),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: 32)),
      ],
    );
  }
}

// ─── Month Overview ───────────────────────────────────────────────────────────

class _MonthOverviewCard extends StatelessWidget {
  final bool isDark;
  final double totalSavings, netDebt;
  final double actualIncome, plannedIncome, actualExpenses, plannedExpenses;
  final bool hasBudgets;

  const _MonthOverviewCard({
    required this.isDark,
    required this.totalSavings,
    required this.netDebt,
    required this.actualIncome,
    required this.plannedIncome,
    required this.actualExpenses,
    required this.plannedExpenses,
    required this.hasBudgets,
  });

  @override
  Widget build(BuildContext context) {
    final cardBg = isDark ? const Color(0xFF2C2C2A) : Colors.white;
    final borderColor = isDark
        ? AppColors.border.withValues(alpha: 0.2)
        : AppColors.border.withValues(alpha: 0.5);
    final textPrimary = isDark ? AppColors.primaryForeground : AppColors.textPrimary;
    final now = DateTime.now();
    final daysInMonth = DateUtils.getDaysInMonth(now.year, now.month);
    final daysPassed = now.day;
    final monthProgress = daysPassed / daysInMonth;
    final isOverBudget = plannedExpenses > 0 && actualExpenses > plannedExpenses;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: borderColor, width: 0.5),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'This Month',
                  style: GoogleFonts.dmSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: textPrimary,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: isDark
                        ? AppColors.border.withValues(alpha: 0.2)
                        : AppColors.background,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    DateFormat('MMMM yyyy').format(now),
                    style: GoogleFonts.dmSans(
                      fontSize: 11,
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Total Balance',
                        style: GoogleFonts.dmSans(
                          fontSize: 11,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      TweenAnimationBuilder<double>(
                        tween: Tween(begin: 0, end: totalSavings),
                        duration: const Duration(milliseconds: 900),
                        curve: Curves.easeOutCubic,
                        builder: (_, value, __) => Text(
                          currencyFormatter.format(value, decimalDigits: 0),
                          style: GoogleFonts.dmMono(
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                            color: textPrimary,
                            fontFeatures: const [FontFeature.tabularFigures()],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      netDebt >= 0 ? 'Receivables' : 'You Owe',
                      style: GoogleFonts.dmSans(
                        fontSize: 11,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0, end: netDebt.abs()),
                      duration: const Duration(milliseconds: 900),
                      curve: Curves.easeOutCubic,
                      builder: (_, value, __) => Text(
                        currencyFormatter.format(value, decimalDigits: 0),
                        style: GoogleFonts.dmMono(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: netDebt >= 0 ? AppColors.info : AppColors.warning,
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            if (hasBudgets) ...[
              const SizedBox(height: 18),
              _ProgressRow(
                isDark: isDark,
                label: 'Income',
                actual: actualIncome,
                planned: plannedIncome,
                progress: plannedIncome > 0
                    ? (actualIncome / plannedIncome).clamp(0.0, 1.0)
                    : 0.0,
                color: AppColors.success,
                icon: Icons.arrow_downward_rounded,
              ),
              const SizedBox(height: 12),
              _ProgressRow(
                isDark: isDark,
                label: 'Expense',
                actual: actualExpenses,
                planned: plannedExpenses,
                progress: plannedExpenses > 0
                    ? (actualExpenses / plannedExpenses).clamp(0.0, 1.0)
                    : 0.0,
                color: isOverBudget ? AppColors.error : AppColors.accent,
                icon: Icons.arrow_upward_rounded,
              ),
            ],
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(2),
                    child: LinearProgressIndicator(
                      value: monthProgress,
                      minHeight: 2,
                      backgroundColor: isDark
                          ? Colors.white.withValues(alpha: 0.08)
                          : AppColors.border,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        AppColors.textTertiary,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'Day $daysPassed of $daysInMonth',
                  style: GoogleFonts.dmSans(
                    fontSize: 10,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ProgressRow extends StatelessWidget {
  final bool isDark;
  final String label;
  final double actual, planned, progress;
  final Color color;
  final IconData icon;

  const _ProgressRow({required this.isDark, required this.label, required this.actual, required this.planned, required this.progress, required this.color, required this.icon});

  @override
  Widget build(BuildContext context) {
    final textPrimary = isDark ? AppColors.primaryForeground : AppColors.textPrimary;
    return Column(
      children: [
        Row(children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 5),
          Text(label, style: GoogleFonts.dmSans(fontSize: 11, color: AppColors.textSecondary, fontWeight: FontWeight.w500)),
          const Spacer(),
          Text(currencyFormatter.format(actual, decimalDigits: 0),
              style: GoogleFonts.dmMono(fontSize: 12, fontWeight: FontWeight.w600, color: textPrimary)),
          Text(' / ${currencyFormatter.format(planned, decimalDigits: 0)}',
              style: GoogleFonts.dmSans(fontSize: 11, color: AppColors.textSecondary)),
        ]),
        const SizedBox(height: 6),
        TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: progress),
          duration: const Duration(milliseconds: 900),
          curve: Curves.easeOutCubic,
          builder: (_, value, __) => ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: LinearProgressIndicator(
              value: value, minHeight: 5,
              backgroundColor: isDark ? Colors.white.withValues(alpha: 0.06) : AppColors.border.withValues(alpha: 0.5),
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
        ),
      ],
    );
  }
}

// ─── Upcoming ─────────────────────────────────────────────────────────────────

class _UpcomingCard extends StatefulWidget {
  final bool isDark;
  final List<Subscription> subs;
  final List<Debt> overdueDebts;
  final List<PlannedPayment> plannedPayments;
  final List<TransactionPlan> txPlans;

  const _UpcomingCard({
    required this.isDark,
    required this.subs,
    required this.overdueDebts,
    required this.plannedPayments,
    required this.txPlans,
  });

  @override
  State<_UpcomingCard> createState() => _UpcomingCardState();
}

class _UpcomingCardState extends State<_UpcomingCard> with SingleTickerProviderStateMixin {
  late AnimationController _anim;

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(vsync: this, duration: const Duration(milliseconds: 600))..forward();
  }

  @override
  void dispose() {
    _anim.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDark;
    final subs = widget.subs;
    final overdueDebts = widget.overdueDebts;
    final plannedPayments = widget.plannedPayments;
    final txPlans = widget.txPlans;
    final cardBg = isDark ? const Color(0xFF2C2C2A) : Colors.white;
    final borderColor = isDark ? AppColors.border.withValues(alpha: 0.2) : AppColors.border.withValues(alpha: 0.5);
    final divColor = isDark ? AppColors.border.withValues(alpha: 0.2) : AppColors.border.withValues(alpha: 0.4);
    final textPrimary = isDark ? AppColors.primaryForeground : AppColors.textPrimary;
    final rows = <_UpcomingRow>[];

    for (final debt in overdueDebts) {
      rows.add(_UpcomingRow(
        isDark: isDark,
        icon: Icons.warning_amber_rounded,
        iconColor: AppColors.error,
        title: debt.personName,
        subtitle: 'Overdue debt',
        amount: currencyFormatter.format(debt.remainingAmount, decimalDigits: 2),
        amountColor: AppColors.error,
        tag: 'Overdue',
        tagColor: AppColors.error,
      ));
    }

    for (final sub in subs) {
      final days = sub.nextBillingDate.difference(DateTime.now()).inDays;
      final tagText = sub.isOverdue ? 'Overdue' : days == 0 ? 'Today' : '${days}d';
      final tagColor = sub.isOverdue ? AppColors.error : days <= 2 ? AppColors.warning : AppColors.textSecondary;
      rows.add(_UpcomingRow(
        isDark: isDark,
        icon: Icons.autorenew_rounded,
        iconColor: tagColor,
        title: sub.name,
        subtitle: sub.billingCycle.displayName,
        amount: currencyFormatter.format(sub.amount, decimalDigits: 2),
        amountColor: AppColors.error,
        tag: tagText,
        tagColor: tagColor,
      ));
    }

    for (final payment in plannedPayments) {
      final days = payment.nextPaymentDate.difference(DateTime.now()).inDays;
      final tagText = payment.isOverdue ? 'Overdue' : days == 0 ? 'Today' : '${days}d';
      final tagColor = payment.isOverdue ? AppColors.error : days <= 2 ? AppColors.warning : AppColors.textSecondary;
      rows.add(_UpcomingRow(
        isDark: isDark,
        icon: payment.category.icon,
        iconColor: tagColor,
        title: payment.name,
        subtitle: payment.frequency.displayName,
        amount: currencyFormatter.format(payment.amount, decimalDigits: 2),
        amountColor: AppColors.error,
        tag: tagText,
        tagColor: tagColor,
      ));
    }

    for (final plan in txPlans) {
      final days = plan.plannedDate.difference(DateTime.now()).inDays;
      final tagText = plan.isOverdue ? 'Overdue' : plan.isDueToday ? 'Today' : '${days}d';
      final tagColor = plan.isOverdue ? AppColors.error : days <= 2 ? AppColors.warning : AppColors.textSecondary;
      final amountColor = plan.type == TransactionType.income ? AppColors.success : AppColors.error;
      rows.add(_UpcomingRow(
        isDark: isDark,
        icon: Icons.event_note_rounded,
        iconColor: tagColor,
        title: plan.description,
        subtitle: plan.type == TransactionType.income ? 'Planned income' : 'Planned expense',
        amount: currencyFormatter.format(plan.amount, decimalDigits: 2),
        amountColor: amountColor,
        tag: tagText,
        tagColor: tagColor,
      ));
    }

    return Container(
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Upcoming', style: GoogleFonts.dmSans(fontSize: 13, fontWeight: FontWeight.w600, color: textPrimary)),
              Text('Bills, payments & debts', style: GoogleFonts.dmSans(fontSize: 10, color: AppColors.textSecondary)),
            ]),
          ),
          Divider(height: 1, thickness: 0.5, color: divColor),
          if (rows.isEmpty)
            Expanded(
              child: Center(
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  Icon(Icons.check_circle_outline_rounded, size: 28, color: AppColors.textTertiary),
                  const SizedBox(height: 8),
                  Text('All clear', style: GoogleFonts.dmSans(fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.textSecondary)),
                  const SizedBox(height: 2),
                  Text('No upcoming payments', style: GoogleFonts.dmSans(fontSize: 11, color: AppColors.textTertiary)),
                ]),
              ),
            )
          else
            Expanded(
              child: Column(
                children: [
                  for (int i = 0; i < rows.length; i++) ...[
                    _FadeSlideIn(
                      parent: _anim,
                      intervalBegin: (i * 0.15).clamp(0.0, 0.6),
                      intervalEnd: (i * 0.15 + 0.55).clamp(0.0, 1.0),
                      child: rows[i],
                    ),
                    if (i < rows.length - 1)
                      Divider(height: 1, thickness: 0.5, color: divColor, indent: 16, endIndent: 16),
                  ],
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _UpcomingRow extends StatelessWidget {
  final bool isDark;
  final IconData icon;
  final Color iconColor, amountColor, tagColor;
  final String title, subtitle, amount, tag;

  const _UpcomingRow({
    required this.isDark, required this.icon, required this.iconColor,
    required this.title, required this.subtitle, required this.amount,
    required this.amountColor, required this.tag, required this.tagColor,
  });

  @override
  Widget build(BuildContext context) {
    final textPrimary = isDark ? AppColors.primaryForeground : AppColors.textPrimary;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(children: [
        Container(
          width: 32, height: 32,
          decoration: BoxDecoration(color: iconColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
          child: Icon(icon, size: 15, color: iconColor),
        ),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: GoogleFonts.dmSans(fontSize: 13, fontWeight: FontWeight.w500, color: textPrimary), maxLines: 1, overflow: TextOverflow.ellipsis),
          Text(subtitle, style: GoogleFonts.dmSans(fontSize: 11, color: AppColors.textSecondary)),
        ])),
        const SizedBox(width: 12),
        Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Text(amount, style: GoogleFonts.dmMono(fontSize: 13, fontWeight: FontWeight.w600, color: amountColor)),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(color: tagColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(20)),
            child: Text(tag, style: GoogleFonts.dmSans(fontSize: 10, fontWeight: FontWeight.w600, color: tagColor)),
          ),
        ]),
      ]),
    );
  }
}

// ─── Recent Transactions ──────────────────────────────────────────────────────

class _RecentTransactionsCard extends StatefulWidget {
  final bool isDark;
  final List<Transaction> transactions;
  final Map<String, String> profileNames;

  static const _previewCount = 3;

  const _RecentTransactionsCard({required this.isDark, required this.transactions, required this.profileNames});

  @override
  State<_RecentTransactionsCard> createState() => _RecentTransactionsCardState();
}

class _RecentTransactionsCardState extends State<_RecentTransactionsCard> with SingleTickerProviderStateMixin {
  late AnimationController _anim;

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(vsync: this, duration: const Duration(milliseconds: 600))..forward();
  }

  @override
  void dispose() {
    _anim.dispose();
    super.dispose();
  }

  void _openSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _TxDrawer(isDark: widget.isDark, transactions: widget.transactions, profileNames: widget.profileNames),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDark;
    final transactions = widget.transactions;
    final profileNames = widget.profileNames;
    final cardBg = isDark ? const Color(0xFF2C2C2A) : Colors.white;
    final borderColor = isDark ? AppColors.border.withValues(alpha: 0.2) : AppColors.border.withValues(alpha: 0.5);
    final divColor = isDark ? AppColors.border.withValues(alpha: 0.2) : AppColors.border.withValues(alpha: 0.4);
    final textPrimary = isDark ? AppColors.primaryForeground : AppColors.textPrimary;
    final preview = transactions.take(_RecentTransactionsCard._previewCount).toList();
    final hasMore = transactions.length > _RecentTransactionsCard._previewCount;

    return Container(
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
            child: Text('Recent Transactions', style: GoogleFonts.dmSans(fontSize: 13, fontWeight: FontWeight.w600, color: textPrimary)),
          ),
          Divider(height: 1, thickness: 0.5, color: divColor),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (int i = 0; i < preview.length; i++) ...[
                  _FadeSlideIn(
                    parent: _anim,
                    intervalBegin: (i * 0.15).clamp(0.0, 0.6),
                    intervalEnd: (i * 0.15 + 0.55).clamp(0.0, 1.0),
                    child: _TxRow(
                      isDark: isDark,
                      transaction: preview[i],
                      profileName: preview[i].budgetProfileId != null ? profileNames[preview[i].budgetProfileId] : null,
                    ),
                  ),
                  if (i < preview.length - 1)
                    Divider(height: 1, thickness: 0.5, color: divColor, indent: 16, endIndent: 16),
                ],
              ],
            ),
          ),
          Divider(height: 1, thickness: 0.5, color: divColor),
          GestureDetector(
            onTap: () => _openSheet(context),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 11),
              child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                Text(
                  hasMore ? 'View all ${transactions.length}' : 'View transactions',
                  style: GoogleFonts.dmSans(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.accent),
                ),
                const SizedBox(width: 3),
                Icon(Icons.chevron_right_rounded, size: 15, color: AppColors.accent),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

class _TxDrawer extends StatelessWidget {
  final bool isDark;
  final List<Transaction> transactions;
  final Map<String, String> profileNames;

  const _TxDrawer({required this.isDark, required this.transactions, required this.profileNames});

  @override
  Widget build(BuildContext context) {
    final sheetBg = isDark ? const Color(0xFF1E1E1C) : Colors.white;
    final divColor = isDark ? AppColors.border.withValues(alpha: 0.15) : AppColors.border.withValues(alpha: 0.4);
    final textPrimary = isDark ? AppColors.primaryForeground : AppColors.textPrimary;

    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.4,
      maxChildSize: 0.92,
      expand: false,
      builder: (_, controller) => Container(
        decoration: BoxDecoration(
          color: sheetBg,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(children: [
          Container(
            width: 36, height: 4,
            margin: const EdgeInsets.only(top: 12, bottom: 8),
            decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(2)),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 14),
            child: Row(children: [
              Text('Transactions', style: GoogleFonts.dmSans(fontSize: 15, fontWeight: FontWeight.w700, color: textPrimary)),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(color: AppColors.textSecondary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(20)),
                child: Text('${transactions.length}', style: GoogleFonts.dmSans(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
              ),
            ]),
          ),
          Divider(height: 1, thickness: 0.5, color: divColor),
          Expanded(
            child: ListView.separated(
              controller: controller,
              padding: const EdgeInsets.only(bottom: 32),
              itemCount: transactions.length,
              separatorBuilder: (_, __) => Divider(height: 1, thickness: 0.5, color: divColor, indent: 16, endIndent: 16),
              itemBuilder: (_, i) => _TxRow(
                isDark: isDark,
                transaction: transactions[i],
                profileName: transactions[i].budgetProfileId != null ? profileNames[transactions[i].budgetProfileId] : null,
              ),
            ),
          ),
        ]),
      ),
    );
  }
}

class _TxRow extends StatelessWidget {
  final bool isDark;
  final Transaction transaction;
  final String? profileName;

  const _TxRow({required this.isDark, required this.transaction, this.profileName});

  @override
  Widget build(BuildContext context) {
    final t = transaction;
    final isIncome = t.type == TransactionType.income;
    final color = isIncome ? AppColors.success : AppColors.error;
    final sign = isIncome ? '+' : '-';
    final now = DateTime.now();
    final isToday = DateUtils.isSameDay(t.date, now);
    final isYesterday = DateUtils.isSameDay(t.date, now.subtract(const Duration(days: 1)));
    final dateStr = isToday ? 'Today' : isYesterday ? 'Yesterday' : DateFormat('MMM d').format(t.date);
    final textPrimary = isDark ? AppColors.primaryForeground : AppColors.textPrimary;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
      child: Row(children: [
        Container(
          width: 32, height: 32,
          decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
          child: Icon(isIncome ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded, size: 14, color: color),
        ),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(t.description ?? (isIncome ? 'Earns' : 'Pays'),
              style: GoogleFonts.dmSans(fontSize: 13, fontWeight: FontWeight.w500, color: textPrimary), maxLines: 1, overflow: TextOverflow.ellipsis),
          const SizedBox(height: 2),
          Row(children: [
            Text(dateStr, style: GoogleFonts.dmSans(fontSize: 11, color: AppColors.textSecondary)),
            if (profileName != null) ...[
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                decoration: BoxDecoration(
                  color: AppColors.accent.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: AppColors.accent.withValues(alpha: 0.25), width: 0.5),
                ),
                child: Text(profileName!, style: GoogleFonts.dmSans(fontSize: 9, fontWeight: FontWeight.w600, color: AppColors.accent)),
              ),
            ],
          ]),
        ])),
        Text('$sign${currencyFormatter.format(t.totalCost, decimalDigits: 2)}',
            style: GoogleFonts.dmMono(fontSize: 13, fontWeight: FontWeight.w600, color: color, fontFeatures: const [FontFeature.tabularFigures()])),
      ]),
    );
  }
}

// ─── Daily Activity Chart ─────────────────────────────────────────────────────

class _SpendingChart extends StatefulWidget {
  final List<Transaction> transactions;
  final bool isDark;
  const _SpendingChart({required this.transactions, required this.isDark});

  @override
  State<_SpendingChart> createState() => _SpendingChartState();
}

class _SpendingChartState extends State<_SpendingChart> with SingleTickerProviderStateMixin {
  int? _selectedIndex;
  late AnimationController _barAnim;

  @override
  void initState() {
    super.initState();
    _barAnim = AnimationController(vsync: this, duration: const Duration(milliseconds: 700))
      ..forward();
  }

  @override
  void didUpdateWidget(covariant _SpendingChart old) {
    super.didUpdateWidget(old);
    if (old.transactions != widget.transactions) {
      _barAnim.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _barAnim.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final today = now.day;
    final incomeByDay = <int, double>{};
    final expenseByDay = <int, double>{};

    for (final t in widget.transactions) {
      if (t.date.month != now.month || t.date.year != now.year) continue;
      if (t.type == TransactionType.income) {
        incomeByDay[t.date.day] = (incomeByDay[t.date.day] ?? 0) + t.amount;
      } else if (t.type == TransactionType.expense) {
        expenseByDay[t.date.day] = (expenseByDay[t.date.day] ?? 0) + t.amount;
      }
    }

    final incomeValues = List.generate(today, (i) => incomeByDay[i + 1] ?? 0.0);
    final expenseValues = List.generate(today, (i) => expenseByDay[i + 1] ?? 0.0);
    final totalIncome = incomeValues.fold(0.0, (s, v) => s + v);
    final totalExpense = expenseValues.fold(0.0, (s, v) => s + v);
    final net = totalIncome - totalExpense;

    final cardBg = widget.isDark ? const Color(0xFF2C2C2A) : Colors.white;
    final borderColor = widget.isDark
        ? AppColors.border.withValues(alpha: 0.2)
        : AppColors.border.withValues(alpha: 0.5);
    final textPrimary = widget.isDark ? AppColors.primaryForeground : AppColors.textPrimary;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: borderColor, width: 0.5),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Daily Activity',
                  style: GoogleFonts.dmSans(fontSize: 13, fontWeight: FontWeight.w600, color: textPrimary),
                ),
                const SizedBox(height: 2),
                Text(
                  DateFormat('MMMM yyyy').format(now),
                  style: GoogleFonts.dmSans(fontSize: 11, color: AppColors.textSecondary),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                _StatChip(label: 'Inflow', amount: totalIncome, color: AppColors.success, isDark: widget.isDark),
                const SizedBox(width: 8),
                _StatChip(label: 'Outflow', amount: totalExpense, color: AppColors.error, isDark: widget.isDark),
                const SizedBox(width: 8),
                _StatChip(
                  label: 'Net',
                  amount: net.abs(),
                  color: net >= 0 ? AppColors.info : AppColors.warning,
                  isDark: widget.isDark,
                  prefix: net >= 0 ? '+' : '−',
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(children: [
              Container(width: 8, height: 8, decoration: BoxDecoration(color: AppColors.success, shape: BoxShape.circle)),
              const SizedBox(width: 5),
              Text('Income', style: GoogleFonts.dmSans(fontSize: 10, color: AppColors.textSecondary)),
              const SizedBox(width: 12),
              Container(width: 8, height: 8, decoration: BoxDecoration(color: AppColors.error, shape: BoxShape.circle)),
              const SizedBox(width: 5),
              Text('Expense', style: GoogleFonts.dmSans(fontSize: 10, color: AppColors.textSecondary)),
            ]),
            const SizedBox(height: 8),
            SizedBox(
              height: 96,
              child: LayoutBuilder(
                builder: (_, constraints) => GestureDetector(
                  onTapUp: (d) {
                    if (today == 0) return;
                    final i = (d.localPosition.dx / (constraints.maxWidth / today))
                        .floor()
                        .clamp(0, today - 1);
                    setState(() => _selectedIndex = _selectedIndex == i ? null : i);
                  },
                  child: AnimatedBuilder(
                    animation: _barAnim,
                    builder: (_, __) => CustomPaint(
                      size: Size(constraints.maxWidth, 96),
                      painter: _DualBarPainter(
                        income: incomeValues,
                        expense: expenseValues,
                        isDark: widget.isDark,
                        selectedIndex: _selectedIndex,
                        animProgress: _barAnim.value,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 4),
            _XAxisLabels(today: today, isDark: widget.isDark),
            if (_selectedIndex != null) ...[
              const SizedBox(height: 8),
              Row(children: [
                Text(
                  'Day ${_selectedIndex! + 1}  ·  ',
                  style: GoogleFonts.dmSans(fontSize: 11, color: AppColors.textSecondary),
                ),
                Text(
                  'In: ${currencyFormatter.format(incomeValues[_selectedIndex!], decimalDigits: 0)}',
                  style: GoogleFonts.dmSans(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.success),
                ),
                const SizedBox(width: 10),
                Text(
                  'Out: ${currencyFormatter.format(expenseValues[_selectedIndex!], decimalDigits: 0)}',
                  style: GoogleFonts.dmSans(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.error),
                ),
              ]),
            ],
          ],
        ),
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final String label;
  final double amount;
  final Color color;
  final bool isDark;
  final String prefix;

  const _StatChip({
    required this.label,
    required this.amount,
    required this.color,
    required this.isDark,
    this.prefix = '',
  });

  @override
  Widget build(BuildContext context) {
    final bg = isDark ? const Color(0xFF3A3A38) : AppColors.background;
    final border = isDark
        ? AppColors.border.withValues(alpha: 0.2)
        : AppColors.border.withValues(alpha: 0.5);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: border, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label, style: GoogleFonts.dmSans(fontSize: 10, color: AppColors.textSecondary)),
          const SizedBox(height: 2),
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: amount),
            duration: const Duration(milliseconds: 900),
            curve: Curves.easeOutCubic,
            builder: (_, value, __) => Text(
              '$prefix${currencyFormatter.format(value, decimalDigits: 0)}',
              style: GoogleFonts.dmMono(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: color,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Dual Bar Painter ─────────────────────────────────────────────────────────

class _DualBarPainter extends CustomPainter {
  final List<double> income;
  final List<double> expense;
  final bool isDark;
  final int? selectedIndex;

  final double animProgress;

  const _DualBarPainter({
    required this.income,
    required this.expense,
    required this.isDark,
    this.selectedIndex,
    this.animProgress = 1.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final n = income.length;
    if (n == 0) return;
    final maxVal = [...income, ...expense].fold(0.0, max);
    if (maxVal == 0) return;
    const topPad = 4.0;
    final chartH = size.height - topPad;
    final slotW = size.width / n;
    final pairW = (slotW * 0.72).clamp(4.0, 32.0);
    final barW = pairW / 2 - 1;

    final gridPaint = Paint()
      ..color = (isDark ? Colors.white : Colors.black).withValues(alpha: 0.04)
      ..strokeWidth = 0.5;
    for (int i = 1; i <= 3; i++) {
      final y = topPad + chartH * (1 - i / 4);
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    for (int i = 0; i < n; i++) {
      final isSelected = selectedIndex == i;
      final alpha = selectedIndex == null ? 0.7 : (isSelected ? 1.0 : 0.3);
      final x0 = slotW * i + (slotW - pairW) / 2;
      _drawBar(canvas, x0, topPad, chartH, barW, income[i], maxVal, AppColors.success.withValues(alpha: alpha), animProgress);
      _drawBar(canvas, x0 + barW + 2, topPad, chartH, barW, expense[i], maxVal, AppColors.error.withValues(alpha: alpha), animProgress);
    }
  }

  void _drawBar(Canvas canvas, double x, double topPad, double chartH, double barW, double val, double maxVal, Color color, double animProgress) {
    if (val < 0.01) return;
    final h = (val / maxVal) * chartH * animProgress;
    canvas.drawRRect(
      RRect.fromRectAndCorners(
        Rect.fromLTWH(x, topPad + chartH - h, barW, h),
        topLeft: const Radius.circular(3),
        topRight: const Radius.circular(3),
      ),
      Paint()..color = color,
    );
  }

  @override
  bool shouldRepaint(covariant _DualBarPainter old) =>
      old.income != income || old.expense != expense || old.selectedIndex != selectedIndex || old.animProgress != animProgress;
}

// ─── Profile Pills ────────────────────────────────────────────────────────────

class _ProfilePills extends StatelessWidget {
  final List<BudgetProfile> profiles;
  final String? selectedId;
  final void Function(String?) onSelect;
  final bool isDark;

  const _ProfilePills({required this.profiles, required this.selectedId, required this.onSelect, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final sorted = [...profiles]..sort((a, b) {
        if (a.isMain) return -1;
        if (b.isMain) return 1;
        return a.name.compareTo(b.name);
      });
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeOut,
      builder: (_, value, child) => Opacity(
        opacity: value,
        child: Transform.translate(offset: Offset(0, (1 - value) * -6), child: child),
      ),
      child: SizedBox(
      height: 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
        itemCount: sorted.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final profile = sorted[i];
          final isSelected = profile.id == selectedId;
          final pillColor = isSelected
              ? AppColors.accent
              : (isDark ? const Color(0xFF2C2C2A) : Colors.white);
          final textColor = isSelected
              ? Colors.white
              : AppColors.textSecondary;
          final borderColor = isSelected
              ? AppColors.accent
              : (isDark ? AppColors.border.withValues(alpha: 0.2) : AppColors.border.withValues(alpha: 0.5));
          return GestureDetector(
            onTap: () => onSelect(profile.id),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: pillColor,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: borderColor, width: 0.5),
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                if (profile.isMain) ...[
                  Icon(Icons.star_rounded, size: 11, color: isSelected ? Colors.white70 : AppColors.textTertiary),
                  const SizedBox(width: 4),
                ],
                Text(
                  profile.name,
                  style: GoogleFonts.dmSans(fontSize: 12, fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500, color: textColor),
                ),
              ]),
            ),
          );
        },
      ),
    ),
    );
  }
}

// ─── Staggered entrance helper ────────────────────────────────────────────────

class _FadeSlideIn extends StatelessWidget {
  final Widget child;
  final Animation<double> parent;
  final double intervalBegin;
  final double intervalEnd;

  const _FadeSlideIn({
    required this.child,
    required this.parent,
    required this.intervalBegin,
    required this.intervalEnd,
  });

  @override
  Widget build(BuildContext context) {
    final curved = CurvedAnimation(
      parent: parent,
      curve: Interval(intervalBegin, intervalEnd, curve: Curves.easeOut),
    );
    return FadeTransition(
      opacity: curved,
      child: SlideTransition(
        position: Tween<Offset>(begin: const Offset(0, 0.12), end: Offset.zero).animate(curved),
        child: child,
      ),
    );
  }
}

// ─── Insights Entry Card ──────────────────────────────────────────────────────

class _InsightsEntryCard extends StatelessWidget {
  final bool isDark;
  final bool hasBudgets;
  final int transactionCount;
  final String monthLabel;
  final VoidCallback onTap;

  const _InsightsEntryCard({
    required this.isDark,
    required this.hasBudgets,
    required this.transactionCount,
    required this.monthLabel,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cardBg = isDark ? const Color(0xFF2C2C2A) : Colors.white;
    final borderColor = isDark ? AppColors.border.withValues(alpha: 0.2) : AppColors.border.withValues(alpha: 0.5);
    final textPrimary = isDark ? AppColors.primaryForeground : AppColors.textPrimary;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: borderColor, width: 0.5),
          ),
          child: Row(
            children: [
              Container(
                width: 44, height: 44,
                decoration: BoxDecoration(
                  color: AppColors.accent.withValues(alpha: isDark ? 0.15 : 0.08),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.insights_rounded, size: 22, color: AppColors.accent),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Monthly Insights',
                      style: GoogleFonts.dmSans(fontSize: 14, fontWeight: FontWeight.w700, color: textPrimary),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      hasBudgets
                          ? 'Review your budget performance & spending patterns for $monthLabel'
                          : 'Explore your $transactionCount transaction${transactionCount == 1 ? '' : 's'} for $monthLabel',
                      style: GoogleFonts.dmSans(fontSize: 12, color: AppColors.textSecondary, height: 1.4),
                      maxLines: 2,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Icon(Icons.chevron_right_rounded, size: 20, color: AppColors.textTertiary),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Insights View Header ─────────────────────────────────────────────────────

class _InsightsHeader extends StatelessWidget {
  final bool isDark;
  final VoidCallback onBack;

  const _InsightsHeader({required this.isDark, required this.onBack});

  @override
  Widget build(BuildContext context) {
    final textPrimary = isDark ? AppColors.primaryForeground : AppColors.textPrimary;
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 12, 16, 4),
      child: Row(
        children: [
          IconButton(
            icon: Icon(Icons.arrow_back_rounded, size: 20, color: textPrimary),
            onPressed: onBack,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Monthly Insights',
                  style: GoogleFonts.dmSans(fontSize: 17, fontWeight: FontWeight.w700, color: textPrimary),
                ),
                Text(
                  'Spending patterns & budget performance over time',
                  style: GoogleFonts.dmSans(fontSize: 12, color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── X-axis labels ────────────────────────────────────────────────────────────

class _XAxisLabels extends StatelessWidget {
  final int today;
  final bool isDark;
  const _XAxisLabels({required this.today, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final marks = <int>{1};
    for (int d = 5; d <= today; d += 5) marks.add(d);
    if (today > 1) marks.add(today);

    return SizedBox(
      height: 14,
      child: LayoutBuilder(builder: (_, c) {
        final w = c.maxWidth;
        final slotW = w / today;
        return Stack(
          children: marks.map((d) {
            final x = slotW * (d - 1) + slotW / 2;
            return Positioned(
              left: (x - 14).clamp(0.0, w - 28),
              child: SizedBox(
                width: 28,
                child: Text(
                  '$d',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.dmSans(fontSize: 9, color: AppColors.textTertiary),
                ),
              ),
            );
          }).toList(),
        );
      }),
    );
  }
}
