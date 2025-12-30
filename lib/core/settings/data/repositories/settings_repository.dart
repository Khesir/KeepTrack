import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../domain/entities/app_settings.dart';

/// Repository for managing app settings using SharedPreferences
class SettingsRepository {
  static const String _settingsKey = 'app_settings';

  final SharedPreferences _prefs;

  SettingsRepository(this._prefs);

  /// Load settings from local storage
  AppSettings loadSettings() {
    final jsonString = _prefs.getString(_settingsKey);
    if (jsonString == null) {
      return const AppSettings(); // Return defaults
    }

    try {
      final json = jsonDecode(jsonString) as Map<String, dynamic>;
      return AppSettings.fromJson(json);
    } catch (e) {
      // If parsing fails, return defaults
      return const AppSettings();
    }
  }

  /// Save settings to local storage
  Future<bool> saveSettings(AppSettings settings) async {
    final jsonString = jsonEncode(settings.toJson());
    return await _prefs.setString(_settingsKey, jsonString);
  }

  /// Clear all settings (reset to defaults)
  Future<bool> clearSettings() async {
    return await _prefs.remove(_settingsKey);
  }

  /// Check if settings exist
  bool hasSettings() {
    return _prefs.containsKey(_settingsKey);
  }
}
