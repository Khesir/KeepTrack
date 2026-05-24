import 'dart:math' show max;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:keep_track/core/settings/utils/currency_formatter.dart';
import 'package:keep_track/core/theme/app_theme.dart';
import 'package:keep_track/features/finance/modules/budget/domain/entities/budget.dart';
import 'package:keep_track/features/finance/modules/transaction/domain/entities/transaction.dart';

enum _InsightRange { ytd, m3, m6, m9, m12, year }

class _ChartItem {
  final String name;
  final double amount;
  final Color color;
  const _ChartItem({required this.name, required this.amount, required this.color});
}

const _kPalette = [
  Color(0xFFEF4444), Color(0xFFF97316), Color(0xFFEAB308),
  Color(0xFF22C55E), Color(0xFF3B82F6), Color(0xFF8B5CF6),
  Color(0xFFEC4899), Color(0xFF14B8A6), Color(0xFFF59E0B),
  Color(0xFF6366F1),
];

class DashboardInsights extends StatefulWidget {
  final bool isDark;
  final List<Transaction> transactions;
  final List<Budget> budgets;

  const DashboardInsights({
    super.key,
    required this.isDark,
    required this.transactions,
    required this.budgets,
  });

  @override
  State<DashboardInsights> createState() => _DashboardInsightsState();
}

class _DashboardInsightsState extends State<DashboardInsights> with TickerProviderStateMixin {
  _InsightRange _range = _InsightRange.ytd;
  int _selectedYear = DateTime.now().year;
  String? _selectedBudgetTitle;

  late AnimationController _donutAnim;
  late AnimationController _barsAnim;
  late AnimationController _compAnim;
  bool _donutTriggered = false;
  bool _barsTriggered = false;
  bool _compTriggered = false;
  int? _selectedBarIdx;
  int? _selectedCompIdx;
  final _donutKey = GlobalKey();
  final _barsKey = GlobalKey();
  final _compKey = GlobalKey();
  ScrollPosition? _scrollPosition;

