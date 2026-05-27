import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Keep Track — Brand color palette
/// Inspired by Lobo the wolf mascot
/// Light mode: Snow white surfaces, Midnight text
/// Dark mode:  Void/Midnight surfaces, Snow text
class AppColors {
  // ── Gray scale (wolf fur palette) ─────────────────────────────────────────
  static const Color snow = Color(0xFFF1EFE8); // Lightest — mascot base
  static const Color ash = Color(0xFFD3D1C7); // Borders (light mode)
  static const Color wolfGray = Color(0xFF888780); // Secondary text (both)
  static const Color ember = Color(0xFF444441); // Borders (dark mode)
  static const Color midnight = Color(0xFF2C2C2A); // Primary text / dark card
  static const Color void_ = Color(0xFF1E1E1C); // Dark mode background

  // ── Gold (peso / coins / savings) ─────────────────────────────────────────
  static const Color goldLight = Color(0xFFFAEEDA);
  static const Color gold = Color(0xFFEF9F27);
  static const Color goldDark = Color(0xFF633806);

  // ── Teal (success / under budget / savings progress) ──────────────────────
  static const Color tealLight = Color(0xFFE1F5EE);
  static const Color teal = Color(0xFF1D9E75);
  static const Color tealDark = Color(0xFF0F6E56);

  // ── Red (danger / overspent / overdue) ────────────────────────────────────
  static const Color redLight = Color(0xFFFCEBEB);
  static const Color red = Color(0xFFE24B4A);
  static const Color redDark = Color(0xFFA32D2D);

  // ── Blue (Pro tier / cloud / AI) ──────────────────────────────────────────
  static const Color blueLight = Color(0xFFE6F1FB);
  static const Color blue = Color(0xFF378ADD);
  static const Color blueDark = Color(0xFF0C447C);

  // ── Violet (insights / analytics / thinking) ──────────────────────────────
  static const Color violetLight = Color(0xFFEEEDFE);
  static const Color violet = Color(0xFF534AB7);
  static const Color violetDark = Color(0xFF3C3489);

  // ── Semantic aliases ───────────────────────────────────────────────────────
  static const Color income = teal;
  static const Color expense = red;
  static const Color savings = gold;
  static const Color pro = blue;
  static const Color insight = violet;

  // ── Light mode surfaces ────────────────────────────────────────────────────
  static const Color backgroundLight = snow;
  static const Color surfaceLight = Color(0xFFFFFFFF);
  static const Color cardLight = Color(0xFFFFFFFF);
  static const Color borderLight = ash;
  static const Color inputLight = Color(0xFFFFFFFF);
  static const Color inputBorderLight = ash;
  static const Color inputFocusLight = midnight;

  // ── Dark mode surfaces ─────────────────────────────────────────────────────
  static const Color backgroundDark = void_;
  static const Color surfaceDark = midnight;
  static const Color cardDark = midnight;
  static const Color borderDark = ember;
  static const Color inputDark = midnight;
  static const Color inputBorderDark = ember;
  static const Color inputFocusDark = snow;

  // ── Text (light mode) ─────────────────────────────────────────────────────
  static const Color textPrimaryLight = midnight;
  static const Color textSecondaryLight = wolfGray;
  static const Color textTertiaryLight = ash;
  static const Color textDisabledLight = ash;

  // ── Text (dark mode) ──────────────────────────────────────────────────────
  static const Color textPrimaryDark = snow;
  static const Color textSecondaryDark = wolfGray;
  static const Color textTertiaryDark = ember;
  static const Color textDisabledDark = ember;
}

/// Keep Track typography
/// DM Sans  → all UI text (friendly, clean, modern)
/// DM Mono  → all numbers, currency, amounts (ledger feel)
class AppTextStyles {
  // ── Display ───────────────────────────────────────────────────────────────
  static TextStyle display(BuildContext context) => GoogleFonts.dmSans(
    fontSize: 36,
    fontWeight: FontWeight.w600,
    height: 1.2,
    letterSpacing: -1,
    color: _textPrimary(context),
  );

  // ── Headers ───────────────────────────────────────────────────────────────
  static TextStyle h1(BuildContext context) => GoogleFonts.dmSans(
    fontSize: 30,
    fontWeight: FontWeight.w600,
    height: 1.2,
    letterSpacing: -0.8,
    color: _textPrimary(context),
  );

