import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:keep_track/core/settings/utils/currency_formatter.dart';
import 'package:keep_track/core/theme/app_theme.dart';
import 'package:keep_track/features/finance/modules/budget/domain/entities/budget.dart';
import 'package:keep_track/features/finance/modules/budget/domain/entities/budget_category.dart';
import 'package:keep_track/features/finance/modules/budget/presentation/widgets/ghost_add_row.dart';
import 'package:keep_track/core/utils/icon_helper.dart';
import 'package:keep_track/features/finance/modules/debt/domain/entities/debt.dart';
import 'package:keep_track/features/finance/modules/goal/domain/entities/goal.dart';
import 'package:keep_track/features/finance/modules/savings/domain/entities/savings_bucket.dart';
import 'package:keep_track/features/finance/modules/subscriptions/domain/entities/subscription.dart';

// ─── Month Nav ────────────────────────────────────────────────────────────────

class SimpleMonthNav extends StatelessWidget {
  final DateTime month;
  final bool isDark;
  final VoidCallback onPrev;
  final VoidCallback? onNext;
  final VoidCallback? onSettings;

  final VoidCallback? onToggleView;

  const SimpleMonthNav({super.key, required this.month, required this.isDark, required this.onPrev, this.onNext, this.onSettings, this.onToggleView});

  @override
  Widget build(BuildContext context) {
    final textPrimary = isDark ? AppColors.primaryForeground : AppColors.textPrimary;
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 16, 8, 0),
      child: Row(
        children: [
          IconButton(icon: Icon(Icons.chevron_left_rounded, color: AppColors.textSecondary), onPressed: onPrev, padding: EdgeInsets.zero, constraints: const BoxConstraints(minWidth: 36, minHeight: 36)),
          Expanded(child: Text(DateFormat('MMMM yyyy').format(month), style: GoogleFonts.dmSans(fontSize: 15, fontWeight: FontWeight.w600, color: textPrimary), textAlign: TextAlign.center)),
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

// ─── Net Balance Card ─────────────────────────────────────────────────────────

class SimpleNetCard extends StatelessWidget {
  final bool isDark;
  final double net, plannedNet, actualIncome, plannedIncome, actualExpenses, plannedExpenses;

  const SimpleNetCard({super.key, required this.isDark, required this.net, required this.plannedNet, required this.actualIncome, required this.plannedIncome, required this.actualExpenses, required this.plannedExpenses});

  @override
  Widget build(BuildContext context) {
    final isPos = net >= 0;
    final cardBg = isDark ? const Color(0xFF2C2C2A) : Colors.white;
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
          Text('${isPos ? '+' : '-'}${currencyFormatter.format(net.abs(), decimalDigits: 2)}',
              style: GoogleFonts.dmMono(fontSize: 30, fontWeight: FontWeight.w700, color: netColor, letterSpacing: -1, fontFeatures: const [FontFeature.tabularFigures()])),
          if (plannedNet != 0) ...[
            const SizedBox(height: 2),
            Text('${plannedNet >= 0 ? '+' : ''}${currencyFormatter.format(plannedNet, decimalDigits: 0)} planned',
                style: GoogleFonts.dmSans(fontSize: 11, color: AppColors.textTertiary)),
          ],
          const SizedBox(height: 14),
          Row(children: [
            Expanded(child: _NetStat(isDark: isDark, label: 'Income', icon: Icons.arrow_downward_rounded, actual: actualIncome, planned: plannedIncome, color: AppColors.success, textPrimary: textPrimary)),
            const SizedBox(width: 10),
            Expanded(child: _NetStat(isDark: isDark, label: 'Expenses', icon: Icons.arrow_upward_rounded, actual: actualExpenses, planned: plannedExpenses, color: AppColors.error, textPrimary: textPrimary)),
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
        ClipRRect(borderRadius: BorderRadius.circular(2), child: LinearProgressIndicator(value: progress, minHeight: 3, backgroundColor: isDark ? Colors.white.withValues(alpha: 0.06) : AppColors.border, valueColor: AlwaysStoppedAnimation<Color>(color))),
      ]),
    );
  }
}

// ─── Subscriptions Summary Card ──────────────────────────────────────────────

class SimpleSubsSummaryCard extends StatelessWidget {
  final bool isDark;
  final List<Subscription> subs;
  final DateTime month;

  const SimpleSubsSummaryCard({super.key, required this.isDark, required this.subs, required this.month});

  bool _paidThisMonth(Subscription s) =>
      s.lastBilledDate != null && s.lastBilledDate!.year == month.year && s.lastBilledDate!.month == month.month;

  @override
  Widget build(BuildContext context) {
    final cardBg = isDark ? const Color(0xFF2C2C2A) : Colors.white;
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
          Text(currencyFormatter.format(monthlyTotal, decimalDigits: 2),
              style: GoogleFonts.dmMono(fontSize: 30, fontWeight: FontWeight.w700, color: AppColors.error, letterSpacing: -1, fontFeatures: const [FontFeature.tabularFigures()])),
          const SizedBox(height: 12),
          Row(children: [
            _SummaryPill(label: '$paidCount paid', color: AppColors.success, isDark: isDark),
            const SizedBox(width: 8),
            _SummaryPill(label: '$dueCount due', color: dueCount > 0 ? AppColors.warning : AppColors.textTertiary, isDark: isDark),
            const SizedBox(width: 8),
            _SummaryPill(label: '${subs.length} total', color: AppColors.textSecondary, isDark: isDark),
          ]),
        ]),
      ),
    );
  }
}

