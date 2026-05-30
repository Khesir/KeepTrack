import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:keep_track/core/theme/app_theme.dart';

import '../../../transaction/domain/entities/transaction.dart';
import '../../domain/entities/budget.dart';
import '../helpers/currency_formatter.dart';
import '../screens/budget_simple_sections.dart' show SimpleDonutInsightCard;

class AllSummaryTab extends StatelessWidget {
  final List<Budget> budgets;
  final List<Transaction> transactions;

  const AllSummaryTab({required this.budgets, required this.transactions});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = isDark ? AppColors.primaryForeground : AppColors.textPrimary;
    final cardBg = isDark ? const Color(0xFF242422) : AppColors.background;
    final divColor = AppColors.border.withValues(alpha: isDark ? 0.12 : 0.3);

    if (budgets.isEmpty) {
      return Center(
        child: Text(
          'No budget groups yet.',
          style: GoogleFonts.dmSans(fontSize: 13, color: AppColors.textTertiary),
        ),
      );
    }

    // Build spent map from transactions
    final spentByCategory = <String, double>{};
    for (final t in transactions) {
      if (t.financeCategoryId != null) {
        spentByCategory[t.financeCategoryId!] =
            (spentByCategory[t.financeCategoryId!] ?? 0.0) + t.amount;
      }
    }

    double groupActual(Budget b) =>
        b.categories.fold(0.0, (s, c) => s + (spentByCategory[c.financeCategoryId] ?? 0.0));

    final incomeBudgets = budgets.where((b) => b.budgetType == BudgetType.income).toList();
    final expenseBudgets = budgets.where((b) => b.budgetType == BudgetType.expense).toList();

    final plannedIncome = incomeBudgets.fold(0.0, (s, b) => s + b.budgetTarget);
    final actualIncome = incomeBudgets.fold(0.0, (s, b) => s + groupActual(b));
    final plannedExpenses = expenseBudgets.fold(0.0, (s, b) => s + b.budgetTarget);
    final actualExpenses = expenseBudgets.fold(0.0, (s, b) => s + groupActual(b));
    final netActual = actualIncome - actualExpenses;
    final netPlanned = plannedIncome - plannedExpenses;

