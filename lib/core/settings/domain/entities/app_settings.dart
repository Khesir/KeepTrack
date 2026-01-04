import 'package:flutter/material.dart';

/// Theme mode options
enum AppThemeMode {
  light,
  dark,
  system;

  String get displayName {
    switch (this) {
      case AppThemeMode.light:
        return 'Light';
      case AppThemeMode.dark:
        return 'Dark';
      case AppThemeMode.system:
        return 'System';
    }
  }

  IconData get icon {
    switch (this) {
      case AppThemeMode.light:
        return Icons.light_mode;
      case AppThemeMode.dark:
        return Icons.dark_mode;
      case AppThemeMode.system:
        return Icons.brightness_auto;
    }
  }

  ThemeMode toThemeMode() {
    switch (this) {
      case AppThemeMode.light:
        return ThemeMode.light;
      case AppThemeMode.dark:
        return ThemeMode.dark;
      case AppThemeMode.system:
        return ThemeMode.system;
    }
  }
}

/// Currency options
enum AppCurrency {
  peso('₱', 'PHP', 'Philippine Peso'),
  dollar('\$', 'USD', 'US Dollar'),
  euro('€', 'EUR', 'Euro'),
  pound('£', 'GBP', 'British Pound'),
  yen('¥', 'JPY', 'Japanese Yen'),
  yuan('¥', 'CNY', 'Chinese Yuan'),
  won('₩', 'KRW', 'South Korean Won'),
  rupee('₹', 'INR', 'Indian Rupee'),
  baht('฿', 'THB', 'Thai Baht'),
  ringgit('RM', 'MYR', 'Malaysian Ringgit'),
  singapore('S\$', 'SGD', 'Singapore Dollar'),
  hongkong('HK\$', 'HKD', 'Hong Kong Dollar'),
  australian('A\$', 'AUD', 'Australian Dollar'),
  canadian('C\$', 'CAD', 'Canadian Dollar'),
  ruble('₽', 'RUB', 'Russian Ruble'),
  real('R\$', 'BRL', 'Brazilian Real'),
  rand('R', 'ZAR', 'South African Rand'),
  dirham('د.إ', 'AED', 'UAE Dirham'),
  riyal('﷼', 'SAR', 'Saudi Riyal'),
  franc('CHF', 'CHF', 'Swiss Franc');

  final String symbol;
  final String code;
  final String displayName;

  const AppCurrency(this.symbol, this.code, this.displayName);
}

/// Application settings
class AppSettings {
  final AppThemeMode themeMode;
  final AppCurrency currency;

  const AppSettings({
    this.themeMode = AppThemeMode.system,
    this.currency = AppCurrency.peso,
  });

  AppSettings copyWith({
    AppThemeMode? themeMode,
    AppCurrency? currency,
  }) {
    return AppSettings(
      themeMode: themeMode ?? this.themeMode,
      currency: currency ?? this.currency,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'themeMode': themeMode.name,
      'currency': currency.name,
    };
  }

  factory AppSettings.fromJson(Map<String, dynamic> json) {
    return AppSettings(
      themeMode: AppThemeMode.values.firstWhere(
        (e) => e.name == json['themeMode'],
        orElse: () => AppThemeMode.system,
      ),
      currency: AppCurrency.values.firstWhere(
        (e) => e.name == json['currency'],
        orElse: () => AppCurrency.peso,
      ),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AppSettings &&
          runtimeType == other.runtimeType &&
          themeMode == other.themeMode &&
          currency == other.currency;

  @override
  int get hashCode => Object.hash(themeMode, currency);

  @override
  String toString() => 'AppSettings(themeMode: $themeMode, currency: $currency)';
}
