import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:keep_track/core/logging/app_logger.dart';
import 'package:keep_track/features/notifications/domain/entities/notification_settings.dart';

/// Repository for persisting notification settings to SharedPreferences
class NotificationSettingsRepository {
  static const String _key = 'notification_settings';

  final SharedPreferences _prefs;

  NotificationSettingsRepository(this._prefs);

  /// Load notification settings from storage
  NotificationSettings load() {
    try {
      final json = _prefs.getString(_key);
      if (json == null) {
        AppLogger.info('NotificationSettingsRepository: No saved settings, using defaults');
        return const NotificationSettings();
      }

      final data = jsonDecode(json) as Map<String, dynamic>;
      final settings = NotificationSettings.fromJson(data);
      AppLogger.info('NotificationSettingsRepository: Settings loaded');
      return settings;
    } catch (e) {
      AppLogger.error('NotificationSettingsRepository: Error loading settings', e);
      return const NotificationSettings();
    }
  }

  /// Save notification settings to storage
  Future<bool> save(NotificationSettings settings) async {
    try {
      final json = jsonEncode(settings.toJson());
      final success = await _prefs.setString(_key, json);
      if (success) {
        AppLogger.info('NotificationSettingsRepository: Settings saved');
      }
      return success;
    } catch (e) {
      AppLogger.error('NotificationSettingsRepository: Error saving settings', e);
      return false;
    }
  }

  /// Clear notification settings
  Future<bool> clear() async {
    try {
      final success = await _prefs.remove(_key);
      if (success) {
        AppLogger.info('NotificationSettingsRepository: Settings cleared');
      }
      return success;
    } catch (e) {
      AppLogger.error('NotificationSettingsRepository: Error clearing settings', e);
      return false;
    }
  }
}
