import 'dart:math' show pi;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:keep_track/core/settings/utils/currency_formatter.dart';
import 'package:keep_track/core/theme/app_theme.dart';
import 'package:keep_track/features/finance/modules/budget/domain/entities/budget.dart';
import 'package:keep_track/features/finance/modules/budget/domain/entities/budget_category.dart';
import 'package:keep_track/features/finance/modules/budget/presentation/helpers/budget_month_filter.dart';
import 'package:keep_track/features/finance/modules/budget/presentation/helpers/linked_category_display.dart';
import 'package:keep_track/features/finance/modules/budget/presentation/widgets/ghost_add_row.dart';
import 'package:keep_track/core/utils/icon_helper.dart';
import 'package:keep_track/features/finance/modules/debt/domain/entities/debt.dart';
import 'package:keep_track/features/finance/modules/goal/domain/entities/goal.dart';
import 'package:keep_track/features/finance/modules/wallet/domain/entities/wallet.dart';
import 'package:keep_track/features/finance/modules/subscriptions/domain/entities/subscription.dart';
import 'package:keep_track/features/finance/modules/transaction/domain/entities/transaction.dart';
import '../sheets/transaction_detail_sheet.dart';


class SimpleMonthNav extends StatelessWidget {
  final DateTime month;
  final bool isDark;
  final bool isClosed;
  final bool isCurrentMonth;
  final VoidCallback onPrev;
  final VoidCallback? onNext;
  final VoidCallback? onBackToCurrentMonth;
  final VoidCallback? onSettings;
  final VoidCallback? onToggleView;

  const SimpleMonthNav({
    super.key,
    required this.month,
    required this.isDark,
    this.isClosed = false,
    this.isCurrentMonth = false,
    required this.onPrev,
    this.onNext,
    this.onBackToCurrentMonth,
    this.onSettings,
    this.onToggleView,
  });

  @override
  Widget build(BuildContext context) {
    final textPrimary = isDark ? AppColors.primaryForeground : AppColors.textPrimary;
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 16, 8, 0),
      child: Row(
        children: [
          IconButton(icon: Icon(Icons.chevron_left_rounded, color: AppColors.textSecondary), onPressed: onPrev, padding: EdgeInsets.zero, constraints: const BoxConstraints(minWidth: 36, minHeight: 36)),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(DateFormat('MMMM yyyy').format(month), style: GoogleFonts.dmSans(fontSize: 15, fontWeight: FontWeight.w600, color: textPrimary), textAlign: TextAlign.center),
                if (isClosed)
                  Container(
                    margin: const EdgeInsets.only(top: 2),
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(color: AppColors.textTertiary.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(10)),
                    child: Text('Closed', style: GoogleFonts.dmSans(fontSize: 10, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
                  )
                else if (!isCurrentMonth && onBackToCurrentMonth != null)
                  GestureDetector(
                    onTap: onBackToCurrentMonth,
                    child: Text('Back to current', style: GoogleFonts.dmSans(fontSize: 10, color: AppColors.accent)),
                  ),
              ],
            ),
          ),
          IconButton(icon: Icon(Icons.chevron_right_rounded, color: onNext != null ? AppColors.textSecondary : AppColors.textTertiary), onPressed: onNext, padding: EdgeInsets.zero, constraints: const BoxConstraints(minWidth: 36, minHeight: 36)),
          if (onToggleView != null)
            IconButton(icon: Icon(Icons.table_rows_outlined, color: AppColors.textSecondary), onPressed: onToggleView, padding: EdgeInsets.zero, constraints: const BoxConstraints(minWidth: 36, minHeight: 36), tooltip: 'Switch to Sheets'),
          if (onSettings != null)
            IconButton(icon: Icon(Icons.more_vert_rounded, color: AppColors.textSecondary), onPressed: onSettings, padding: EdgeInsets.zero, constraints: const BoxConstraints(minWidth: 36, minHeight: 36)),
        ],
      ),
    );
  }
}


class SimpleNetCard extends StatelessWidget {
  final bool isDark;
  final double net, plannedNet, actualIncome, plannedIncome, actualExpenses, plannedExpenses;

  const SimpleNetCard({super.key, required this.isDark, required this.net, required this.plannedNet, required this.actualIncome, required this.plannedIncome, required this.actualExpenses, required this.plannedExpenses});

  @override
  Widget build(BuildContext context) {
    final isPos = net >= 0;
    final cardBg = isDark ? AppColors.cardDark : AppColors.card;
    final border = isDark ? AppColors.border.withValues(alpha: 0.2) : AppColors.border.withValues(alpha: 0.5);
    final netColor = isPos ? AppColors.success : AppColors.error;
    final textPrimary = isDark ? AppColors.primaryForeground : AppColors.textPrimary;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(color: cardBg, borderRadius: BorderRadius.circular(14), border: Border.all(color: border, width: 0.5)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(isPos ? 'Surplus' : 'Deficit', style: GoogleFonts.dmSans(fontSize: 11, color: AppColors.textSecondary, fontWeight: FontWeight.w500)),
          const SizedBox(height: 4),
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: net.abs()),
            duration: const Duration(milliseconds: 900),
            curve: Curves.easeOutCubic,
            builder: (_, v, __) => Text(
              '${isPos ? '+' : '-'}${currencyFormatter.format(v, decimalDigits: 2)}',
              style: GoogleFonts.dmMono(fontSize: 30, fontWeight: FontWeight.w700, color: netColor, letterSpacing: -1, fontFeatures: const [FontFeature.tabularFigures()]),
            ),
          ),
          if (plannedNet != 0) ...[
            const SizedBox(height: 2),
            Text('${plannedNet >= 0 ? '+' : ''}${currencyFormatter.format(plannedNet, decimalDigits: 0)} planned',
                style: GoogleFonts.dmSans(fontSize: 11, color: AppColors.textTertiary)),
          ],
          const SizedBox(height: 14),
          Row(children: [
            Expanded(child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.0, end: 1.0),
              duration: const Duration(milliseconds: 600),
              curve: const Interval(0.0, 0.65, curve: Curves.easeOut),
              builder: (_, v, child) => Opacity(opacity: v, child: Transform.translate(offset: Offset(0, (1 - v) * 8), child: child)),
              child: _NetStat(isDark: isDark, label: 'Income', icon: Icons.arrow_downward_rounded, actual: actualIncome, planned: plannedIncome, color: AppColors.success, textPrimary: textPrimary),
            )),
            const SizedBox(width: 10),
            Expanded(child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.0, end: 1.0),
              duration: const Duration(milliseconds: 600),
              curve: const Interval(0.2, 0.85, curve: Curves.easeOut),
              builder: (_, v, child) => Opacity(opacity: v, child: Transform.translate(offset: Offset(0, (1 - v) * 8), child: child)),
              child: _NetStat(isDark: isDark, label: 'Expenses', icon: Icons.arrow_upward_rounded, actual: actualExpenses, planned: plannedExpenses, color: AppColors.error, textPrimary: textPrimary),
            )),
          ]),
        ]),
      ),
    );
  }
}

class _NetStat extends StatelessWidget {
  final bool isDark;
  final String label;
  final IconData icon;
  final double actual, planned;
  final Color color, textPrimary;

  const _NetStat({required this.isDark, required this.label, required this.icon, required this.actual, required this.planned, required this.color, required this.textPrimary});

  @override
  Widget build(BuildContext context) {
    final bg = isDark ? Colors.white.withValues(alpha: 0.04) : AppColors.background;
    final progress = planned > 0 ? (actual / planned).clamp(0.0, 1.0) : 0.0;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(10)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [Icon(icon, size: 12, color: color), const SizedBox(width: 4), Text(label, style: GoogleFonts.dmSans(fontSize: 11, color: AppColors.textSecondary))]),
        const SizedBox(height: 6),
        Text(currencyFormatter.format(actual, decimalDigits: 0), style: GoogleFonts.dmMono(fontSize: 14, fontWeight: FontWeight.w600, color: textPrimary, fontFeatures: const [FontFeature.tabularFigures()])),
        Text('of ${currencyFormatter.format(planned, decimalDigits: 0)}', style: GoogleFonts.dmSans(fontSize: 10, color: AppColors.textSecondary)),
        const SizedBox(height: 6),
        TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: progress),
          duration: const Duration(milliseconds: 900),
          curve: Curves.easeOutCubic,
          builder: (_, v, __) => ClipRRect(
            borderRadius: BorderRadius.circular(2),
            child: LinearProgressIndicator(value: v, minHeight: 3, backgroundColor: isDark ? Colors.white.withValues(alpha: 0.06) : AppColors.border, valueColor: AlwaysStoppedAnimation<Color>(color)),
          ),
        ),
      ]),
    );
  }
}


class SimpleSubsSummaryCard extends StatelessWidget {
  final bool isDark;
  final List<Subscription> subs;
  final DateTime month;

  const SimpleSubsSummaryCard({super.key, required this.isDark, required this.subs, required this.month});

  bool _paidThisMonth(Subscription s) =>
      s.lastBilledDate != null && s.lastBilledDate!.year == month.year && s.lastBilledDate!.month == month.month;

