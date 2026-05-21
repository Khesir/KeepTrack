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
import 'package:keep_track/features/finance/modules/debt/domain/entities/debt.dart';
import 'package:keep_track/features/finance/modules/savings/domain/entities/savings_bucket.dart';
import 'package:keep_track/features/finance/modules/subscriptions/domain/entities/subscription.dart';
import 'package:keep_track/features/finance/modules/transaction/domain/entities/transaction.dart';
import 'package:keep_track/features/finance/presentation/state/debt_controller.dart';
import 'package:keep_track/features/finance/presentation/state/savings_controller.dart';
import 'package:keep_track/features/finance/presentation/state/subscription_controller.dart';
import 'package:keep_track/features/finance/presentation/state/transaction_controller.dart';

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

  @override
  void initState() {
    super.initState();
    _savingsController = locator.get<SavingsController>();
    _budgetController = locator.get<BudgetController>();
    _txController = locator.get<TransactionController>();
    _subController = locator.get<SubscriptionController>();
    _debtController = locator.get<DebtController>();
    _savingsController.loadSavings();
    _budgetController.loadBudgets();
    final now = DateTime.now();
    _txController.loadTransactionsByDateRange(
      DateTime(now.year, now.month, 1),
      DateTime(now.year, now.month + 1, 1),
    );
  }

  String get _monthKey {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

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
              builder: (_, subs) => _buildDashboard(
                context, isDark,
                buckets, budgets, txs, debts, subs,
              ),
              loadingBuilder: (_) => _buildDashboard(context, isDark, buckets, budgets, txs, debts, []),
              errorBuilder: (_, __) => _buildDashboard(context, isDark, buckets, budgets, txs, debts, []),
            ),
            loadingBuilder: (_) => _buildDashboard(context, isDark, buckets, budgets, txs, [], []),
            errorBuilder: (_, __) => _buildDashboard(context, isDark, buckets, budgets, txs, [], []),
          ),
          loadingBuilder: (_) => _buildDashboard(context, isDark, buckets, budgets, [], [], []),
          errorBuilder: (_, __) => _buildDashboard(context, isDark, buckets, budgets, [], [], []),
        ),
        loadingBuilder: (_) => _buildDashboard(context, isDark, buckets, [], [], [], []),
        errorBuilder: (_, __) => _buildDashboard(context, isDark, buckets, [], [], [], []),
      ),
      loadingBuilder: (_) => const Center(child: CircularProgressIndicator()),
      errorBuilder: (_, __) => const Center(child: CircularProgressIndicator()),
    );
  }

  Widget _buildDashboard(
    BuildContext context, bool isDark,
    List<SavingsBucket> buckets, List<Budget> budgets,
    List<Transaction> txs, List<Debt> debts, List<Subscription> subs,
  ) {
    final spentByCategory = BudgetMonthFilter.buildSpentByCategory(txs);
    final monthBudgets = budgets.where((b) => b.month == _monthKey && b.status == BudgetStatus.active).toList();
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

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(child: _MetricsRow(
          isDark: isDark,
          actualIncome: actualIncome, plannedIncome: plannedIncome,
          actualExpenses: actualExpenses, plannedExpenses: plannedExpenses,
          netDebt: totalReceivables - totalDebt,
        )),
        SliverToBoxAdapter(child: _SpendingChart(transactions: txs, isDark: isDark)),
        if (monthBudgets.isNotEmpty)
          SliverToBoxAdapter(child: _BudgetProgressCard(
            isDark: isDark,
            actualExpenses: actualExpenses, plannedExpenses: plannedExpenses,
            actualIncome: actualIncome, plannedIncome: plannedIncome,
          )),
        if (upcomingSubs.isNotEmpty || overdueDebts.isNotEmpty)
          SliverToBoxAdapter(child: _UpcomingCard(
            isDark: isDark,
            subs: upcomingSubs.take(3).toList(),
            overdueDebts: overdueDebts.take(2).toList(),
          )),
        if (txs.isNotEmpty)
          SliverToBoxAdapter(child: _RecentTransactionsCard(
            isDark: isDark,
            transactions: (List.of(txs)..sort((a, b) => b.date.compareTo(a.date))).take(5).toList(),
          )),
        const SliverToBoxAdapter(child: SizedBox(height: 32)),
      ],
    );
  }
}

