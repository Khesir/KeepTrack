import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:keep_track/core/di/service_locator.dart';
import 'package:keep_track/core/settings/utils/currency_formatter.dart';
import 'package:keep_track/core/state/stream_builder_widget.dart';
import 'package:keep_track/core/theme/app_theme.dart';
import 'package:keep_track/features/auth/presentation/state/auth_controller.dart';
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
  late final AuthController _authController;

  @override
  void initState() {
    super.initState();
    _savingsController = locator.get<SavingsController>();
    _budgetController = locator.get<BudgetController>();
    _txController = locator.get<TransactionController>();
    _subController = locator.get<SubscriptionController>();
    _debtController = locator.get<DebtController>();
    _authController = locator.get<AuthController>();
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
    final user = _authController.currentUser;
    final firstName = user?.displayName?.split(' ').first ?? 'there';

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
                context, isDark, firstName,
                buckets, budgets, txs, debts, subs,
              ),
              loadingBuilder: (_) => _buildDashboard(context, isDark, firstName, buckets, budgets, txs, debts, []),
              errorBuilder: (_, __) => _buildDashboard(context, isDark, firstName, buckets, budgets, txs, debts, []),
            ),
            loadingBuilder: (_) => _buildDashboard(context, isDark, firstName, buckets, budgets, txs, [], []),
            errorBuilder: (_, __) => _buildDashboard(context, isDark, firstName, buckets, budgets, txs, [], []),
          ),
          loadingBuilder: (_) => _buildDashboard(context, isDark, firstName, buckets, budgets, [], [], []),
          errorBuilder: (_, __) => _buildDashboard(context, isDark, firstName, buckets, budgets, [], [], []),
        ),
        loadingBuilder: (_) => _buildDashboard(context, isDark, firstName, buckets, [], [], [], []),
        errorBuilder: (_, __) => _buildDashboard(context, isDark, firstName, buckets, [], [], [], []),
      ),
      loadingBuilder: (_) => const Center(child: CircularProgressIndicator()),
      errorBuilder: (_, __) => const Center(child: CircularProgressIndicator()),
    );
  }

  Widget _buildDashboard(
    BuildContext context, bool isDark, String firstName,
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
    final hasAlerts = overdueDebts.isNotEmpty || (plannedExpenses > 0 && actualExpenses > plannedExpenses);
    final loboAsset = hasAlerts
        ? 'assets/lobo-thinking.svg'
        : (totalSavings > 0 && (plannedExpenses == 0 || actualExpenses < plannedExpenses * 0.7))
            ? 'assets/lobo-happy.svg'
            : 'assets/lobo-waving.svg';

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(child: _GreetingSection(
          isDark: isDark, firstName: firstName,
          totalSavings: totalSavings, bucketCount: buckets.length,
          loboAsset: loboAsset,
        )),
        SliverToBoxAdapter(child: _MetricsRow(
          isDark: isDark,
          actualIncome: actualIncome, plannedIncome: plannedIncome,
          actualExpenses: actualExpenses, plannedExpenses: plannedExpenses,
          netDebt: totalReceivables - totalDebt,
        )),
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

// ─── Greeting Section (Lobo outside card) ────────────────────────────────────

class _GreetingSection extends StatelessWidget {
  final bool isDark;
  final String firstName, loboAsset;
  final double totalSavings;
  final int bucketCount;

  const _GreetingSection({
    required this.isDark, required this.firstName, required this.loboAsset,
    required this.totalSavings, required this.bucketCount,
  });

  String get _greeting {
    final h = DateTime.now().hour;
    if (h < 12) return 'Good morning';
    if (h < 17) return 'Good afternoon';
    return 'Good evening';
  }

  String _message(String name) =>
      '$_greeting, $name! Today is ${DateFormat('EEEE, MMMM d').format(DateTime.now())}. '
      'Hope your day is going well. Keep tracking your spending, grow those savings buckets, '
      'and stay ahead of your bills — every peso tracked is a step closer to financial freedom! 💪';

  @override
  Widget build(BuildContext context) {
    final cardBg = isDark ? const Color(0xFF2C2C2A) : Colors.white;
    final cardBorder = isDark ? AppColors.border.withValues(alpha: 0.2) : AppColors.border.withValues(alpha: 0.5);
    final msgColor = isDark ? AppColors.primaryForeground.withValues(alpha: 0.8) : AppColors.textSecondary;

    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 16, 0, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Lobo + bubble row — Lobo on scaffold background, bubble to the right
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Padding(
                  padding: const EdgeInsets.only(left: 12),
                  child: SvgPicture.asset(loboAsset, height: 110),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: CustomPaint(
                    painter: _BubblePainter(color: cardBg, borderColor: cardBorder),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(18, 14, 14, 14),
                      child: Text(
                        _message(firstName),
                        style: GoogleFonts.dmSans(
                            fontSize: 12.5,
                            color: msgColor,
                            height: 1.65),
                        maxLines: 5,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          // Savings hero — full-width card
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Container(
              padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: cardBorder, width: 0.5),
              ),
              child: Row(
                children: [
                  Container(
                    width: 40, height: 40,
                    decoration: BoxDecoration(
                      color: AppColors.success.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(Icons.savings_outlined, size: 20, color: AppColors.success),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Total Savings',
                            style: GoogleFonts.dmSans(
                                fontSize: 11,
                                color: AppColors.textSecondary,
                                fontWeight: FontWeight.w500)),
                        const SizedBox(height: 3),
                        Text(
                          currencyFormatter.format(totalSavings, decimalDigits: 2),
                          style: GoogleFonts.dmMono(
                              fontSize: 24,
                              fontWeight: FontWeight.w600,
                              color: AppColors.success,
                              letterSpacing: -0.5,
                              fontFeatures: const [FontFeature.tabularFigures()]),
                        ),
                      ],
                    ),
                  ),
                  if (bucketCount > 0)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: AppColors.success.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '$bucketCount bucket${bucketCount == 1 ? '' : 's'}',
                        style: GoogleFonts.dmSans(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: AppColors.success),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BubblePainter extends CustomPainter {
  final Color color;
  final Color borderColor;

  const _BubblePainter({required this.color, required this.borderColor});

  @override
  void paint(Canvas canvas, Size size) {
    const r = 12.0;
    const tailW = 11.0;
    const tailH = 10.0;
    const tailY = 26.0;

    Path buildPath() => Path()
      ..moveTo(tailW + r, 0)
      ..lineTo(size.width - r, 0)
      ..arcToPoint(Offset(size.width, r), radius: const Radius.circular(r))
      ..lineTo(size.width, size.height - r)
      ..arcToPoint(Offset(size.width - r, size.height), radius: const Radius.circular(r))
      ..lineTo(tailW + r, size.height)
      ..arcToPoint(Offset(tailW, size.height - r), radius: const Radius.circular(r))
      ..lineTo(tailW, tailY + tailH)
      ..lineTo(0, tailY + tailH / 2)
      ..lineTo(tailW, tailY)
      ..lineTo(tailW, r)
      ..arcToPoint(Offset(tailW + r, 0), radius: const Radius.circular(r))
      ..close();

    final path = buildPath();
    canvas.drawPath(path, Paint()..color = color..style = PaintingStyle.fill);
    canvas.drawPath(path, Paint()
      ..color = borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.5);
  }

  @override
  bool shouldRepaint(covariant _BubblePainter old) =>
      old.color != color || old.borderColor != borderColor;
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
            isDark: isDark, label: 'Income',
            value: currencyFormatter.format(actualIncome, decimalDigits: 0),
            sub: 'of ${currencyFormatter.format(plannedIncome, decimalDigits: 0)} planned',
            color: AppColors.success, icon: Icons.arrow_downward_rounded,
          )),
          const SizedBox(width: 10),
          Expanded(child: _MetricCard(
            isDark: isDark, label: 'Expenses',
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
              isDark: isDark, label: 'Expenses',
              actual: actualExpenses, planned: plannedExpenses,
              progress: expenseProgress, color: expenseColor,
              icon: Icons.arrow_upward_rounded,
            ),
            const SizedBox(height: 14),
            _ProgressRow(
              isDark: isDark, label: 'Income',
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
