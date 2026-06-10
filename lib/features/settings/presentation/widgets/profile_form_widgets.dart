import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:keep_track/core/theme/app_theme.dart';

class ProfileInfoField extends StatelessWidget {
  final String label;
  final String value;
  final bool isDark;
  const ProfileInfoField({super.key, required this.label, required this.value, required this.isDark});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label.toUpperCase(), style: GoogleFonts.dmSans(fontSize: 10, fontWeight: FontWeight.w600, color: AppColors.textSecondary, letterSpacing: 0.6)),
            const SizedBox(height: 4),
            Text(value, style: GoogleFonts.dmSans(fontSize: 13, fontWeight: FontWeight.w500, color: isDark ? AppColors.primaryForeground : AppColors.textPrimary)),
          ],
        ),
      );
}

class ProfileInlineEditCard extends StatelessWidget {
  final bool isDark;
  final String label;
  final String value;
  final Color? valueColor;
  final bool expanded;
  final VoidCallback onToggle;
  final Widget? child;

  const ProfileInlineEditCard({
    super.key,
    required this.isDark,
    required this.label,
    required this.value,
    required this.expanded,
    required this.onToggle,
    this.valueColor,
    this.child,
  });

  @override
  Widget build(BuildContext context) {
    final bg = isDark ? AppColors.cardDark : AppColors.card;
    final border = isDark ? AppColors.border.withValues(alpha: 0.2) : AppColors.border.withValues(alpha: 0.5);

    return Container(
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(12), border: Border.all(color: border, width: 0.5)),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 12, 12),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(label.toUpperCase(), style: GoogleFonts.dmSans(fontSize: 10, fontWeight: FontWeight.w600, color: AppColors.textSecondary, letterSpacing: 0.6)),
                      const SizedBox(height: 4),
                      Text(value, style: GoogleFonts.dmSans(fontSize: 13, fontWeight: FontWeight.w500,
                          color: valueColor ?? (isDark ? AppColors.primaryForeground : AppColors.textPrimary))),
                    ],
                  ),
                ),
                MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: GestureDetector(
                    onTap: onToggle,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: isDark ? Colors.white.withValues(alpha: 0.07) : AppColors.background,
                        borderRadius: BorderRadius.circular(7),
                        border: Border.all(color: border),
                      ),
                      child: Text(
                        expanded ? 'Cancel' : 'Edit',
                        style: GoogleFonts.dmSans(fontSize: 12, fontWeight: FontWeight.w600,
                            color: expanded ? AppColors.textSecondary : AppColors.accent),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (child != null) ...[
            Divider(height: 1, thickness: 0.5, color: border),
            child!,
          ],
        ],
      ),
    );
  }
}

class ProfileTextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final bool obscure;
  final VoidCallback? onToggleObscure;
  final String? error;
  final bool isDark;

  const ProfileTextField({super.key, required this.controller, required this.label, required this.isDark, this.obscure = false, this.onToggleObscure, this.error});

  @override
  Widget build(BuildContext context) {
    final border = isDark ? AppColors.border.withValues(alpha: 0.3) : AppColors.border;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: controller,
          obscureText: obscure,
          style: GoogleFonts.dmSans(fontSize: 13, color: isDark ? AppColors.primaryForeground : AppColors.textPrimary),
          decoration: InputDecoration(
            labelText: label,
            labelStyle: GoogleFonts.dmSans(fontSize: 12, color: AppColors.textSecondary),
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            filled: true,
            fillColor: isDark ? Colors.white.withValues(alpha: 0.05) : AppColors.background,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: border)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: border, width: 0.5)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppColors.accent, width: 1.5)),
            suffixIcon: onToggleObscure != null
                ? IconButton(icon: Icon(obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined, size: 15, color: AppColors.textSecondary), onPressed: onToggleObscure)
                : null,
          ),
        ),
        if (error != null) ...[
          const SizedBox(height: 5),
          Text(error!, style: GoogleFonts.dmSans(fontSize: 11, color: AppColors.error)),
        ],
      ],
    );
  }
}

class ProfileFormActions extends StatelessWidget {
  final bool loading;
  final VoidCallback onSave;
  final VoidCallback onCancel;
  final bool isDark;

  const ProfileFormActions({super.key, required this.loading, required this.onSave, required this.onCancel, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: onCancel,
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.textSecondary,
              side: BorderSide(color: isDark ? AppColors.border.withValues(alpha: 0.3) : AppColors.border),
              padding: const EdgeInsets.symmetric(vertical: 10),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: Text('Cancel', style: GoogleFonts.dmSans(fontSize: 12, fontWeight: FontWeight.w500)),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: FilledButton(
            onPressed: loading ? null : onSave,
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.accent,
              padding: const EdgeInsets.symmetric(vertical: 10),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: loading
                ? const SizedBox(height: 14, width: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : Text('Save changes', style: GoogleFonts.dmSans(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white)),
          ),
        ),
      ],
    );
  }
}

class ProfileNameEditFields extends StatelessWidget {
  final TextEditingController controller;
  final String? error;
  final bool loading;
  final bool isDark;
  final VoidCallback onSave;
  final VoidCallback onCancel;

  const ProfileNameEditFields({super.key, required this.controller, required this.error, required this.loading, required this.isDark, required this.onSave, required this.onCancel});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ProfileTextField(controller: controller, label: 'New display name', isDark: isDark, error: error),
          const SizedBox(height: 12),
          ProfileFormActions(loading: loading, onSave: onSave, onCancel: onCancel, isDark: isDark),
        ],
      ),
    );
  }
}

class ProfilePasswordEditFields extends StatelessWidget {
  final TextEditingController passwordCtrl;
  final TextEditingController confirmCtrl;
  final bool obscurePwd;
  final bool obscureConfirm;
  final VoidCallback onTogglePwd;
  final VoidCallback onToggleConfirm;
  final String? error;
  final bool loading;
  final bool isDark;
  final VoidCallback onSave;
  final VoidCallback onCancel;

  const ProfilePasswordEditFields({
    super.key,
    required this.passwordCtrl, required this.confirmCtrl,
    required this.obscurePwd, required this.obscureConfirm,
    required this.onTogglePwd, required this.onToggleConfirm,
    required this.error, required this.loading, required this.isDark,
    required this.onSave, required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ProfileTextField(controller: passwordCtrl, label: 'New password', obscure: obscurePwd, onToggleObscure: onTogglePwd, isDark: isDark, error: error),
          const SizedBox(height: 10),
          ProfileTextField(controller: confirmCtrl, label: 'Confirm new password', obscure: obscureConfirm, onToggleObscure: onToggleConfirm, isDark: isDark),
          const SizedBox(height: 12),
          ProfileFormActions(loading: loading, onSave: onSave, onCancel: onCancel, isDark: isDark),
        ],
      ),
    );
  }
}
