import 'package:intl/intl.dart';
import 'package:keep_track/core/di/service_locator.dart';
import 'package:keep_track/core/settings/domain/entities/app_settings.dart';
import 'package:keep_track/core/settings/presentation/settings_controller.dart';
import 'package:keep_track/core/state/stream_state.dart';

/// Utility class for formatting currency based on user settings.
/// Resolves SettingsController once and subscribes to changes — never calls
/// locator.get<>() from inside a build method.
class CurrencyFormatter {
  CurrencyFormatter._() {
    _initFromLocator();
  }

  static final CurrencyFormatter _instance = CurrencyFormatter._();
  static CurrencyFormatter get instance => _instance;

  String _symbol = '₱';
  String _code = 'PHP';

  void _initFromLocator() {
    try {
      final controller = locator.get<SettingsController>();
      _applySettings(controller.data);
      controller.stream.listen((state) {
        if (state is AsyncData<AppSettings>) _applySettings(state.data);
      });
    } catch (_) {
      // SettingsController not yet registered — keep defaults
    }
  }

  void _applySettings(AppSettings? settings) {
    if (settings == null) return;
    _symbol = settings.currency.symbol;
    _code = settings.currency.code;
  }

  String get currencySymbol => _symbol;
  String get currencyCode => _code;

  String format(double amount, {int decimalDigits = 0}) =>
      NumberFormat.currency(symbol: _symbol, decimalDigits: decimalDigits).format(amount);

  String formatCompact(double amount) =>
      NumberFormat.compactCurrency(symbol: _symbol, decimalDigits: 1).format(amount);

  String formatWithoutSymbol(double amount, {int decimalDigits = 0}) =>
      NumberFormat.currency(symbol: '', decimalDigits: decimalDigits).format(amount).trim();

  String formatWithDecimals(double amount, int decimalDigits) =>
      NumberFormat.currency(symbol: _symbol, decimalDigits: decimalDigits).format(amount);
}

/// Shorthand for currency formatter
final currencyFormatter = CurrencyFormatter.instance;
