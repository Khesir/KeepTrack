import 'package:intl/intl.dart';
import 'package:keep_track/core/di/service_locator.dart';
import 'package:keep_track/core/settings/presentation/settings_controller.dart';
import 'package:keep_track/core/state/stream_state.dart';

/// Utility class for formatting currency based on user settings
class CurrencyFormatter {
  CurrencyFormatter._();

  static final CurrencyFormatter _instance = CurrencyFormatter._();
  static CurrencyFormatter get instance => _instance;

  /// Get the current currency symbol from settings
  String get currencySymbol {
    try {
      final controller = locator.get<SettingsController>();
      return controller.data?.currency.symbol ?? '₱';
    } catch (e) {
      return '₱'; // Default to peso if settings not available
    }
  }

  /// Get the current currency code from settings
  String get currencyCode {
    try {
      final controller = locator.get<SettingsController>();
      return controller.data?.currency.code ?? 'PHP';
    } catch (e) {
      return 'PHP'; // Default to PHP if settings not available
    }
  }

  /// Format a number as currency with symbol and no decimal places
  String format(double amount, {int decimalDigits = 0}) {
    return NumberFormat.currency(
      symbol: currencySymbol,
      decimalDigits: decimalDigits,
    ).format(amount);
  }

  /// Format a number as currency with compact notation (e.g., 1.5K, 2.3M)
  String formatCompact(double amount) {
    return NumberFormat.compactCurrency(
      symbol: currencySymbol,
      decimalDigits: 1,
    ).format(amount);
  }

  /// Format a number without symbol (just the number with separators)
  String formatWithoutSymbol(double amount, {int decimalDigits = 0}) {
    return NumberFormat.currency(
      symbol: '',
      decimalDigits: decimalDigits,
    ).format(amount).trim();
  }

  /// Format with custom decimal places
  String formatWithDecimals(double amount, int decimalDigits) {
    return NumberFormat.currency(
      symbol: currencySymbol,
      decimalDigits: decimalDigits,
    ).format(amount);
  }
}

/// Shorthand for currency formatter
final currencyFormatter = CurrencyFormatter.instance;
