import 'package:flutter/material.dart';
import 'package:keep_track/core/theme/app_theme.dart';

ThemeData getLightTheme() {
  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    colorScheme: const ColorScheme.light(
      primary: AppColors.primary,
      onPrimary: AppColors.background,
      secondary: AppColors.success,
      onSecondary: Colors.white,
      tertiary: AppColors.warning,
      onTertiary: AppColors.goldDark,
      error: AppColors.error,
      onError: Colors.white,
      surface: AppColors.surface,
      onSurface: AppColors.textPrimary,
      surfaceContainerHighest: AppColors.background,
    ),
    scaffoldBackgroundColor: AppColors.background,
    textTheme: AppTextStyles.baseTextTheme().copyWith(
      displayLarge: AppTextStyles.display,
      headlineLarge: AppTextStyles.h1,
      headlineMedium: AppTextStyles.h2,
      headlineSmall: AppTextStyles.h3,
      titleLarge: AppTextStyles.h4,
      bodyLarge: AppTextStyles.bodyLarge,
      bodyMedium: AppTextStyles.bodyMedium,
      bodySmall: AppTextStyles.bodySmall,
      labelLarge: AppTextStyles.label,
      labelMedium: AppTextStyles.labelSmall,
      labelSmall: AppTextStyles.caption,
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: AppColors.background,
      foregroundColor: AppColors.textPrimary,
      elevation: 0,
      centerTitle: false,
      titleTextStyle: AppTextStyles.h3.copyWith(color: AppColors.textPrimary),
      iconTheme: const IconThemeData(color: AppColors.textPrimary),
    ),
    cardTheme: CardThemeData(
      color: AppColors.card,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: AppRadius.circularLg,
        side: const BorderSide(color: AppColors.borderLight, width: 0.5),
      ),
      margin: EdgeInsets.zero,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.input,
      border: OutlineInputBorder(
        borderRadius: AppRadius.circularMd,
        borderSide: const BorderSide(color: AppColors.inputBorder, width: 1),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: AppRadius.circularMd,
        borderSide: const BorderSide(color: AppColors.inputBorder, width: 1),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: AppRadius.circularMd,
        borderSide: const BorderSide(color: AppColors.inputFocus, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: AppRadius.circularMd,
        borderSide: const BorderSide(color: AppColors.error, width: 1),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      labelStyle: AppTextStyles.label.copyWith(color: AppColors.mutedForeground),
      hintStyle: AppTextStyles.muted,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(style: AppButtons.primary),
    outlinedButtonTheme: OutlinedButtonThemeData(style: AppButtons.outline),
    textButtonTheme: TextButtonThemeData(style: AppButtons.ghost),
    dividerTheme: const DividerThemeData(
      color: AppColors.borderLight,
      thickness: 0.5,
      space: 1,
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: AppColors.primary,
      foregroundColor: AppColors.background,
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: AppRadius.circularLg),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: AppColors.background,
      selectedColor: AppColors.primary,
      labelStyle: AppTextStyles.labelSmall,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: AppRadius.circularMd,
        side: const BorderSide(color: AppColors.border, width: 0.5),
      ),
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: AppColors.surface,
      selectedItemColor: AppColors.primary,
      unselectedItemColor: AppColors.mutedForeground,
      elevation: 0,
      type: BottomNavigationBarType.fixed,
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: AppColors.surface,
      indicatorColor: AppColors.background,
      labelTextStyle: WidgetStateProperty.all(AppTextStyles.caption),
    ),
  );
}

