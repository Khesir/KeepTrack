import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:keep_track/core/settings/utils/currency_formatter.dart';
import 'package:keep_track/core/theme/app_theme.dart';
import 'package:keep_track/features/finance/modules/goal/domain/entities/goal.dart';

class GoalSection extends StatelessWidget {
  final List<Goal> goals;
  final Map<String, double> contributedThisMonth;
  final VoidCallback onAdd;
  final void Function(Goal) onGoalTap;
  final int? dragIndex;

  const GoalSection({
    super.key,
    required this.goals,
    required this.onAdd,
    required this.onGoalTap,
    this.contributedThisMonth = const {},
    this.dragIndex,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? const Color(0xFF2C2C2A) : Colors.white;
    final borderColor = AppColors.border.withValues(alpha: isDark ? 0.15 : 0.4);

    final activeGoals = goals.where((g) => g.status == GoalStatus.active).length;
    final completedGoals = goals.where((g) => g.status == GoalStatus.completed).length;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: borderColor, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Section header ─────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 12, 12),
            child: Row(
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Text(
                        'Goals',
                        style: GoogleFonts.dmSans(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: isDark ? AppColors.primaryForeground : AppColors.textPrimary,
                        ),
                      ),
                      if (goals.isNotEmpty) ...[
                        const SizedBox(width: 8),
                        if (activeGoals > 0)
                          _StatusChip(label: '$activeGoals active', color: AppColors.accent),
                        if (completedGoals > 0) ...[
                          const SizedBox(width: 4),
                          _StatusChip(label: '$completedGoals done', color: AppColors.success),
                        ],
                      ],
                    ],
                  ),
                ),
                if (dragIndex != null)
                  ReorderableDragStartListener(
                    index: dragIndex!,
                    child: const MouseRegion(
                      cursor: SystemMouseCursors.grab,
                      child: Padding(
                        padding: EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                        child: Icon(Icons.drag_handle, size: 16, color: AppColors.textTertiary),
                      ),
                    ),
                  ),
                const SizedBox(width: 8),
                // Column labels
                SizedBox(
                  width: 80,
                  child: Text(
                    'Saved',
                    textAlign: TextAlign.right,
                    style: GoogleFonts.dmSans(fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.textSecondary),
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  width: 80,
                  child: Text(
                    'Target',
                    textAlign: TextAlign.right,
                    style: GoogleFonts.dmSans(fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.textSecondary),
                  ),
                ),
              ],
            ),
          ),

          Divider(height: 1, color: borderColor),

          // ── Goal rows ──────────────────────────────────────────────────
          if (goals.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Text(
                'No goals yet',
                style: GoogleFonts.dmSans(fontSize: 13, color: AppColors.textTertiary),
              ),
            )
          else
            ...goals.expand((g) => [
              _GoalRow(
                goal: g,
                isDark: isDark,
                contributedThisMonth: contributedThisMonth[g.id] ?? 0,
                onTap: () => onGoalTap(g),
              ),
              Divider(height: 1, color: borderColor),
            ]),

          // ── Add link ───────────────────────────────────────────────────
          GestureDetector(
            onTap: onAdd,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
              child: Text(
                'Add Goal',
                style: GoogleFonts.dmSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.accent,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _GoalRow extends StatelessWidget {
  final Goal goal;
  final bool isDark;
  final double contributedThisMonth;
  final VoidCallback onTap;

  const _GoalRow({
    required this.goal,
    required this.isDark,
    required this.onTap,
    this.contributedThisMonth = 0,
  });

  @override
  Widget build(BuildContext context) {
    final g = goal;
    final isActive = g.status == GoalStatus.active;
    final isCompleted = g.status == GoalStatus.completed;
    final textPrimary = isDark ? AppColors.primaryForeground : AppColors.textPrimary;

    final goalColor = g.colorHex != null
        ? Color(int.parse(g.colorHex!.replaceFirst('#', '0xff')))
        : AppColors.accent;
    final displayColor = isActive ? goalColor : goalColor.withValues(alpha: 0.45);
    final progress = g.progress.clamp(0.0, 1.0);

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 11, 16, 11),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // Color dot
                Container(
                  width: 8,
                  height: 8,
                  margin: const EdgeInsets.only(right: 8),
                  decoration: BoxDecoration(color: displayColor, shape: BoxShape.circle),
                ),
                // Goal name + status
                Expanded(
                  child: Row(
                    children: [
                      Flexible(
                        child: Text(
                          g.name,
                          style: GoogleFonts.dmSans(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: isActive ? textPrimary : AppColors.textSecondary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (!isActive) ...[
                        const SizedBox(width: 6),
                        _StatusChip(
                          label: isCompleted ? 'Done' : 'Paused',
                          color: isCompleted ? AppColors.success : AppColors.warning,
                        ),
                      ],
                      if (g.targetDate != null) ...[
                        const SizedBox(width: 6),
                        Text(
                          DateFormat('MMM d').format(g.targetDate!),
                          style: GoogleFonts.dmSans(fontSize: 11, color: AppColors.textTertiary),
                        ),
                      ],
                      if (contributedThisMonth > 0) ...[
                        const SizedBox(width: 6),
                        _StatusChip(label: 'contributed', color: AppColors.success),
                      ],
                    ],
                  ),
                ),
                // Saved
                SizedBox(
                  width: 80,
                  child: Text(
                    currencyFormatter.format(g.currentAmount, decimalDigits: 0),
                    textAlign: TextAlign.right,
                    style: GoogleFonts.dmMono(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: isCompleted ? AppColors.success : displayColor,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                // Target
                SizedBox(
                  width: 80,
                  child: Text(
                    currencyFormatter.format(g.targetAmount, decimalDigits: 0),
                    textAlign: TextAlign.right,
                    style: GoogleFonts.dmMono(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textSecondary,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                ),
              ],
            ),
            // Progress bar
            if (g.targetAmount > 0) ...[
              const SizedBox(height: 6),
              Padding(
                padding: const EdgeInsets.only(left: 16),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(2),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 3,
                    backgroundColor: AppColors.textTertiary.withValues(alpha: 0.15),
                    valueColor: AlwaysStoppedAnimation<Color>(
                      isCompleted ? AppColors.success : displayColor,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String label;
  final Color color;
  const _StatusChip({required this.label, required this.color});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.1),
      borderRadius: BorderRadius.circular(20),
    ),
    child: Text(
      label,
      style: GoogleFonts.dmSans(fontSize: 10, fontWeight: FontWeight.w600, color: color),
    ),
  );
}