  static TextStyle h2(BuildContext context) => GoogleFonts.dmSans(
    fontSize: 24,
    fontWeight: FontWeight.w600,
    height: 1.25,
    letterSpacing: -0.5,
    color: _textPrimary(context),
  );

  static TextStyle h3(BuildContext context) => GoogleFonts.dmSans(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    height: 1.3,
    letterSpacing: -0.3,
    color: _textPrimary(context),
  );

  static TextStyle h4(BuildContext context) => GoogleFonts.dmSans(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    height: 1.4,
    color: _textPrimary(context),
  );

  // ── Body ──────────────────────────────────────────────────────────────────
  static TextStyle bodyLarge(BuildContext context) => GoogleFonts.dmSans(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    height: 1.5,
    color: _textPrimary(context),
  );

  static TextStyle bodyMedium(BuildContext context) => GoogleFonts.dmSans(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    height: 1.5,
    color: _textPrimary(context),
  );

  static TextStyle bodySmall(BuildContext context) => GoogleFonts.dmSans(
    fontSize: 13,
    fontWeight: FontWeight.w400,
    height: 1.5,
    color: _textSecondary(context),
  );

  // ── Labels ────────────────────────────────────────────────────────────────
  static TextStyle label(BuildContext context) => GoogleFonts.dmSans(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    height: 1.4,
    color: _textPrimary(context),
  );

  static TextStyle labelSmall(BuildContext context) => GoogleFonts.dmSans(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    height: 1.4,
    letterSpacing: 0.2,
    color: _textSecondary(context),
  );

  static TextStyle caption(BuildContext context) => GoogleFonts.dmSans(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    height: 1.4,
    color: _textSecondary(context),
  );

  static TextStyle muted(BuildContext context) => GoogleFonts.dmSans(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    height: 1.5,
    color: _textSecondary(context),
  );

  // ── Currency / numbers (DM Mono — ledger feel) ────────────────────────────
  static TextStyle currency(BuildContext context) => GoogleFonts.dmMono(
    fontSize: 24,
    fontWeight: FontWeight.w500,
    letterSpacing: -0.5,
    color: _textPrimary(context),
    fontFeatures: const [FontFeature.tabularFigures()],
  );

  static TextStyle currencyLarge(BuildContext context) => GoogleFonts.dmMono(
    fontSize: 32,
    fontWeight: FontWeight.w500,
    letterSpacing: -1,
    color: _textPrimary(context),
    fontFeatures: const [FontFeature.tabularFigures()],
  );

  static TextStyle currencySmall(BuildContext context) => GoogleFonts.dmMono(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    color: _textPrimary(context),
    fontFeatures: const [FontFeature.tabularFigures()],
  );

  static TextStyle currencyMono(BuildContext context) => GoogleFonts.dmMono(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    color: _textPrimary(context),
    fontFeatures: const [FontFeature.tabularFigures()],
  );

  // ── Static fallbacks (for ThemeData where context is unavailable) ──────────
  static final TextStyle displayStatic = GoogleFonts.dmSans(
    fontSize: 36,
    fontWeight: FontWeight.w600,
    height: 1.2,
    letterSpacing: -1,
  );
  static final TextStyle h1Static = GoogleFonts.dmSans(
    fontSize: 30,
    fontWeight: FontWeight.w600,
    height: 1.2,
    letterSpacing: -0.8,
  );
  static final TextStyle h2Static = GoogleFonts.dmSans(
    fontSize: 24,
    fontWeight: FontWeight.w600,
    height: 1.25,
    letterSpacing: -0.5,
  );
  static final TextStyle h3Static = GoogleFonts.dmSans(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    height: 1.3,
    letterSpacing: -0.3,
  );
  static final TextStyle h4Static = GoogleFonts.dmSans(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    height: 1.4,
  );
  static final TextStyle bodyLargeStatic = GoogleFonts.dmSans(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    height: 1.5,
  );
  static final TextStyle bodyMediumStatic = GoogleFonts.dmSans(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    height: 1.5,
  );
  static final TextStyle bodySmallStatic = GoogleFonts.dmSans(
    fontSize: 13,
    fontWeight: FontWeight.w400,
    height: 1.5,
    color: AppColors.wolfGray,
  );
  static final TextStyle labelStatic = GoogleFonts.dmSans(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    height: 1.4,
  );
  static final TextStyle labelSmallStatic = GoogleFonts.dmSans(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    height: 1.4,
    letterSpacing: 0.2,
    color: AppColors.wolfGray,
  );
  static final TextStyle captionStatic = GoogleFonts.dmSans(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    height: 1.4,
    color: AppColors.wolfGray,
  );
  static final TextStyle mutedStatic = GoogleFonts.dmSans(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    height: 1.5,
    color: AppColors.wolfGray,
  );
  static final TextStyle currencyStatic = GoogleFonts.dmMono(
    fontSize: 24,
    fontWeight: FontWeight.w500,
    letterSpacing: -0.5,
    fontFeatures: [FontFeature.tabularFigures()],
  );
  static final TextStyle currencyLargeStatic = GoogleFonts.dmMono(
    fontSize: 32,
    fontWeight: FontWeight.w500,
    letterSpacing: -1,
    fontFeatures: [FontFeature.tabularFigures()],
  );
  static final TextStyle currencySmallStatic = GoogleFonts.dmMono(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    fontFeatures: [FontFeature.tabularFigures()],
  );

