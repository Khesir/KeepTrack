import 'package:hive_flutter/hive_flutter.dart';
import 'local_cache.dart';
import 'sync_status.dart';

/// Hive-backed local cache — used on mobile and desktop.
/// Each "box" maps to a named Hive box.
class HiveLocalCache implements LocalCache {
  final Map<String, Box<Map>> _boxes = {};

  @override
  Future<void> init() async {
    await Hive.initFlutter();
  }

  Future<Box<Map>> _box(String name) async {
    return _boxes[name] ??= await Hive.openBox<Map>(name);
  }

  @override
  Future<Map<String, dynamic>?> get(String box, String key) async {
    final b = await _box(box);
    final raw = b.get(key);
    if (raw == null) return null;
    final cast = raw.cast<String, dynamic>();
    return {...extractData(cast), kSyncKey: cast[kSyncKey]};
  }

  @override
  Future<List<Map<String, dynamic>>> getAll(String box) async {
    final b = await _box(box);
    return b.values
        .map((raw) {
          final cast = raw.cast<String, dynamic>();
          final status = extractStatus(cast);
          // Skip pending deletes from normal reads
          if (status == SyncStatus.pendingDelete) return null;
          return {...extractData(cast), kSyncKey: cast[kSyncKey]};
        })
        .whereType<Map<String, dynamic>>()
        .toList();
  }

  @override
  Future<List<Map<String, dynamic>>> getDirty(String box) async {
    final b = await _box(box);
    return b.toMap().entries
        .where((e) {
          final cast = (e.value as Map).cast<String, dynamic>();
          return extractStatus(cast).isDirty;
        })
        .map((e) {
          final cast = (e.value as Map).cast<String, dynamic>();
          return {
            'key': e.key,
            ...extractData(cast),
            kSyncKey: cast[kSyncKey],
          };
        })
        .toList();
  }

  @override
  Future<void> put(
    String box,
    String key,
    Map<String, dynamic> data, {
    SyncStatus status = SyncStatus.synced,
  }) async {
    final b = await _box(box);
    await b.put(key, wrapEntry(data, status));
  }

  @override
  Future<void> putAll(
    String box,
    Map<String, Map<String, dynamic>> entries, {
    SyncStatus status = SyncStatus.synced,
  }) async {
    final b = await _box(box);
    await b.putAll(
        entries.map((k, v) => MapEntry(k, wrapEntry(v, status))));
  }

  @override
  Future<void> setStatus(String box, String key, SyncStatus status) async {
    final b = await _box(box);
    final raw = b.get(key);
    if (raw == null) return;
    final cast = raw.cast<String, dynamic>();
    await b.put(key, {...cast, kSyncKey: status.value});
  }

  @override
  Future<void> delete(String box, String key) async {
    final b = await _box(box);
    await b.delete(key);
  }

  @override
  Future<void> clear(String box) async {
    final b = await _box(box);
    await b.clear();
  }

  @override
  Future<void> dispose() async {
    for (final b in _boxes.values) {
      await b.close();
    }
    _boxes.clear();
  }
}
