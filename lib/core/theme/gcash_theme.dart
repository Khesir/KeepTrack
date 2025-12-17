import 'package:flutter/material.dart';

/// GCash-inspired color palette
class GCashColors {
  // Primary colors
  static const Color primary = Color(0xFF002CB8);
  static const Color primaryLight = Color(0xFF007DFF);
  static const Color primaryDark = Color(0xFF0062CC);

  // Accent colors
  static const Color skyBlue = Color(0xFF80C0FC);
  static const Color mediumBlue = Color(0xFF2A6496);

  // Semantic colors
  static const Color success = Color(0xFF00C853);
  static const Color error = Color(0xFFE53935);
  static const Color warning = Color(0xFFFF9800);
  static const Color info = Color(0xFF2196F3);

  // Neutral colors
  static const Color background = Color(0xFFF5F7FA);
  static const Color cardBackground = Color(0xFFFFFFFF);
  static const Color border = Color(0xFFE0E7ED);
  static const Color textPrimary = Color(0xFF1A1F36);
  static const Color textSecondary = Color(0xFF8492A6);
  static const Color textDisabled = Color(0xFFC0CCDA);
}

/// GCash-inspired text styles
class GCashTextStyles {
  // Headers
  static const TextStyle h1 = TextStyle(
    fontSize: 32,
    fontWeight: FontWeight.w700,
    height: 1.25,
    letterSpacing: -0.5,
    color: GCashColors.textPrimary,
  );

  static const TextStyle h2 = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.w600,
    height: 1.33,
    letterSpacing: -0.3,
    color: GCashColors.textPrimary,
  );

  static const TextStyle h3 = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    height: 1.4,
    color: GCashColors.textPrimary,
  );

  // Body text
  static const TextStyle bodyLarge = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    height: 1.5,
    color: GCashColors.textPrimary,
  );

  static const TextStyle bodyMedium = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    height: 1.43,
    color: GCashColors.textPrimary,
  );

  static const TextStyle bodySmall = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    height: 1.33,
    color: GCashColors.textSecondary,
  );

  // Currency/numbers (emphasized)
  static const TextStyle currency = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.5,
    color: GCashColors.textPrimary,
  );

  static const TextStyle currencyMedium = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    color: GCashColors.textPrimary,
  );

  // Labels
  static const TextStyle label = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.5,
    color: GCashColors.textSecondary,
  );

  static const TextStyle caption = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w400,
    color: GCashColors.textSecondary,
  );
}

/// Shadow system for cards
class GCashShadows {
  // Elevated cards (floating above background)
  static const BoxShadow cardElevated = BoxShadow(
    color: Color(0x1A000000),
    offset: Offset(0, 4),
    blurRadius: 16,
    spreadRadius: 0,
  );

  // Standard cards
  static const BoxShadow cardDefault = BoxShadow(
    color: Color(0x0D000000),
    offset: Offset(0, 2),
    blurRadius: 8,
    spreadRadius: 0,
  );

  // Subtle cards (minimal elevation)
  static const BoxShadow cardSubtle = BoxShadow(
    color: Color(0x08000000),
    offset: Offset(0, 1),
    blurRadius: 4,
    spreadRadius: 0,
  );

  // Pressed state
  static const BoxShadow cardPressed = BoxShadow(
    color: Color(0x05000000),
    offset: Offset(0, 1),
    blurRadius: 2,
    spreadRadius: 0,
  );
}

/// Spacing constants (8px base)
class GCashSpacing {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;
  static const double xxl = 48;

  // Screen padding
  static const EdgeInsets screenPadding = EdgeInsets.all(16);
  static const EdgeInsets screenPaddingHorizontal =
      EdgeInsets.symmetric(horizontal: 16);

  // Card spacing
  static const EdgeInsets cardPadding = EdgeInsets.all(16);
  static const EdgeInsets cardPaddingLarge = EdgeInsets.all(20);
  static const double cardGap = 16;

  // List item spacing
  static const EdgeInsets listItemPadding = EdgeInsets.symmetric(
    horizontal: 16,
    vertical: 12,
  );
}