  @override
  Widget build(BuildContext context) {
    final cardBg = isDark ? AppColors.cardDark : AppColors.card;
    final border = isDark ? AppColors.border.withValues(alpha: 0.2) : AppColors.border.withValues(alpha: 0.5);
    final monthlyTotal = subs.fold(0.0, (s, sub) => s + sub.monthlyEquivalent);
    final paidCount = subs.where(_paidThisMonth).length;
    final dueCount = subs.length - paidCount;
    final textPrimary = isDark ? AppColors.primaryForeground : AppColors.textPrimary;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(color: cardBg, borderRadius: BorderRadius.circular(14), border: Border.all(color: border, width: 0.5)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Monthly Subscriptions', style: GoogleFonts.dmSans(fontSize: 11, color: AppColors.textSecondary, fontWeight: FontWeight.w500)),
          const SizedBox(height: 4),
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: monthlyTotal),
            duration: const Duration(milliseconds: 900),
            curve: Curves.easeOutCubic,
            builder: (_, v, __) => Text(
              currencyFormatter.format(v, decimalDigits: 2),
              style: GoogleFonts.dmMono(fontSize: 30, fontWeight: FontWeight.w700, color: AppColors.error, letterSpacing: -1, fontFeatures: const [FontFeature.tabularFigures()]),
            ),
          ),
          const SizedBox(height: 12),
          Row(children: [
            for (int i = 0; i < 3; i++) ...[
              if (i > 0) const SizedBox(width: 8),
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.0, end: 1.0),
                duration: const Duration(milliseconds: 500),
                curve: Interval(i * 0.18, i * 0.18 + 0.55, curve: Curves.easeOut),
                builder: (_, v, child) => Opacity(opacity: v, child: Transform.translate(offset: Offset(0, (1 - v) * 6), child: child)),
                child: [
                  _SummaryPill(label: '$paidCount paid', color: AppColors.success, isDark: isDark),
                  _SummaryPill(label: '$dueCount due', color: dueCount > 0 ? AppColors.warning : AppColors.textTertiary, isDark: isDark),
                  _SummaryPill(label: '${subs.length} total', color: AppColors.textSecondary, isDark: isDark),
                ][i],
              ),
            ],
          ]),
        ]),
      ),
    );
  }
}


class SimpleDebtSummaryCard extends StatelessWidget {
  final bool isDark;
  final double totalOwed, totalReceivable;
  final int debtCount, receivableCount, settledDebtCount, settledReceivableCount;

  const SimpleDebtSummaryCard({super.key, required this.isDark, required this.totalOwed, required this.totalReceivable, required this.debtCount, required this.receivableCount, this.settledDebtCount = 0, this.settledReceivableCount = 0});

  @override
  Widget build(BuildContext context) {
    final cardBg = isDark ? AppColors.cardDark : AppColors.card;
    final border = isDark ? AppColors.border.withValues(alpha: 0.2) : AppColors.border.withValues(alpha: 0.5);

    // Single-type view (debts only or receivables only)
    final isDebtsOnly = totalReceivable == 0;
    final isReceivablesOnly = totalOwed == 0;

    if (isDebtsOnly || isReceivablesOnly) {
      final amount = isDebtsOnly ? totalOwed : totalReceivable;
      final count = isDebtsOnly ? debtCount : receivableCount;
      final settledCount = isDebtsOnly ? settledDebtCount : settledReceivableCount;
      final isAllClear = count == 0 && settledCount > 0;
      final color = isDebtsOnly ? AppColors.error : AppColors.success;
      final badgeColor = isAllClear ? AppColors.success : color;
      final label = isDebtsOnly ? 'TOTAL OWED' : 'TOTAL RECEIVABLE';
      final countLabel = isAllClear
          ? (isDebtsOnly ? '$settledCount settled' : '$settledCount collected')
          : count == 0
              ? (isDebtsOnly ? 'No active debts' : 'No active receivables')
              : (isDebtsOnly ? '$count active debt${count == 1 ? '' : 's'}' : '$count active receivable${count == 1 ? '' : 's'}');

      return Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(color: cardBg, borderRadius: BorderRadius.circular(14), border: Border.all(color: border, width: 0.5)),
          child: Row(children: [
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(label, style: GoogleFonts.dmSans(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.textTertiary, letterSpacing: 0.8)),
              const SizedBox(height: 4),
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: amount),
                duration: const Duration(milliseconds: 900),
                curve: Curves.easeOutCubic,
                builder: (_, v, __) => Text(currencyFormatter.format(v), style: GoogleFonts.dmMono(fontSize: 26, fontWeight: FontWeight.w700, color: color, fontFeatures: const [FontFeature.tabularFigures()])),
              ),
            ])),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(color: badgeColor.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(20), border: Border.all(color: badgeColor.withValues(alpha: 0.2))),
              child: Text(countLabel, style: GoogleFonts.dmSans(fontSize: 12, fontWeight: FontWeight.w600, color: badgeColor)),
            ),
          ]),
        ),
      );
    }

    // Combined view (both present)
    final net = totalReceivable - totalOwed;
    final isPositive = net >= 0;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(color: cardBg, borderRadius: BorderRadius.circular(14), border: Border.all(color: border, width: 0.5)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Net Position', style: GoogleFonts.dmSans(fontSize: 11, color: AppColors.textSecondary, fontWeight: FontWeight.w500)),
          const SizedBox(height: 4),
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: net.abs()),
            duration: const Duration(milliseconds: 900),
            curve: Curves.easeOutCubic,
            builder: (_, v, __) => Text(
              '${isPositive ? '+' : '-'}${currencyFormatter.format(v, decimalDigits: 2)}',
              style: GoogleFonts.dmMono(fontSize: 30, fontWeight: FontWeight.w700, color: isPositive ? AppColors.success : AppColors.error, letterSpacing: -1, fontFeatures: const [FontFeature.tabularFigures()]),
            ),
          ),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.0, end: 1.0),
              duration: const Duration(milliseconds: 500),
              curve: const Interval(0.0, 0.65, curve: Curves.easeOut),
              builder: (_, v, child) => Opacity(opacity: v, child: Transform.translate(offset: Offset(0, (1 - v) * 8), child: child)),
              child: _StatMini(label: 'I Owe', value: currencyFormatter.format(totalOwed, decimalDigits: 0), count: '$debtCount active', color: AppColors.error, isDark: isDark),
            )),
            const SizedBox(width: 10),
            Expanded(child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.0, end: 1.0),
              duration: const Duration(milliseconds: 500),
              curve: const Interval(0.2, 0.85, curve: Curves.easeOut),
              builder: (_, v, child) => Opacity(opacity: v, child: Transform.translate(offset: Offset(0, (1 - v) * 8), child: child)),
              child: _StatMini(label: 'Owed to Me', value: currencyFormatter.format(totalReceivable, decimalDigits: 0), count: '$receivableCount active', color: AppColors.success, isDark: isDark),
            )),
          ]),
        ]),
      ),
    );
  }
}


class SimpleGoalsSummaryCard extends StatelessWidget {
  final bool isDark;
  final List<Goal> goals;

  const SimpleGoalsSummaryCard({super.key, required this.isDark, required this.goals});

  @override
  Widget build(BuildContext context) {
    final cardBg = isDark ? AppColors.cardDark : AppColors.card;
    final border = isDark ? AppColors.border.withValues(alpha: 0.2) : AppColors.border.withValues(alpha: 0.5);
    final totalSaved = goals.fold(0.0, (s, g) => s + g.currentAmount);
    final totalTarget = goals.fold(0.0, (s, g) => s + g.targetAmount);
    final overallProgress = totalTarget > 0 ? (totalSaved / totalTarget).clamp(0.0, 1.0) : 0.0;
    final activeCount = goals.where((g) => g.status == GoalStatus.active).length;
    final completedCount = goals.where((g) => g.status == GoalStatus.completed).length;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(color: cardBg, borderRadius: BorderRadius.circular(14), border: Border.all(color: border, width: 0.5)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Total Saved', style: GoogleFonts.dmSans(fontSize: 11, color: AppColors.textSecondary, fontWeight: FontWeight.w500)),
          const SizedBox(height: 4),
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: totalSaved),
            duration: const Duration(milliseconds: 900),
            curve: Curves.easeOutCubic,
            builder: (_, v, __) => Text(
              currencyFormatter.format(v, decimalDigits: 2),
              style: GoogleFonts.dmMono(fontSize: 30, fontWeight: FontWeight.w700, color: AppColors.accent, letterSpacing: -1, fontFeatures: const [FontFeature.tabularFigures()]),
            ),
          ),
          if (totalTarget > 0) ...[
            const SizedBox(height: 4),
            Text('of ${currencyFormatter.format(totalTarget, decimalDigits: 0)} target · ${(overallProgress * 100).round()}% overall',
                style: GoogleFonts.dmSans(fontSize: 11, color: AppColors.textTertiary)),
            const SizedBox(height: 10),
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: overallProgress),
              duration: const Duration(milliseconds: 900),
              curve: Curves.easeOutCubic,
              builder: (_, v, __) => ClipRRect(borderRadius: BorderRadius.circular(3), child: LinearProgressIndicator(
                value: v, minHeight: 5,
                backgroundColor: isDark ? Colors.white.withValues(alpha: 0.06) : AppColors.border,
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.accent),
              )),
            ),
          ],
          const SizedBox(height: 12),
          Row(children: [
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.0, end: 1.0),
              duration: const Duration(milliseconds: 500),
              curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
              builder: (_, v, child) => Opacity(opacity: v, child: Transform.translate(offset: Offset(0, (1 - v) * 6), child: child)),
              child: _SummaryPill(label: '$activeCount active', color: AppColors.accent, isDark: isDark),
            ),
            if (completedCount > 0) ...[
              const SizedBox(width: 8),
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.0, end: 1.0),
                duration: const Duration(milliseconds: 500),
                curve: const Interval(0.2, 0.8, curve: Curves.easeOut),
                builder: (_, v, child) => Opacity(opacity: v, child: Transform.translate(offset: Offset(0, (1 - v) * 6), child: child)),
                child: _SummaryPill(label: '$completedCount completed', color: AppColors.success, isDark: isDark),
              ),
            ],
          ]),
        ]),
      ),
    );
  }
}