// ─── Debts Summary Card ───────────────────────────────────────────────────────

class SimpleDebtSummaryCard extends StatelessWidget {
  final bool isDark;
  final double totalOwed, totalReceivable;
  final int debtCount, receivableCount;

  const SimpleDebtSummaryCard({super.key, required this.isDark, required this.totalOwed, required this.totalReceivable, required this.debtCount, required this.receivableCount});

  @override
  Widget build(BuildContext context) {
    final cardBg = isDark ? const Color(0xFF2C2C2A) : Colors.white;
    final border = isDark ? AppColors.border.withValues(alpha: 0.2) : AppColors.border.withValues(alpha: 0.5);

    // Single-type view (debts only or receivables only)
    final isDebtsOnly = totalReceivable == 0;
    final isReceivablesOnly = totalOwed == 0;

    if (isDebtsOnly || isReceivablesOnly) {
      final amount = isDebtsOnly ? totalOwed : totalReceivable;
      final count = isDebtsOnly ? debtCount : receivableCount;
      final color = isDebtsOnly ? AppColors.error : AppColors.success;
      final label = isDebtsOnly ? 'TOTAL OWED' : 'TOTAL RECEIVABLE';
      final countLabel = isDebtsOnly ? '$count active debt${count == 1 ? '' : 's'}' : '$count active receivable${count == 1 ? '' : 's'}';

      return Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(color: cardBg, borderRadius: BorderRadius.circular(14), border: Border.all(color: border, width: 0.5)),
          child: Row(children: [
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(label, style: GoogleFonts.dmSans(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.textTertiary, letterSpacing: 0.8)),
              const SizedBox(height: 4),
              Text(currencyFormatter.format(amount), style: GoogleFonts.dmMono(fontSize: 26, fontWeight: FontWeight.w700, color: color, fontFeatures: const [FontFeature.tabularFigures()])),
            ])),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(color: color.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(20), border: Border.all(color: color.withValues(alpha: 0.2))),
              child: Text(countLabel, style: GoogleFonts.dmSans(fontSize: 12, fontWeight: FontWeight.w600, color: color)),
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
          Text('${isPositive ? '+' : ''}${currencyFormatter.format(net, decimalDigits: 2)}',
              style: GoogleFonts.dmMono(fontSize: 30, fontWeight: FontWeight.w700, color: isPositive ? AppColors.success : AppColors.error, letterSpacing: -1, fontFeatures: const [FontFeature.tabularFigures()])),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(child: _StatMini(label: 'I Owe', value: currencyFormatter.format(totalOwed, decimalDigits: 0), count: '$debtCount active', color: AppColors.error, isDark: isDark)),
            const SizedBox(width: 10),
            Expanded(child: _StatMini(label: 'Owed to Me', value: currencyFormatter.format(totalReceivable, decimalDigits: 0), count: '$receivableCount active', color: AppColors.success, isDark: isDark)),
          ]),
        ]),
      ),
    );
  }
}

// ─── Goals Summary Card ───────────────────────────────────────────────────────

class SimpleGoalsSummaryCard extends StatelessWidget {
  final bool isDark;
  final List<Goal> goals;

  const SimpleGoalsSummaryCard({super.key, required this.isDark, required this.goals});