  @override
  void initState() {
    super.initState();
    _donutAnim = AnimationController(vsync: this, duration: const Duration(milliseconds: 900));
    _barsAnim = AnimationController(vsync: this, duration: const Duration(milliseconds: 700));
    _compAnim = AnimationController(vsync: this, duration: const Duration(milliseconds: 700));
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkVisibility());
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _scrollPosition?.removeListener(_checkVisibility);
    _scrollPosition = Scrollable.maybeOf(context)?.position;
    _scrollPosition?.addListener(_checkVisibility);
  }

  @override
  void dispose() {
    _scrollPosition?.removeListener(_checkVisibility);
    _donutAnim.dispose();
    _barsAnim.dispose();
    _compAnim.dispose();
    super.dispose();
  }

  void _checkVisibility() {
    if (!mounted) return;
    _tryTrigger(_donutKey, _donutAnim, _donutTriggered, () => setState(() => _donutTriggered = true));
    _tryTrigger(_barsKey, _barsAnim, _barsTriggered, () => setState(() => _barsTriggered = true));
    _tryTrigger(_compKey, _compAnim, _compTriggered, () => setState(() => _compTriggered = true));
  }

  void _tryTrigger(GlobalKey key, AnimationController anim, bool triggered, VoidCallback onTrigger) {
    if (triggered) return;
    final ctx = key.currentContext;
    if (ctx == null) return;
    final box = ctx.findRenderObject() as RenderBox?;
    if (box == null || !box.attached) return;
    final pos = box.localToGlobal(Offset.zero);
    final screenH = MediaQuery.of(context).size.height;
    if (pos.dy < screenH) {
      onTrigger();
      anim.forward();
    }
  }

  DateTimeRange get _effectiveRange {
    final now = DateTime.now();
    switch (_range) {
      case _InsightRange.ytd:
        return DateTimeRange(start: DateTime(now.year, 1, 1), end: now);
      case _InsightRange.m3:
        return DateTimeRange(start: DateTime(now.year, now.month - 2, 1), end: now);
      case _InsightRange.m6:
        return DateTimeRange(start: DateTime(now.year, now.month - 5, 1), end: now);
      case _InsightRange.m9:
        return DateTimeRange(start: DateTime(now.year, now.month - 8, 1), end: now);
      case _InsightRange.m12:
        return DateTimeRange(start: DateTime(now.year, now.month - 11, 1), end: now);
      case _InsightRange.year:
        return DateTimeRange(start: DateTime(_selectedYear, 1, 1), end: DateTime(_selectedYear, 12, 31));
    }
  }

  List<Transaction> get _filteredTxs {
    final r = _effectiveRange;
    return widget.transactions.where((t) => !t.date.isBefore(r.start) && !t.date.isAfter(r.end)).toList();
  }

  List<String> get _monthsInRange {
    final r = _effectiveRange;
    final months = <String>[];
    var c = DateTime(r.start.year, r.start.month);
    final end = DateTime(r.end.year, r.end.month);
    while (!c.isAfter(end)) {
      months.add('${c.year}-${c.month.toString().padLeft(2, '0')}');
      c = DateTime(c.year, c.month + 1);
    }
    return months;
  }

  Map<String, double> _byMonth(List<Transaction> txs, TransactionType type) {
    final out = <String, double>{};
    for (final t in txs) {
      if (t.type != type) continue;
      final k = '${t.date.year}-${t.date.month.toString().padLeft(2, '0')}';
      out[k] = (out[k] ?? 0) + t.amount;
    }
    return out;
  }

  @override
  Widget build(BuildContext context) {
    final txs = _filteredTxs;
    final months = _monthsInRange;
    final expenseBudgets = widget.budgets.where((b) => b.budgetType == BudgetType.expense).toList();
    final titles = expenseBudgets.map((b) => b.title ?? 'Expense').toSet().toList()..sort();
    final effectiveTitle = (_selectedBudgetTitle != null && titles.contains(_selectedBudgetTitle))
        ? _selectedBudgetTitle
        : null;
    final cardBg = widget.isDark ? const Color(0xFF2C2C2A) : Colors.white;
    final borderColor = widget.isDark
        ? AppColors.border.withValues(alpha: 0.2)
        : AppColors.border.withValues(alpha: 0.5);
    final textPrimary = widget.isDark ? AppColors.primaryForeground : AppColors.textPrimary;

    final hasExpenseBreakdown = expenseBudgets.isNotEmpty;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Section header ──────────────────────────────────────────────────
          Text(
            'Monthly Insights',
            style: GoogleFonts.dmSans(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: textPrimary,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            'Visualize spending patterns and budget performance over time.',
            style: GoogleFonts.dmSans(fontSize: 12, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 14),
          _buildRangeChips(),

          // ── Transactions Involved + Expense Breakdown ────────────────────
          const SizedBox(height: 14),
          SizedBox(
            height: 300,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(child: _buildFilteredTxCard(txs, cardBg, borderColor, textPrimary)),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildExpenseDonut(
                    txs, expenseBudgets, titles, effectiveTitle, cardBg, borderColor, _donutAnim,
                  ),
                ),
              ],
            ),
          ),

          // ── Spending Trends ──────────────────────────────────────────────
          const SizedBox(height: 20),
          Text(
            'Spending Trends',
            style: GoogleFonts.dmSans(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: textPrimary,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            'Monthly outflow and inflow totals across the selected range.',
            style: GoogleFonts.dmSans(fontSize: 11, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 10),
          Row(key: _barsKey, children: [
            Expanded(child: _buildMonthlyBarCard(txs, months, TransactionType.expense, 'Outflow', AppColors.error, cardBg, borderColor, _barsAnim, selectedIdx: _selectedBarIdx, onSelect: (i) => setState(() => _selectedBarIdx = i))),
            const SizedBox(width: 10),
            Expanded(child: _buildMonthlyBarCard(txs, months, TransactionType.income, 'Inflow', AppColors.success, cardBg, borderColor, _barsAnim, selectedIdx: _selectedBarIdx, onSelect: (i) => setState(() => _selectedBarIdx = i))),
          ]),

          // ── Income vs Outflow comparison ─────────────────────────────────
          const SizedBox(height: 20),
          Text(
            'Income vs Outflow',
            style: GoogleFonts.dmSans(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: textPrimary,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            'Side-by-side view of earnings and spending per month — green bars above red means you saved.',
            style: GoogleFonts.dmSans(fontSize: 11, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 10),
          _buildComparisonCard(txs, months, cardBg, borderColor, _compAnim, selectedIdx: _selectedCompIdx, onSelect: (i) => setState(() => _selectedCompIdx = i)),
        ],
      ),
    );
  }

  Widget _buildFilteredTxCard(
    List<Transaction> txs, Color cardBg, Color borderColor, Color textPrimary,
  ) {
    final isDark = widget.isDark;
    final divColor = isDark
        ? AppColors.border.withValues(alpha: 0.2)
        : AppColors.border.withValues(alpha: 0.4);
    final sorted = (List.of(txs)..sort((a, b) => b.date.compareTo(a.date))).take(6).toList();

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
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Transactions Involved',
                  style: GoogleFonts.dmSans(fontSize: 12, fontWeight: FontWeight.w600, color: textPrimary)),
              Text('In selected period',
                  style: GoogleFonts.dmSans(fontSize: 10, color: AppColors.textSecondary)),
            ]),
          ),
          Divider(height: 1, thickness: 0.5, color: divColor),
          Expanded(
            child: sorted.isEmpty
                ? Center(
                    child: Text('No transactions',
                        style: GoogleFonts.dmSans(fontSize: 11, color: AppColors.textTertiary)),
                  )
                : ListView.separated(
                    padding: EdgeInsets.zero,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: sorted.length,
                    separatorBuilder: (_, __) =>
                        Divider(height: 1, thickness: 0.5, color: divColor, indent: 14, endIndent: 14),
                    itemBuilder: (_, i) {
                      final t = sorted[i];
                      final isIncome = t.type == TransactionType.income;
                      final color = isIncome ? AppColors.success : AppColors.error;
                      final sign = isIncome ? '+' : '−';
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                        child: Row(children: [
                          Container(
                            width: 28, height: 28,
                            decoration: BoxDecoration(
                              color: color.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(7),
                            ),
                            child: Icon(
                              isIncome ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded,
                              size: 12, color: color,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              Text(
                                t.description ?? (isIncome ? 'Income' : 'Expense'),
                                style: GoogleFonts.dmSans(
                                  fontSize: 11, fontWeight: FontWeight.w500, color: textPrimary,
                                ),
                                maxLines: 1, overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                DateFormat('MMM d').format(t.date),
                                style: GoogleFonts.dmSans(fontSize: 10, color: AppColors.textSecondary),
                              ),
                            ]),
                          ),
                          Text(
                            '$sign${currencyFormatter.format(t.amount, decimalDigits: 0)}',
                            style: GoogleFonts.dmMono(
                              fontSize: 11, fontWeight: FontWeight.w600, color: color,
                              fontFeatures: const [FontFeature.tabularFigures()],
                            ),
                          ),
                        ]),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildRangeChips() {
    const items = [
      (_InsightRange.ytd, 'YTD'),
      (_InsightRange.m3, '3M'),
      (_InsightRange.m6, '6M'),
      (_InsightRange.m9, '9M'),
      (_InsightRange.m12, '12M'),
      (_InsightRange.year, 'Year'),
    ];
    final isDark = widget.isDark;
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          ...items.map((e) {
            final isSelected = _range == e.$1;
            return Padding(
              padding: const EdgeInsets.only(right: 6),
              child: GestureDetector(
                onTap: () => setState(() { _range = e.$1; _selectedBarIdx = null; _selectedCompIdx = null; }),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.accent : (isDark ? const Color(0xFF2C2C2A) : Colors.white),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isSelected ? AppColors.accent : (isDark ? AppColors.border.withValues(alpha: 0.2) : AppColors.border.withValues(alpha: 0.5)),
                      width: 0.5,
                    ),
                  ),
                  child: Text(e.$2, style: GoogleFonts.dmSans(
                    fontSize: 11,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                    color: isSelected ? Colors.white : AppColors.textSecondary,
                  )),
                ),
              ),
            );
          }),
          if (_range == _InsightRange.year) ...[
            const SizedBox(width: 4),
            _YearDropdown(selectedYear: _selectedYear, isDark: isDark, onChanged: (y) => setState(() => _selectedYear = y)),
          ],
        ],
      ),
    );
  }

  Widget _buildExpenseDonut(
    List<Transaction> txs, List<Budget> expenseBudgets,
    List<String> titles, String? effectiveTitle,
    Color cardBg, Color borderColor, AnimationController anim,
  ) {
    final isDark = widget.isDark;
    final textPrimary = isDark ? AppColors.primaryForeground : AppColors.textPrimary;

    final matchingBudgets = effectiveTitle == null
        ? expenseBudgets
        : expenseBudgets.where((b) => (b.title ?? 'Expense') == effectiveTitle);
    final categoryMap = <String, String>{};
    for (final b in matchingBudgets) {
      for (final c in b.categories) {
        categoryMap[c.financeCategoryId] = c.financeCategory?.name ?? c.financeCategoryId;
      }
    }
    final spending = <String, double>{};
    for (final t in txs) {
      if (t.type != TransactionType.expense || t.financeCategoryId == null) continue;
      if (!categoryMap.containsKey(t.financeCategoryId)) continue;
      spending[t.financeCategoryId!] = (spending[t.financeCategoryId!] ?? 0) + t.amount;
    }
    final sortedKeys = categoryMap.keys
        .where((k) => (spending[k] ?? 0) > 0)
        .toList()
      ..sort((a, b) => (spending[b] ?? 0).compareTo(spending[a] ?? 0));
    final items = sortedKeys.asMap().entries.map((e) => _ChartItem(
      name: categoryMap[e.value]!,
      amount: spending[e.value]!,
      color: _kPalette[e.key % _kPalette.length],
    )).toList();
    final total = items.fold(0.0, (s, i) => s + i.amount);

    return Container(
      key: _donutKey,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: cardBg, borderRadius: BorderRadius.circular(14), border: Border.all(color: borderColor, width: 0.5)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Expense Breakdown', style: GoogleFonts.dmSans(fontSize: 13, fontWeight: FontWeight.w600, color: textPrimary)),
                    const SizedBox(height: 2),
                    Text('Where your money is going', style: GoogleFonts.dmSans(fontSize: 11, color: AppColors.textSecondary)),
                  ],
                ),
              ),
              if (expenseBudgets.isNotEmpty)
                _BudgetDropdown(titles: titles, selectedTitle: effectiveTitle, isDark: isDark, onChanged: (t) => setState(() => _selectedBudgetTitle = t)),
            ],
          ),
          const SizedBox(height: 12),
          Expanded(
            child: items.isEmpty
                ? Center(
                    child: Text('No expense data', style: GoogleFonts.dmSans(fontSize: 12, color: AppColors.textTertiary)),
                  )
                : LayoutBuilder(
                    builder: (_, constraints) {
                      final donutSize = constraints.maxHeight.clamp(80.0, 150.0);
                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: donutSize,
                            height: donutSize,
                            child: AnimatedBuilder(
                              animation: anim,
                              builder: (_, __) => CustomPaint(
                                painter: _DonutPainter(items: items, animProgress: anim.value),
                              ),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: items.take(6).map((item) => _LegendRow(item: item, total: total, isDark: isDark)).toList(),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildMonthlyBarCard(
    List<Transaction> txs, List<String> months, TransactionType type,
    String label, Color color, Color cardBg, Color borderColor, AnimationController anim,
    {int? selectedIdx, void Function(int?)? onSelect}
  ) {
    final byMonth = _byMonth(txs, type);
    final values = months.map((m) => byMonth[m] ?? 0.0).toList();
    final total = values.fold(0.0, (s, v) => s + v);
    final isDark = widget.isDark;
    final textPrimary = isDark ? AppColors.primaryForeground : AppColors.textPrimary;
    final hasSelection = selectedIdx != null && selectedIdx < values.length;
    final displayValue = hasSelection ? values[selectedIdx!] : total;
    final displayLabel = hasSelection
        ? DateFormat('MMM yyyy').format(DateFormat('yyyy-MM').parse(months[selectedIdx!]))
        : label;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: cardBg, borderRadius: BorderRadius.circular(14), border: Border.all(color: borderColor, width: 0.5)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 180),
            child: Column(
              key: ValueKey(displayLabel),
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(displayLabel, style: GoogleFonts.dmSans(fontSize: 11, color: hasSelection ? color : AppColors.textSecondary, fontWeight: FontWeight.w500)),
                const SizedBox(height: 2),
                Text(currencyFormatter.format(displayValue, decimalDigits: 0),
                    style: GoogleFonts.dmMono(fontSize: 14, fontWeight: FontWeight.w700, color: textPrimary)),
              ],
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 72,
            child: values.isEmpty
                ? Center(child: Text('No data', style: GoogleFonts.dmSans(fontSize: 11, color: AppColors.textTertiary)))
                : LayoutBuilder(builder: (_, c) {
                    final slotW = c.maxWidth / values.length;
                    return GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTapDown: (d) {
                        final idx = (d.localPosition.dx / slotW).floor().clamp(0, values.length - 1);
                        onSelect?.call(selectedIdx == idx ? null : idx);
                      },
                      child: AnimatedBuilder(
                        animation: anim,
                        builder: (_, __) => CustomPaint(
                          size: Size.infinite,
                          painter: _MonthBarPainter(values: values, color: color, isDark: isDark, animProgress: anim.value, selectedIdx: selectedIdx),
                        ),
                      ),
                    );
                  }),
          ),
          const SizedBox(height: 4),
          _MonthXLabels(months: months, isDark: isDark, selectedIdx: selectedIdx),
        ],
      ),
    );
  }

  Widget _buildComparisonCard(List<Transaction> txs, List<String> months, Color cardBg, Color borderColor, AnimationController anim, {int? selectedIdx, void Function(int?)? onSelect}) {
    final expenseByMonth = _byMonth(txs, TransactionType.expense);
    final incomeByMonth = _byMonth(txs, TransactionType.income);
    final expValues = months.map((m) => expenseByMonth[m] ?? 0.0).toList();
    final incValues = months.map((m) => incomeByMonth[m] ?? 0.0).toList();
    final isDark = widget.isDark;
    final textPrimary = isDark ? AppColors.primaryForeground : AppColors.textPrimary;
    final hasSelection = selectedIdx != null && selectedIdx < months.length;
    final selLabel = hasSelection ? DateFormat('MMM yyyy').format(DateFormat('yyyy-MM').parse(months[selectedIdx!])) : null;

    return Container(
      key: _compKey,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: cardBg, borderRadius: BorderRadius.circular(14), border: Border.all(color: borderColor, width: 0.5)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            _Dot(color: AppColors.success), const SizedBox(width: 4),
            Text('Inflow', style: GoogleFonts.dmSans(fontSize: 10, color: AppColors.textSecondary)),
            const SizedBox(width: 10),
            _Dot(color: AppColors.error), const SizedBox(width: 4),
            Text('Outflow', style: GoogleFonts.dmSans(fontSize: 10, color: AppColors.textSecondary)),
            if (hasSelection) ...[
              const Spacer(),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 180),
                child: Column(
                  key: ValueKey(selLabel),
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(selLabel!, style: GoogleFonts.dmSans(fontSize: 10, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
                    Row(mainAxisSize: MainAxisSize.min, children: [
                      Text(currencyFormatter.format(incValues[selectedIdx!], decimalDigits: 0),
                          style: GoogleFonts.dmMono(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.success)),
                      Text('  /  ', style: GoogleFonts.dmSans(fontSize: 10, color: AppColors.textTertiary)),
                      Text(currencyFormatter.format(expValues[selectedIdx!], decimalDigits: 0),
                          style: GoogleFonts.dmMono(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.error)),
                    ]),
                  ],
                ),
              ),
            ],
          ]),
          const SizedBox(height: 12),
          SizedBox(
            height: 100,
            child: LayoutBuilder(builder: (_, c) {
              final slotW = months.isEmpty ? 1.0 : c.maxWidth / months.length;
              return GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTapDown: (d) {
                  if (months.isEmpty) return;
                  final idx = (d.localPosition.dx / slotW).floor().clamp(0, months.length - 1);
                  onSelect?.call(selectedIdx == idx ? null : idx);
                },
                child: AnimatedBuilder(
                  animation: anim,
                  builder: (_, __) => CustomPaint(
                    size: Size.infinite,
                    painter: _ComparisonPainter(income: incValues, expense: expValues, isDark: isDark, animProgress: anim.value, selectedIdx: selectedIdx),
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 4),
          _MonthXLabels(months: months, isDark: isDark, selectedIdx: selectedIdx),
        ],
      ),
    );
  }
}