// ─── Metrics Row ──────────────────────────────────────────────────────────────

class _MetricsRow extends StatelessWidget {
  final bool isDark;
  final double actualIncome, plannedIncome, actualExpenses, plannedExpenses, netDebt;

  const _MetricsRow({
    required this.isDark, required this.actualIncome, required this.plannedIncome,
    required this.actualExpenses, required this.plannedExpenses, required this.netDebt,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Row(
        children: [
          Expanded(child: _MetricCard(
            isDark: isDark, label: 'Inflow',
            value: currencyFormatter.format(actualIncome, decimalDigits: 0),
            sub: 'of ${currencyFormatter.format(plannedIncome, decimalDigits: 0)} planned',
            color: AppColors.success, icon: Icons.arrow_downward_rounded,
          )),
          const SizedBox(width: 10),
          Expanded(child: _MetricCard(
            isDark: isDark, label: 'Outflow',
            value: currencyFormatter.format(actualExpenses, decimalDigits: 0),
            sub: 'of ${currencyFormatter.format(plannedExpenses, decimalDigits: 0)} planned',
            color: actualExpenses > plannedExpenses && plannedExpenses > 0 ? AppColors.error : AppColors.error,
            icon: Icons.arrow_upward_rounded,
          )),
          const SizedBox(width: 10),
          Expanded(child: _MetricCard(
            isDark: isDark, label: 'Net Debt',
            value: currencyFormatter.format(netDebt.abs(), decimalDigits: 0),
            sub: netDebt >= 0 ? 'owed to you' : 'you owe',
            color: netDebt >= 0 ? AppColors.info : AppColors.warning,
            icon: Icons.swap_horiz_rounded,
          )),
        ],
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  final bool isDark;
  final String label, value, sub;
  final Color color;
  final IconData icon;

  const _MetricCard({required this.isDark, required this.label, required this.value, required this.sub, required this.color, required this.icon});

  @override
  Widget build(BuildContext context) {
    final cardBg = isDark ? const Color(0xFF2C2C2A) : Colors.white;
    final borderColor = isDark ? AppColors.border.withValues(alpha: 0.2) : AppColors.border.withValues(alpha: 0.5);
    final textPrimary = isDark ? AppColors.primaryForeground : AppColors.textPrimary;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Container(
              width: 26, height: 26,
              decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(7)),
              child: Icon(icon, size: 13, color: color),
            ),
            const SizedBox(width: 6),
            Expanded(child: Text(label, style: GoogleFonts.dmSans(fontSize: 11, color: AppColors.textSecondary, fontWeight: FontWeight.w500), overflow: TextOverflow.ellipsis)),
          ]),
          const SizedBox(height: 10),
          Text(value, style: GoogleFonts.dmMono(fontSize: 14, fontWeight: FontWeight.w600, color: textPrimary, fontFeatures: const [FontFeature.tabularFigures()]), maxLines: 1, overflow: TextOverflow.ellipsis),
          const SizedBox(height: 2),
          Text(sub, style: GoogleFonts.dmSans(fontSize: 10, color: AppColors.textSecondary), maxLines: 1, overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }
}

// ─── Budget Progress ──────────────────────────────────────────────────────────

class _BudgetProgressCard extends StatelessWidget {
  final bool isDark;
  final double actualExpenses, plannedExpenses, actualIncome, plannedIncome;

  const _BudgetProgressCard({
    required this.isDark, required this.actualExpenses, required this.plannedExpenses,
    required this.actualIncome, required this.plannedIncome,
  });