  @override
  Widget build(BuildContext context) {
    final cardBg = isDark ? const Color(0xFF2C2C2A) : Colors.white;
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
          Text(currencyFormatter.format(totalSaved, decimalDigits: 2),
              style: GoogleFonts.dmMono(fontSize: 30, fontWeight: FontWeight.w700, color: AppColors.accent, letterSpacing: -1, fontFeatures: const [FontFeature.tabularFigures()])),
          if (totalTarget > 0) ...[
            const SizedBox(height: 4),
            Text('of ${currencyFormatter.format(totalTarget, decimalDigits: 0)} target · ${(overallProgress * 100).round()}% overall',
                style: GoogleFonts.dmSans(fontSize: 11, color: AppColors.textTertiary)),
            const SizedBox(height: 10),
            ClipRRect(borderRadius: BorderRadius.circular(3), child: LinearProgressIndicator(
              value: overallProgress, minHeight: 5,
              backgroundColor: isDark ? Colors.white.withValues(alpha: 0.06) : AppColors.border,
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.accent),
            )),
          ],
          const SizedBox(height: 12),
          Row(children: [
            _SummaryPill(label: '$activeCount active', color: AppColors.accent, isDark: isDark),
            const SizedBox(width: 8),
            if (completedCount > 0) _SummaryPill(label: '$completedCount completed', color: AppColors.success, isDark: isDark),
          ]),
        ]),
      ),
    );
  }
}

// ─── Shared summary helpers ───────────────────────────────────────────────────

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

// ─── Budget Groups Section ────────────────────────────────────────────────────

class SimpleBudgetSection extends StatelessWidget {
  final bool isDark, isIncome;
  final String label;
  final List<Budget> groups;
  final Map<String, double> spentByCategory;
  final VoidCallback? onAddGroup;
  final void Function(Budget)? onAddCategory, onEditGroup;
  final void Function(Budget, BudgetCategory, double)? onCategoryTap;

  const SimpleBudgetSection({super.key, required this.isDark, required this.label, required this.groups, required this.spentByCategory, required this.isIncome, this.onAddGroup, this.onAddCategory, this.onEditGroup, this.onCategoryTap});

  @override
  Widget build(BuildContext context) {
    final cardBg = isDark ? const Color(0xFF2C2C2A) : Colors.white;
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
                    final divColor = isDark ? AppColors.border.withValues(alpha: 0.15) : AppColors.border.withValues(alpha: 0.4);
                    return [
                      if (e.key > 0) Divider(height: 1, thickness: 0.5, color: divColor, indent: 16, endIndent: 16),
                      _GroupRow(isDark: isDark, budget: e.value, spentByCategory: spentByCategory, isIncome: isIncome, onAddCategory: onAddCategory, onEditGroup: onEditGroup, onCategoryTap: onCategoryTap),
                    ];
                  }).toList(),
                ),
        ),
      ]),
    );
  }
}

class _GroupRow extends StatefulWidget {
  final bool isDark, isIncome;
  final Budget budget;
  final Map<String, double> spentByCategory;
  final void Function(Budget)? onAddCategory, onEditGroup;
  final void Function(Budget, BudgetCategory, double)? onCategoryTap;

  const _GroupRow({required this.isDark, required this.budget, required this.spentByCategory, required this.isIncome, this.onAddCategory, this.onEditGroup, this.onCategoryTap});

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
    final spent = b.categories.fold(0.0, (s, c) => s + (widget.spentByCategory[c.financeCategoryId] ?? 0.0));
    final planned = b.budgetTarget;
    final over = planned > 0 && spent > planned;
    final barColor = over ? AppColors.error : color;
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
              Text(currencyFormatter.format(spent, decimalDigits: 0), style: GoogleFonts.dmMono(fontSize: 13, fontWeight: FontWeight.w600, color: over ? AppColors.error : textPrimary, fontFeatures: const [FontFeature.tabularFigures()])),
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
      if (_expanded)
        Container(
          color: isDark ? Colors.white.withValues(alpha: 0.02) : AppColors.background.withValues(alpha: 0.5),
          child: Column(children: [
            ...b.categories.map((cat) {
              final catSpent = widget.spentByCategory[cat.financeCategoryId] ?? 0.0;
              final catPlanned = cat.targetAmount;
              final catOver = catPlanned > 0 && catSpent > catPlanned;
              return Column(children: [
                Divider(height: 1, thickness: 0.5, color: divColor),
                InkWell(
                  onTap: widget.onCategoryTap != null ? () => widget.onCategoryTap!(b, cat, catSpent) : null,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(34, 10, 16, 10),
                    child: Row(children: [
                      Expanded(child: Text(cat.financeCategory?.name ?? 'Category', style: GoogleFonts.dmSans(fontSize: 12, color: AppColors.textSecondary), maxLines: 1, overflow: TextOverflow.ellipsis)),
                      Text(currencyFormatter.format(catSpent, decimalDigits: 0), style: GoogleFonts.dmMono(fontSize: 12, fontWeight: FontWeight.w500, color: catOver ? AppColors.error : textPrimary, fontFeatures: const [FontFeature.tabularFigures()])),
                      Text(' / ${currencyFormatter.format(catPlanned, decimalDigits: 0)}', style: GoogleFonts.dmSans(fontSize: 10, color: AppColors.textTertiary)),
                      const SizedBox(width: 10),
                      SizedBox(width: 52, child: _HpBar(spent: catSpent, planned: catPlanned, color: catOver ? AppColors.error : color, isDark: isDark, height: 4)),
                      const SizedBox(width: 4),
                      Icon(Icons.chevron_right_rounded, size: 14, color: AppColors.textTertiary),
                    ]),
                  ),
                ),
              ]);
            }),
            Divider(height: 1, thickness: 0.5, color: divColor),
            if (widget.onAddCategory != null)
              GhostAddRow(label: 'Add Category', onTap: () => widget.onAddCategory!(b)),
          ]),
        ),
    ]);
  }
}

