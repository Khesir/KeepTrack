import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:keep_track/core/settings/utils/currency_formatter.dart';
import 'package:keep_track/core/state/state.dart';
import 'package:keep_track/core/theme/app_theme.dart';
import 'package:keep_track/features/finance/modules/goal/domain/entities/goal.dart';
import 'package:keep_track/features/finance/presentation/screens/configuration/goals/widgets/goals_management_dialog.dart';
import 'package:keep_track/features/finance/presentation/state/goal_controller.dart';
import '../widgets/detail_sheet_widgets.dart';
import 'goal_contribution_drawer.dart';

class GoalDetailSheet extends StatefulWidget {
  final Goal goal;
  final GoalController goalController;
  final Future<void> Function(Goal currentGoal, double amount, PaymentTxConfig config) onContribute;
  final Future<void> Function(Goal updated) onUpdate;
  final VoidCallback? onDelete;

  const GoalDetailSheet({
    super.key,
    required this.goal,
    required this.goalController,
    required this.onContribute,
    required this.onUpdate,
    this.onDelete,
  });

  @override
  State<GoalDetailSheet> createState() => _GoalDetailSheetState();
}

class _GoalDetailSheetState extends State<GoalDetailSheet> {
  bool _loading = false;

  Goal _latestGoal(AsyncState<List<Goal>> state) {
    if (state is AsyncData<List<Goal>>) {
      for (final g in state.data) {
        if (g.id == widget.goal.id) return g;
      }
    }
    return widget.goal;
  }

  Future<void> _confirmDelete(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete?'),
        content: const Text('This cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(context, true), style: TextButton.styleFrom(foregroundColor: AppColors.error), child: const Text('Delete')),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      Navigator.of(context).pop();
      widget.onDelete?.call();
    }
  }

  void _showEditDialog(Goal current) {
    GoalsManagementDialog.show(context, goal: current, onSave: (updated) async { await widget.onUpdate(updated); });
  }