  @override
  Widget build(BuildContext context) {
    final cardBg = isDark ? const Color(0xFF2C2C2A) : Colors.white;
    final borderColor = isDark ? AppColors.border.withValues(alpha: 0.2) : AppColors.border.withValues(alpha: 0.5);
    final textPrimary = isDark ? AppColors.primaryForeground : AppColors.textPrimary;
    final now = DateTime.now();
    final daysInMonth = DateUtils.getDaysInMonth(now.year, now.month);
    final daysPassed = now.day;
    final monthProgress = daysPassed / daysInMonth;
    final expenseProgress = plannedExpenses > 0 ? (actualExpenses / plannedExpenses).clamp(0.0, 1.0) : 0.0;
    final incomeProgress = plannedIncome > 0 ? (actualIncome / plannedIncome).clamp(0.0, 1.0) : 0.0;
    final isOverBudget = plannedExpenses > 0 && actualExpenses > plannedExpenses;
    final expenseColor = isOverBudget ? AppColors.error : AppColors.accent;

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
                Text('This Month', style: GoogleFonts.dmSans(fontSize: 13, fontWeight: FontWeight.w600, color: textPrimary)),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.border.withValues(alpha: 0.2) : AppColors.background,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(DateFormat('MMMM yyyy').format(now),
                      style: GoogleFonts.dmSans(fontSize: 11, color: AppColors.textSecondary, fontWeight: FontWeight.w500)),
                ),
              ],
            ),
            const SizedBox(height: 18),
            _ProgressRow(
              isDark: isDark, label: 'Outflow',
              actual: actualExpenses, planned: plannedExpenses,
              progress: expenseProgress, color: expenseColor,
              icon: Icons.arrow_upward_rounded,
            ),
            const SizedBox(height: 14),
            _ProgressRow(
              isDark: isDark, label: 'Inflow',
              actual: actualIncome, planned: plannedIncome,
              progress: incomeProgress, color: AppColors.success,
              icon: Icons.arrow_downward_rounded,
            ),
            const SizedBox(height: 16),
            Row(children: [
              Expanded(child: ClipRRect(
                borderRadius: BorderRadius.circular(2),
                child: LinearProgressIndicator(
                  value: monthProgress, minHeight: 2,
                  backgroundColor: isDark ? Colors.white.withValues(alpha: 0.08) : AppColors.border,
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.textTertiary),
                ),
              )),
              const SizedBox(width: 8),
              Text('Day $daysPassed of $daysInMonth',
                  style: GoogleFonts.dmSans(fontSize: 10, color: AppColors.textSecondary)),
            ]),
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
        ClipRRect(
          borderRadius: BorderRadius.circular(3),
          child: LinearProgressIndicator(
            value: progress, minHeight: 5,
            backgroundColor: isDark ? Colors.white.withValues(alpha: 0.06) : AppColors.border.withValues(alpha: 0.5),
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
      ],
    );
  }
}

// ─── Upcoming ─────────────────────────────────────────────────────────────────

class _UpcomingCard extends StatelessWidget {
  final bool isDark;
  final List<Subscription> subs;
  final List<Debt> overdueDebts;

  const _UpcomingCard({required this.isDark, required this.subs, required this.overdueDebts});

  @override
  Widget build(BuildContext context) {
    final cardBg = isDark ? const Color(0xFF2C2C2A) : Colors.white;
    final borderColor = isDark ? AppColors.border.withValues(alpha: 0.2) : AppColors.border.withValues(alpha: 0.5);
    final divColor = isDark ? AppColors.border.withValues(alpha: 0.2) : AppColors.border.withValues(alpha: 0.4);
    final textPrimary = isDark ? AppColors.primaryForeground : AppColors.textPrimary;
    final items = <Widget>[];

    for (final debt in overdueDebts) {
      items.add(_UpcomingRow(
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
      items.add(_UpcomingRow(
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

    if (items.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Container(
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
              child: Text('Upcoming', style: GoogleFonts.dmSans(fontSize: 13, fontWeight: FontWeight.w600, color: textPrimary)),
            ),
            Divider(height: 1, thickness: 0.5, color: divColor),
            ...items.expand((w) => [w, Divider(height: 1, thickness: 0.5, color: divColor, indent: 16, endIndent: 16)]).toList()
              ..removeLast(),
            const SizedBox(height: 4),
          ],
        ),
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

class _RecentTransactionsCard extends StatelessWidget {
  final bool isDark;
  final List<Transaction> transactions;

  const _RecentTransactionsCard({required this.isDark, required this.transactions});

  @override
  Widget build(BuildContext context) {
    final cardBg = isDark ? const Color(0xFF2C2C2A) : Colors.white;
    final borderColor = isDark ? AppColors.border.withValues(alpha: 0.2) : AppColors.border.withValues(alpha: 0.5);
    final divColor = isDark ? AppColors.border.withValues(alpha: 0.2) : AppColors.border.withValues(alpha: 0.4);
    final textPrimary = isDark ? AppColors.primaryForeground : AppColors.textPrimary;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Container(
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
            ...transactions.expand((t) => [
              _TxRow(isDark: isDark, transaction: t),
              Divider(height: 1, thickness: 0.5, color: divColor, indent: 16, endIndent: 16),
            ]).toList()..removeLast(),
            const SizedBox(height: 4),
          ],
        ),
      ),
    );
  }
}

class _TxRow extends StatelessWidget {
  final bool isDark;
  final Transaction transaction;

  const _TxRow({required this.isDark, required this.transaction});

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
          Text(t.description ?? (isIncome ? 'Income' : 'Expense'),
              style: GoogleFonts.dmSans(fontSize: 13, fontWeight: FontWeight.w500, color: textPrimary), maxLines: 1, overflow: TextOverflow.ellipsis),
          Text(dateStr, style: GoogleFonts.dmSans(fontSize: 11, color: AppColors.textSecondary)),
        ])),
        Text('$sign${currencyFormatter.format(t.totalCost, decimalDigits: 2)}',
            style: GoogleFonts.dmMono(fontSize: 13, fontWeight: FontWeight.w600, color: color, fontFeatures: const [FontFeature.tabularFigures()])),
      ]),
    );
  }
}

