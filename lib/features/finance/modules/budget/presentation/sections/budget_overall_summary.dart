import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:keep_track/core/settings/utils/currency_formatter.dart';
import 'package:keep_track/core/theme/app_theme.dart';
import 'package:keep_track/features/finance/modules/budget/domain/entities/budget.dart';
import 'package:keep_track/features/finance/modules/debt/domain/entities/debt.dart';
import 'package:keep_track/features/finance/modules/goal/domain/entities/goal.dart';
import 'package:keep_track/features/finance/modules/subscriptions/domain/entities/subscription.dart';
import 'package:keep_track/features/finance/modules/transaction/domain/entities/transaction.dart';

class BudgetOverallSummary extends StatelessWidget {
  final List<Budget> monthBudgets;
  final Map<String, double> spentByCategory;
  final List<Subscription> subscriptions;
  final List<Debt> debts;
  final List<Debt> receivables;
  final List<Goal> goals;
  final List<Transaction> transactions;
  final DateTime currentMonth;
  final bool isDark;

  const BudgetOverallSummary({
    super.key,
    required this.monthBudgets,
    required this.spentByCategory,
    required this.subscriptions,
    required this.debts,
    required this.receivables,
    required this.goals,
    required this.transactions,
    required this.currentMonth,
    required this.isDark,
  });

  // ── Planned ───────────────────────────────────────────────────────────────

  double get _plannedIncome => _sumBudgets(BudgetType.income, (b) => b.budgetTarget);
  double get _plannedExpenses => _sumBudgets(BudgetType.expense, (b) => b.budgetTarget);

  double get _subCostPlanned => subscriptions
      .where((s) => s.status != SubscriptionStatus.cancelled)
      .fold(0.0, (s, sub) => s + sub.monthlyEquivalent);

  double get _debtPaymentsPlanned => debts
      .where((d) => d.status == DebtStatus.active)
      .fold(0.0, (s, d) => s + d.monthlyPaymentAmount);

  double get _receivablePlanned => receivables
      .where((d) => d.status == DebtStatus.active && d.monthlyPaymentAmount > 0)
      .fold(0.0, (s, d) => s + d.monthlyPaymentAmount);

  double get _goalPlanned => goals
      .where((g) => g.status == GoalStatus.active && g.monthlyContribution > 0)
      .fold(0.0, (s, g) => s + g.monthlyContribution);

  // ── Actual ────────────────────────────────────────────────────────────────

  double _groupSpent(Budget b) => b.categories.fold(
        0.0, (s, c) => s + (spentByCategory[c.financeCategoryId] ?? 0.0));

  double get _actualIncome => _sumBudgets(BudgetType.income, _groupSpent);
  double get _actualExpenses => _sumBudgets(BudgetType.expense, _groupSpent);

  double get _subsActual => subscriptions
      .where((s) =>
          s.status != SubscriptionStatus.cancelled &&
          s.lastBilledDate != null &&
          s.lastBilledDate!.year == currentMonth.year &&
          s.lastBilledDate!.month == currentMonth.month)
      .fold(0.0, (s, sub) => s + sub.amount);

  int get _subsPaidCount => subscriptions
      .where((s) =>
          s.status != SubscriptionStatus.cancelled &&
          s.lastBilledDate != null &&
          s.lastBilledDate!.year == currentMonth.year &&
          s.lastBilledDate!.month == currentMonth.month)
      .length;

  int get _subsTotalCount =>
      subscriptions.where((s) => s.status != SubscriptionStatus.cancelled).length;

  double get _debtPaymentsActual {
    final borrowingIds = debts.map((d) => d.id).whereType<String>().toSet();
    return transactions
        .where((t) => t.debtId != null && borrowingIds.contains(t.debtId))
        .fold(0.0, (s, t) => s + t.amount);
  }

  double get _receivableActual {
    final lendingIds = receivables.map((d) => d.id).whereType<String>().toSet();
    return transactions
        .where((t) => t.debtId != null && lendingIds.contains(t.debtId))
        .fold(0.0, (s, t) => s + t.amount);
  }