// ─── Painters ─────────────────────────────────────────────────────────────────

class _DonutPainter extends CustomPainter {
  final List<_ChartItem> items;
  final double animProgress;
  const _DonutPainter({required this.items, this.animProgress = 1.0});

  @override
  void paint(Canvas canvas, Size size) {
    final total = items.fold(0.0, (s, i) => s + i.amount);
    if (total == 0) return;
    const gap = 0.025;
    const start = -1.5707963;
    final radius = size.width / 2;
    final stroke = radius * 0.34;
    final rect = Rect.fromCircle(center: Offset(radius, radius), radius: radius - stroke / 2);
    double sweep = start;
    for (final item in items) {
      final fraction = item.amount / total;
      final arc = (fraction * 6.2831853 - gap) * animProgress;
      if (arc > 0.001) {
        canvas.drawArc(rect, sweep, arc, false, Paint()..color = item.color..style = PaintingStyle.stroke..strokeWidth = stroke..strokeCap = StrokeCap.butt);
      }
      sweep += fraction * 6.2831853 * animProgress;
    }
  }

  @override
  bool shouldRepaint(covariant _DonutPainter old) => old.items != items || old.animProgress != animProgress;
}

class _MonthBarPainter extends CustomPainter {
  final List<double> values;
  final Color color;
  final bool isDark;
  final double animProgress;
  final int? selectedIdx;
  const _MonthBarPainter({required this.values, required this.color, required this.isDark, this.animProgress = 1.0, this.selectedIdx});

