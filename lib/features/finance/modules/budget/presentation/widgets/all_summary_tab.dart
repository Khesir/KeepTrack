import 'package:flutter/material.dart';
import 'package:keep_track/core/theme/app_theme.dart';

import '../../../transaction/domain/entities/transaction.dart';
import '../../domain/entities/budget.dart';
import '../helpers/currency_formatter.dart';

class _ChartItem {
  final String name;
  final double value;
  const _ChartItem(this.name, this.value);
}

class AllSummaryTab extends StatelessWidget {
  final List<Budget> budgets;
  final List<Transaction> transactions;

  const AllSummaryTab({required this.budgets, required this.transactions});

  // Income Pallet Possible to be moved?
  // TODO: Investigate central coloring setting
  static const _incomePalette = [
    Color(0xFF12B886),
    Color(0xFF2F9E44),
    Color(0xFF087F5B),
    Color(0xFF40C057),
    Color(0xFF63E6BE),
    Color(0xFF20C997),
  ];

  static const _expensePalette = [
    Color(0xFF4C6EF5),
    Color(0xFFF76707),
    Color(0xFFE64980),
    Color(0xFF7950F2),
    Color(0xFF1C7ED6),
    Color(0xFFE67700),
    Color(0xFFAE3EC9),
    Color(0xFF0CA678),
    Color(0xFFD6336C),
    Color(0xFF3BC9DB),
  ];

  @override
  Widget build(BuildContext context) {
    if (budgets.isEmpty) {
      return Center(
        child: Text(
          'No budget groups yet.',
          style: AppTextStyles.bodySmall.copyWith(
            color: AppColors.textTertiary,
          ),
        ),
      );
    }

    // Build spent-per-financeCategoryId map from actual transactions
    final Map<String, double> spentByCategory = {};
    for (final t in transactions) {
      if (t.financeCategoryId != null) {
        spentByCategory[t.financeCategoryId!] =
            (spentByCategory[t.financeCategoryId!] ?? 0.0) + t.amount;
      }
    }

    // Flatten categories per type
    final incomeItems = budgets
        .where((b) => b.budgetType == BudgetType.income)
        .expand((b) => b.categories)
        .map(
          (c) => _ChartItem(
            c.financeCategory?.name ?? '—',
            spentByCategory[c.financeCategoryId] ?? 0.0,
          ),
        )
        .where((i) => i.value > 0)
        .toList();

    final expenseItems = budgets
        .where((b) => b.budgetType == BudgetType.expense)
        .expand((b) => b.categories)
        .map(
          (c) => _ChartItem(
            c.financeCategory?.name ?? '—',
            spentByCategory[c.financeCategoryId] ?? 0.0,
          ),
        )
        .where((i) => i.value > 0)
        .toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (incomeItems.isNotEmpty) ...[
            _DonutSection(
              label: 'INCOME',
              labelColor: AppColors.success,
              items: incomeItems,
              palette: _incomePalette,
              centerLabel: 'received',
            ),
            const SizedBox(height: 24),
          ],
          if (expenseItems.isNotEmpty)
            _DonutSection(
              label: 'EXPENSES',
              labelColor: AppColors.error,
              items: expenseItems,
              palette: _expensePalette,
              centerLabel: 'spent',
            ),
          if (incomeItems.isEmpty && expenseItems.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Text(
                  'No transactions yet this month.',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textTertiary,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _DonutSection extends StatelessWidget {
  final String label;
  final Color labelColor;
  final List<_ChartItem> items;
  final List<Color> palette;
  final String centerLabel;

  const _DonutSection({
    required this.label,
    required this.labelColor,
    required this.items,
    required this.palette,
    required this.centerLabel,
  });

  @override
  Widget build(BuildContext context) {
    final total = items.fold<double>(0, (s, i) => s + i.value);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTextStyles.caption.copyWith(
            color: labelColor,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.8,
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 160,
          child: CustomPaint(
            painter: _DonutChartPainter(
              items: items,
              palette: palette,
              totalValue: total,
            ),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    formatCurrency(total),
                    style: AppTextStyles.bodyMedium.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    centerLabel,
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.textTertiary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        ...items.asMap().entries.map((e) {
          final color = palette[e.key % palette.length];
          final pct = total > 0
              ? (e.value.value / total * 100).toStringAsFixed(1)
              : '0.0';
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              children: [
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    e.value.name,
                    style: AppTextStyles.bodySmall,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Text(
                  '$pct%',
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  formatCurrency(e.value.value),
                  style: AppTextStyles.bodySmall.copyWith(
                    fontWeight: FontWeight.w600,
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

class _DonutChartPainter extends CustomPainter {
  final List<_ChartItem> items;
  final List<Color> palette;
  final double totalValue;

  _DonutChartPainter({
    required this.items,
    required this.palette,
    required this.totalValue,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final radius = (size.height / 2) - 8;
    final strokeWidth = radius * 0.38;
    final rect = Rect.fromCircle(
      center: Offset(cx, cy),
      radius: radius - strokeWidth / 2,
    );

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.butt;

    if (totalValue <= 0) {
      paint.color = AppColors.textTertiary.withValues(alpha: 0.15);
      canvas.drawCircle(Offset(cx, cy), radius - strokeWidth / 2, paint);
      return;
    }

    double startAngle = -1.5708; // -π/2 (top)
    for (var i = 0; i < items.length; i++) {
      final val = items[i].value;
      if (val <= 0) continue;
      final sweep = (val / totalValue) * 6.2832;
      paint.color = palette[i % palette.length];
      canvas.drawArc(rect, startAngle, sweep - 0.03, false, paint);
      startAngle += sweep;
    }
  }

  @override
  bool shouldRepaint(_DonutChartPainter old) =>
      old.totalValue != totalValue || old.items != items;
}
