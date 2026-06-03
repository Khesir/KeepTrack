import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Keep Track brand color palette – wolf-inspired
/// Light mode: Snow white surfaces, Midnight text
/// Dark mode:  Void/Midnight surfaces, Snow text
class AppColors {
  static const Color primary = Color(0xFF2C2C2A);           // midnight
  static const Color primaryForeground = Color(0xFFF1EFE8); // snow

  static const Color secondary = Color(0xFFF1EFE8);         // snow
  static const Color secondaryForeground = Color(0xFF2C2C2A);

  static const Color accent = Color(0xFF534AB7);            // violet
  static const Color accentLight = Color(0xFFEEEDFE);       // violetLight
  static const Color accentDark = Color(0xFF3C3489);        // violetDark

  static const Color success = Color(0xFF1D9E75);           // teal
  static const Color successLight = Color(0xFFE1F5EE);      // tealLight
  static const Color error = Color(0xFFE24B4A);             // red
  static const Color errorLight = Color(0xFFFCEBEB);        // redLight
  static const Color warning = Color(0xFFEF9F27);           // gold
  static const Color warningLight = Color(0xFFFAEEDA);      // goldLight
  static const Color info = Color(0xFF378ADD);              // blue
  static const Color infoLight = Color(0xFFE6F1FB);         // blueLight

  static const Color background = Color(0xFFF1EFE8);        // snow
  static const Color backgroundSecondary = Color(0xFFEBE9E1);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceHover = Color(0xFFF5F4EE);
  static const Color border = Color(0xFFD3D1C7);            // ash
  static const Color borderLight = Color(0xFFE8E7DF);
  static const Color divider = Color(0xFFD3D1C7);           // ash

  static const Color textPrimary = Color(0xFF2C2C2A);       // midnight
  static const Color textSecondary = Color(0xFF888780);     // wolfGray
  static const Color textTertiary = Color(0xFFD3D1C7);      // ash
  static const Color textDisabled = Color(0xFFD3D1C7);      // ash
  static const Color textOnPrimary = Color(0xFFF1EFE8);     // snow

  static const Color card = Color(0xFFFFFFFF);
  static const Color cardBorder = Color(0xFFD3D1C7);        // ash
  static const Color input = Color(0xFFFFFFFF);
  static const Color inputBorder = Color(0xFFD3D1C7);       // ash
  static const Color inputFocus = Color(0xFF2C2C2A);        // midnight

  static const Color muted = Color(0xFFF1EFE8);             // snow
  static const Color mutedForeground = Color(0xFF888780);   // wolfGray

  static const Color income = Color(0xFF1D9E75);            // teal
  static const Color expense = Color(0xFFE24B4A);           // red

  static const Color void_ = Color(0xFF1E1E1C);             // dark background
  static const Color ember = Color(0xFF444441);             // dark borders

  static const Color tealDark = Color(0xFF0F6E56);
  static const Color goldDark = Color(0xFF633806);
  static const Color redDark = Color(0xFFA32D2D);
  static const Color blueDark = Color(0xFF0C447C);

  static const Color surfaceDark = Color(0xFF2C2C2A);       // midnight
  static const Color cardDark = Color(0xFF2C2C2A);          // midnight
  static const Color borderDark = Color(0xFF444441);        // ember
  static const Color inputDark = Color(0xFF2C2C2A);         // midnight
  static const Color inputBorderDark = Color(0xFF444441);   // ember
  static const Color inputFocusDark = Color(0xFFF1EFE8);   // snow
  static const Color textPrimaryDark = Color(0xFFF1EFE8);  // snow
  static const Color textTertiaryDark = Color(0xFF444441);  // ember
  static const Color textDisabledDark = Color(0xFF444441);  // ember
}

/// Keep Track typography – DM Sans UI + DM Mono for numbers
class AppTextStyles {
  static TextTheme baseTextTheme() => GoogleFonts.dmSansTextTheme();

  static final TextStyle display = GoogleFonts.dmSans(
    fontSize: 36, fontWeight: FontWeight.w600, height: 1.2,
    letterSpacing: -1, color: AppColors.textPrimary,
  );

  static final TextStyle h1 = GoogleFonts.dmSans(
    fontSize: 30, fontWeight: FontWeight.w600, height: 1.2,
    letterSpacing: -0.8, color: AppColors.textPrimary,
  );
  static final TextStyle h2 = GoogleFonts.dmSans(
    fontSize: 24, fontWeight: FontWeight.w600, height: 1.25,
    letterSpacing: -0.5, color: AppColors.textPrimary,
  );
  static final TextStyle h3 = GoogleFonts.dmSans(
    fontSize: 20, fontWeight: FontWeight.w600, height: 1.3,
    letterSpacing: -0.3, color: AppColors.textPrimary,
  );
  static final TextStyle h4 = GoogleFonts.dmSans(
    fontSize: 16, fontWeight: FontWeight.w600, height: 1.4,
    color: AppColors.textPrimary,
  );