class _SummaryPill extends StatelessWidget {
  final String label;
  final Color color;
  final bool isDark;
  const _SummaryPill({required this.label, required this.color, required this.isDark});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
    decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(20)),
    child: Text(label, style: GoogleFonts.dmSans(fontSize: 11, fontWeight: FontWeight.w600, color: color)),
  );
}

class _StatMini extends StatelessWidget {
  final String label, value, count;
  final Color color;
  final bool isDark;
  const _StatMini({required this.label, required this.value, required this.count, required this.color, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final bg = isDark ? Colors.white.withValues(alpha: 0.04) : AppColors.background;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(10)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: GoogleFonts.dmSans(fontSize: 11, color: AppColors.textSecondary)),
        const SizedBox(height: 4),
        Text(value, style: GoogleFonts.dmMono(fontSize: 15, fontWeight: FontWeight.w700, color: color, fontFeatures: const [FontFeature.tabularFigures()])),
        Text(count, style: GoogleFonts.dmSans(fontSize: 10, color: AppColors.textSecondary)),
      ]),
    );
  }
}


class SimpleBudgetSection extends StatelessWidget {
  final bool isDark, isIncome;
  final String label;
  final List<Budget> groups;
  final Map<String, double> spentByCategory;
  final List<Transaction> monthTxs;
  final VoidCallback? onAddGroup;
  final void Function(Budget)? onAddCategory, onEditGroup;
  final void Function(Budget, BudgetCategory, double)? onCategoryTap;

  const SimpleBudgetSection({super.key, required this.isDark, required this.label, required this.groups, required this.spentByCategory, required this.isIncome, this.monthTxs = const [], this.onAddGroup, this.onAddCategory, this.onEditGroup, this.onCategoryTap});

  @override
  Widget build(BuildContext context) {
    final cardBg = isDark ? AppColors.cardDark : AppColors.card;
    final border = isDark ? AppColors.border.withValues(alpha: 0.2) : AppColors.border.withValues(alpha: 0.5);
    final color = isIncome ? AppColors.success : AppColors.accent;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 8, left: 2),
          child: Row(children: [
            Text(label, style: GoogleFonts.dmSans(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.textSecondary, letterSpacing: 1.2)),
            const Spacer(),
            if (onAddGroup != null)
              GestureDetector(
                onTap: onAddGroup,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(20)),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Icon(Icons.add, size: 11, color: color),
                    const SizedBox(width: 3),
                    Text('Add Group', style: GoogleFonts.dmSans(fontSize: 10, fontWeight: FontWeight.w600, color: color)),
                  ]),
                ),
              ),
          ]),
        ),
        Container(
          decoration: BoxDecoration(color: cardBg, borderRadius: BorderRadius.circular(14), border: Border.all(color: border, width: 0.5)),
          child: groups.isEmpty
              ? Padding(
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  child: Center(child: Text('No ${isIncome ? 'income' : 'expense'} groups', style: GoogleFonts.dmSans(fontSize: 12, color: AppColors.textTertiary))),
                )
              : Column(
                  children: groups.asMap().entries.expand((e) {
                    final i = e.key;
                    final divColor = isDark ? AppColors.border.withValues(alpha: 0.15) : AppColors.border.withValues(alpha: 0.4);
                    return [
                      if (i > 0) Divider(height: 1, thickness: 0.5, color: divColor, indent: 16, endIndent: 16),
                      TweenAnimationBuilder<double>(
                        key: ValueKey(e.value.id),
                        tween: Tween(begin: 0.0, end: 1.0),
                        duration: const Duration(milliseconds: 450),
                        curve: Interval(
                          (i * 0.1).clamp(0.0, 0.5),
                          ((i * 0.1) + 0.4).clamp(0.0, 1.0),
                          curve: Curves.easeOut,
                        ),
                        builder: (_, v, child) => Opacity(
                          opacity: v,
                          child: Transform.translate(offset: Offset(0, (1 - v) * 10), child: child),
                        ),
                        child: _GroupRow(isDark: isDark, budget: e.value, spentByCategory: spentByCategory, monthTxs: monthTxs, isIncome: isIncome, onAddCategory: onAddCategory, onEditGroup: onEditGroup, onCategoryTap: onCategoryTap),
                      ),
                    ];
                  }).toList(),
                ),
        ),
      ]),
    );
  }
}

/// Spend for a Budget Category row: for a Category Link, matches by the
/// linked entity's transactions (precise, no cross-category double-counting);
/// for a plain category, keeps today's category-wide `financeCategoryId`
/// match unchanged. See CONTEXT.md ("Linked spend").
double _categorySpent(BudgetCategory cat, Map<String, double> spentByCategory, List<Transaction> monthTxs) {
  return cat.isLinked
      ? BudgetMonthFilter.buildLinkedSpend(cat, monthTxs)
      : (spentByCategory[cat.financeCategoryId] ?? 0.0);
}

class _GroupRow extends StatefulWidget {
  final bool isDark, isIncome;
  final Budget budget;
  final Map<String, double> spentByCategory;
  final List<Transaction> monthTxs;
  final void Function(Budget)? onAddCategory, onEditGroup;
  final void Function(Budget, BudgetCategory, double)? onCategoryTap;

  const _GroupRow({required this.isDark, required this.budget, required this.spentByCategory, this.monthTxs = const [], required this.isIncome, this.onAddCategory, this.onEditGroup, this.onCategoryTap});

  @override
  State<_GroupRow> createState() => _GroupRowState();
}

class _GroupRowState extends State<_GroupRow> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final b = widget.budget;
    final isDark = widget.isDark;
    final color = widget.isIncome ? AppColors.success : AppColors.accent;
    final overColor = widget.isIncome ? AppColors.success : AppColors.error;
    final spent = b.categories.fold(0.0, (s, c) => s + _categorySpent(c, widget.spentByCategory, widget.monthTxs));
    final planned = b.budgetTarget;
    final over = planned > 0 && spent > planned;
    final barColor = over ? overColor : color;
    final textPrimary = isDark ? AppColors.primaryForeground : AppColors.textPrimary;
    final divColor = isDark ? AppColors.border.withValues(alpha: 0.15) : AppColors.border.withValues(alpha: 0.4);

    return Column(children: [
      InkWell(
        onTap: () => setState(() => _expanded = !_expanded),
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
          child: Column(children: [
            Row(children: [
              Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
              const SizedBox(width: 10),
              Expanded(child: Text(b.title ?? (widget.isIncome ? 'Income' : 'Expenses'), style: GoogleFonts.dmSans(fontSize: 13, fontWeight: FontWeight.w600, color: textPrimary))),
              if (widget.onEditGroup != null)
                GestureDetector(
                  onTap: () => widget.onEditGroup!(b),
                  child: Padding(
                    padding: const EdgeInsets.all(6),
                    child: Icon(Icons.edit_outlined, size: 14, color: AppColors.textTertiary),
                  ),
                ),
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.0, end: spent),
                duration: const Duration(milliseconds: 700),
                curve: Curves.easeOutCubic,
                builder: (_, v, __) => Text(currencyFormatter.format(v, decimalDigits: 0), style: GoogleFonts.dmMono(fontSize: 13, fontWeight: FontWeight.w600, color: over ? overColor : textPrimary, fontFeatures: const [FontFeature.tabularFigures()])),
              ),
              Text(' / ${currencyFormatter.format(planned, decimalDigits: 0)}', style: GoogleFonts.dmSans(fontSize: 11, color: AppColors.textSecondary)),
              const SizedBox(width: 4),
              AnimatedRotation(turns: _expanded ? 0.5 : 0, duration: const Duration(milliseconds: 150),
                  child: Icon(Icons.keyboard_arrow_down_rounded, size: 16, color: AppColors.textTertiary)),
            ]),
            const SizedBox(height: 8),
            _HpBar(spent: spent, planned: planned, color: barColor, isDark: isDark, height: 6),
          ]),
        ),
      ),
      AnimatedSize(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOutCubic,
        child: _expanded
            ? Container(
                color: isDark ? Colors.white.withValues(alpha: 0.02) : AppColors.background.withValues(alpha: 0.5),
                child: Column(children: [
                  ...b.categories.asMap().entries.map((ce) {
                    final ci = ce.key;
                    final cat = ce.value;
                    final catSpent = _categorySpent(cat, widget.spentByCategory, widget.monthTxs);
                    final catPlanned = cat.targetAmount;
                    final catOver = catPlanned > 0 && catSpent > catPlanned;
                    final catDisplay = resolveLinkedCategoryDisplay(cat);
                    return TweenAnimationBuilder<double>(
                      key: ValueKey(cat.id),
                      tween: Tween(begin: 0.0, end: 1.0),
                      duration: const Duration(milliseconds: 350),
                      curve: Interval(
                        (ci * 0.1).clamp(0.0, 0.5),
                        ((ci * 0.1) + 0.4).clamp(0.0, 1.0),
                        curve: Curves.easeOut,
                      ),
                      builder: (_, v, child) => Opacity(
                        opacity: v,
                        child: Transform.translate(offset: Offset(0, (1 - v) * 8), child: child),
                      ),
                      child: Column(children: [
                        Divider(height: 1, thickness: 0.5, color: divColor),
                        InkWell(
                          onTap: widget.onCategoryTap != null ? () => widget.onCategoryTap!(b, cat, catSpent) : null,
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(34, 10, 16, 10),
                            child: Row(children: [
                              if (cat.isLinked)
                                Padding(
                                  padding: const EdgeInsets.only(right: 5),
                                  child: Icon(Icons.link_rounded, size: 11, color: AppColors.textTertiary),
                                ),
                              Expanded(
                                child: Row(mainAxisSize: MainAxisSize.min, children: [
                                  Flexible(
                                    child: Text(catDisplay.name, style: GoogleFonts.dmSans(fontSize: 12, color: AppColors.textSecondary), maxLines: 1, overflow: TextOverflow.ellipsis),
                                  ),
                                  if (catDisplay.statusLabel != null) ...[
                                    const SizedBox(width: 6),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                                      decoration: BoxDecoration(
                                        color: (catDisplay.statusColor ?? AppColors.textTertiary).withValues(alpha: 0.12),
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: Text(
                                        catDisplay.statusLabel!,
                                        style: GoogleFonts.dmSans(fontSize: 9, fontWeight: FontWeight.w600, color: catDisplay.statusColor ?? AppColors.textTertiary),
                                      ),
                                    ),
                                  ],
                                ]),
                              ),
                              TweenAnimationBuilder<double>(
                                tween: Tween(begin: 0.0, end: catSpent),
                                duration: const Duration(milliseconds: 600),
                                curve: Curves.easeOutCubic,
                                builder: (_, v, __) => Text(currencyFormatter.format(v, decimalDigits: 0), style: GoogleFonts.dmMono(fontSize: 12, fontWeight: FontWeight.w500, color: catOver ? overColor : textPrimary, fontFeatures: const [FontFeature.tabularFigures()])),
                              ),
                              Text(' / ${currencyFormatter.format(catPlanned, decimalDigits: 0)}', style: GoogleFonts.dmSans(fontSize: 10, color: AppColors.textTertiary)),
                              const SizedBox(width: 10),
                              SizedBox(width: 52, child: _HpBar(spent: catSpent, planned: catPlanned, color: catOver ? overColor : color, isDark: isDark, height: 4)),
                              const SizedBox(width: 4),
                              Icon(Icons.chevron_right_rounded, size: 14, color: AppColors.textTertiary),
                            ]),
                          ),
                        ),
                      ]),
                    );
                  }),
                  Divider(height: 1, thickness: 0.5, color: divColor),
                  if (widget.onAddCategory != null)
                    GhostAddRow(label: 'Add Category', onTap: () => widget.onAddCategory!(b)),
                ]),
              )
            : const SizedBox.shrink(),
      ),
    ]);
  }
}