  double get _goalActual => transactions
      .where((t) => t.goalId != null)
      .fold(0.0, (s, t) => s + t.amount);

  // ── Totals ────────────────────────────────────────────────────────────────

  double get _totalInPlanned => _plannedIncome + _receivablePlanned;
  double get _totalOutPlanned => _plannedExpenses + _subCostPlanned + _debtPaymentsPlanned + _goalPlanned;
  double get _netPlanned => _totalInPlanned - _totalOutPlanned;

  double get _totalInActual => _actualIncome + _receivableActual;
  double get _totalOutActual => _actualExpenses + _subsActual + _debtPaymentsActual + _goalActual;
  double get _netActual => _totalInActual - _totalOutActual;

  double _sumBudgets(BudgetType type, double Function(Budget) fn) =>
      monthBudgets.where((b) => b.budgetType == type).fold(0.0, (s, b) => s + fn(b));

  @override
  Widget build(BuildContext context) {
    final textPrimary = isDark ? AppColors.primaryForeground : AppColors.textPrimary;
    final cardColor = isDark ? const Color(0xFF2C2C2A) : Colors.white;
    final borderColor = AppColors.border.withValues(alpha: isDark ? 0.15 : 0.4);
    final headerBg = isDark ? Colors.white.withValues(alpha: 0.04) : AppColors.background;

    final hasIncome = _plannedIncome > 0 || _actualIncome > 0;
    final hasSubs = _subCostPlanned > 0;
    final hasDebts = _debtPaymentsPlanned > 0;
    final hasReceivables = _receivablePlanned > 0;
    final hasGoals = _goalPlanned > 0;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
      child: Container(
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: borderColor, width: 0.5),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Column header ─────────────────────────────────────────────
            Container(
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
              decoration: BoxDecoration(
                color: headerBg,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(11)),
                border: Border(bottom: BorderSide(color: borderColor, width: 0.5)),
              ),
              child: Row(children: [
                const Expanded(child: SizedBox()),
                _ColLabel('PLANNED'),
                const SizedBox(width: 16),
                _ColLabel('ACTUAL'),
              ]),
            ),

            // ── INFLOWS group ─────────────────────────────────────────────
            _GroupLabel(label: 'INFLOWS', color: AppColors.success, borderColor: borderColor),

            if (hasIncome)
              _TableRow(
                label: 'Budget Income',
                planned: _plannedIncome,
                actual: _actualIncome,
                actualOverColor: null,
                textPrimary: textPrimary,
                borderColor: borderColor,
              ),

            if (hasReceivables)
              _TableRow(
                label: 'Receivables',
                sublabel: '${receivables.where((d) => d.status == DebtStatus.active && d.monthlyPaymentAmount > 0).length} expected',
                planned: _receivablePlanned,
                actual: _receivableActual,
                textPrimary: textPrimary,
                borderColor: borderColor,
              ),

            // ── OUTFLOWS group ────────────────────────────────────────────
            _GroupLabel(label: 'OUTFLOWS', color: AppColors.error, borderColor: borderColor, topBorder: true),

            _TableRow(
              label: 'Budget Expenses',
              planned: _plannedExpenses,
              actual: _actualExpenses,
              actualOverColor: _actualExpenses > _plannedExpenses ? AppColors.error : null,
              textPrimary: textPrimary,
              borderColor: borderColor,
            ),

            if (hasSubs)
              _TableRow(
                label: 'Subscriptions',
                sublabel: '$_subsPaidCount / $_subsTotalCount paid this month',
                planned: _subCostPlanned,
                actual: _subsActual,
                textPrimary: textPrimary,
                borderColor: borderColor,
              ),

            if (hasDebts)
              _TableRow(
                label: 'Debt Payments',
                sublabel: '${debts.where((d) => d.status == DebtStatus.active && d.monthlyPaymentAmount > 0).length} active',
                planned: _debtPaymentsPlanned,
                actual: _debtPaymentsActual,
                textPrimary: textPrimary,
                borderColor: borderColor,
              ),