    final incomeProgress = plannedIncome > 0 ? (actualIncome / plannedIncome).clamp(0.0, 1.0) : 0.0;
    final expenseProgress = plannedExpenses > 0 ? (actualExpenses / plannedExpenses).clamp(0.0, 1.0) : 0.0;
    final netColor = netActual >= 0 ? AppColors.success : AppColors.error;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Net Balance card ───────────────────────────────────────────
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
            decoration: BoxDecoration(
              color: netColor.withValues(alpha: isDark ? 0.12 : 0.07),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: netColor.withValues(alpha: 0.2), width: 0.5),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'NET BALANCE',
                  style: GoogleFonts.dmSans(
                    fontSize: 9, fontWeight: FontWeight.w700,
                    color: netColor, letterSpacing: 0.8,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  formatCurrency(netActual),
                  style: GoogleFonts.dmMono(
                    fontSize: 22, fontWeight: FontWeight.w700,
                    color: netColor,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Planned: ${formatCurrency(netPlanned)}',
                  style: GoogleFonts.dmSans(fontSize: 11, color: netColor.withValues(alpha: 0.7)),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // ── Income & Expense rows ──────────────────────────────────────
          Container(
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: divColor, width: 0.5),
            ),
            child: Column(
              children: [
                _ProgressRow(
                  isDark: isDark,
                  label: 'INCOME',
                  actual: actualIncome,
                  planned: plannedIncome,
                  progress: incomeProgress,
                  color: AppColors.success,
                  isOver: actualIncome > plannedIncome,
                ),
                Divider(height: 1, color: divColor),
                _ProgressRow(
                  isDark: isDark,
                  label: 'EXPENSES',
                  actual: actualExpenses,
                  planned: plannedExpenses,
                  progress: expenseProgress,
                  color: AppColors.error,
                  isOver: actualExpenses > plannedExpenses,
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // ── Budget groups breakdown ────────────────────────────────────
          if (budgets.isNotEmpty) ...[
            Text(
              'BUDGET GROUPS',
              style: GoogleFonts.dmSans(
                fontSize: 9, fontWeight: FontWeight.w700,
                color: AppColors.textTertiary, letterSpacing: 0.8,
              ),
            ),
            const SizedBox(height: 6),
            Container(
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: divColor, width: 0.5),
              ),
              child: Column(
                children: [
                  for (int i = 0; i < budgets.length; i++) ...[
                    if (i > 0) Divider(height: 1, color: divColor),
                    _GroupRow(
                      isDark: isDark,
                      group: budgets[i],
                      actual: groupActual(budgets[i]),
                    ),
                  ],
                ],
              ),
            ),
          ],

          const SizedBox(height: 12),

          // ── Category breakdown (compact stacked bar) ──────────────────
          _CategoryBreakdown(
            isDark: isDark,
            label: 'INCOME BREAKDOWN',
            labelColor: AppColors.success,
            budgets: incomeBudgets,
            spentByCategory: spentByCategory,
            palette: _incomePalette,
          ),
          if (incomeBudgets.isNotEmpty) const SizedBox(height: 10),
          _CategoryBreakdown(
            isDark: isDark,
            label: 'EXPENSE BREAKDOWN',
            labelColor: AppColors.error,
            budgets: expenseBudgets,
            spentByCategory: spentByCategory,
            palette: _expensePalette,
          ),

          const SizedBox(height: 20),

          // ── Insights ring cards (from simple view) ─────────────────────
          SimpleDonutInsightCard(
            isDark: isDark,
            budgets: budgets,
            spentByCategory: spentByCategory,
          ),

          const SizedBox(height: 8),
        ],
      ),
    );
  }

  static const _incomePalette = [
    Color(0xFF12B886), Color(0xFF2F9E44), Color(0xFF087F5B),
    Color(0xFF40C057), Color(0xFF63E6BE), Color(0xFF20C997),
  ];
  static const _expensePalette = [
    Color(0xFF4C6EF5), Color(0xFFF76707), Color(0xFFE64980),
    Color(0xFF7950F2), Color(0xFF1C7ED6), Color(0xFFE67700),
    Color(0xFFAE3EC9), Color(0xFF0CA678), Color(0xFFD6336C),
  ];
}

// ── Progress row (income / expenses) ─────────────────────────────────────────

class _ProgressRow extends StatelessWidget {
  final bool isDark;
  final String label;
  final double actual, planned, progress;
  final Color color;
  final bool isOver;

  const _ProgressRow({
    required this.isDark, required this.label, required this.actual,
    required this.planned, required this.progress, required this.color,
    required this.isOver,
  });

