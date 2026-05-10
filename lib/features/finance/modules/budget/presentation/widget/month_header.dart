import 'package:flutter/material.dart';
import 'package:keep_track/core/theme/app_theme.dart';

class MonthHeader extends StatelessWidget {
  final String monthLabel;
  final VoidCallback onPrev;
  final VoidCallback onNext;
  final VoidCallback? onSummaryTap;
  final VoidCallback? onDelete;

  const MonthHeader({
    required this.monthLabel,
    required this.onPrev,
    required this.onNext,
    this.onSummaryTap,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        IconButton(icon: const Icon(Icons.chevron_left), onPressed: onPrev),
        Expanded(
          child: Text(
            monthLabel,
            textAlign: TextAlign.center,
            style: AppTextStyles.h3,
          ),
        ),
        IconButton(icon: const Icon(Icons.chevron_right), onPressed: onNext),
        if (onSummaryTap != null)
          IconButton(
            icon: const Icon(Icons.bar_chart_rounded),
            onPressed: onSummaryTap,
            tooltip: 'Summary & Transactions',
          ),
        if (onDelete != null)
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: onDelete,
            tooltip: 'Delete plan',
            color: AppColors.textTertiary,
          ),
      ],
    );
  }
}
