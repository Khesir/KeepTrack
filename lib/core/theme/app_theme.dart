/// App theme configuration
library;

import 'package:flutter/material.dart';

/// App theme - provides light and dark themes
class AppTheme {
  // Private constructor to prevent instantiation
  AppTheme._();

  // ============================================================
  // COLORS
  // ============================================================

  // Primary colors
  static const Color primaryColor = Color(0xFF6200EE);
  static const Color primaryVariant = Color(0xFF3700B3);
  static const Color secondaryColor = Color(0xFF03DAC6);
  static const Color secondaryVariant = Color(0xFF018786);

  // Background colors
  static const Color backgroundLight = Color(0xFFFFFFFF);
  static const Color backgroundDark = Color(0xFF121212);

  // Surface colors
  static const Color surfaceLight = Color(0xFFFFFFFF);
  static const Color surfaceDark = Color(0xFF1E1E1E);

  // Error colors
  static const Color errorColor = Color(0xFFB00020);

  // Status colors
  static const Color successColor = Color(0xFF4CAF50);
  static const Color warningColor = Color(0xFFFF9800);
  static const Color infoColor = Color(0xFF2196F3);

  // Priority colors (for tasks)
  static const Color urgentColor = Color(0xFFD32F2F);
  static const Color highColor = Color(0xFFFF6F00);
  static const Color mediumColor = Color(0xFF1976D2);
  static const Color lowColor = Color(0xFF757575);

  // ============================================================
  // LIGHT THEME
  // ============================================================

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,

      // Color scheme
      colorScheme: const ColorScheme.light(
        primary: primaryColor,
        secondary: secondaryColor,
        surface: surfaceLight,
        error: errorColor,
      ),

      // Scaffold
      scaffoldBackgroundColor: backgroundLight,

      // App bar
      appBarTheme: const AppBarTheme(
        centerTitle: false,
        elevation: 0,
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
      ),

      // Card
      cardTheme: CardThemeData(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),

      // Floating action button
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
      ),

      // Elevated button
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),

      // Text button
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: primaryColor),
      ),

      // Input decoration
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        filled: true,
        fillColor: Colors.grey[100],
      ),

      // Chip
      chipTheme: ChipThemeData(
        backgroundColor: Colors.grey[200],
        selectedColor: primaryColor.withOpacity(0.2),
        labelStyle: const TextStyle(color: Colors.black87),
      ),

      // List tile
      listTileTheme: const ListTileThemeData(
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),
    );
  }

  // ============================================================
  // DARK THEME
  // ============================================================

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,

      // Color scheme
      colorScheme: const ColorScheme.dark(
        primary: primaryColor,
        secondary: secondaryColor,
        surface: surfaceDark,
        error: errorColor,
      ),

      // Scaffold
      scaffoldBackgroundColor: backgroundDark,

      // App bar
      appBarTheme: const AppBarTheme(
        centerTitle: false,
        elevation: 0,
        backgroundColor: surfaceDark,
        foregroundColor: Colors.white,
      ),

      // Card
      cardTheme: CardThemeData(
        elevation: 4,
        color: surfaceDark,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),

      // Floating action button
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
      ),

      // Elevated button
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),

      // Text button
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: primaryColor),
      ),

      // Input decoration
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        filled: true,
        fillColor: Colors.grey[900],
      ),

      // Chip
      chipTheme: ChipThemeData(
        backgroundColor: Colors.grey[800],
        selectedColor: primaryColor.withOpacity(0.3),
        labelStyle: const TextStyle(color: Colors.white70),
      ),

      // List tile
      listTileTheme: const ListTileThemeData(
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: Colors.white, // background of the bar
        selectedItemColor: primaryColor, // selected icon + label
        unselectedItemColor: Colors.grey, // unselected icon + label
        selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold),
        unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.normal),
        type: BottomNavigationBarType.fixed, // or shifting
        showUnselectedLabels: true,
      ),
    );
  }

  // ============================================================
  // CUSTOM COLORS
  // ============================================================

  /// Get color for task priority
  static Color getPriorityColor(String priority) {
    return switch (priority.toLowerCase()) {
      'urgent' => urgentColor,
      'high' => highColor,
      'medium' => mediumColor,
      'low' => lowColor,
      _ => mediumColor,
    };
  }

  /// Get color for task status
  static Color getStatusColor(String status) {
    return switch (status.toLowerCase()) {
      'completed' => successColor,
      'in_progress' || 'inprogress' => infoColor,
      'todo' => warningColor,
      _ => Colors.grey,
    };
  }
}

/// Text styles (can be used throughout the app)
class AppTextStyles {
  AppTextStyles._();

  static const TextStyle headline1 = TextStyle(
    fontSize: 32,
    fontWeight: FontWeight.bold,
  );

  static const TextStyle headline2 = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.bold,
  );

  static const TextStyle headline3 = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w600,
  );

  static const TextStyle body1 = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.normal,
  );

  static const TextStyle body2 = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.normal,
  );

  static const TextStyle caption = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.normal,
  );

  static const TextStyle button = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w600,
  );
}

/// Spacing constants
class AppSpacing {
  AppSpacing._();

  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 16.0;
  static const double lg = 24.0;
  static const double xl = 32.0;
  static const double xxl = 48.0;
}

/// Border radius constants
class AppBorderRadius {
  AppBorderRadius._();

  static const double sm = 4.0;
  static const double md = 8.0;
  static const double lg = 12.0;
  static const double xl = 16.0;
  static const double round = 999.0;
}