ThemeData getDarkTheme() {
  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: const ColorScheme.dark(
      primary: AppColors.background,
      onPrimary: AppColors.primary,
      secondary: AppColors.success,
      onSecondary: Colors.white,
      tertiary: AppColors.warning,
      onTertiary: AppColors.goldDark,
      error: AppColors.error,
      onError: Colors.white,
      surface: AppColors.surfaceDark,
      onSurface: AppColors.textPrimaryDark,
      surfaceContainerHighest: AppColors.primary,
    ),
    scaffoldBackgroundColor: AppColors.void_,
    textTheme: AppTextStyles.baseTextTheme().copyWith(
      displayLarge: AppTextStyles.display.copyWith(color: AppColors.textPrimaryDark),
      headlineLarge: AppTextStyles.h1.copyWith(color: AppColors.textPrimaryDark),
      headlineMedium: AppTextStyles.h2.copyWith(color: AppColors.textPrimaryDark),
      headlineSmall: AppTextStyles.h3.copyWith(color: AppColors.textPrimaryDark),
      titleLarge: AppTextStyles.h4.copyWith(color: AppColors.textPrimaryDark),
      bodyLarge: AppTextStyles.bodyLarge.copyWith(color: AppColors.textPrimaryDark),
      bodyMedium: AppTextStyles.bodyMedium.copyWith(color: AppColors.textPrimaryDark),
      bodySmall: AppTextStyles.bodySmall,
      labelLarge: AppTextStyles.label.copyWith(color: AppColors.textPrimaryDark),
      labelMedium: AppTextStyles.labelSmall,
      labelSmall: AppTextStyles.caption,
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: AppColors.void_,
      foregroundColor: AppColors.textPrimaryDark,
      elevation: 0,
      centerTitle: false,
      titleTextStyle: AppTextStyles.h3.copyWith(color: AppColors.textPrimaryDark),
      iconTheme: const IconThemeData(color: AppColors.textPrimaryDark),
    ),
    cardTheme: CardThemeData(
      color: AppColors.cardDark,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: AppRadius.circularLg,
        side: const BorderSide(color: AppColors.borderDark, width: 0.5),
      ),
      margin: EdgeInsets.zero,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.inputDark,
      border: OutlineInputBorder(
        borderRadius: AppRadius.circularMd,
        borderSide: const BorderSide(color: AppColors.inputBorderDark, width: 1),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: AppRadius.circularMd,
        borderSide: const BorderSide(color: AppColors.inputBorderDark, width: 1),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: AppRadius.circularMd,
        borderSide: const BorderSide(color: AppColors.inputFocusDark, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: AppRadius.circularMd,
        borderSide: const BorderSide(color: AppColors.error, width: 1),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      labelStyle: AppTextStyles.label.copyWith(color: AppColors.mutedForeground),
      hintStyle: AppTextStyles.muted,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(style: AppButtons.primaryDark),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: AppButtons.outline.copyWith(
        foregroundColor: WidgetStateProperty.all(AppColors.textPrimaryDark),
        side: WidgetStateProperty.all(
          const BorderSide(color: AppColors.borderDark, width: 1),
        ),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: AppButtons.ghost.copyWith(
        foregroundColor: WidgetStateProperty.all(AppColors.textPrimaryDark),
      ),
    ),
    dividerTheme: const DividerThemeData(
      color: AppColors.borderDark,
      thickness: 0.5,
      space: 1,
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: AppColors.background,
      foregroundColor: AppColors.primary,
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: AppRadius.circularLg),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: AppColors.primary,
      selectedColor: AppColors.background,
      labelStyle: AppTextStyles.labelSmall.copyWith(color: AppColors.textPrimaryDark),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: AppRadius.circularMd,
        side: const BorderSide(color: AppColors.borderDark, width: 0.5),
      ),
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: AppColors.surfaceDark,
      selectedItemColor: AppColors.textPrimaryDark,
      unselectedItemColor: AppColors.mutedForeground,
      elevation: 0,
      type: BottomNavigationBarType.fixed,
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: AppColors.surfaceDark,
      indicatorColor: AppColors.ember,
      labelTextStyle: WidgetStateProperty.all(
        AppTextStyles.caption.copyWith(color: AppColors.mutedForeground),
      ),
    ),
  );
}