/// Button styles
class GCashButtons {
  // PRIMARY BUTTON (Main CTAs)
  static final ButtonStyle primary = ElevatedButton.styleFrom(
    backgroundColor: GCashColors.primary,
    foregroundColor: Colors.white,
    elevation: 0,
    shadowColor: Colors.transparent,
    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
    ),
    textStyle: const TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.w600,
      letterSpacing: 0.2,
    ),
  );

  // SECONDARY BUTTON (Alternative actions)
  static final ButtonStyle secondary = OutlinedButton.styleFrom(
    foregroundColor: GCashColors.primary,
    backgroundColor: Colors.transparent,
    side: const BorderSide(color: GCashColors.primary, width: 1.5),
    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
    ),
    textStyle: const TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.w600,
      letterSpacing: 0.2,
    ),
  );

  // TERTIARY/GHOST BUTTON (Low priority)
  static final ButtonStyle tertiary = TextButton.styleFrom(
    foregroundColor: GCashColors.primary,
    backgroundColor: Colors.transparent,
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(8),
    ),
    textStyle: const TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.w600,
      letterSpacing: 0.2,
    ),
  );

  // DESTRUCTIVE BUTTON (Delete, cancel actions)
  static final ButtonStyle destructive = ElevatedButton.styleFrom(
    backgroundColor: GCashColors.error,
    foregroundColor: Colors.white,
    elevation: 0,
    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
    ),
  );

  // SMALL BUTTON (Compact variant)
  static final ButtonStyle small = ElevatedButton.styleFrom(
    backgroundColor: GCashColors.primary,
    foregroundColor: Colors.white,
    elevation: 0,
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
    minimumSize: const Size(0, 36),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(8),
    ),
    textStyle: const TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.w600,
    ),
  );
}

/// Icon specifications
class GCashIcons {
  static const double sizeSmall = 20;
  static const double sizeStandard = 24;
  static const double sizeLarge = 32;
  static const double sizeXLarge = 48;

  /// Icon with background (for feature icons)
  static Widget withBackground({
    required IconData icon,
    Color backgroundColor = const Color(0xFFEEF5FF),
    Color iconColor = GCashColors.primary,
    double size = 24,
    double padding = 12,
  }) {
    return Container(
      padding: EdgeInsets.all(padding),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(
        icon,
        size: size,
        color: iconColor,
      ),
    );
  }
}

/// Main GCash theme configuration
ThemeData getGCashTheme() {
  return ThemeData(
    useMaterial3: true,

    // Color scheme
    colorScheme: const ColorScheme.light(
      primary: GCashColors.primary,
      secondary: GCashColors.primaryLight,
      error: GCashColors.error,
      surface: GCashColors.cardBackground,
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      onSurface: GCashColors.textPrimary,
    ),

    // Typography
    textTheme: const TextTheme(
      displayLarge: GCashTextStyles.h1,
      displayMedium: GCashTextStyles.h2,
      displaySmall: GCashTextStyles.h3,
      bodyLarge: GCashTextStyles.bodyLarge,
      bodyMedium: GCashTextStyles.bodyMedium,
      bodySmall: GCashTextStyles.bodySmall,
      labelLarge: GCashTextStyles.label,
      labelSmall: GCashTextStyles.caption,
    ),

    // Component themes
    scaffoldBackgroundColor: GCashColors.background,

    cardTheme: CardThemeData(
      color: GCashColors.cardBackground,
      elevation: 0,
      shadowColor: Colors.black.withValues(alpha: 0.05),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
    ),

    elevatedButtonTheme: ElevatedButtonThemeData(
      style: GCashButtons.primary,
    ),

    outlinedButtonTheme: OutlinedButtonThemeData(
      style: GCashButtons.secondary,
    ),

    textButtonTheme: TextButtonThemeData(
      style: GCashButtons.tertiary,
    ),

    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.white,
      foregroundColor: GCashColors.textPrimary,
      elevation: 0,
      centerTitle: false,
      titleTextStyle: GCashTextStyles.h3,
      iconTheme: IconThemeData(
        color: GCashColors.textPrimary,
        size: 24,
      ),
    ),

    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: Colors.white,
      selectedItemColor: GCashColors.primary,
      unselectedItemColor: GCashColors.textSecondary,
      selectedLabelStyle: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w600,
      ),
      unselectedLabelStyle: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w400,
      ),
      type: BottomNavigationBarType.fixed,
      elevation: 0,
    ),

    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: GCashColors.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: GCashColors.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: GCashColors.primary, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: GCashColors.error),
      ),
      labelStyle: GCashTextStyles.bodyMedium.copyWith(
        color: GCashColors.textSecondary,
      ),
      hintStyle: GCashTextStyles.bodyMedium.copyWith(
        color: GCashColors.textDisabled,
      ),
    ),

    dividerTheme: const DividerThemeData(
      color: GCashColors.border,
      thickness: 1,
      space: 1,
    ),
  );
}