  @override
  Widget build(BuildContext context) {
    final textPrimary = isDark ? AppColors.primaryForeground : AppColors.textPrimary;
    final barColor = isOver ? (label == 'INCOME' ? AppColors.success : AppColors.error) : color;

    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 11, 14, 11),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                label,
                style: GoogleFonts.dmSans(
                  fontSize: 9, fontWeight: FontWeight.w700,
                  color: color, letterSpacing: 0.8,
                ),
              ),
              const Spacer(),
              Text(
                formatCurrency(actual),
                style: GoogleFonts.dmMono(
                  fontSize: 12, fontWeight: FontWeight.w700, color: textPrimary,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
              Text(
                ' / ${formatCurrency(planned)}',
                style: GoogleFonts.dmMono(
                  fontSize: 11, color: AppColors.textTertiary,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: progress),
            duration: const Duration(milliseconds: 700),
            curve: Curves.easeOutCubic,
            builder: (_, v, __) => ClipRRect(
              borderRadius: BorderRadius.circular(3),
              child: LinearProgressIndicator(
                value: v,
                minHeight: 5,
                backgroundColor: AppColors.textTertiary.withValues(alpha: 0.12),
                valueColor: AlwaysStoppedAnimation<Color>(barColor),
              ),
            ),
          ),
          const SizedBox(height: 3),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                planned > 0 ? '${(progress * 100).toStringAsFixed(0)}%' : '—',
                style: GoogleFonts.dmSans(fontSize: 10, color: AppColors.textTertiary),
              ),
              if (isOver)
                Text(
                  label == 'INCOME' ? '▲ over target' : '▲ over budget',
                  style: GoogleFonts.dmSans(
                    fontSize: 10, fontWeight: FontWeight.w600,
                    color: label == 'INCOME' ? AppColors.success : AppColors.error,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Individual budget group row ───────────────────────────────────────────────

class _GroupRow extends StatelessWidget {
  final bool isDark;
  final Budget group;
  final double actual;

  const _GroupRow({required this.isDark, required this.group, required this.actual});

  @override
  Widget build(BuildContext context) {
    final textPrimary = isDark ? AppColors.primaryForeground : AppColors.textPrimary;
    final isIncome = group.budgetType == BudgetType.income;
    final planned = group.budgetTarget;
    final progress = planned > 0 ? (actual / planned).clamp(0.0, 1.0) : 0.0;
    final isOver = actual > planned;
    final color = isOver
        ? (isIncome ? AppColors.success : AppColors.error)
        : (isIncome ? AppColors.success : AppColors.accent);

    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 9, 14, 9),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 6, height: 6,
                margin: const EdgeInsets.only(right: 6),
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              ),
              Expanded(
                child: Text(
                  group.title ?? (isIncome ? 'Income' : 'Expenses'),
                  style: GoogleFonts.dmSans(fontSize: 12, fontWeight: FontWeight.w500, color: textPrimary),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(
                formatCurrency(actual),
                style: GoogleFonts.dmMono(
                  fontSize: 11, fontWeight: FontWeight.w600, color: color,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
              Text(
                ' / ${formatCurrency(planned)}',
                style: GoogleFonts.dmMono(
                  fontSize: 10, color: AppColors.textTertiary,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ],
          ),
          const SizedBox(height: 5),
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: progress),
            duration: const Duration(milliseconds: 600),
            curve: Curves.easeOutCubic,
            builder: (_, v, __) => ClipRRect(
              borderRadius: BorderRadius.circular(2),
              child: LinearProgressIndicator(
                value: v,
                minHeight: 3,
                backgroundColor: AppColors.textTertiary.withValues(alpha: 0.1),
                valueColor: AlwaysStoppedAnimation<Color>(color),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Category breakdown (compact legend, no donut) ────────────────────────────

class _CategoryBreakdown extends StatelessWidget {
  final bool isDark;
  final String label;
  final Color labelColor;
  final List<Budget> budgets;
  final Map<String, double> spentByCategory;
  final List<Color> palette;

  const _CategoryBreakdown({
    required this.isDark, required this.label, required this.labelColor,
    required this.budgets, required this.spentByCategory, required this.palette,
  });

  @override
  Widget build(BuildContext context) {
    final textPrimary = isDark ? AppColors.primaryForeground : AppColors.textPrimary;
    final items = budgets
        .expand((b) => b.categories)
        .map((c) => (
          name: c.financeCategory?.name ?? '—',
          value: spentByCategory[c.financeCategoryId] ?? 0.0,
        ))
        .where((i) => i.value > 0)
        .toList();

    if (items.isEmpty) return const SizedBox.shrink();

    final total = items.fold(0.0, (s, i) => s + i.value);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.dmSans(
            fontSize: 9, fontWeight: FontWeight.w700,
            color: labelColor, letterSpacing: 0.8,
          ),
        ),
        const SizedBox(height: 6),
        // Stacked bar
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: SizedBox(
            height: 8,
            child: Row(
              children: [
                for (int i = 0; i < items.length; i++)
                  Flexible(
                    flex: (items[i].value / total * 1000).round(),
                    child: Container(color: palette[i % palette.length]),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        // Legend
        ...items.asMap().entries.map((e) {
          final color = palette[e.key % palette.length];
          final pct = total > 0 ? (e.value.value / total * 100).toStringAsFixed(0) : '0';
          return Padding(
            padding: const EdgeInsets.only(bottom: 3),
            child: Row(
              children: [
                Container(
                  width: 8, height: 8,
                  decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    e.value.name,
                    style: GoogleFonts.dmSans(fontSize: 11, color: textPrimary),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Text(
                  '$pct%',
                  style: GoogleFonts.dmSans(fontSize: 10, color: AppColors.textTertiary),
                ),
                const SizedBox(width: 8),
                Text(
                  formatCurrency(e.value.value),
                  style: GoogleFonts.dmMono(
                    fontSize: 11, fontWeight: FontWeight.w600, color: textPrimary,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }
}