// ─── Subscriptions Section ────────────────────────────────────────────────────

class SimpleSubscriptionsSection extends StatelessWidget {
  final bool isDark;
  final List<Subscription> subs;
  final DateTime month;
  final VoidCallback onAdd;
  final void Function(Subscription) onRowTap;
  final void Function(Subscription)? onSkip;

  const SimpleSubscriptionsSection({super.key, required this.isDark, required this.subs, required this.month, required this.onAdd, required this.onRowTap, this.onSkip});

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
      child: entries.isEmpty
          ? _EmptyRow(isDark: isDark, text: 'No subscriptions yet')
          : Column(
              children: entries.expand((entry) {
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
                  InkWell(
                    onTap: () => onRowTap(s),
                    child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 11, 12, 11),
                    child: Row(children: [
                      Container(width: 8, height: 8, margin: const EdgeInsets.only(right: 10), decoration: BoxDecoration(color: badgeColor, shape: BoxShape.circle)),
                      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(s.name, style: GoogleFonts.dmSans(fontSize: 13, fontWeight: FontWeight.w500, color: entry.paid ? AppColors.textSecondary : textPrimary), maxLines: 1, overflow: TextOverflow.ellipsis),
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

// ─── Debts & Receivables Section ─────────────────────────────────────────────

class SimpleDebtsSection extends StatelessWidget {
  final bool isDark;
  final List<Debt> debts, receivables;
  final Map<String, double> paidThisMonth;
  final VoidCallback onAddDebt, onAddReceivable;
  final void Function(Debt) onRowTap;

  const SimpleDebtsSection({super.key, required this.isDark, required this.debts, required this.receivables, required this.onAddDebt, required this.onAddReceivable, required this.onRowTap, this.paidThisMonth = const {}});

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
      child: (debts.isEmpty && receivables.isEmpty)
          ? _EmptyRow(isDark: isDark, text: emptyLabel)
          : Column(children: [
              ...debts.expand((d) => [
                Divider(height: 1, thickness: 0.5, color: divColor, indent: 16, endIndent: 16),
                _DebtRow(isDark: isDark, debt: d, textPrimary: textPrimary, paidThisMonth: paidThisMonth[d.id] ?? 0, onTap: () => onRowTap(d)),
              ]),
              ...receivables.expand((d) => [
                Divider(height: 1, thickness: 0.5, color: divColor, indent: 16, endIndent: 16),
                _DebtRow(isDark: isDark, debt: d, textPrimary: textPrimary, paidThisMonth: paidThisMonth[d.id] ?? 0, onTap: () => onRowTap(d)),
              ]),
            ]),
    );
  }
}

class _DebtRow extends StatelessWidget {
  final bool isDark;
  final Debt debt;
  final Color textPrimary;
  final double paidThisMonth;
  final VoidCallback onTap;

  const _DebtRow({required this.isDark, required this.debt, required this.textPrimary, required this.onTap, this.paidThisMonth = 0});

  @override
  Widget build(BuildContext context) {
    final isReceivable = debt.type == DebtType.lending;
    final isSettled = debt.status == DebtStatus.settled;
    final baseColor = isReceivable ? AppColors.success : AppColors.error;
    final color = isSettled ? baseColor.withValues(alpha: 0.4) : baseColor;
    final icon = isReceivable ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded;
    final hasMonthly = debt.monthlyPaymentAmount > 0;

    return InkWell(
      onTap: isSettled ? null : onTap,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 11, 16, 11),
        child: Row(children: [
          Container(width: 32, height: 32, decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)), child: Icon(icon, size: 14, color: color)),
          const SizedBox(width: 10),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(debt.personName, style: GoogleFonts.dmSans(fontSize: 13, fontWeight: FontWeight.w500, color: isSettled ? AppColors.textSecondary : textPrimary), maxLines: 1, overflow: TextOverflow.ellipsis),
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
              isSettled ? 'Settled' : currencyFormatter.format(debt.remainingAmount, decimalDigits: 2),
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
          if (!isSettled) ...[
            const SizedBox(width: 4),
            Icon(Icons.chevron_right_rounded, size: 14, color: AppColors.textTertiary),
          ],
        ]),
      ),
    );
  }
}

