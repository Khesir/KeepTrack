import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:keep_track/core/settings/utils/currency_formatter.dart';
import 'package:keep_track/core/theme/app_theme.dart';
import 'package:keep_track/features/finance/modules/budget/domain/entities/budget.dart';
import 'package:keep_track/features/finance/modules/budget/domain/entities/month_plan.dart';
import 'package:keep_track/features/finance/modules/debt/domain/entities/debt.dart';
import 'package:keep_track/features/finance/modules/wallet/domain/entities/wallet.dart';
import 'package:keep_track/features/finance/modules/subscriptions/domain/entities/subscription.dart';

const _palette = [
  Color(0xFF6366F1), Color(0xFF10B981), Color(0xFFEF4444), Color(0xFFF59E0B),
  Color(0xFF3B82F6), Color(0xFF8B5CF6), Color(0xFF14B8A6), Color(0xFFF97316),
];


class InsightSpendingSection extends StatelessWidget {
  final List<Budget> allBudgets;
  final Map<String, double> spentByCategory;

  const InsightSpendingSection({super.key, required this.allBudgets, required this.spentByCategory});

  @override
  Widget build(BuildContext context) {
    final groups = allBudgets.map((b) {
      final spent = b.categories.fold(0.0, (s, c) => s + (spentByCategory[c.financeCategoryId] ?? 0.0));
      return (budget: b, spent: spent);
    }).where((d) => d.spent > 0).toList();

    final total = groups.fold(0.0, (s, d) => s + d.spent);

    return _ChartCard(
      title: 'Spending Breakdown',
      child: groups.isEmpty
          ? _emptyState('No spending data for this month')
          : Column(
              children: [
                SizedBox(
                  height: 200,
                  child: PieChart(
                    PieChartData(
                      sections: groups.asMap().entries.map((e) => PieChartSectionData(
                        value: e.value.spent,
                        color: _palette[e.key % _palette.length],
                        title: '',
                        radius: 40,
                      )).toList(),
                      centerSpaceRadius: 60,
                      sectionsSpace: 2,
                      startDegreeOffset: -90,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                ...groups.asMap().entries.map((e) => _LegendRow(
                  color: _palette[e.key % _palette.length],
                  label: e.value.budget.title ?? (e.value.budget.budgetType == BudgetType.income ? 'Income' : 'Expenses'),
                  amount: e.value.spent,
                  pct: total > 0 ? e.value.spent / total : 0,
                )),
              ],
            ),
    );
  }
}


class InsightBudgetBarsSection extends StatelessWidget {
  final List<Budget> allBudgets;
  final Map<String, double> spentByCategory;

  const InsightBudgetBarsSection({super.key, required this.allBudgets, required this.spentByCategory});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final labelColor = isDark ? Colors.white54 : Colors.black45;

    final groups = allBudgets.asMap().entries.map((e) {
      final b = e.value;
      final actual = b.categories.fold(0.0, (s, c) => s + (spentByCategory[c.financeCategoryId] ?? 0.0));
      final isIncome = b.budgetType == BudgetType.income;
      final color = isIncome ? AppColors.success : _palette[e.key % _palette.length];
      return (budget: b, actual: actual, color: color);
    }).toList();

    final maxY = groups.fold(0.0, (m, g) => [m, g.actual, g.budget.budgetTarget].reduce((a, b) => a > b ? a : b)) * 1.15;
    if (maxY == 0) return const SizedBox.shrink();

    return _ChartCard(
      title: 'Budget Performance',
      subtitle: 'Planned vs Actual',
      child: SizedBox(
        height: 220,
        child: BarChart(
          BarChartData(
            maxY: maxY,
            barGroups: groups.asMap().entries.map((e) => BarChartGroupData(
              x: e.key,
              barRods: [
                BarChartRodData(toY: e.value.budget.budgetTarget, color: e.value.color.withValues(alpha: 0.25), width: 14, borderRadius: BorderRadius.circular(3)),
                BarChartRodData(toY: e.value.actual, color: e.value.color, width: 14, borderRadius: BorderRadius.circular(3)),
              ],
              barsSpace: 3,
            )).toList(),
            titlesData: FlTitlesData(
              bottomTitles: AxisTitles(sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 32,
                getTitlesWidget: (v, _) {
                  final i = v.toInt();
                  if (i < 0 || i >= groups.length) return const SizedBox.shrink();
                  final title = groups[i].budget.title ?? (groups[i].budget.budgetType == BudgetType.income ? 'Inc' : 'Exp');
                  return Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(title.length > 6 ? '${title.substring(0, 5)}…' : title,
                        style: TextStyle(fontSize: 9, color: labelColor), textAlign: TextAlign.center),
                  );
                },
              )),
              leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
              rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
              topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            ),
            gridData: FlGridData(show: true, drawVerticalLine: false, getDrawingHorizontalLine: (_) => FlLine(color: labelColor.withValues(alpha: 0.3), strokeWidth: 0.5)),
            borderData: FlBorderData(show: false),
          ),
        ),
      ),
    );
  }
}