class SimpleSubscriptionsSection extends StatelessWidget {
  final bool isDark;
  final List<Subscription> subs;
  final DateTime month;
  final VoidCallback onAdd;
  final void Function(Subscription) onRowTap;
  final void Function(Subscription)? onSkip;
  final bool isLocked;
  final Set<String> linkedIds;

  const SimpleSubscriptionsSection({super.key, required this.isDark, required this.subs, required this.month, required this.onAdd, required this.onRowTap, this.onSkip, this.isLocked = false, this.linkedIds = const {}});

  bool _paidThisMonth(Subscription s) {
    final d = s.lastBilledDate;
    return d != null && d.year == month.year && d.month == month.month;
  }

  List<_SubEntry> get _entries {
    // Show all subs sorted by next billing date; overdue first, then upcoming, paid last
    final list = subs.map((s) => _SubEntry(sub: s, paid: _paidThisMonth(s))).toList();
    list.sort((a, b) {
      if (a.paid != b.paid) return a.paid ? 1 : -1;
      return a.sub.nextBillingDate.compareTo(b.sub.nextBillingDate);
    });
    return list;
  }

  @override
  Widget build(BuildContext context) {
    final divColor = isDark ? AppColors.border.withValues(alpha: 0.15) : AppColors.border.withValues(alpha: 0.4);
    final textPrimary = isDark ? AppColors.primaryForeground : AppColors.textPrimary;
    final entries = _entries;
    final paidCount = entries.where((e) => e.paid).length;

    return _SimpleSection(
      isDark: isDark,
      label: 'SUBSCRIPTIONS',
      trailing: entries.isEmpty ? null : '$paidCount/${entries.length} paid',
      trailingColor: paidCount == entries.length && entries.isNotEmpty ? AppColors.success : null,
      onAdd: onAdd,
      isLocked: isLocked,
      child: entries.isEmpty
          ? _EmptyRow(isDark: isDark, text: 'No subscriptions yet')
          : Column(
              children: entries.asMap().entries.expand((mapEntry) {
                final i = mapEntry.key;
                final entry = mapEntry.value;
                final s = entry.sub;
                final now = DateTime.now();
                final Color badgeColor;
                final String badgeText;
                final String dateLine;

                if (entry.paid) {
                  badgeColor = AppColors.success;
                  badgeText = 'Paid';
                  dateLine = 'Paid ${DateFormat('MMM d').format(s.lastBilledDate!)}';
                } else if (s.nextBillingDate.isBefore(now)) {
                  badgeColor = AppColors.error;
                  badgeText = 'Overdue';
                  dateLine = 'Was due ${DateFormat('MMM d').format(s.nextBillingDate)}';
                } else {
                  final days = s.nextBillingDate.difference(now).inDays;
                  badgeColor = days == 0 ? AppColors.warning : days <= 3 ? AppColors.warning : AppColors.textTertiary;
                  badgeText = days == 0 ? 'Due today' : 'Due ${DateFormat('MMM d').format(s.nextBillingDate)}';
                  dateLine = s.billingCycle.displayName;
                }

                return [
                  Divider(height: 1, thickness: 0.5, color: divColor, indent: 16, endIndent: 16),
                  TweenAnimationBuilder<double>(
                    key: ValueKey(s.id),
                    tween: Tween(begin: 0.0, end: 1.0),
                    duration: const Duration(milliseconds: 450),
                    curve: Interval(
                      (i * 0.08).clamp(0.0, 0.6),
                      ((i * 0.08) + 0.4).clamp(0.0, 1.0),
                      curve: Curves.easeOut,
                    ),
                    builder: (_, v, child) => Opacity(
                      opacity: v,
                      child: Transform.translate(offset: Offset(0, (1 - v) * 10), child: child),
                    ),
                    child: InkWell(
                    onTap: isLocked ? null : () => onRowTap(s),
                    child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 11, 12, 11),
                    child: Row(children: [
                      Container(width: 8, height: 8, margin: const EdgeInsets.only(right: 10), decoration: BoxDecoration(color: badgeColor, shape: BoxShape.circle)),
                      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Row(children: [
                          Flexible(child: Text(s.name, style: GoogleFonts.dmSans(fontSize: 13, fontWeight: FontWeight.w500, color: entry.paid ? AppColors.textSecondary : textPrimary), maxLines: 1, overflow: TextOverflow.ellipsis)),
                          if (linkedIds.contains(s.id)) ...[const SizedBox(width: 6), const _LinkedBadge()],
                        ]),
                        const SizedBox(height: 1),
                        Text(dateLine, style: GoogleFonts.dmSans(fontSize: 11, color: AppColors.textSecondary)),
                      ])),
                      Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                        Text(
                          currencyFormatter.format(s.amount, decimalDigits: 2),
                          style: GoogleFonts.dmMono(
                            fontSize: 13, fontWeight: FontWeight.w600,
                            color: entry.paid ? AppColors.textTertiary : AppColors.textPrimary,
                            decoration: entry.paid ? TextDecoration.lineThrough : null,
                            fontFeatures: const [FontFeature.tabularFigures()],
                          ),
                        ),
                        const SizedBox(height: 3),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(color: badgeColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(20)),
                          child: Text(badgeText, style: GoogleFonts.dmSans(fontSize: 10, fontWeight: FontWeight.w600, color: badgeColor)),
                        ),
                      ]),
                      if (!entry.paid && onSkip != null) ...[
                        const SizedBox(width: 8),
                        GestureDetector(
                          onTap: () => onSkip!(s),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.textTertiary.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: AppColors.border.withValues(alpha: 0.4)),
                            ),
                            child: Text('Skip', style: GoogleFonts.dmSans(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
                          ),
                        ),
                      ] else
                        const SizedBox(width: 4),
                      Icon(Icons.chevron_right_rounded, size: 16, color: AppColors.textTertiary),
                    ]),
                  )),
                  ),
                ];
              }).toList(),
            ),
    );
  }
}

class _SubEntry {
  final Subscription sub;
  final bool paid;
  const _SubEntry({required this.sub, required this.paid});
}


class SimpleDebtsSection extends StatelessWidget {
  final bool isDark;
  final List<Debt> debts, receivables;
  final Map<String, double> paidThisMonth;
  final VoidCallback onAddDebt, onAddReceivable;
  final void Function(Debt) onRowTap;
  final bool isLocked;
  final Set<String> linkedIds;

  const SimpleDebtsSection({super.key, required this.isDark, required this.debts, required this.receivables, required this.onAddDebt, required this.onAddReceivable, required this.onRowTap, this.paidThisMonth = const {}, this.isLocked = false, this.linkedIds = const {}});