// ─── Shared Section Shell ─────────────────────────────────────────────────────

class _SimpleSection extends StatelessWidget {
  final bool isDark;
  final String label;
  final String? trailing, addLabel;
  final Color? trailingColor;
  final VoidCallback onAdd;
  final Widget? extraAction;
  final Widget child;

  const _SimpleSection({required this.isDark, required this.label, this.trailing, this.trailingColor, required this.onAdd, this.addLabel, this.extraAction, required this.child});

  @override
  Widget build(BuildContext context) {
    final cardBg = isDark ? const Color(0xFF2C2C2A) : Colors.white;
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

// ─── HP Bar ───────────────────────────────────────────────────────────────────

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

    return ClipRRect(
      borderRadius: BorderRadius.circular(height),
      child: SizedBox(
        height: height,
        child: Stack(children: [
          // Track (empty)
          Container(color: trackBg),
          // Planned extension (lighter fill up to 100%)
          if (planned > 0 && !over)
            FractionallySizedBox(
              widthFactor: 1.0,
              child: Container(color: plannedColor),
            ),
          // Spent (solid fill)
          FractionallySizedBox(
            widthFactor: over ? 1.0 : spentRatio,
            child: Container(color: over ? AppColors.error : color),
          ),
        ]),
      ),
    );
  }
}

// ─── Goals Section ────────────────────────────────────────────────────────────

class SimpleGoalsSection extends StatelessWidget {
  final bool isDark;
  final List<Goal> goals;
  final Map<String, double> contributedThisMonth;
  final VoidCallback onAdd;
  final ValueChanged<Goal>? onRowTap;

  const SimpleGoalsSection({super.key, required this.isDark, required this.goals, required this.onAdd, this.onRowTap, this.contributedThisMonth = const {}});

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
      child: goals.isEmpty
          ? _EmptyRow(isDark: isDark, text: 'No goals yet — tap Add Goal to get started')
          : Column(
              children: goals.asMap().entries.expand((e) {
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
                  InkWell(
                    onTap: onRowTap != null ? () => onRowTap!(g) : null,
                    child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 13, 16, 13),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Row(children: [
                        Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
                        const SizedBox(width: 10),
                        Expanded(child: Text(g.name, style: GoogleFonts.dmSans(fontSize: 13, fontWeight: FontWeight.w600, color: isActive ? textPrimary : AppColors.textSecondary), maxLines: 1, overflow: TextOverflow.ellipsis)),
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
                ];
              }).toList(),
            ),
    );
  }
}

// ─── Savings Summary Card ─────────────────────────────────────────────────────

class SimpleSavingsSummaryCard extends StatelessWidget {
  final bool isDark;
  final List<SavingsBucket> buckets;

  const SimpleSavingsSummaryCard({super.key, required this.isDark, required this.buckets});

  @override
  Widget build(BuildContext context) {
    final total = buckets.fold(0.0, (s, b) => s + b.balance);
    final cardBg = isDark ? const Color(0xFF2C2C2A) : Colors.white;
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

// ─── Savings Section ──────────────────────────────────────────────────────────

class SimpleSavingsSection extends StatelessWidget {
  final bool isDark;
  final List<SavingsBucket> buckets;
  final VoidCallback onAdd;
  final void Function(SavingsBucket) onRowTap;

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
          ? _EmptyRow(isDark: isDark, text: 'No savings buckets yet')
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