  void _showContributeDrawer(Goal current) {
    showModalBottomSheet(
      context: context, isScrollControlled: true, backgroundColor: Colors.transparent,
      builder: (_) => GoalContributionDrawer(
        goal: current,
        onConfirm: (amount, config) async {
          setState(() => _loading = true);
          try { await widget.onContribute(current, amount, config); }
          finally { if (mounted) setState(() => _loading = false); }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return StreamBuilder<AsyncState<List<Goal>>>(
      stream: widget.goalController.stream,
      initialData: widget.goalController.state,
      builder: (_, snap) {
        final g = _latestGoal(snap.data ?? widget.goalController.state);
        final color = g.colorHex != null
            ? Color(int.parse(g.colorHex!.replaceFirst('#', '0xff')))
            : AppColors.accent;
        final statusLabel = switch (g.status) {
          GoalStatus.completed => ('Completed', AppColors.success),
          GoalStatus.paused    => ('Paused', AppColors.warning),
          _                    => ('Active', color),
        };

        return CompactFrame(
          isDark: isDark,
          title: g.name,
          trailing: StatusPill(text: statusLabel.$1, color: statusLabel.$2),
          child: _GoalViewBody(
            goal: g, color: color, isDark: isDark, loading: _loading,
            onContribute: g.status != GoalStatus.completed ? () => _showContributeDrawer(g) : null,
            onEdit: () => _showEditDialog(g),
            onDelete: widget.onDelete != null ? () => _confirmDelete(context) : null,
          ),
        );
      },
    );
  }
}

class _GoalViewBody extends StatelessWidget {
  final Goal goal;
  final Color color;
  final bool isDark, loading;
  final VoidCallback? onContribute;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const _GoalViewBody({required this.goal, required this.color, required this.isDark, required this.loading, required this.onContribute, this.onEdit, this.onDelete});

  @override
  Widget build(BuildContext context) {
    final g = goal;
    final progress = g.progress.clamp(0.0, 1.0);
    final isComplete = g.isCompleted;

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: isDark ? Colors.white.withValues(alpha: 0.04) : AppColors.background, borderRadius: BorderRadius.circular(12)),
        child: Column(children: [
          Row(children: [
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Saved', style: GoogleFonts.dmSans(fontSize: 11, color: AppColors.textSecondary)),
              Text(currencyFormatter.format(g.currentAmount, decimalDigits: 2),
                  style: GoogleFonts.dmMono(fontSize: 22, fontWeight: FontWeight.w700, color: color, fontFeatures: const [FontFeature.tabularFigures()])),
            ])),
            Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
              Text('Target', style: GoogleFonts.dmSans(fontSize: 11, color: AppColors.textSecondary)),
              Text(currencyFormatter.format(g.targetAmount, decimalDigits: 2),
                  style: GoogleFonts.dmMono(fontSize: 13, fontWeight: FontWeight.w600, color: isDark ? AppColors.primaryForeground : AppColors.textPrimary, fontFeatures: const [FontFeature.tabularFigures()])),
            ]),
          ]),
          const SizedBox(height: 10),
          ClipRRect(borderRadius: BorderRadius.circular(3), child: LinearProgressIndicator(value: progress, minHeight: 6, backgroundColor: isDark ? Colors.white.withValues(alpha: 0.06) : AppColors.border, valueColor: AlwaysStoppedAnimation<Color>(isComplete ? AppColors.success : color))),
          const SizedBox(height: 4),
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text('${(progress * 100).round()}% saved', style: GoogleFonts.dmSans(fontSize: 10, color: AppColors.textSecondary)),
            Text(isComplete ? 'Goal reached!' : '${currencyFormatter.format(g.remainingAmount, decimalDigits: 2)} to go',
                style: GoogleFonts.dmSans(fontSize: 10, color: isComplete ? AppColors.success : AppColors.textSecondary)),
          ]),
        ]),
      ),
      const SizedBox(height: 14),
      if (g.targetDate != null)
        DetailInfoRow(isDark: isDark, label: 'Target date', value: DateFormat('MMMM d, yyyy').format(g.targetDate!),
            sub: g.daysRemaining != null && g.daysRemaining! > 0 ? '${g.daysRemaining} days remaining' : null),
      if (g.monthlyContribution > 0)
        DetailInfoRow(isDark: isDark, label: 'Monthly', value: '${currencyFormatter.format(g.monthlyContribution, decimalDigits: 2)} / month'),
      if (g.savingsBucketId != null)
        DetailInfoRow(isDark: isDark, label: 'Linked to', value: 'Savings bucket', sub: 'Contributions update both goal & bucket balance'),
      const SizedBox(height: 20),
      Row(
        children: [
          Expanded(
            flex: 7,
            child: SizedBox(
              height: 46,
              child: ElevatedButton.icon(
                onPressed: loading ? null : onContribute,
                icon: loading
                    ? const SizedBox(width: 15, height: 15, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : Icon(isComplete ? Icons.check_circle_rounded : Icons.add_circle_outline_rounded, size: 15),
                label: Text(isComplete ? 'Goal Completed' : 'Add Contribution'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: onContribute == null ? AppColors.textTertiary : (isComplete ? AppColors.success : color),
                  foregroundColor: AppColors.textPrimaryDark, elevation: 0,
                  textStyle: GoogleFonts.dmSans(fontSize: 13, fontWeight: FontWeight.w600),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ),
          ),
          if (onEdit != null) ...[
            const SizedBox(width: 8),
            Expanded(flex: 1, child: SizedBox(height: 46, child: OutlinedButton(
              onPressed: onEdit,
              style: OutlinedButton.styleFrom(foregroundColor: isDark ? AppColors.primaryForeground : AppColors.textPrimary, side: BorderSide(color: (isDark ? AppColors.primaryForeground : AppColors.textPrimary).withValues(alpha: 0.4)), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)), padding: EdgeInsets.zero),
              child: const Icon(Icons.edit_outlined, size: 16),
            ))),
          ],
          if (onDelete != null) ...[
            const SizedBox(width: 8),
            Expanded(flex: 1, child: SizedBox(height: 46, child: OutlinedButton(
              onPressed: onDelete,
              style: OutlinedButton.styleFrom(foregroundColor: AppColors.error, side: BorderSide(color: AppColors.error.withValues(alpha: 0.4)), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)), padding: EdgeInsets.zero),
              child: const Icon(Icons.delete_outlined, size: 16),
            ))),
          ],
        ],
      ),
    ]);
  }
}