            if (hasGoals)
              _TableRow(
                label: 'Goal Contributions',
                sublabel: '${goals.where((g) => g.status == GoalStatus.active && g.monthlyContribution > 0).length} goals',
                planned: _goalPlanned,
                actual: _goalActual,
                textPrimary: textPrimary,
                borderColor: borderColor,
              ),

            // ── NET footer ────────────────────────────────────────────────
            Container(
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
              decoration: BoxDecoration(
                color: headerBg,
                borderRadius: const BorderRadius.vertical(bottom: Radius.circular(11)),
                border: Border(top: BorderSide(color: borderColor, width: 0.5)),
              ),
              child: Row(children: [
                Expanded(
                  child: Text('NET',
                    style: GoogleFonts.dmSans(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.textSecondary, letterSpacing: 0.6)),
                ),
                _AmountCell(
                  value: _netPlanned,
                  color: _netPlanned >= 0 ? AppColors.success : AppColors.error,
                  bold: true,
                ),
                const SizedBox(width: 16),
                _AmountCell(
                  value: _netActual,
                  color: _netActual >= 0 ? AppColors.success : AppColors.error,
                  bold: true,
                ),
              ]),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Sub-widgets ───────────────────────────────────────────────────────────────

class _ColLabel extends StatelessWidget {
  final String text;
  const _ColLabel(this.text);

  @override
  Widget build(BuildContext context) => SizedBox(
    width: 74,
    child: Text(text,
      textAlign: TextAlign.right,
      style: GoogleFonts.dmSans(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.textTertiary, letterSpacing: 0.5)),
  );
}

class _GroupLabel extends StatelessWidget {
  final String label;
  final Color color;
  final Color borderColor;
  final bool topBorder;

  const _GroupLabel({required this.label, required this.color, required this.borderColor, this.topBorder = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 8, 14, 6),
      decoration: BoxDecoration(
        border: Border(
          top: topBorder ? BorderSide(color: borderColor, width: 0.5) : BorderSide.none,
          bottom: BorderSide(color: borderColor, width: 0.5),
          left: BorderSide(color: color, width: 3),
        ),
      ),
      child: Text(label,
        style: GoogleFonts.dmSans(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.textSecondary, letterSpacing: 0.8)),
    );
  }
}

class _TableRow extends StatelessWidget {
  final String label;
  final String? sublabel;
  final double planned;
  final double? actual;
  final Color? actualOverColor;
  final Color textPrimary;
  final Color borderColor;

  const _TableRow({
    required this.label,
    required this.planned,
    required this.textPrimary,
    required this.borderColor,
    this.sublabel,
    this.actual,
    this.actualOverColor,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final defaultColor = isDark ? AppColors.primaryForeground : AppColors.textPrimary;

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: borderColor, width: 0.5)),
      ),
      child: Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(label, style: GoogleFonts.dmSans(fontSize: 13, fontWeight: FontWeight.w500, color: textPrimary)),
            if (sublabel != null)
              Text(sublabel!, style: GoogleFonts.dmSans(fontSize: 11, color: AppColors.textTertiary)),
          ]),
        ),
        _AmountCell(value: planned, color: AppColors.textSecondary),
        const SizedBox(width: 16),
        actual != null
            ? _AmountCell(value: actual!, color: actualOverColor ?? defaultColor, bold: true)
            : SizedBox(
                width: 74,
                child: Text('—', textAlign: TextAlign.right,
                  style: GoogleFonts.dmMono(fontSize: 13, color: AppColors.textTertiary)),
              ),
      ]),
    );
  }
}

class _AmountCell extends StatelessWidget {
  final double value;
  final Color color;
  final bool bold;

  const _AmountCell({required this.value, required this.color, this.bold = false});

  @override
  Widget build(BuildContext context) => SizedBox(
    width: 74,
    child: Text(
      '${value < 0 ? '-' : ''}${currencyFormatter.format(value.abs(), decimalDigits: 0)}',
      textAlign: TextAlign.right,
      style: GoogleFonts.dmMono(
        fontSize: 13,
        fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
        color: color,
        fontFeatures: const [FontFeature.tabularFigures()],
      ),
    ),
  );
}