  static final TextStyle bodyLarge = GoogleFonts.dmSans(
    fontSize: 16, fontWeight: FontWeight.w400, height: 1.5,
    color: AppColors.textPrimary,
  );
  static final TextStyle bodyMedium = GoogleFonts.dmSans(
    fontSize: 14, fontWeight: FontWeight.w400, height: 1.5,
    color: AppColors.textPrimary,
  );
  static final TextStyle bodySmall = GoogleFonts.dmSans(
    fontSize: 13, fontWeight: FontWeight.w400, height: 1.5,
    color: AppColors.textSecondary,
  );

  static final TextStyle label = GoogleFonts.dmSans(
    fontSize: 14, fontWeight: FontWeight.w500, height: 1.4,
    color: AppColors.textPrimary,
  );
  static final TextStyle labelSmall = GoogleFonts.dmSans(
    fontSize: 12, fontWeight: FontWeight.w500, height: 1.4,
    letterSpacing: 0.2, color: AppColors.textSecondary,
  );
  static final TextStyle caption = GoogleFonts.dmSans(
    fontSize: 12, fontWeight: FontWeight.w400, height: 1.4,
    color: AppColors.textSecondary,
  );
  static final TextStyle muted = GoogleFonts.dmSans(
    fontSize: 14, fontWeight: FontWeight.w400, height: 1.5,
    color: AppColors.mutedForeground,
  );

  static final TextStyle currency = GoogleFonts.dmMono(
    fontSize: 24, fontWeight: FontWeight.w500, letterSpacing: -0.5,
    color: AppColors.textPrimary,
    fontFeatures: const [FontFeature.tabularFigures()],
  );
  static final TextStyle currencyLarge = GoogleFonts.dmMono(
    fontSize: 32, fontWeight: FontWeight.w500, letterSpacing: -1,
    color: AppColors.textPrimary,
    fontFeatures: const [FontFeature.tabularFigures()],
  );
  static final TextStyle currencySmall = GoogleFonts.dmMono(
    fontSize: 16, fontWeight: FontWeight.w500,
    color: AppColors.textPrimary,
    fontFeatures: const [FontFeature.tabularFigures()],
  );
}

/// Button styles
class AppButtons {
  static final ButtonStyle primary = ElevatedButton.styleFrom(
    backgroundColor: AppColors.primary,
    foregroundColor: AppColors.primaryForeground,
    elevation: 0,
    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    textStyle: GoogleFonts.dmSans(fontSize: 14, fontWeight: FontWeight.w500),
  );

  static final ButtonStyle primaryDark = ElevatedButton.styleFrom(
    backgroundColor: AppColors.background,
    foregroundColor: AppColors.primary,
    elevation: 0,
    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    textStyle: GoogleFonts.dmSans(fontSize: 14, fontWeight: FontWeight.w500),
  );

  static final ButtonStyle secondary = ElevatedButton.styleFrom(
    backgroundColor: AppColors.secondary,
    foregroundColor: AppColors.secondaryForeground,
    elevation: 0,
    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    textStyle: GoogleFonts.dmSans(fontSize: 14, fontWeight: FontWeight.w500),
  );

  static final ButtonStyle outline = OutlinedButton.styleFrom(
    foregroundColor: AppColors.textPrimary,
    backgroundColor: Colors.transparent,
    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
    side: const BorderSide(color: AppColors.inputBorder, width: 1),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    textStyle: GoogleFonts.dmSans(fontSize: 14, fontWeight: FontWeight.w500),
  );

  static final ButtonStyle ghost = TextButton.styleFrom(
    foregroundColor: AppColors.textPrimary,
    backgroundColor: Colors.transparent,
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
    textStyle: GoogleFonts.dmSans(fontSize: 14, fontWeight: FontWeight.w500),
  );

  static final ButtonStyle destructive = ElevatedButton.styleFrom(
    backgroundColor: AppColors.error,
    foregroundColor: AppColors.textPrimaryDark,
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

/// Shadows
class AppShadows {
  static const BoxShadow subtle = BoxShadow(color: Color(0x0A000000), blurRadius: 2, offset: Offset(0, 1));
  static const BoxShadow sm = BoxShadow(color: Color(0x0D000000), blurRadius: 4, offset: Offset(0, 1));
  static const BoxShadow md = BoxShadow(color: Color(0x0F000000), blurRadius: 8, offset: Offset(0, 2));
  static const BoxShadow lg = BoxShadow(color: Color(0x10000000), blurRadius: 16, offset: Offset(0, 4));
}
