import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:keep_track/core/theme/app_theme.dart';
import 'package:keep_track/features/finance/modules/budget/domain/entities/month_plan.dart';

class BudgetSettingsDialog extends StatefulWidget {
  final String monthLabel;
  final String? profileName;
  final Color? profileColor;
  final MonthPlan? monthPlan;
  final bool hasMonthPlan;
  // Month plan callbacks
  final Future<void> Function()? onStartPlanning;
  final Future<void> Function()? onCloseMonthPlan;
  final Future<void> Function()? onReopenMonthPlan;
  final VoidCallback? onDeleteMonth;
  // Profile callbacks
  final VoidCallback? onEditProfile;
  final VoidCallback? onDeleteProfile;

  const BudgetSettingsDialog({
    super.key,
    required this.monthLabel,
    this.profileName,
    this.profileColor,
    this.monthPlan,
    this.hasMonthPlan = false,
    this.onStartPlanning,
    this.onCloseMonthPlan,
    this.onReopenMonthPlan,
    this.onDeleteMonth,
    this.onEditProfile,
    this.onDeleteProfile,
  });

  static Future<void> show(
    BuildContext context, {
    required String monthLabel,
    String? profileName,
    Color? profileColor,
    MonthPlan? monthPlan,
    bool hasMonthPlan = false,
    Future<void> Function()? onStartPlanning,
    Future<void> Function()? onCloseMonthPlan,
    Future<void> Function()? onReopenMonthPlan,
    VoidCallback? onDeleteMonth,
    VoidCallback? onEditProfile,
    VoidCallback? onDeleteProfile,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: true,
      builder: (_) => BudgetSettingsDialog(
        monthLabel: monthLabel,
        profileName: profileName,
        profileColor: profileColor,
        monthPlan: monthPlan,
        hasMonthPlan: hasMonthPlan,
        onStartPlanning: onStartPlanning,
        onCloseMonthPlan: onCloseMonthPlan,
        onReopenMonthPlan: onReopenMonthPlan,
        onDeleteMonth: onDeleteMonth,
        onEditProfile: onEditProfile,
        onDeleteProfile: onDeleteProfile,
      ),
    );
  }

  @override
  State<BudgetSettingsDialog> createState() => _BudgetSettingsDialogState();
}

class _BudgetSettingsDialogState extends State<BudgetSettingsDialog> {
  bool _loading = false;

  Future<void> _run(Future<void> Function() action) async {
    setState(() => _loading = true);
    try {
      await action();
      if (mounted) Navigator.pop(context);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF2C2C2A) : Colors.white;
    final textPrimary = isDark ? AppColors.primaryForeground : AppColors.textPrimary;
    final divColor = AppColors.border.withValues(alpha: isDark ? 0.15 : 0.3);
    final accent = widget.profileColor ?? AppColors.accent;
    final plan = widget.monthPlan;

    return Dialog(
      backgroundColor: bg,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: _buildMain(bg, textPrimary, divColor, accent, plan, isDark),
    );
  }

  Widget _buildMain(Color bg, Color textPrimary, Color divColor, Color accent, MonthPlan? plan, bool isDark) {
    final isClosed = plan?.isClosed ?? false;
    final showMonthPlanSection = widget.onStartPlanning != null || widget.hasMonthPlan;
    final showProfileSection = widget.onEditProfile != null || widget.onDeleteProfile != null;

    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 20, 0, 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              if (widget.profileName != null)
                Row(children: [
                  Container(width: 8, height: 8, decoration: BoxDecoration(color: accent, shape: BoxShape.circle)),
                  const SizedBox(width: 6),
                  Text(widget.profileName!, style: GoogleFonts.dmSans(fontSize: 12, color: AppColors.textSecondary)),
                ]),
              const SizedBox(height: 4),
              Text('Budget Settings', style: GoogleFonts.dmSans(fontSize: 16, fontWeight: FontWeight.w700, color: textPrimary)),
              Text(widget.monthLabel, style: GoogleFonts.dmSans(fontSize: 12, color: AppColors.textSecondary)),
            ]),
          ),

          // Month Plan section
          if (showMonthPlanSection) ...[
            Divider(height: 1, color: divColor),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
              child: Text('MONTH PLAN', style: GoogleFonts.dmSans(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.textTertiary, letterSpacing: 0.8)),
            ),
            if (!widget.hasMonthPlan && widget.onStartPlanning != null)
              _loading
                  ? const Padding(padding: EdgeInsets.all(16), child: Center(child: CircularProgressIndicator()))
                  : _DialogRow(
                      icon: Icons.play_circle_outline_rounded,
                      label: 'Start Planning',
                      color: accent,
                      onTap: () => _run(widget.onStartPlanning!),
                    ),
            if (widget.hasMonthPlan) ...[
              if (_loading)
                const Padding(padding: EdgeInsets.all(16), child: Center(child: CircularProgressIndicator()))
              else if (!isClosed && widget.onCloseMonthPlan != null)
                _DialogRow(
                  icon: Icons.check_circle_outline_rounded,
                  label: 'Close Budget',
                  onTap: () => _run(widget.onCloseMonthPlan!),
                  color: textPrimary,
                )
              else if (isClosed && widget.onReopenMonthPlan != null)
                _DialogRow(
                  icon: Icons.lock_open_rounded,
                  label: 'Re-open Budget',
                  onTap: () => _run(widget.onReopenMonthPlan!),
                  color: textPrimary,
                ),
              if (widget.onDeleteMonth != null)
                _DialogRow(
                  icon: Icons.delete_outline_rounded,
                  label: 'Delete Month',
                  color: AppColors.error,
                  onTap: _loading ? null : () {
                    Navigator.pop(context);
                    widget.onDeleteMonth!();
                  },
                ),
            ],
            if (!widget.hasMonthPlan && widget.onDeleteMonth == null)
              const SizedBox(height: 4),
          ],

          // Profile section
          if (showProfileSection) ...[
            Divider(height: 1, color: divColor),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
              child: Text('PROFILE', style: GoogleFonts.dmSans(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.textTertiary, letterSpacing: 0.8)),
            ),
            if (widget.onEditProfile != null)
              _DialogRow(
                icon: Icons.edit_outlined,
                label: 'Edit Profile',
                color: textPrimary,
                onTap: _loading ? null : () {
                  Navigator.pop(context);
                  widget.onEditProfile!();
                },
              ),
            if (widget.onDeleteProfile != null)
              _DialogRow(
                icon: Icons.delete_forever_rounded,
                label: 'Delete Profile',
                color: AppColors.error,
                onTap: _loading ? null : () {
                  Navigator.pop(context);
                  widget.onDeleteProfile!();
                },
              ),
          ],

          // Cancel
          Divider(height: 1, color: divColor),
          TextButton(
            onPressed: () => Navigator.pop(context),
            style: TextButton.styleFrom(minimumSize: const Size(double.infinity, 48)),
            child: Text('Cancel', style: GoogleFonts.dmSans(fontSize: 14, color: AppColors.textSecondary)),
          ),
        ],
      ),
    );
  }

}

class _DialogRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback? onTap;

  const _DialogRow({required this.icon, required this.label, required this.color, this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 13),
        child: Row(children: [
          Icon(icon, size: 18, color: onTap != null ? color : AppColors.textTertiary),
          const SizedBox(width: 12),
          Text(label, style: GoogleFonts.dmSans(
            fontSize: 14, fontWeight: FontWeight.w500,
            color: onTap != null ? color : AppColors.textTertiary,
          )),
        ]),
      ),
    );
  }
}