  @override
  Widget build(BuildContext context) {
    final divColor = isDark ? AppColors.border.withValues(alpha: 0.15) : AppColors.border.withValues(alpha: 0.4);
    final textPrimary = isDark ? AppColors.primaryForeground : AppColors.textPrimary;
    final totalCount = debts.length + receivables.length;
    final emptyLabel = debts.isEmpty && receivables.isEmpty
        ? 'No debts or receivables'
        : debts.isEmpty ? 'No debts' : 'No receivables';

    return _SimpleSection(
      isDark: isDark,
      label: debts.isNotEmpty || receivables.isEmpty ? 'DEBTS' : 'RECEIVABLES',
      trailing: totalCount == 0 ? null : '$totalCount active',
      onAdd: debts.isNotEmpty || receivables.isEmpty ? onAddDebt : onAddReceivable,
      addLabel: debts.isNotEmpty || receivables.isEmpty ? 'Add Debt' : 'Add Receivable',
      isLocked: isLocked,
      child: (debts.isEmpty && receivables.isEmpty)
          ? _EmptyRow(isDark: isDark, text: emptyLabel)
          : Column(children: [
              ...debts.asMap().entries.expand((e) => [
                Divider(height: 1, thickness: 0.5, color: divColor, indent: 16, endIndent: 16),
                TweenAnimationBuilder<double>(
                  key: ValueKey(e.value.id),
                  tween: Tween(begin: 0.0, end: 1.0),
                  duration: const Duration(milliseconds: 450),
                  curve: Interval(
                    (e.key * 0.08).clamp(0.0, 0.6),
                    ((e.key * 0.08) + 0.4).clamp(0.0, 1.0),
                    curve: Curves.easeOut,
                  ),
                  builder: (_, v, child) => Opacity(opacity: v, child: Transform.translate(offset: Offset(0, (1 - v) * 10), child: child)),
                  child: _DebtRow(isDark: isDark, debt: e.value, textPrimary: textPrimary, paidThisMonth: paidThisMonth[e.value.id] ?? 0, onTap: () => onRowTap(e.value), isLocked: isLocked, isLinked: linkedIds.contains(e.value.id)),
                ),
              ]),
              ...receivables.asMap().entries.expand((e) {
                final i = e.key + debts.length;
                return [
                  Divider(height: 1, thickness: 0.5, color: divColor, indent: 16, endIndent: 16),
                  TweenAnimationBuilder<double>(
                    key: ValueKey(e.value.id),
                    tween: Tween(begin: 0.0, end: 1.0),
                    duration: const Duration(milliseconds: 450),
                    curve: Interval(
                      (i * 0.08).clamp(0.0, 0.6),
                      ((i * 0.08) + 0.4).clamp(0.0, 1.0),
                      curve: Curves.easeOut,
                    ),
                    builder: (_, v, child) => Opacity(opacity: v, child: Transform.translate(offset: Offset(0, (1 - v) * 10), child: child)),
                    child: _DebtRow(isDark: isDark, debt: e.value, textPrimary: textPrimary, paidThisMonth: paidThisMonth[e.value.id] ?? 0, onTap: () => onRowTap(e.value), isLocked: isLocked, isLinked: linkedIds.contains(e.value.id)),
                  ),
                ];
              }),
            ]),
    );
  }
}

class _DebtRow extends StatelessWidget {
  final bool isDark;
  final Debt debt;
  final Color textPrimary;
  final double paidThisMonth;
  final VoidCallback? onTap;
  final bool isLocked;
  final bool isLinked;

  const _DebtRow({required this.isDark, required this.debt, required this.textPrimary, required this.onTap, this.paidThisMonth = 0, this.isLocked = false, this.isLinked = false});

  @override
  Widget build(BuildContext context) {
    final isReceivable = debt.type == DebtType.lending;
    final isSettled = debt.status == DebtStatus.settled || debt.remainingAmount <= 0;
    final baseColor = isReceivable ? AppColors.success : AppColors.error;
    final color = isSettled ? baseColor.withValues(alpha: 0.4) : baseColor;
    final icon = isReceivable ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded;
    final hasMonthly = debt.monthlyPaymentAmount > 0;
    final canTap = isSettled || !isLocked;

    return InkWell(
      onTap: canTap ? onTap : null,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 11, 16, 11),
        child: Row(children: [
          Container(width: 32, height: 32, decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)), child: Icon(icon, size: 14, color: color)),
          const SizedBox(width: 10),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Flexible(child: Text(debt.personName, style: GoogleFonts.dmSans(fontSize: 13, fontWeight: FontWeight.w500, color: isSettled ? AppColors.textSecondary : textPrimary), maxLines: 1, overflow: TextOverflow.ellipsis)),
              if (isLinked) ...[const SizedBox(width: 6), const _LinkedBadge()],
            ]),
            const SizedBox(height: 1),
            Text(
              [
                isReceivable ? 'Receivable' : 'Debt',
                if (hasMonthly) '${currencyFormatter.format(debt.monthlyPaymentAmount, decimalDigits: 0)}/mo planned',
                'Since ${DateFormat('MMM d').format(debt.startDate)}',
              ].join(' · '),
              style: GoogleFonts.dmSans(fontSize: 11, color: AppColors.textSecondary),
              maxLines: 1, overflow: TextOverflow.ellipsis,
            ),
          ])),
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Text(
              isSettled ? (isReceivable ? 'Collected' : 'Settled') : currencyFormatter.format(debt.remainingAmount, decimalDigits: 2),
              style: isSettled
                  ? GoogleFonts.dmSans(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.success)
                  : GoogleFonts.dmMono(fontSize: 13, fontWeight: FontWeight.w600, color: color, fontFeatures: const [FontFeature.tabularFigures()]),
            ),
            const SizedBox(height: 2),
            if (!isSettled && debt.isOverdue)
              Container(padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2), decoration: BoxDecoration(color: AppColors.error.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(20)), child: Text('Overdue', style: GoogleFonts.dmSans(fontSize: 10, fontWeight: FontWeight.w600, color: AppColors.error)))
            else if (!isSettled && paidThisMonth > 0)
              Container(padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2), decoration: BoxDecoration(color: AppColors.success.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(20)), child: Text(isReceivable ? 'Collected' : 'Paid', style: GoogleFonts.dmSans(fontSize: 10, fontWeight: FontWeight.w600, color: AppColors.success)))
            else if (!isSettled)
              Text('Remaining', style: GoogleFonts.dmSans(fontSize: 10, color: AppColors.textTertiary)),
          ]),
          const SizedBox(width: 4),
          Icon(Icons.chevron_right_rounded, size: 14, color: AppColors.textTertiary),
        ]),
      ),
    );
  }
}


class _SimpleSection extends StatelessWidget {
  final bool isDark;
  final String label;
  final String? trailing, addLabel;
  final Color? trailingColor;
  final VoidCallback onAdd;
  final Widget? extraAction;
  final Widget child;
  final bool isLocked;

  const _SimpleSection({required this.isDark, required this.label, this.trailing, this.trailingColor, required this.onAdd, this.addLabel, this.extraAction, required this.child, this.isLocked = false});

  @override
  Widget build(BuildContext context) {
    final cardBg = isDark ? AppColors.cardDark : AppColors.card;
    final border = isDark ? AppColors.border.withValues(alpha: 0.2) : AppColors.border.withValues(alpha: 0.5);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 8, left: 2),
          child: Row(children: [
            Text(label, style: GoogleFonts.dmSans(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.textSecondary, letterSpacing: 1.2)),
            if (trailing != null) ...[
              const SizedBox(width: 6),
              Container(padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(color: (trailingColor ?? AppColors.textSecondary).withValues(alpha: 0.1), borderRadius: BorderRadius.circular(20)),
                  child: Text(trailing!, style: GoogleFonts.dmSans(fontSize: 10, color: trailingColor ?? AppColors.textSecondary, fontWeight: FontWeight.w600))),
            ],
            const Spacer(),
            if (!isLocked) ...[
              if (extraAction != null) ...[extraAction!, const SizedBox(width: 6)],
              GestureDetector(
                onTap: onAdd,
                child: Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3), decoration: BoxDecoration(color: AppColors.accent.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(20)),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      Icon(Icons.add, size: 11, color: AppColors.accent),
                      const SizedBox(width: 3),
                      Text(addLabel ?? 'Add', style: GoogleFonts.dmSans(fontSize: 10, fontWeight: FontWeight.w600, color: AppColors.accent)),
                    ])),
              ),
            ],
          ]),
        ),
        Container(
          decoration: BoxDecoration(color: cardBg, borderRadius: BorderRadius.circular(14), border: Border.all(color: border, width: 0.5)),
          child: Column(children: [
            child,
            const SizedBox(height: 4),
          ]),
        ),
      ]),
    );
  }
}

class _ExtraAddButton extends StatelessWidget {
  final String label;
  final bool isDark;
  final VoidCallback onTap;

  const _ExtraAddButton({required this.label, required this.isDark, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: AppColors.success.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(20)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(Icons.add, size: 11, color: AppColors.success),
        const SizedBox(width: 3),
        Text(label, style: GoogleFonts.dmSans(fontSize: 10, fontWeight: FontWeight.w600, color: AppColors.success)),
      ]),
    ),
  );
}

