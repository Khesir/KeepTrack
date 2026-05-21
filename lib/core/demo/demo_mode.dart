import 'package:shared_preferences/shared_preferences.dart';

class DemoMode {
  static const _key = 'demo_mode_enabled';
  static bool _enabled = false;

  static bool get enabled => _enabled;

  static Future<void> load(SharedPreferences prefs) async {
    _enabled = prefs.getBool(_key) ?? false;
  }

  static Future<void> setEnabled(SharedPreferences prefs, bool value) async {
    _enabled = value;
    await prefs.setBool(_key, value);
  }
}
