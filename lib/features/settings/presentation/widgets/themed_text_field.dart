import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:keep_track/core/theme/app_theme.dart';

class ThemedTextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final bool obscure;
  final bool isDark;
  final String? error;
  final VoidCallback onToggleObscure;

  const ThemedTextField({
    super.key,
    required this.controller,
    required this.label,
    required this.obscure,
    required this.isDark,
    required this.onToggleObscure,
    this.error,
  });

  @override
  Widget build(BuildContext context) {
    final border = isDark
        ? AppColors.border.withValues(alpha: 0.3)
        : AppColors.border;
    final textPrimary = isDark
        ? AppColors.primaryForeground
        : AppColors.textPrimary;

    return TextField(
      controller: controller,
      obscureText: obscure,
      style: GoogleFonts.dmSans(fontSize: 14, color: textPrimary),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.dmSans(
          fontSize: 13,
          color: AppColors.textSecondary,
        ),
        errorText: error,
        errorStyle: GoogleFonts.dmSans(fontSize: 12, color: AppColors.error),
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 12,
        ),
        filled: true,
        fillColor: isDark
            ? Colors.white.withValues(alpha: 0.05)
            : AppColors.background,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: border, width: 0.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.accent, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.error),
        ),
        suffixIcon: IconButton(
          icon: Icon(
            obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined,
            size: 16,
            color: AppColors.textSecondary,
          ),
          onPressed: onToggleObscure,
        ),
      ),
    );
  }
}
