import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:keep_track/core/theme/app_theme.dart';

class BudgetSettingsSheet extends StatelessWidget {
  final String monthLabel;
  final VoidCallback? onEditBudget;
  final VoidCallback? onCloseBudget;
  final VoidCallback? onDeleteBudget;
  final VoidCallback? onDeleteProfile;

  const BudgetSettingsSheet({
    super.key,
    required this.monthLabel,
    this.onEditBudget,
    this.onCloseBudget,
    this.onDeleteBudget,
    this.onDeleteProfile,
  });

  static Future<void> show(
    BuildContext context, {
    required String monthLabel,
    VoidCallback? onEditBudget,
    VoidCallback? onCloseBudget,
    VoidCallback? onDeleteBudget,
    VoidCallback? onDeleteProfile,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => BudgetSettingsSheet(
        monthLabel: monthLabel,
        onEditBudget: onEditBudget,
        onCloseBudget: onCloseBudget,
        onDeleteBudget: onDeleteBudget,
        onDeleteProfile: onDeleteProfile,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.void_ : Colors.white;
    final textPrimary = isDark ? AppColors.primaryForeground : AppColors.textPrimary;
    final divColor = isDark ? AppColors.border.withValues(alpha: 0.15) : AppColors.border.withValues(alpha: 0.35);

    return Container(
      decoration: BoxDecoration(
        color: bg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom + 24),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        const SizedBox(height: 12),
        Center(
          child: Container(
            width: 36, height: 4,
            decoration: BoxDecoration(color: AppColors.textTertiary.withValues(alpha: 0.3), borderRadius: BorderRadius.circular(2)),
          ),
        ),
        const SizedBox(height: 20),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(children: [
            Text('Budget Settings', style: GoogleFonts.dmSans(fontSize: 15, fontWeight: FontWeight.w700, color: textPrimary)),
            const SizedBox(width: 8),
            Text(monthLabel, style: GoogleFonts.dmSans(fontSize: 12, color: AppColors.textSecondary)),
          ]),
        ),
        const SizedBox(height: 16),
        if (onEditBudget != null) ...[
          Divider(height: 1, color: divColor),
          _SettingsRow(
            icon: Icons.edit_outlined,
            label: 'Edit Budget',
            color: isDark ? AppColors.primaryForeground : AppColors.textPrimary,
            onTap: () {
              Navigator.pop(context);
              onEditBudget!();
            },
          ),
        ],
        if (onCloseBudget != null) ...[
          Divider(height: 1, color: divColor),
          _SettingsRow(
            icon: Icons.check_circle_outline_rounded,
            label: 'Close Budget',
            color: isDark ? AppColors.primaryForeground : AppColors.textPrimary,
            onTap: () {
              Navigator.pop(context);
              onCloseBudget!();
            },
          ),
        ],
        if (onDeleteBudget != null) ...[
          Divider(height: 1, color: divColor),
          _SettingsRow(
            icon: Icons.delete_outline_rounded,
            label: 'Delete Month',
            color: AppColors.error,
            onTap: () {
              Navigator.pop(context);
              onDeleteBudget!();
            },
          ),
        ],
        if (onDeleteProfile != null) ...[
          Divider(height: 1, color: divColor),
          _SettingsRow(
            icon: Icons.delete_forever_rounded,
            label: 'Delete Profile',
            color: AppColors.error,
            onTap: () {
              Navigator.pop(context);
              onDeleteProfile!();
            },
          ),
        ],
        Divider(height: 1, color: divColor),
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: SizedBox(
            width: double.infinity,
            child: TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel', style: GoogleFonts.dmSans(fontSize: 14, color: AppColors.textSecondary)),
            ),
          ),
        ),
      ]),
    );
  }
}

class _SettingsRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _SettingsRow({required this.icon, required this.label, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Row(children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 12),
          Text(label, style: GoogleFonts.dmSans(fontSize: 14, fontWeight: FontWeight.w500, color: color)),
        ]),
      ),
    );
  }
}
