import 'package:keep_track/core/connectivity/connectivity_service.dart';
import 'package:keep_track/core/state/stream_state.dart';
import '../domain/entities/app_settings.dart';
import '../data/repositories/settings_repository.dart';

/// Controller for managing app settings
class SettingsController extends StreamState<AsyncState<AppSettings>> {
  final SettingsRepository _repository;

  SettingsController(this._repository) : super(AsyncData(_repository.loadSettings())) {
    final saved = _repository.loadSettings();
    if (saved.forceOfflineMode) {
      ConnectivityService.instance.setForceOffline(true);
    }
  }

  /// Update theme mode
  Future<void> updateThemeMode(AppThemeMode mode) async {
    final currentSettings = data;
    if (currentSettings == null) return;

    final newSettings = currentSettings.copyWith(themeMode: mode);
    emit(AsyncData(newSettings));
    await _repository.saveSettings(newSettings);
  }

  /// Update currency
  Future<void> updateCurrency(AppCurrency currency) async {
    final currentSettings = data;
    if (currentSettings == null) return;

    final newSettings = currentSettings.copyWith(currency: currency);
    emit(AsyncData(newSettings));
    await _repository.saveSettings(newSettings);
  }

  /// Toggle force offline mode
  Future<void> setForceOfflineMode(bool enabled) async {
    final currentSettings = data;
    if (currentSettings == null) return;
    ConnectivityService.instance.setForceOffline(enabled);
    final newSettings = currentSettings.copyWith(forceOfflineMode: enabled);
    emit(AsyncData(newSettings));
    await _repository.saveSettings(newSettings);
  }

  /// Toggle budget view mode (Simple vs Sheet)
  Future<void> updateBudgetSheetMode(bool sheetMode) async {
    final currentSettings = data;
    if (currentSettings == null) return;
    final newSettings = currentSettings.copyWith(budgetSheetMode: sheetMode);
    emit(AsyncData(newSettings));
    await _repository.saveSettings(newSettings);
  }

  /// Reset to defaults
  Future<void> resetToDefaults() async {
    const defaultSettings = AppSettings();
    emit(const AsyncData(defaultSettings));
    await _repository.clearSettings();
  }

  /// Reload settings from storage
  void reloadSettings() {
    emit(AsyncData(_repository.loadSettings()));
  }
}