/// Reverse indicator shown on a Subscription/Debt/Goal's own row when it's
/// currently linked into a Budget Category. See CONTEXT.md
/// ("Linked badge (reverse indicator)").
class _LinkedBadge extends StatelessWidget {
  const _LinkedBadge();

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
    decoration: BoxDecoration(color: AppColors.accent.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(20)),
    child: Row(mainAxisSize: MainAxisSize.min, children: [
      Icon(Icons.link_rounded, size: 9, color: AppColors.accent),
      const SizedBox(width: 3),
      Text('Linked', style: GoogleFonts.dmSans(fontSize: 9, fontWeight: FontWeight.w600, color: AppColors.accent)),
    ]),
  );
}

class _EmptyRow extends StatelessWidget {
  final bool isDark;
  final String text;
  const _EmptyRow({required this.isDark, required this.text});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 16),
    child: Center(child: Text(text, style: GoogleFonts.dmSans(fontSize: 12, color: AppColors.textTertiary))),
  );
}


class _HpBar extends StatelessWidget {
  final double spent, planned;
  final Color color;
  final bool isDark;
  final double height;

  const _HpBar({required this.spent, required this.planned, required this.color, required this.isDark, required this.height});

  @override
  Widget build(BuildContext context) {
    final trackBg = isDark ? Colors.white.withValues(alpha: 0.06) : AppColors.border.withValues(alpha: 0.4);
    final plannedColor = color.withValues(alpha: 0.22);
    final spentRatio = planned > 0 ? (spent / planned).clamp(0.0, 1.0) : 0.0;
    final over = planned > 0 && spent > planned;

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: over ? 1.0 : spentRatio),
      duration: const Duration(milliseconds: 700),
      curve: Curves.easeOutCubic,
      builder: (_, v, __) => ClipRRect(
        borderRadius: BorderRadius.circular(height),
        child: SizedBox(
          height: height,
          child: Stack(children: [
            Container(color: trackBg),
            if (planned > 0 && !over)
              FractionallySizedBox(widthFactor: 1.0, child: Container(color: plannedColor)),
            FractionallySizedBox(
              widthFactor: v,
              child: Container(color: over ? AppColors.error : color),
            ),
          ]),
        ),
      ),
    );
  }
}


class SimpleGoalsSection extends StatelessWidget {
  final bool isDark;
  final List<Goal> goals;
  final Map<String, double> contributedThisMonth;
  final VoidCallback onAdd;
  final ValueChanged<Goal>? onRowTap;
  final bool isLocked;
  final Set<String> linkedIds;

  const SimpleGoalsSection({super.key, required this.isDark, required this.goals, required this.onAdd, this.onRowTap, this.contributedThisMonth = const {}, this.isLocked = false, this.linkedIds = const {}});

  @override
  Widget build(BuildContext context) {
    final divColor = isDark ? AppColors.border.withValues(alpha: 0.15) : AppColors.border.withValues(alpha: 0.4);
    final textPrimary = isDark ? AppColors.primaryForeground : AppColors.textPrimary;

    return _SimpleSection(
      isDark: isDark,
      label: 'GOALS',
      trailing: goals.isEmpty ? null : '${goals.where((g) => g.status == GoalStatus.active).length} active',
      onAdd: onAdd,
      addLabel: 'Add Goal',
      isLocked: isLocked,
      child: goals.isEmpty
          ? _EmptyRow(isDark: isDark, text: 'No goals yet – tap Add Goal to get started')
          : Column(
              children: goals.asMap().entries.expand((e) {
                final i = e.key;
                final g = e.value;
                final progress = g.progress.clamp(0.0, 1.0);
                final isActive = g.status == GoalStatus.active;
                final baseColor = g.colorHex != null
                    ? Color(int.parse(g.colorHex!.replaceFirst('#', '0xff')))
                    : AppColors.accent;
                final color = isActive ? baseColor : baseColor.withValues(alpha: 0.45);
                final statusBadge = switch (g.status) {
                  GoalStatus.completed => ('Completed', AppColors.success),
                  GoalStatus.paused => ('Paused', AppColors.warning),
                  _ => (null, AppColors.accent),
                };

                return [
                  Divider(height: 1, thickness: 0.5, color: divColor, indent: 16, endIndent: 16),
                  TweenAnimationBuilder<double>(
                    key: ValueKey(g.id),
                    tween: Tween(begin: 0.0, end: 1.0),
                    duration: const Duration(milliseconds: 450),
                    curve: Interval(
                      (i * 0.08).clamp(0.0, 0.6),
                      ((i * 0.08) + 0.4).clamp(0.0, 1.0),
                      curve: Curves.easeOut,
                    ),
                    builder: (_, v, child) => Opacity(opacity: v, child: Transform.translate(offset: Offset(0, (1 - v) * 10), child: child)),
                    child: InkWell(
                    onTap: !isLocked && onRowTap != null ? () => onRowTap!(g) : null,
                    child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 13, 16, 13),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Row(children: [
                        Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
                        const SizedBox(width: 10),
                        Expanded(child: Text(g.name, style: GoogleFonts.dmSans(fontSize: 13, fontWeight: FontWeight.w600, color: isActive ? textPrimary : AppColors.textSecondary), maxLines: 1, overflow: TextOverflow.ellipsis)),
                        if (linkedIds.contains(g.id)) ...[const SizedBox(width: 6), const _LinkedBadge()],
                        if (statusBadge.$1 != null) ...[
                          const SizedBox(width: 6),
                          Container(padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2), decoration: BoxDecoration(color: statusBadge.$2.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(20)),
                              child: Text(statusBadge.$1!, style: GoogleFonts.dmSans(fontSize: 10, fontWeight: FontWeight.w600, color: statusBadge.$2))),
                        ],
                        if ((contributedThisMonth[g.id] ?? 0) > 0) ...[
                          const SizedBox(width: 6),
                          Container(padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2), decoration: BoxDecoration(color: AppColors.success.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(20)),
                              child: Text('contributed', style: GoogleFonts.dmSans(fontSize: 10, fontWeight: FontWeight.w600, color: AppColors.success))),
                        ],
                        const SizedBox(width: 6),
                        Text('${(progress * 100).round()}%', style: GoogleFonts.dmSans(fontSize: 11, fontWeight: FontWeight.w600, color: color)),
                      ]),
                      const SizedBox(height: 3),
                      Row(children: [
                        const SizedBox(width: 18),
                        Text(currencyFormatter.format(g.currentAmount, decimalDigits: 0), style: GoogleFonts.dmMono(fontSize: 11, color: color, fontFeatures: const [FontFeature.tabularFigures()])),
                        Text(' / ${currencyFormatter.format(g.targetAmount, decimalDigits: 0)}', style: GoogleFonts.dmSans(fontSize: 11, color: AppColors.textSecondary)),
                        if (g.targetDate != null) ...[
                          Text('  ·  Target ${DateFormat('MMM d').format(g.targetDate!)}', style: GoogleFonts.dmSans(fontSize: 10, color: AppColors.textTertiary)),
                        ],
                      ]),
                      const SizedBox(height: 8),
                      _HpBar(spent: g.currentAmount, planned: g.targetAmount, color: color, isDark: isDark, height: 5),
                    ]),
                  ),
                  ),
                  ),
                ];
              }).toList(),
            ),
    );
  }
}


class SimpleSavingsSummaryCard extends StatelessWidget {
  final bool isDark;
  final List<Wallet> buckets;

  const SimpleSavingsSummaryCard({super.key, required this.isDark, required this.buckets});

  @override
  Widget build(BuildContext context) {
    final total = buckets.fold(0.0, (s, b) => s + b.balance);
    final cardBg = isDark ? AppColors.cardDark : AppColors.card;
    final border = isDark ? AppColors.border.withValues(alpha: 0.2) : AppColors.border.withValues(alpha: 0.5);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(color: cardBg, borderRadius: BorderRadius.circular(14), border: Border.all(color: border, width: 0.5)),
        child: Row(children: [
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('TOTAL SAVINGS', style: GoogleFonts.dmSans(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.textTertiary, letterSpacing: 0.8)),
            const SizedBox(height: 4),
            Text(currencyFormatter.format(total), style: GoogleFonts.dmMono(fontSize: 26, fontWeight: FontWeight.w700, color: AppColors.info, fontFeatures: const [FontFeature.tabularFigures()])),
          ])),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(color: AppColors.info.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(20), border: Border.all(color: AppColors.info.withValues(alpha: 0.2))),
            child: Text('${buckets.length} bucket${buckets.length == 1 ? "" : "s"}', style: GoogleFonts.dmSans(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.info)),
          ),
        ]),
      ),
    );
  }
}


class SimpleSavingsSection extends StatelessWidget {
  final bool isDark;
  final List<Wallet> buckets;
  final VoidCallback onAdd;
  final void Function(Wallet) onRowTap;

  const SimpleSavingsSection({super.key, required this.isDark, required this.buckets, required this.onAdd, required this.onRowTap});