// ─── Spending / Income Chart ──────────────────────────────────────────────────

class _SpendingChart extends StatefulWidget {
  final List<Transaction> transactions;
  final bool isDark;
  const _SpendingChart({required this.transactions, required this.isDark});

  @override
  State<_SpendingChart> createState() => _SpendingChartState();
}

class _SpendingChartState extends State<_SpendingChart> {
  bool _showExpenses = true;
  int? _selectedIndex;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final today = now.day;

    final byDay = <int, double>{};
    for (final t in widget.transactions) {
      if (t.date.month != now.month || t.date.year != now.year) continue;
      final isExpense = t.type == TransactionType.expense;
      if (_showExpenses != isExpense) continue;
      byDay[t.date.day] = (byDay[t.date.day] ?? 0) + t.amount;
    }

    final values = List.generate(today, (i) => byDay[i + 1] ?? 0.0);
    final total = values.fold(0.0, (s, v) => s + v);
    final color = _showExpenses ? AppColors.error : AppColors.success;
    final cardBg = widget.isDark ? const Color(0xFF2C2C2A) : Colors.white;
    final borderColor = widget.isDark
        ? AppColors.border.withValues(alpha: 0.2)
        : AppColors.border.withValues(alpha: 0.5);
    final fg = widget.isDark ? AppColors.primaryForeground : AppColors.textPrimary;

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
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(
                      _showExpenses ? 'Outflow' : 'Inflow',
                      style: GoogleFonts.dmSans(fontSize: 11, color: AppColors.textSecondary, fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      currencyFormatter.format(total, decimalDigits: 0),
                      style: GoogleFonts.dmMono(
                        fontSize: 22, fontWeight: FontWeight.w700, color: color,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                    if (_selectedIndex != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 3),
                        child: Text(
                          'Day ${_selectedIndex! + 1}  ·  ${currencyFormatter.format(values[_selectedIndex!], decimalDigits: 2)}',
                          style: GoogleFonts.dmSans(fontSize: 11, color: AppColors.textSecondary),
                        ),
                      ),
                  ]),
                ),
                _ChartToggle(
                  showExpenses: _showExpenses,
                  isDark: widget.isDark,
                  onToggle: (v) => setState(() { _showExpenses = v; _selectedIndex = null; }),
                ),
              ],
            ),
            const SizedBox(height: 18),
            SizedBox(
              height: 96,
              child: _BarChart(
                values: values,
                color: color,
                isDark: widget.isDark,
                selectedIndex: _selectedIndex,
                onTap: (i) => setState(() => _selectedIndex = _selectedIndex == i ? null : i),
              ),
            ),
            const SizedBox(height: 4),
            _XAxisLabels(today: today, isDark: widget.isDark),
          ],
        ),
      ),
    );
  }
}

// ─── Toggle ───────────────────────────────────────────────────────────────────

class _ChartToggle extends StatelessWidget {
  final bool showExpenses;
  final bool isDark;
  final void Function(bool) onToggle;

