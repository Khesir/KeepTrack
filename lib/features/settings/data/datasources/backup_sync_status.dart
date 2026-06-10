import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class BackupSyncStatus {
  BackupSyncStatus._();
  static final BackupSyncStatus instance = BackupSyncStatus._();

  static const _key = 'backup_last_synced_at';

  final notifier = ValueNotifier<DateTime?>(null);

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw != null) notifier.value = DateTime.tryParse(raw);
  }

  Future<void> update(DateTime dt) async {
    notifier.value = dt;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, dt.toIso8601String());
  }
}