  @override
  Widget build(BuildContext context) {
    final divColor = isDark ? AppColors.border.withValues(alpha: 0.15) : AppColors.border.withValues(alpha: 0.4);
    final textPrimary = isDark ? AppColors.primaryForeground : AppColors.textPrimary;

    return _SimpleSection(
      isDark: isDark,
      label: 'SAVINGS BUCKETS',
      trailing: buckets.isEmpty ? null : '${buckets.length}',
      onAdd: onAdd,
      addLabel: 'Add Bucket',
      child: buckets.isEmpty
          ? _EmptyRow(isDark: isDark, text: 'No wallets yet')
          : Column(children: [
              ...buckets.map((b) {
                final color = b.colorHex != null
                    ? Color(int.parse(b.colorHex!.replaceFirst('#', '0xff')))
                    : AppColors.info;
                final icon = IconHelper.fromString(b.iconCodePoint);
                return Column(children: [
                  Divider(height: 1, thickness: 0.5, color: divColor, indent: 16, endIndent: 16),
                  InkWell(
                    onTap: () => onRowTap(b),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 11, 16, 11),
                      child: Row(children: [
                        Container(width: 32, height: 32, decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                            child: Icon(icon, size: 14, color: color)),
                        const SizedBox(width: 10),
                        Expanded(child: Text(b.name, style: GoogleFonts.dmSans(fontSize: 13, fontWeight: FontWeight.w500, color: textPrimary), maxLines: 1, overflow: TextOverflow.ellipsis)),
                        Text(currencyFormatter.format(b.balance, decimalDigits: 2),
                            style: GoogleFonts.dmMono(fontSize: 13, fontWeight: FontWeight.w600, color: color, fontFeatures: const [FontFeature.tabularFigures()])),
                        const SizedBox(width: 4),
                        Icon(Icons.chevron_right_rounded, size: 14, color: AppColors.textTertiary),
                      ]),
                    ),
                  ),
                ]);
              }),
            ]),
    );
  }
}


class SimpleDonutInsightCard extends StatelessWidget {
  final bool isDark;
  final List<Budget> budgets;
  final Map<String, double> spentByCategory;

  const SimpleDonutInsightCard({
    super.key,
    required this.isDark,
    required this.budgets,
    required this.spentByCategory,
  });

  static const _palette = [
    Color(0xFF4C6EF5), Color(0xFFF76707), Color(0xFFE64980),
    Color(0xFF7950F2), Color(0xFF12B886), Color(0xFF1C7ED6),
    Color(0xFFE67700), Color(0xFFAE3EC9), Color(0xFF0CA678),
    Color(0xFF3BC9DB),
  ];

  List<_RingRow> _rows(List<Budget> groups, Map<String, double> spent) {
    final cats = groups.expand((b) => b.categories).toList();
    return cats.asMap().entries
        .map((e) => _RingRow(
              name: e.value.financeCategory?.name ?? 'Category',
              planned: e.value.targetAmount,
              spent: spent[e.value.financeCategoryId] ?? 0.0,
              color: _palette[e.key % _palette.length],
            ))
        .where((r) => r.planned > 0 || r.spent > 0)
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final incomeGroups = budgets.where((b) => b.budgetType == BudgetType.income).toList();
    final expenseGroups = budgets.where((b) => b.budgetType == BudgetType.expense).toList();

    final incomeRows = _rows(incomeGroups, spentByCategory);
    final expenseRows = _rows(expenseGroups, spentByCategory);

    if (incomeRows.isEmpty && expenseRows.isEmpty) return const SizedBox.shrink();

    final actualIncome = incomeRows.fold(0.0, (s, r) => s + r.spent);
    final plannedIncome = incomeRows.fold(0.0, (s, r) => s + r.planned);
    final actualExpenses = expenseRows.fold(0.0, (s, r) => s + r.spent);
    final plannedExpenses = expenseRows.fold(0.0, (s, r) => s + r.planned);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 8, left: 2),
          child: Text('INSIGHTS', style: GoogleFonts.dmSans(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.textSecondary, letterSpacing: 1.2)),
        ),
        LayoutBuilder(builder: (_, constraints) {
          final isWide = constraints.maxWidth >= 380;

          final incomeCard = incomeRows.isNotEmpty
              ? _CompactRingCard(isDark: isDark, label: 'INCOME', actual: actualIncome, planned: plannedIncome, rows: incomeRows)
              : null;
          final expenseCard = expenseRows.isNotEmpty
              ? _CompactRingCard(isDark: isDark, label: 'EXPENSES', actual: actualExpenses, planned: plannedExpenses, rows: expenseRows)
              : null;

          if (isWide && incomeCard != null && expenseCard != null) {
            return IntrinsicHeight(
              child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                Expanded(child: incomeCard),
                const SizedBox(width: 10),
                Expanded(child: expenseCard),
              ]),
            );
          }

          return Column(children: [
            if (incomeCard != null) incomeCard,
            if (incomeCard != null && expenseCard != null) const SizedBox(height: 10),
            if (expenseCard != null) expenseCard,
          ]);
        }),
      ]),
    );
  }
}

class _RingRow {
  final String name;
  final double planned, spent;
  final Color color;
  const _RingRow({required this.name, required this.planned, required this.spent, required this.color});
  double get remaining => planned - spent;
}

class _CompactRingCard extends StatelessWidget {
  final bool isDark;
  final String label;
  final double actual, planned;
  final List<_RingRow> rows;

  const _CompactRingCard({
    required this.isDark,
    required this.label,
    required this.actual,
    required this.planned,
    required this.rows,
  });

  void _openDetail(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _RingDetailSheet(
        isDark: isDark,
        label: label,
        actual: actual,
        planned: planned,
        rows: rows,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final textPrimary = isDark ? AppColors.primaryForeground : AppColors.textPrimary;
    final cardBg = isDark ? AppColors.cardDark : AppColors.card;
    final border = isDark ? AppColors.border.withValues(alpha: 0.2) : AppColors.border.withValues(alpha: 0.5);

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 450),
      curve: Curves.easeOut,
      builder: (_, v, child) => Opacity(
        opacity: v,
        child: Transform.translate(offset: Offset(0, (1 - v) * 14), child: child),
      ),
      child: GestureDetector(
        onTap: () => _openDetail(context),
        child: Container(
          padding: const EdgeInsets.fromLTRB(12, 14, 12, 12),
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: border, width: 0.5),
          ),
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.0, end: 1.0),
              duration: const Duration(milliseconds: 800),
              curve: Curves.easeOutCubic,
              builder: (_, ringV, __) => SizedBox(
                width: 110, height: 110,
                child: CustomPaint(
                  painter: _RingPainter(rows: rows, showActual: true, isDark: isDark, animProgress: ringV),
                  child: Center(
                    child: Column(mainAxisSize: MainAxisSize.min, children: [
                      Text(label,
                          style: GoogleFonts.dmSans(fontSize: 9, fontWeight: FontWeight.w600, color: AppColors.textSecondary, letterSpacing: 0.5)),
                      const SizedBox(height: 2),
                      Text(
                        currencyFormatter.format(actual * ringV, decimalDigits: 0),
                        style: GoogleFonts.dmMono(fontSize: 12, fontWeight: FontWeight.w700, color: textPrimary, fontFeatures: const [FontFeature.tabularFigures()]),
                      ),
                    ]),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              Text('View details', style: GoogleFonts.dmSans(fontSize: 11, fontWeight: FontWeight.w500, color: AppColors.textSecondary)),
              const SizedBox(width: 2),
              Icon(Icons.chevron_right_rounded, size: 14, color: AppColors.textSecondary),
            ]),
          ]),
        ),
      ),
    );
  }
}

class _RingDetailSheet extends StatelessWidget {
  final bool isDark;
  final String label;
  final double actual, planned;
  final List<_RingRow> rows;

  const _RingDetailSheet({
    required this.isDark,
    required this.label,
    required this.actual,
    required this.planned,
    required this.rows,
  });

  @override
  Widget build(BuildContext context) {
    final sheetBg = isDark ? AppColors.void_ : Colors.white;
    final textPrimary = isDark ? AppColors.primaryForeground : AppColors.textPrimary;
    final divColor = isDark ? AppColors.border.withValues(alpha: 0.15) : AppColors.border.withValues(alpha: 0.4);

    return DraggableScrollableSheet(
      initialChildSize: 0.55,
      minChildSize: 0.4,
      maxChildSize: 0.85,
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
            child: Text(label, style: GoogleFonts.dmSans(fontSize: 15, fontWeight: FontWeight.w700, color: textPrimary)),
          ),
          Divider(height: 1, thickness: 0.5, color: divColor),
          Expanded(
            child: ListView(
              controller: controller,
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
              children: [
                TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0.0, end: 1.0),
                  duration: const Duration(milliseconds: 800),
                  curve: Curves.easeOutCubic,
                  builder: (_, ringV, __) => Center(
                    child: SizedBox(
                      width: 150, height: 150,
                      child: CustomPaint(
                        painter: _RingPainter(rows: rows, showActual: true, isDark: isDark, animProgress: ringV),
                        child: Center(
                          child: Column(mainAxisSize: MainAxisSize.min, children: [
                            Text(label, style: GoogleFonts.dmSans(fontSize: 10, fontWeight: FontWeight.w600, color: AppColors.textSecondary, letterSpacing: 0.5)),
                            const SizedBox(height: 3),
                            Text(
                              currencyFormatter.format(actual * ringV, decimalDigits: 0),
                              style: GoogleFonts.dmMono(fontSize: 17, fontWeight: FontWeight.w700, color: textPrimary, fontFeatures: const [FontFeature.tabularFigures()]),
                            ),
                            Text(
                              'actual',
                              style: GoogleFonts.dmSans(fontSize: 9, color: AppColors.textTertiary),
                            ),
                          ]),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Row(children: [
                  const Expanded(child: SizedBox()),
                  _RingColHead('PLANNED'),
                  const SizedBox(width: 10),
                  _RingColHead('SPENT'),
                  const SizedBox(width: 10),
                  _RingColHead('LEFT'),
                ]),
                const SizedBox(height: 8),
                Divider(height: 1, thickness: 0.5, color: divColor),
                ...rows.asMap().entries.map((e) {
                  final i = e.key;
                  final r = e.value;
                  return TweenAnimationBuilder<double>(
                    key: ValueKey(r.name),
                    tween: Tween(begin: 0.0, end: 1.0),
                    duration: const Duration(milliseconds: 500),
                    curve: Interval(
                      (i * 0.08).clamp(0.0, 0.6),
                      ((i * 0.08) + 0.4).clamp(0.0, 1.0),
                      curve: Curves.easeOut,
                    ),
                    builder: (_, v, child) => Opacity(
                      opacity: v,
                      child: Transform.translate(offset: Offset((1 - v) * 10, 0), child: child),
                    ),
                    child: Column(children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 11),
                        child: Row(children: [
                          Container(width: 7, height: 7, decoration: BoxDecoration(color: r.color, shape: BoxShape.circle)),
                          const SizedBox(width: 9),
                          Expanded(child: Text(r.name, style: GoogleFonts.dmSans(fontSize: 12, color: textPrimary), maxLines: 1, overflow: TextOverflow.ellipsis)),
                          _RingAmountCol(value: r.planned, color: AppColors.textTertiary),
                          const SizedBox(width: 10),
                          _RingAmountCol(value: r.spent, color: r.spent > r.planned && r.planned > 0 ? AppColors.error : textPrimary),
                          const SizedBox(width: 10),
                          _RingAmountCol(value: r.remaining, color: r.remaining < 0 ? AppColors.error : AppColors.success),
                        ]),
                      ),
                      Divider(height: 1, thickness: 0.5, color: divColor),
                    ]),
                  );
                }),
              ],
            ),
          ),
        ]),
      ),
    );
  }
}