  const _ChartToggle({required this.showExpenses, required this.isDark, required this.onToggle});

  @override
  Widget build(BuildContext context) {
    final trackBg = isDark ? const Color(0xFF3A3A38) : const Color(0xFFF0F0EE);
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(color: trackBg, borderRadius: BorderRadius.circular(10)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        _ToggleChip(label: 'Outflow', selected: showExpenses, color: AppColors.error, isDark: isDark, onTap: () => onToggle(true)),
        _ToggleChip(label: 'Inflow', selected: !showExpenses, color: AppColors.success, isDark: isDark, onTap: () => onToggle(false)),
      ]),
    );
  }
}

class _ToggleChip extends StatelessWidget {
  final String label;
  final bool selected;
  final Color color;
  final bool isDark;
  final VoidCallback onTap;

  const _ToggleChip({required this.label, required this.selected, required this.color, required this.isDark, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? (isDark ? const Color(0xFF2C2C2A) : Colors.white) : Colors.transparent,
          borderRadius: BorderRadius.circular(7),
          boxShadow: selected
              ? [BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 4, offset: const Offset(0, 1))]
              : [],
        ),
        child: Text(
          label,
          style: GoogleFonts.dmSans(
            fontSize: 11,
            fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
            color: selected ? color : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}

// ─── Bar chart ────────────────────────────────────────────────────────────────

class _BarChart extends StatelessWidget {
  final List<double> values;
  final Color color;
  final bool isDark;
  final int? selectedIndex;
  final void Function(int) onTap;

  const _BarChart({required this.values, required this.color, required this.isDark, required this.onTap, this.selectedIndex});

  @override
  Widget build(BuildContext context) {
    if (values.isEmpty) {
      return Center(child: Text('No data yet', style: GoogleFonts.dmSans(fontSize: 12, color: AppColors.textTertiary)));
    }
    return LayoutBuilder(builder: (_, constraints) {
      final w = constraints.maxWidth;
      return GestureDetector(
        onTapUp: (d) {
          final i = (d.localPosition.dx / (w / values.length)).floor().clamp(0, values.length - 1);
          onTap(i);
        },
        child: CustomPaint(
          size: Size(w, constraints.maxHeight),
          painter: _BarPainter(values: values, color: color, isDark: isDark, selectedIndex: selectedIndex),
        ),
      );
    });
  }
}

class _BarPainter extends CustomPainter {
  final List<double> values;
  final Color color;
  final bool isDark;
  final int? selectedIndex;

  const _BarPainter({required this.values, required this.color, required this.isDark, this.selectedIndex});

  @override
  void paint(Canvas canvas, Size size) {
    if (values.isEmpty) return;
    final maxVal = values.fold(0.0, max);
    const topPad = 6.0;
    final chartH = size.height - topPad;
    final n = values.length;
    final slotW = size.width / n;
    final barW = (slotW * 0.52).clamp(2.0, 16.0);

    // Subtle grid
    final gridPaint = Paint()
      ..color = (isDark ? Colors.white : Colors.black).withValues(alpha: 0.04)
      ..strokeWidth = 0.5;
    for (int i = 1; i <= 3; i++) {
      final y = topPad + chartH * (1 - i / 4);
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    if (maxVal == 0) return;

    for (int i = 0; i < n; i++) {
      final val = values[i];
      final isSelected = selectedIndex == i;
      final x = slotW * i + (slotW - barW) / 2;

      if (val <= 0) {
        canvas.drawRRect(
          RRect.fromRectAndRadius(Rect.fromLTWH(x, size.height - 2, barW, 2), const Radius.circular(1)),
          Paint()..color = color.withValues(alpha: 0.1),
        );
        continue;
      }

      final barH = (val / maxVal) * chartH;
      final y = topPad + chartH - barH;

      canvas.drawRRect(
        RRect.fromRectAndCorners(
          Rect.fromLTWH(x, y, barW, barH),
          topLeft: const Radius.circular(5),
          topRight: const Radius.circular(5),
        ),
        Paint()..color = isSelected ? color : color.withValues(alpha: 0.55),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _BarPainter old) =>
      old.values != values || old.selectedIndex != selectedIndex || old.color != color;
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
