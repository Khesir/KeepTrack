import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:keep_track/core/settings/utils/currency_formatter.dart';
import 'package:keep_track/core/theme/app_theme.dart';

class TransactionTypeChip extends StatelessWidget {
  final IconData? icon;
  final String label;
  final Color color;
  final bool isDark;
  final bool highlighted;
  final VoidCallback? onTap;
  const TransactionTypeChip({
    super.key,
    required this.label,
    required this.color,
    required this.isDark,
    required this.onTap,
    this.icon,
    this.highlighted = false,
  });

  @override
  Widget build(BuildContext context) {
    final bg = highlighted
        ? AppColors.error.withValues(alpha: 0.08)
        : (isDark
              ? Colors.white.withValues(alpha: 0.07)
              : AppColors.background);
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(20),
          border: highlighted
              ? Border.all(color: AppColors.error.withValues(alpha: 0.4))
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon!, size: 13, color: color),
              const SizedBox(width: 4),
            ],
            Text(
              label,
              style: GoogleFonts.dmSans(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class SplitEntryChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final bool isDark;
  final VoidCallback? onTap;

  const SplitEntryChip({
    super.key,
    required this.icon,
    required this.label,
    required this.color,
    required this.isDark,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: isDark ? 0.12 : 0.07),
        borderRadius: BorderRadius.circular(7),
        border: Border.all(color: color.withValues(alpha: 0.25), width: 0.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: GoogleFonts.dmSans(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    ),
  );
}

class TransactionTypePill extends StatelessWidget {
  final String label;
  final Color color;
  final bool selected;
  final VoidCallback onTap;
  const TransactionTypePill({
    super.key,
    required this.label,
    required this.color,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
      decoration: BoxDecoration(
        color: selected ? color : color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: GoogleFonts.dmSans(
          fontSize: 12,
          fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
          color: selected ? Colors.white : color,
        ),
      ),
    ),
  );
}

class PlanTogglePill extends StatelessWidget {
  final bool active;
  final VoidCallback onTap;
  const PlanTogglePill({super.key, required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: active
            ? AppColors.accent.withValues(alpha: 0.12)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: active
              ? AppColors.accent.withValues(alpha: 0.5)
              : AppColors.border.withValues(alpha: 0.5),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.event_note_outlined,
            size: 12,
            color: active ? AppColors.accent : AppColors.textSecondary,
          ),
          const SizedBox(width: 5),
          Text(
            'Plan',
            style: GoogleFonts.dmSans(
              fontSize: 12,
              fontWeight: active ? FontWeight.w700 : FontWeight.w400,
              color: active ? AppColors.accent : AppColors.textSecondary,
            ),
          ),
        ],
      ),
    ),
  );
}

class BudgetPlannedIndicator extends StatelessWidget {
  final double spent, planned;
  final Color color;
  final bool isDark;

  const BudgetPlannedIndicator({
    super.key,
    required this.spent,
    required this.planned,
    required this.color,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final remaining = (planned - spent).clamp(0.0, double.infinity);
    final isOver = spent > planned;
    final bg = isDark
        ? Colors.white.withValues(alpha: 0.04)
        : AppColors.background;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(
            Icons.bar_chart_rounded,
            size: 13,
            color: AppColors.textSecondary,
          ),
          const SizedBox(width: 6),
          Text(
            'Budget: ${currencyFormatter.format(planned, decimalDigits: 0)}',
            style: GoogleFonts.dmSans(
              fontSize: 11,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '·',
            style: GoogleFonts.dmSans(
              fontSize: 11,
              color: AppColors.textTertiary,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            isOver
                ? 'Over by ${currencyFormatter.format(spent - planned, decimalDigits: 0)}'
                : '${currencyFormatter.format(remaining, decimalDigits: 0)} left',
            style: GoogleFonts.dmSans(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: isOver ? AppColors.error : color,
            ),
          ),
        ],
      ),
    );
  }
}