  // ── Helpers ───────────────────────────────────────────────────────────────
  static Color _textPrimary(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
      ? AppColors.textPrimaryDark
      : AppColors.textPrimaryLight;

  static Color _textSecondary(BuildContext context) => AppColors.wolfGray;
}

/// Button styles
class AppButtons {
  static final ButtonStyle primary = ElevatedButton.styleFrom(
    backgroundColor: AppColors.midnight,
    foregroundColor: AppColors.snow,
    elevation: 0,
    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    textStyle: GoogleFonts.dmSans(fontSize: 14, fontWeight: FontWeight.w500),
  );

  static final ButtonStyle primaryDark = ElevatedButton.styleFrom(
    backgroundColor: AppColors.snow,
    foregroundColor: AppColors.midnight,
    elevation: 0,
    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    textStyle: GoogleFonts.dmSans(fontSize: 14, fontWeight: FontWeight.w500),
  );

  static final ButtonStyle secondary = ElevatedButton.styleFrom(
    backgroundColor: AppColors.ash,
    foregroundColor: AppColors.midnight,
    elevation: 0,
    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    textStyle: GoogleFonts.dmSans(fontSize: 14, fontWeight: FontWeight.w500),
  );

  static final ButtonStyle outline = OutlinedButton.styleFrom(
    foregroundColor: AppColors.midnight,
    backgroundColor: Colors.transparent,
    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
    side: const BorderSide(color: AppColors.ash, width: 1),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    textStyle: GoogleFonts.dmSans(fontSize: 14, fontWeight: FontWeight.w500),
  );

  static final ButtonStyle ghost = TextButton.styleFrom(
    foregroundColor: AppColors.midnight,
    backgroundColor: Colors.transparent,
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
    textStyle: GoogleFonts.dmSans(fontSize: 14, fontWeight: FontWeight.w500),
  );

  static final ButtonStyle destructive = ElevatedButton.styleFrom(
    backgroundColor: AppColors.red,
    foregroundColor: Colors.white,
    elevation: 0,
    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    textStyle: GoogleFonts.dmSans(fontSize: 14, fontWeight: FontWeight.w500),
  );

  static final ButtonStyle pro = ElevatedButton.styleFrom(
    backgroundColor: AppColors.blue,
    foregroundColor: Colors.white,
    elevation: 0,
    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    textStyle: GoogleFonts.dmSans(fontSize: 14, fontWeight: FontWeight.w500),
  );
}

/// Spacing constants (4px base grid)
class AppSpacing {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;
  static const double xxl = 48;
  static const double xxxl = 64;

