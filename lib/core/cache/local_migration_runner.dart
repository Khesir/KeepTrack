import 'package:shared_preferences/shared_preferences.dart';
import 'local_cache.dart';

typedef _Migration = Future<void> Function(LocalCache cache);

class LocalMigrationRunner {
  final LocalCache _cache;
  final SharedPreferences _prefs;

  static const _versionKey = 'hive_schema_version';

  LocalMigrationRunner(this._cache, this._prefs);

  /// Ordered list of migrations. Index = version - 1.
  /// Append new migrations here; never reorder or remove existing ones.
  static final List<_Migration> _migrations = [
    _v1_add_wallet_notes,
    _v2_add_transaction_image_paths,
  ];

  Future<void> run() async {
    final current = _prefs.getInt(_versionKey) ?? 0;
    if (current >= _migrations.length) return;
    for (var i = current; i < _migrations.length; i++) {
      print('[LocalMigration] Running migration v${i + 1}...');
      await _migrations[i](_cache);
      await _prefs.setInt(_versionKey, i + 1);
      print('[LocalMigration] Migration v${i + 1} complete.');
    }
  }

  static Future<void> _v1_add_wallet_notes(LocalCache cache) async {
    final entries = await cache.getAll('wallets');
    for (final entry in entries) {
      if (!entry.containsKey('notes')) {
        await cache.put('wallets', entry['id'] as String, {
          ...entry,
          'notes': null,
        });
      }
    }
  }

  static Future<void> _v2_add_transaction_image_paths(LocalCache cache) async {
    final entries = await cache.getAll('transactions');
    for (final entry in entries) {
      if (!entry.containsKey('imagePaths')) {
        await cache.put('transactions', entry['id'] as String, {
          ...entry,
          'imagePaths': <String>[],
        });
      }
    }
  }

  // Template for future migrations:
  //
  // static Future<void> _vN_description(LocalCache cache) async {
  //   final entries = await cache.getAll('<box>');
  //   for (final entry in entries) {
  //     if (!entry.containsKey('<field>')) {
  //       await cache.put('<box>', entry['id'] as String, {
  //         ...entry,
  //         '<field>': <defaultValue>,
  //       });
  //     }
  //   }
  // }
}