class InsightTrendSection extends StatelessWidget {
  final List<MonthPlan> plans;
  final List<Budget> allBudgets;

  const InsightTrendSection({super.key, required this.plans, required this.allBudgets});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final labelColor = isDark ? Colors.white54 : Colors.black45;
    final ordered = plans.reversed.toList();

    List<double> incomeSeries = ordered.map((p) =>
        allBudgets.where((b) => b.month == p.month && b.budgetType == BudgetType.income && b.status == BudgetStatus.active)
            .fold(0.0, (s, b) => s + b.budgetTarget)).toList();
    List<double> expenseSeries = ordered.map((p) =>
        allBudgets.where((b) => b.month == p.month && b.budgetType == BudgetType.expense && b.status == BudgetStatus.active)
            .fold(0.0, (s, b) => s + b.budgetTarget)).toList();

    final maxY = [...incomeSeries, ...expenseSeries].fold(0.0, (m, v) => v > m ? v : m) * 1.2;
    if (maxY == 0) return const SizedBox.shrink();

    List<String> xLabels = ordered.map((p) {
      if (p.month == null) return '';
      final parts = p.month!.split('-');
      if (parts.length != 2) return p.month!;
      return DateFormat('MMM').format(DateTime(int.parse(parts[0]), int.parse(parts[1])));
    }).toList();

    return _ChartCard(
      title: '6-Month Trend',
      subtitle: 'Planned income vs expenses',
      legend: Row(children: [
        _Dot(color: AppColors.success), const SizedBox(width: 4),
        Text('Income', style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary)),
        const SizedBox(width: 12),
        _Dot(color: AppColors.error), const SizedBox(width: 4),
        Text('Expenses', style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary)),
      ]),
      child: SizedBox(
        height: 180,
        child: LineChart(
          LineChartData(
            minY: 0, maxY: maxY,
            lineBarsData: [
              _lineSeries(incomeSeries, AppColors.success),
              _lineSeries(expenseSeries, AppColors.error),
            ],
            titlesData: FlTitlesData(
              bottomTitles: AxisTitles(sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 24,
                getTitlesWidget: (v, _) {
                  final i = v.toInt();
                  if (i < 0 || i >= xLabels.length) return const SizedBox.shrink();
                  return Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(xLabels[i], style: TextStyle(fontSize: 9, color: labelColor)),
                  );
                },
              )),
              leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
              rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
              topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            ),
            gridData: FlGridData(show: true, drawVerticalLine: false, getDrawingHorizontalLine: (_) => FlLine(color: labelColor.withValues(alpha: 0.3), strokeWidth: 0.5)),
            borderData: FlBorderData(show: false),
          ),
        ),
      ),
    );
  }

  LineChartBarData _lineSeries(List<double> values, Color color) => LineChartBarData(
    spots: values.asMap().entries.map((e) => FlSpot(e.key.toDouble(), e.value)).toList(),
    isCurved: true,
    color: color,
    barWidth: 2.5,
    dotData: FlDotData(getDotPainter: (_, __, ___, ____) => FlDotCirclePainter(radius: 3.5, color: color, strokeWidth: 2, strokeColor: Colors.white)),
    belowBarData: BarAreaData(show: true, color: color.withValues(alpha: 0.07)),
  );
}


class InsightSavingsSection extends StatelessWidget {
  final List<Wallet> buckets;
  final double total;

  const InsightSavingsSection({super.key, required this.buckets, required this.total});

  @override
  Widget build(BuildContext context) {
    if (buckets.length == 1) {
      return _ChartCard(
        title: 'Savings',
        child: _LegendRow(color: AppColors.success, label: buckets.first.name, amount: buckets.first.balance, pct: 1),
      );
    }

    return _ChartCard(
      title: 'Savings Allocation',
      child: Column(
        children: [
          SizedBox(
            height: 180,
            child: PieChart(
              PieChartData(
                sections: buckets.asMap().entries.map((e) => PieChartSectionData(
                  value: e.value.balance,
                  color: _palette[e.key % _palette.length],
                  title: '',
                  radius: 36,
                )).toList(),
                centerSpaceRadius: 54,
                sectionsSpace: 2,
                startDegreeOffset: -90,
              ),
            ),
          ),
          const SizedBox(height: 12),
          ...buckets.asMap().entries.map((e) => _LegendRow(
            color: _palette[e.key % _palette.length],
            label: e.value.name,
            amount: e.value.balance,
            pct: total > 0 ? e.value.balance / total : 0,
          )),
        ],
      ),
    );
  }
}


