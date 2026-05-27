import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:keep_track/core/theme/app_theme.dart';

class MonthHeader extends StatelessWidget {
  final String monthLabel;
  final VoidCallback onPrev;
  final VoidCallback onNext;
  final VoidCallback? onSummaryTap;
  final VoidCallback? onSettings;
  final VoidCallback? onToggleView;

  const MonthHeader({
    super.key,
    required this.monthLabel,
    required this.onPrev,
    required this.onNext,
    this.onSummaryTap,
    this.onSettings,
    this.onToggleView,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = isDark ? AppColors.primaryForeground : AppColors.textPrimary;

    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 8, 4, 0),
      child: Row(
        children: [
          IconButton(
            icon: Icon(Icons.chevron_left_rounded, color: AppColors.textSecondary),
            onPressed: onPrev,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
          ),
          Expanded(
            child: Text(
              monthLabel,
              textAlign: TextAlign.center,
              style: GoogleFonts.dmSans(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: textPrimary,
              ),
            ),
          ),
          IconButton(
            icon: Icon(Icons.chevron_right_rounded, color: AppColors.textSecondary),
            onPressed: onNext,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
          ),
          if (onSummaryTap != null)
            IconButton(
              icon: Icon(Icons.bar_chart_rounded, color: AppColors.textSecondary),
              onPressed: onSummaryTap,
              tooltip: 'Summary & Transactions',
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
            ),
          if (onToggleView != null)
            IconButton(
              icon: Icon(Icons.view_list_outlined, color: AppColors.textSecondary),
              onPressed: onToggleView,
              tooltip: 'Switch to Simple',
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
            ),
          if (onSettings != null)
            IconButton(
              icon: Icon(Icons.more_vert_rounded, color: AppColors.textSecondary),
              onPressed: onSettings,
              tooltip: 'Budget settings',
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
            ),
        ],
      ),
    );
  }
}
