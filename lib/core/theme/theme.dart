import 'package:flutter/material.dart';
import 'package:keep_track/core/theme/app_theme.dart';

/// App theme aligned with Shadcn-inspired AppColors
class AppTheme {
  AppTheme._();

  // ============================================================
  // LIGHT THEME
  // ============================================================

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,

      colorScheme: ColorScheme.light(
        primary: AppColors.primary,
        onPrimary: AppColors.primaryForeground,
        secondary: AppColors.accent,
        onSecondary: Colors.white,
        error: AppColors.error,
        onError: Colors.white,
        surface: AppColors.surface,
        onSurface: AppColors.textPrimary,
      ),

      scaffoldBackgroundColor: AppColors.background,

      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        centerTitle: false,
        iconTheme: IconThemeData(color: AppColors.textPrimary),
      ),

      cardTheme: CardThemeData(
        color: AppColors.card,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: AppColors.border),
        ),
      ),

      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.primaryForeground,
        elevation: 2,
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(style: AppButtons.primary),
      outlinedButtonTheme: OutlinedButtonThemeData(style: AppButtons.outline),
      textButtonTheme: TextButtonThemeData(style: AppButtons.ghost),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.input,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.inputBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.inputBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.inputFocus, width: 2),
        ),
      ),

      chipTheme: ChipThemeData(
        backgroundColor: AppColors.secondary,
        selectedColor: AppColors.primary.withOpacity(0.1),
        labelStyle: const TextStyle(color: AppColors.textPrimary, fontSize: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),

      listTileTheme: const ListTileThemeData(
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        iconColor: AppColors.textSecondary,
        textColor: AppColors.textPrimary,
      ),

      dividerTheme: DividerThemeData(
        color: AppColors.border.withOpacity(0.5),
        thickness: 1,
      ),
    );
  }

  // ============================================================
  // DARK THEME (Zinc-inspired)
  // ============================================================

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,

      colorScheme: ColorScheme.dark(
        primary: AppColors.accentLight,
        onPrimary: Colors.white,
        secondary: AppColors.accent,
        onSecondary: Colors.white,
        error: AppColors.error,
        onError: Colors.white,
        surface: const Color(0xFF09090B), // zinc-950
        onSurface: AppColors.primaryForeground,
      ),

      scaffoldBackgroundColor: const Color(0xFF09090B),

      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF09090B),
        foregroundColor: AppColors.primaryForeground,
        elevation: 0,
        centerTitle: false,
        iconTheme: IconThemeData(color: AppColors.primaryForeground),
      ),

      cardTheme: CardThemeData(
        color: const Color(0xFF18181B), // zinc-900
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: Color(0xFF27272A)), // zinc-800
        ),
      ),

      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppColors.accent,
        foregroundColor: Colors.white,
        elevation: 2,
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(style: AppButtons.primary),
      outlinedButtonTheme: OutlinedButtonThemeData(style: AppButtons.outline),
      textButtonTheme: TextButtonThemeData(style: AppButtons.ghost),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFF18181B),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFF27272A)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.accent, width: 2),
        ),
      ),

      chipTheme: ChipThemeData(
        backgroundColor: const Color(0xFF27272A),
        selectedColor: AppColors.accent.withOpacity(0.3),
        labelStyle: const TextStyle(
          color: AppColors.primaryForeground,
          fontSize: 12,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),

      listTileTheme: const ListTileThemeData(
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        iconColor: AppColors.textTertiary,
        textColor: AppColors.primaryForeground,
      ),

      dividerTheme: DividerThemeData(
        color: const Color(0xFF27272A).withOpacity(0.6),
        thickness: 1,
      ),

      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: Color(0xFF09090B),
        selectedItemColor: AppColors.accent,
        unselectedItemColor: AppColors.textTertiary,
        type: BottomNavigationBarType.fixed,
        showUnselectedLabels: true,
      ),
    );
  }

  // ============================================================
  // SEMANTIC HELPERS
  // ============================================================

  static Color getPriorityColor(String priority) {
    return switch (priority.toLowerCase()) {
      'urgent' => AppColors.error,
      'high' => AppColors.warning,
      'medium' => AppColors.accent,
      'low' => AppColors.mutedForeground,
      _ => AppColors.mutedForeground,
    };
  }

  static Color getStatusColor(String status) {
    return switch (status.toLowerCase()) {
      'completed' => AppColors.success,
      'in_progress' || 'inprogress' => AppColors.info,
      'todo' => AppColors.warning,
      _ => AppColors.textSecondary,
    };
  }
}
