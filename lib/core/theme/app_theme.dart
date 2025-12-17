import 'package:flutter/material.dart';

/// Modern Shadcn-inspired color palette with minimalist design
class AppColors {
  // Primary colors - Subtle and professional
  static const Color primary = Color(0xFF18181B); // Near black (zinc-900)
  static const Color primaryForeground = Color(0xFFFAFAFA); // Off-white

  // Secondary colors
  static const Color secondary = Color(0xFFF4F4F5); // Zinc-100
  static const Color secondaryForeground = Color(0xFF18181B);

  // Accent color - Subtle indigo
  static const Color accent = Color(0xFF6366F1); // Indigo-500
  static const Color accentLight = Color(0xFF818CF8); // Indigo-400
  static const Color accentDark = Color(0xFF4F46E5); // Indigo-600

  // Semantic colors - Muted and professional
  static const Color success = Color(0xFF10B981); // Emerald-500
  static const Color successLight = Color(0xFFD1FAE5); // Emerald-100
  static const Color error = Color(0xFFEF4444); // Red-500
  static const Color errorLight = Color(0xFFFEE2E2); // Red-100
  static const Color warning = Color(0xFFF59E0B); // Amber-500
  static const Color warningLight = Color(0xFFFEF3C7); // Amber-100
  static const Color info = Color(0xFF3B82F6); // Blue-500
  static const Color infoLight = Color(0xFFDCEFFE); // Blue-100

  // Neutral colors - Clean and minimal
  static const Color background = Color(0xFFFFFFFF); // Pure white
  static const Color backgroundSecondary = Color(0xFFFAFAFA); // Zinc-50
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceHover = Color(0xFFF9FAFB); // Gray-50
  static const Color border = Color(0xFFE4E4E7); // Zinc-200
  static const Color borderLight = Color(0xFFF4F4F5); // Zinc-100
  static const Color divider = Color(0xFFF4F4F5);

  // Text colors - High contrast and readable
  static const Color textPrimary = Color(0xFF09090B); // Zinc-950
  static const Color textSecondary = Color(0xFF71717A); // Zinc-500
  static const Color textTertiary = Color(0xFFA1A1AA); // Zinc-400
  static const Color textDisabled = Color(0xFFD4D4D8); // Zinc-300
  static const Color textOnPrimary = Color(0xFFFFFFFF);

  // Card colors
  static const Color card = Color(0xFFFFFFFF);
  static const Color cardBorder = Color(0xFFF4F4F5);

  // Input colors
  static const Color input = Color(0xFFFFFFFF);
  static const Color inputBorder = Color(0xFFE4E4E7);
  static const Color inputFocus = Color(0xFF18181B);

  // Muted colors for less emphasis
  static const Color muted = Color(0xFFF4F4F5);
  static const Color mutedForeground = Color(0xFF71717A);

  // Income/Expense colors (EveryDollar style)
  static const Color income = Color(0xFF10B981); // Green
  static const Color expense = Color(0xFFEF4444); // Red
}

/// Modern text styles inspired by Shadcn
class AppTextStyles {
  // Display styles - Large, impactful
  static const TextStyle display = TextStyle(
    fontSize: 36,
    fontWeight: FontWeight.w600,
    height: 1.2,
    letterSpacing: -1,
    color: AppColors.textPrimary,
  );

  // Headers
  static const TextStyle h1 = TextStyle(
    fontSize: 30,
    fontWeight: FontWeight.w600,
    height: 1.2,
    letterSpacing: -0.8,
    color: AppColors.textPrimary,
  );

  static const TextStyle h2 = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.w600,
    height: 1.25,
    letterSpacing: -0.5,
    color: AppColors.textPrimary,
  );

  static const TextStyle h3 = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    height: 1.3,
    letterSpacing: -0.3,
    color: AppColors.textPrimary,
  );

  static const TextStyle h4 = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    height: 1.4,
    color: AppColors.textPrimary,
  );

  // Body text
  static const TextStyle bodyLarge = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    height: 1.5,
    color: AppColors.textPrimary,
  );

  static const TextStyle bodyMedium = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    height: 1.5,
    color: AppColors.textPrimary,
  );

  static const TextStyle bodySmall = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w400,
    height: 1.5,
    color: AppColors.textSecondary,
  );

  // Labels
  static const TextStyle label = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    height: 1.4,
    color: AppColors.textPrimary,
  );

  static const TextStyle labelSmall = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    height: 1.4,
    letterSpacing: 0.2,
    color: AppColors.textSecondary,
  );

  // Caption/helper text
  static const TextStyle caption = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    height: 1.4,
    color: AppColors.textSecondary,
  );

  // Muted text
  static const TextStyle muted = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    height: 1.5,
    color: AppColors.mutedForeground,
  );

  // Currency/numbers (tabular)
  static const TextStyle currency = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.5,
    color: AppColors.textPrimary,
    fontFeatures: [FontFeature.tabularFigures()],
  );

  static const TextStyle currencyLarge = TextStyle(
    fontSize: 32,
    fontWeight: FontWeight.w600,
    letterSpacing: -1,
    color: AppColors.textPrimary,
    fontFeatures: [FontFeature.tabularFigures()],
  );

  static const TextStyle currencySmall = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w500,
    color: AppColors.textPrimary,
    fontFeatures: [FontFeature.tabularFigures()],
  );
}