  @override
  void paint(Canvas canvas, Size size) {
    if (values.isEmpty) return;
    final maxVal = values.fold(0.0, max);
    if (maxVal == 0) return;
    const topPad = 4.0;
    final chartH = size.height - topPad;
    final slotW = size.width / values.length;
    final barW = (slotW * 0.6).clamp(3.0, 20.0);
    final hasSelection = selectedIdx != null;
    for (int i = 0; i < values.length; i++) {
      final h = (values[i] / maxVal) * chartH * animProgress;
      final x = slotW * i + (slotW - barW) / 2;
      final y = topPad + chartH - h;
      if (h < 1) continue;
      final alpha = hasSelection ? (i == selectedIdx ? 1.0 : 0.25) : 0.7;
      canvas.drawRRect(
        RRect.fromRectAndCorners(Rect.fromLTWH(x, y, barW, h), topLeft: const Radius.circular(4), topRight: const Radius.circular(4)),
        Paint()..color = color.withValues(alpha: alpha),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _MonthBarPainter old) => old.values != values || old.animProgress != animProgress || old.selectedIdx != selectedIdx;
}

class _ComparisonPainter extends CustomPainter {
  final List<double> income;
  final List<double> expense;
  final bool isDark;
  final double animProgress;
  final int? selectedIdx;
  const _ComparisonPainter({required this.income, required this.expense, required this.isDark, this.animProgress = 1.0, this.selectedIdx});

  @override
  void paint(Canvas canvas, Size size) {
    final n = income.length;
    if (n == 0) return;
    final maxVal = [...income, ...expense].fold(0.0, max);
    if (maxVal == 0) return;
    const topPad = 4.0;
    final chartH = size.height - topPad;
    final slotW = size.width / n;
    final pairW = (slotW * 0.7).clamp(6.0, 36.0);
    final barW = pairW / 2 - 1;
    final hasSelection = selectedIdx != null;
    for (int i = 0; i < n; i++) {
      final x0 = slotW * i + (slotW - pairW) / 2;
      final alpha = hasSelection ? (i == selectedIdx ? 1.0 : 0.2) : 0.75;
      _drawBar(canvas, x0, topPad, chartH, barW, income[i], maxVal, AppColors.success, alpha);
      _drawBar(canvas, x0 + barW + 2, topPad, chartH, barW, expense[i], maxVal, AppColors.error, alpha);
    }
  }

  void _drawBar(Canvas canvas, double x, double topPad, double chartH, double barW, double val, double maxVal, Color color, double alpha) {
    final h = (val / maxVal) * chartH * animProgress;
    if (h < 1) return;
    canvas.drawRRect(
      RRect.fromRectAndCorners(Rect.fromLTWH(x, topPad + chartH - h, barW, h), topLeft: const Radius.circular(3), topRight: const Radius.circular(3)),
      Paint()..color = color.withValues(alpha: alpha),
    );
  }

  @override
  bool shouldRepaint(covariant _ComparisonPainter old) => old.income != income || old.expense != expense || old.animProgress != animProgress || old.selectedIdx != selectedIdx;
}

// ─── Small helpers ─────────────────────────────────────────────────────────────

class _LegendRow extends StatelessWidget {
  final _ChartItem item;
  final double total;
  final bool isDark;
  const _LegendRow({required this.item, required this.total, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final pct = total > 0 ? (item.amount / total * 100).toStringAsFixed(1) : '0.0';
    return Padding(
      padding: const EdgeInsets.only(bottom: 5),
      child: Row(children: [
        Container(width: 8, height: 8, decoration: BoxDecoration(color: item.color, borderRadius: BorderRadius.circular(2))),
        const SizedBox(width: 6),
        Expanded(child: Text(item.name, style: GoogleFonts.dmSans(fontSize: 10, color: isDark ? AppColors.primaryForeground : AppColors.textPrimary), maxLines: 1, overflow: TextOverflow.ellipsis)),
        Text('$pct%', style: GoogleFonts.dmSans(fontSize: 10, color: AppColors.textSecondary, fontWeight: FontWeight.w600)),
      ]),
    );
  }
}

class _BudgetDropdown extends StatelessWidget {
  final List<String> titles;
  final String? selectedTitle;
  final bool isDark;
  final void Function(String?) onChanged;

  const _BudgetDropdown({required this.titles, required this.selectedTitle, required this.isDark, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final bg = isDark ? const Color(0xFF3A3A38) : AppColors.background;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(8)),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String?>(
          value: selectedTitle,
          isDense: true,
          style: GoogleFonts.dmSans(fontSize: 11, color: isDark ? AppColors.primaryForeground : AppColors.textPrimary),
          dropdownColor: isDark ? const Color(0xFF2C2C2A) : Colors.white,
          icon: Icon(Icons.keyboard_arrow_down_rounded, size: 14, color: AppColors.textSecondary),
          items: [
            DropdownMenuItem<String?>(value: null, child: Text('All', style: GoogleFonts.dmSans(fontSize: 11))),
            ...titles.map((t) => DropdownMenuItem<String?>(value: t, child: Text(t))),
          ],
          onChanged: (v) => onChanged(v),
        ),
      ),
    );
  }
}

class _YearDropdown extends StatelessWidget {
  final int selectedYear;
  final bool isDark;
  final void Function(int) onChanged;