class InsightDebtSection extends StatelessWidget {
  final List<Debt> debts, receivables;
  final double totalDebt, totalReceivables;

  const InsightDebtSection({super.key, required this.debts, required this.receivables, required this.totalDebt, required this.totalReceivables});

  @override
  Widget build(BuildContext context) {
    final overdueCount = [...debts, ...receivables].where((d) => d.isOverdue).length;
    return _ChartCard(
      title: 'Debts & Receivables',
      child: Column(
        children: [
          Row(children: [
            Expanded(child: _StatBox(label: 'I Owe', value: currencyFormatter.format(totalDebt, decimalDigits: 0), color: AppColors.error)),
            const SizedBox(width: 10),
            Expanded(child: _StatBox(label: 'Owed to Me', value: currencyFormatter.format(totalReceivables, decimalDigits: 0), color: AppColors.success)),
            if (overdueCount > 0) ...[
              const SizedBox(width: 10),
              Expanded(child: _StatBox(label: 'Overdue', value: '$overdueCount item${overdueCount == 1 ? '' : 's'}', color: AppColors.warning)),
            ],
          ]),
        ],
      ),
    );
  }
}


class InsightSubscriptionsSection extends StatelessWidget {
  final List<Subscription> subs;

  const InsightSubscriptionsSection({super.key, required this.subs});

  double _monthly(Subscription s) {
    switch (s.billingCycle) {
      case BillingCycle.weekly: return s.amount * 4.33;
      case BillingCycle.monthly: return s.amount;
      case BillingCycle.quarterly: return s.amount / 3;
      case BillingCycle.annual: return s.amount / 12;
    }
  }

  @override
  Widget build(BuildContext context) {
    final monthlyTotal = subs.fold(0.0, (s, sub) => s + _monthly(sub));
    final upcoming = subs.where((s) => s.isUpcoming || s.isOverdue).length;

    return _ChartCard(
      title: 'Subscriptions',
      child: Row(children: [
        Expanded(child: _StatBox(label: 'Active', value: '${subs.length}', color: AppColors.accent)),
        const SizedBox(width: 10),
        Expanded(child: _StatBox(label: 'Monthly cost', value: currencyFormatter.format(monthlyTotal, decimalDigits: 0), color: AppColors.error)),
        const SizedBox(width: 10),
        Expanded(child: _StatBox(label: 'Due soon', value: '$upcoming', color: upcoming > 0 ? AppColors.warning : AppColors.textTertiary)),
      ]),
    );
  }
}


class _ChartCard extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget? legend;
  final Widget child;

  const _ChartCard({required this.title, required this.child, this.subtitle, this.legend});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF18181B) : AppColors.surface,
          border: Border.all(color: isDark ? Colors.white12 : AppColors.border),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(title, style: AppTextStyles.h4),
                  if (subtitle != null) Text(subtitle!, style: AppTextStyles.caption.copyWith(color: AppColors.textTertiary)),
                ]),
                if (legend != null) ...[const Spacer(), legend!],
              ],
            ),
            const SizedBox(height: 16),
            child,
          ],
        ),
      ),
    );
  }
}

class _LegendRow extends StatelessWidget {
  final Color color;
  final String label;
  final double amount, pct;

  const _LegendRow({required this.color, required this.label, required this.amount, required this.pct});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(width: 10, height: 10, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
          const SizedBox(width: 8),
          Expanded(child: Text(label, style: AppTextStyles.bodySmall.copyWith(fontWeight: FontWeight.w500), maxLines: 1, overflow: TextOverflow.ellipsis)),
          Text(currencyFormatter.format(amount, decimalDigits: 0), style: AppTextStyles.bodySmall.copyWith(fontWeight: FontWeight.w600)),
          const SizedBox(width: 8),
          SizedBox(width: 36, child: Text('${(pct * 100).round()}%', style: AppTextStyles.caption.copyWith(color: AppColors.textTertiary), textAlign: TextAlign.right)),
        ],
      ),
    );
  }
}

class _StatBox extends StatelessWidget {
  final String label, value;
  final Color color;

  const _StatBox({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: AppTextStyles.caption.copyWith(color: AppColors.textTertiary)),
      const SizedBox(height: 2),
      Text(value, style: AppTextStyles.bodyMedium.copyWith(color: color, fontWeight: FontWeight.w700), maxLines: 1, overflow: TextOverflow.ellipsis),
    ]);
  }
}

class _Dot extends StatelessWidget {
  final Color color;
  const _Dot({required this.color});

  @override
  Widget build(BuildContext context) =>
      Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle));
}

Widget _emptyState(String msg) => Padding(
  padding: const EdgeInsets.symmetric(vertical: 24),
  child: Center(child: Text(msg, style: AppTextStyles.bodySmall.copyWith(color: AppColors.textTertiary))),
);