/// Modern button styles
class AppButtons {
  // Primary button - Dark background
  static final ButtonStyle primary = ElevatedButton.styleFrom(
    backgroundColor: AppColors.primary,
    foregroundColor: AppColors.primaryForeground,
    elevation: 0,
    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    textStyle: const TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.w500,
      letterSpacing: 0,
    ),
  );

  // Secondary button - Light background
  static final ButtonStyle secondary = ElevatedButton.styleFrom(
    backgroundColor: AppColors.secondary,
    foregroundColor: AppColors.secondaryForeground,
    elevation: 0,
    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
  );

  // Outline button
  static final ButtonStyle outline = OutlinedButton.styleFrom(
    foregroundColor: AppColors.textPrimary,
    backgroundColor: Colors.transparent,
    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
    side: const BorderSide(color: AppColors.inputBorder, width: 1),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
  );

  // Ghost button - Minimal
  static final ButtonStyle ghost = TextButton.styleFrom(
    foregroundColor: AppColors.textPrimary,
    backgroundColor: Colors.transparent,
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
    textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
  );

  // Destructive button
  static final ButtonStyle destructive = ElevatedButton.styleFrom(
    backgroundColor: AppColors.error,
    foregroundColor: Colors.white,
    elevation: 0,
    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
  );
}

/// Spacing constants (4px base)
class AppSpacing {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;
  static const double xxl = 48;
  static const double xxxl = 64;

  // Screen padding
  static const EdgeInsets screenPadding = EdgeInsets.all(16);
  static const EdgeInsets screenPaddingH = EdgeInsets.symmetric(horizontal: 16);
  static const EdgeInsets screenPaddingV = EdgeInsets.symmetric(vertical: 16);

  // Card padding
  static const EdgeInsets cardPadding = EdgeInsets.all(16);
  static const EdgeInsets cardPaddingLarge = EdgeInsets.all(24);
}

/// Border radius constants
class AppRadius {
  static const double sm = 6;
  static const double md = 8;
  static const double lg = 12;
  static const double xl = 16;
  static const double full = 9999;

  static BorderRadius circular(double radius) => BorderRadius.circular(radius);
  static BorderRadius circularSm = BorderRadius.circular(sm);
  static BorderRadius circularMd = BorderRadius.circular(md);
  static BorderRadius circularLg = BorderRadius.circular(lg);
  static BorderRadius circularXl = BorderRadius.circular(xl);
}

/// Shadow styles - Subtle and minimal
class AppShadows {
  static const BoxShadow subtle = BoxShadow(
    color: Color(0x0A000000), // Very subtle
    blurRadius: 2,
    offset: Offset(0, 1),
  );

  static const BoxShadow sm = BoxShadow(
    color: Color(0x0D000000),
    blurRadius: 4,
    offset: Offset(0, 1),
  );

  static const BoxShadow md = BoxShadow(
    color: Color(0x0F000000),
    blurRadius: 8,
    offset: Offset(0, 2),
  );

  static const BoxShadow lg = BoxShadow(
    color: Color(0x10000000),
    blurRadius: 16,
    offset: Offset(0, 4),
  );
}

/// Complete Material 3 theme
ThemeData getModernTheme() {
  return ThemeData(
    useMaterial3: true,
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

    // Typography
    textTheme: const TextTheme(
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

    // AppBar
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.background,
      foregroundColor: AppColors.textPrimary,
      elevation: 0,
      centerTitle: false,
      titleTextStyle: AppTextStyles.h3,
      iconTheme: IconThemeData(color: AppColors.textPrimary),
    ),

    // Card
    cardTheme: CardThemeData(
      color: AppColors.card,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: AppRadius.circularLg,
        side: const BorderSide(color: AppColors.border, width: 1),
      ),
      margin: EdgeInsets.zero,
    ),

    // Input decoration
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
      labelStyle: AppTextStyles.label,
      hintStyle: AppTextStyles.muted,
    ),

    // Buttons
    elevatedButtonTheme: ElevatedButtonThemeData(style: AppButtons.primary),
    outlinedButtonTheme: OutlinedButtonThemeData(style: AppButtons.outline),
    textButtonTheme: TextButtonThemeData(style: AppButtons.ghost),

    // Divider
    dividerTheme: const DividerThemeData(
      color: AppColors.divider,
      thickness: 1,
      space: 1,
    ),

    // FloatingActionButton
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: AppColors.primary,
      foregroundColor: AppColors.primaryForeground,
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: AppRadius.circularLg),
    ),

    // Chip
    chipTheme: ChipThemeData(
      backgroundColor: AppColors.secondary,
      selectedColor: AppColors.primary,
      secondarySelectedColor: AppColors.primary,
      labelStyle: AppTextStyles.labelSmall,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: AppRadius.circularMd),
    ),
  );
}