class _RingColHead extends StatelessWidget {
  final String text;
  const _RingColHead(this.text);

  @override
  Widget build(BuildContext context) => SizedBox(
    width: 56,
    child: Text(text, textAlign: TextAlign.right,
        style: GoogleFonts.dmSans(fontSize: 9, fontWeight: FontWeight.w700, color: AppColors.textTertiary, letterSpacing: 0.4)),
  );
}

class _RingAmountCol extends StatelessWidget {
  final double value;
  final Color color;
  const _RingAmountCol({required this.value, required this.color});

  @override
  Widget build(BuildContext context) => SizedBox(
    width: 56,
    child: Text(
      '${value < 0 ? '-' : ''}${currencyFormatter.format(value.abs(), decimalDigits: 0)}',
      textAlign: TextAlign.right,
      style: GoogleFonts.dmMono(fontSize: 11, fontWeight: FontWeight.w500, color: color, fontFeatures: const [FontFeature.tabularFigures()]),
    ),
  );
}

class _RingPainter extends CustomPainter {
  final List<_RingRow> rows;
  final bool showActual;
  final bool isDark;
  final double animProgress;

  const _RingPainter({required this.rows, required this.showActual, required this.isDark, this.animProgress = 1.0});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 12;
    const strokeWidth = 13.0;
    const startAngle = -pi / 2;
    const gap = 0.04;

    final trackPaint = Paint()
      ..color = isDark ? Colors.white.withValues(alpha: 0.08) : AppColors.border.withValues(alpha: 0.45)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.butt;
    canvas.drawCircle(center, radius, trackPaint);

    final values = rows.map((r) => showActual ? r.spent : r.planned).toList();
    final total = values.fold(0.0, (s, v) => s + v);
    if (total <= 0) return;

    final rect = Rect.fromCircle(center: center, radius: radius);
    final arcPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.butt;

    double angle = startAngle;
    for (int i = 0; i < rows.length; i++) {
      if (values[i] <= 0) continue;
      final fullSweep = (values[i] / total) * 2 * pi;
      final animSweep = fullSweep * animProgress;
      arcPaint.color = rows[i].color;
      if (animSweep > gap) canvas.drawArc(rect, angle + gap / 2, animSweep - gap, false, arcPaint);
      angle += animSweep;
    }
  }

  @override
  bool shouldRepaint(_RingPainter old) => old.rows != rows || old.showActual != showActual || old.animProgress != animProgress;
}


class SimpleTransactionsSection extends StatefulWidget {
  final bool isDark;
  final List<Transaction> transactions;
  final Map<String, String> categoryNames;

  const SimpleTransactionsSection({
    super.key,
    required this.isDark,
    required this.transactions,
    this.categoryNames = const {},
  });

  @override
  State<SimpleTransactionsSection> createState() => _SimpleTransactionsSectionState();
}

class _SimpleTransactionsSectionState extends State<SimpleTransactionsSection> {
  static const _pageSize = 5;
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDark;
    final cardBg = isDark ? AppColors.cardDark : AppColors.card;
    final border = isDark ? AppColors.border.withValues(alpha: 0.2) : AppColors.border.withValues(alpha: 0.5);
    final divColor = isDark ? AppColors.border.withValues(alpha: 0.15) : AppColors.border.withValues(alpha: 0.4);
    final textPrimary = isDark ? AppColors.primaryForeground : AppColors.textPrimary;

    final sorted = [...widget.transactions]..sort((a, b) => b.date.compareTo(a.date));
    final hasMore = sorted.length > _pageSize;
    final visible = _expanded ? sorted : sorted.take(_pageSize).toList();

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 8, left: 2),
          child: Row(children: [
            Text('TRANSACTIONS', style: GoogleFonts.dmSans(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.textSecondary, letterSpacing: 1.2)),
            if (widget.transactions.isNotEmpty) ...[
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(color: AppColors.textSecondary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(20)),
                child: Text('${widget.transactions.length}', style: GoogleFonts.dmSans(fontSize: 10, color: AppColors.textSecondary, fontWeight: FontWeight.w600)),
              ),
            ],
          ]),
        ),
        Container(
          decoration: BoxDecoration(color: cardBg, borderRadius: BorderRadius.circular(14), border: Border.all(color: border, width: 0.5)),
          child: sorted.isEmpty
              ? Padding(
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  child: Center(child: Text('No transactions this period', style: GoogleFonts.dmSans(fontSize: 12, color: AppColors.textTertiary))),
                )
              : Column(children: [
                  ...visible.asMap().entries.map((e) {
                    final i = e.key;
                    final t = e.value;
                    final isIncome = t.type == TransactionType.income;
                    final color = isIncome ? AppColors.success : AppColors.error;
                    final sign = isIncome ? '+' : '-';
                    final catName = t.financeCategoryId != null ? widget.categoryNames[t.financeCategoryId] : null;

                    return TweenAnimationBuilder<double>(
                      key: ValueKey(t.id ?? i),
                      tween: Tween(begin: 0.0, end: 1.0),
                      duration: const Duration(milliseconds: 450),
                      curve: Interval(
                        (i * 0.08).clamp(0.0, 0.6),
                        ((i * 0.08) + 0.4).clamp(0.0, 1.0),
                        curve: Curves.easeOut,
                      ),
                      builder: (_, v, child) => Opacity(
                        opacity: v,
                        child: Transform.translate(offset: Offset(0, (1 - v) * 10), child: child),
                      ),
                      child: Column(children: [
                        if (i > 0) Divider(height: 1, thickness: 0.5, color: divColor, indent: 16, endIndent: 16),
                        InkWell(
                          onTap: () => TransactionDetailSheet.show(context, transaction: t),
                          child: Padding(
                          padding: const EdgeInsets.fromLTRB(16, 11, 16, 11),
                          child: Row(children: [
                            Container(
                              width: 32, height: 32,
                              decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                              child: Icon(isIncome ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded, size: 14, color: color),
                            ),
                            const SizedBox(width: 10),
                            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              Text(t.description ?? '–', style: GoogleFonts.dmSans(fontSize: 13, fontWeight: FontWeight.w500, color: textPrimary), maxLines: 1, overflow: TextOverflow.ellipsis),
                              Text(
                                [DateFormat('MMM d').format(t.date), if (catName != null) catName].join(' · '),
                                style: GoogleFonts.dmSans(fontSize: 11, color: AppColors.textSecondary),
                              ),
                            ])),
                            Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                              Text(
                                '$sign${currencyFormatter.format(t.amount, decimalDigits: 2)}',
                                style: GoogleFonts.dmMono(fontSize: 13, fontWeight: FontWeight.w600, color: color, fontFeatures: const [FontFeature.tabularFigures()]),
                              ),
                              if (t.hasFee)
                                Text('+${currencyFormatter.format(t.fee, decimalDigits: 2)} fee', style: GoogleFonts.dmSans(fontSize: 10, color: AppColors.textTertiary)),
                            ]),
                            const SizedBox(width: 4),
                            Icon(Icons.chevron_right_rounded, size: 14, color: AppColors.textTertiary),
                          ]),
                        )),
                      ]),
                    );
                  }),
                  if (hasMore) ...[
                    Divider(height: 1, thickness: 0.5, color: divColor),
                    GestureDetector(
                      onTap: () => setState(() => _expanded = !_expanded),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                          Text(
                            _expanded ? 'Show less' : 'View ${sorted.length - _pageSize} more',
                            style: GoogleFonts.dmSans(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.accent),
                          ),
                          const SizedBox(width: 4),
                          AnimatedRotation(
                            turns: _expanded ? 0.5 : 0,
                            duration: const Duration(milliseconds: 150),
                            child: Icon(Icons.keyboard_arrow_down_rounded, size: 16, color: AppColors.accent),
                          ),
                        ]),
                      ),
                    ),
                  ],
                ]),
        ),
      ]),
    );
  }
}