  const _YearDropdown({required this.selectedYear, required this.isDark, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now().year;
    final years = List.generate(6, (i) => now - i);
    final bg = isDark ? const Color(0xFF2C2C2A) : Colors.white;
    final border = isDark ? AppColors.border.withValues(alpha: 0.2) : AppColors.border.withValues(alpha: 0.5);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20), border: Border.all(color: border, width: 0.5)),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<int>(
          value: selectedYear,
          isDense: true,
          style: GoogleFonts.dmSans(fontSize: 11, fontWeight: FontWeight.w600, color: isDark ? AppColors.primaryForeground : AppColors.textPrimary),
          dropdownColor: isDark ? const Color(0xFF2C2C2A) : Colors.white,
          icon: Icon(Icons.keyboard_arrow_down_rounded, size: 14, color: AppColors.textSecondary),
          items: years.map((y) => DropdownMenuItem(value: y, child: Text('$y'))).toList(),
          onChanged: (v) { if (v != null) onChanged(v); },
        ),
      ),
    );
  }
}

class _MonthXLabels extends StatelessWidget {
  final List<String> months;
  final bool isDark;
  final int? selectedIdx;
  const _MonthXLabels({required this.months, required this.isDark, this.selectedIdx});

  @override
  Widget build(BuildContext context) {
    if (months.isEmpty) return const SizedBox.shrink();
    return LayoutBuilder(builder: (_, c) {
      final slotW = c.maxWidth / months.length;
      return SizedBox(
        height: 14,
        child: Stack(
          children: months.asMap().entries.map((e) {
            final dt = DateFormat('yyyy-MM').parse(e.value);
            final isSelected = e.key == selectedIdx;
            return Positioned(
              left: (slotW * e.key + slotW / 2 - 14).clamp(0.0, c.maxWidth - 28),
              child: SizedBox(
                width: 28,
                child: Text(DateFormat('MMM').format(dt), textAlign: TextAlign.center,
                    style: GoogleFonts.dmSans(fontSize: 9, fontWeight: isSelected ? FontWeight.w700 : FontWeight.w400, color: isSelected ? AppColors.accent : AppColors.textTertiary)),
              ),
            );
          }).toList(),
        ),
      );
    });
  }
}

class _Dot extends StatelessWidget {
  final Color color;
  const _Dot({required this.color});
  @override
  Widget build(BuildContext context) => Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle));
}