  static const EdgeInsets screenPadding = EdgeInsets.all(16);
  static const EdgeInsets screenPaddingH = EdgeInsets.symmetric(horizontal: 16);
  static const EdgeInsets screenPaddingV = EdgeInsets.symmetric(vertical: 16);
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
  static final BorderRadius circularSm = BorderRadius.circular(sm);
  static final BorderRadius circularMd = BorderRadius.circular(md);
  static final BorderRadius circularLg = BorderRadius.circular(lg);
  static final BorderRadius circularXl = BorderRadius.circular(xl);
}

/// Shadows — subtle and minimal
class AppShadows {
  static const BoxShadow subtle = BoxShadow(
    color: Color(0x0A000000),
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

/// Badge / pill helpers for budget states
class AppBadgeColors {
  // Under budget
  static const Color underBgLight = AppColors.tealLight;
  static const Color underTextLight = AppColors.tealDark;
  static const Color underBgDark = Color(0xFF04342C);
  static const Color underTextDark = Color(0xFF9FE1CB);

  // Over budget
  static const Color overBgLight = AppColors.redLight;
  static const Color overTextLight = AppColors.redDark;
  static const Color overBgDark = Color(0xFF501313);
  static const Color overTextDark = Color(0xFFF7C1C1);

  // Savings / goal
  static const Color goalBgLight = AppColors.goldLight;
  static const Color goalTextLight = AppColors.goldDark;
  static const Color goalBgDark = Color(0xFF412402);
  static const Color goalTextDark = Color(0xFFFAC775);

  // Pro feature
  static const Color proBgLight = AppColors.blueLight;
  static const Color proTextLight = AppColors.blueDark;
  static const Color proBgDark = Color(0xFF042C53);
  static const Color proTextDark = Color(0xFF85B7EB);

  // Insight / AI
  static const Color insightBgLight = AppColors.violetLight;
  static const Color insightTextLight = AppColors.violetDark;
  static const Color insightBgDark = Color(0xFF26215C);
  static const Color insightTextDark = Color(0xFFCECBF6);
}

/// Light theme
ThemeData getLightTheme() {
  final base = GoogleFonts.dmSansTextTheme();

  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    colorScheme: const ColorScheme.light(
      primary: AppColors.midnight,
      onPrimary: AppColors.snow,
      secondary: AppColors.teal,
      onSecondary: Colors.white,
      tertiary: AppColors.gold,
      onTertiary: AppColors.goldDark,
      error: AppColors.red,
      onError: Colors.white,
      surface: AppColors.surfaceLight,
      onSurface: AppColors.textPrimaryLight,
      surfaceContainerHighest: AppColors.snow,
    ),
    scaffoldBackgroundColor: AppColors.backgroundLight,
    textTheme: base.copyWith(
      displayLarge: AppTextStyles.displayStatic,
      headlineLarge: AppTextStyles.h1Static,
      headlineMedium: AppTextStyles.h2Static,
      headlineSmall: AppTextStyles.h3Static,
      titleLarge: AppTextStyles.h4Static,
      bodyLarge: AppTextStyles.bodyLargeStatic,
      bodyMedium: AppTextStyles.bodyMediumStatic,
      bodySmall: AppTextStyles.bodySmallStatic,
      labelLarge: AppTextStyles.labelStatic,
      labelMedium: AppTextStyles.labelSmallStatic,
      labelSmall: AppTextStyles.captionStatic,
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: AppColors.backgroundLight,
      foregroundColor: AppColors.textPrimaryLight,
      elevation: 0,
      centerTitle: false,
      titleTextStyle: AppTextStyles.h3Static.copyWith(
        color: AppColors.textPrimaryLight,
      ),
      iconTheme: const IconThemeData(color: AppColors.textPrimaryLight),
    ),
    cardTheme: CardThemeData(
      color: AppColors.cardLight,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: AppRadius.circularLg,
        side: const BorderSide(color: AppColors.borderLight, width: 0.5),
      ),
      margin: EdgeInsets.zero,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.inputLight,
      border: OutlineInputBorder(
        borderRadius: AppRadius.circularMd,
        borderSide: const BorderSide(
          color: AppColors.inputBorderLight,
          width: 1,
        ),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: AppRadius.circularMd,
        borderSide: const BorderSide(
          color: AppColors.inputBorderLight,
          width: 1,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: AppRadius.circularMd,
        borderSide: const BorderSide(
          color: AppColors.inputFocusLight,
          width: 2,
        ),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: AppRadius.circularMd,
        borderSide: const BorderSide(color: AppColors.red, width: 1),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      labelStyle: AppTextStyles.labelStatic.copyWith(color: AppColors.wolfGray),
      hintStyle: AppTextStyles.mutedStatic,
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
      backgroundColor: AppColors.midnight,
      foregroundColor: AppColors.snow,
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: AppRadius.circularLg),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: AppColors.snow,
      selectedColor: AppColors.midnight,
      labelStyle: AppTextStyles.labelSmallStatic,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: AppRadius.circularMd,
        side: const BorderSide(color: AppColors.ash, width: 0.5),
      ),
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: AppColors.surfaceLight,
      selectedItemColor: AppColors.midnight,
      unselectedItemColor: AppColors.wolfGray,
      elevation: 0,
      type: BottomNavigationBarType.fixed,
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: AppColors.surfaceLight,
      indicatorColor: AppColors.snow,
      labelTextStyle: WidgetStateProperty.all(AppTextStyles.captionStatic),
    ),
  );
}

/// Dark theme
ThemeData getDarkTheme() {
  final base = GoogleFonts.dmSansTextTheme();

  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: const ColorScheme.dark(
      primary: AppColors.snow,
      onPrimary: AppColors.midnight,
      secondary: AppColors.teal,
      onSecondary: Colors.white,
      tertiary: AppColors.gold,
      onTertiary: AppColors.goldDark,
      error: AppColors.red,
      onError: Colors.white,
      surface: AppColors.surfaceDark,
      onSurface: AppColors.textPrimaryDark,
      surfaceContainerHighest: AppColors.midnight,
    ),
    scaffoldBackgroundColor: AppColors.backgroundDark,
    textTheme: base.copyWith(
      displayLarge: AppTextStyles.displayStatic.copyWith(color: AppColors.snow),
      headlineLarge: AppTextStyles.h1Static.copyWith(color: AppColors.snow),
      headlineMedium: AppTextStyles.h2Static.copyWith(color: AppColors.snow),
      headlineSmall: AppTextStyles.h3Static.copyWith(color: AppColors.snow),
      titleLarge: AppTextStyles.h4Static.copyWith(color: AppColors.snow),
      bodyLarge: AppTextStyles.bodyLargeStatic.copyWith(color: AppColors.snow),
      bodyMedium: AppTextStyles.bodyMediumStatic.copyWith(
        color: AppColors.snow,
      ),
      bodySmall: AppTextStyles.bodySmallStatic,
      labelLarge: AppTextStyles.labelStatic.copyWith(color: AppColors.snow),
      labelMedium: AppTextStyles.labelSmallStatic,
      labelSmall: AppTextStyles.captionStatic,
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: AppColors.backgroundDark,
      foregroundColor: AppColors.textPrimaryDark,
      elevation: 0,
      centerTitle: false,
      titleTextStyle: AppTextStyles.h3Static.copyWith(
        color: AppColors.textPrimaryDark,
      ),
      iconTheme: const IconThemeData(color: AppColors.snow),
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
        borderSide: const BorderSide(
          color: AppColors.inputBorderDark,
          width: 1,
        ),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: AppRadius.circularMd,
        borderSide: const BorderSide(
          color: AppColors.inputBorderDark,
          width: 1,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: AppRadius.circularMd,
        borderSide: const BorderSide(color: AppColors.inputFocusDark, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: AppRadius.circularMd,
        borderSide: const BorderSide(color: AppColors.red, width: 1),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      labelStyle: AppTextStyles.labelStatic.copyWith(color: AppColors.wolfGray),
      hintStyle: AppTextStyles.mutedStatic,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(style: AppButtons.primaryDark),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: AppButtons.outline.copyWith(
        foregroundColor: WidgetStateProperty.all(AppColors.snow),
        side: WidgetStateProperty.all(
          const BorderSide(color: AppColors.ember, width: 1),
        ),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: AppButtons.ghost.copyWith(
        foregroundColor: WidgetStateProperty.all(AppColors.snow),
      ),
    ),
    dividerTheme: const DividerThemeData(
      color: AppColors.borderDark,
      thickness: 0.5,
      space: 1,
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: AppColors.snow,
      foregroundColor: AppColors.midnight,
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: AppRadius.circularLg),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: AppColors.midnight,
      selectedColor: AppColors.snow,
      labelStyle: AppTextStyles.labelSmallStatic.copyWith(
        color: AppColors.snow,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: AppRadius.circularMd,
        side: const BorderSide(color: AppColors.ember, width: 0.5),
      ),
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: AppColors.surfaceDark,
      selectedItemColor: AppColors.snow,
      unselectedItemColor: AppColors.wolfGray,
      elevation: 0,
      type: BottomNavigationBarType.fixed,
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: AppColors.surfaceDark,
      indicatorColor: AppColors.ember,
      labelTextStyle: WidgetStateProperty.all(
        AppTextStyles.captionStatic.copyWith(color: AppColors.wolfGray),
      ),
    ),
  );
}
