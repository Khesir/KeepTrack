import 'local_cache.dart';
import 'sync_status.dart';

/// In-memory cache — used on web (no persistence by design).
class MemoryLocalCache implements LocalCache {
  final Map<String, Map<String, Map<String, dynamic>>> _store = {};

  Map<String, Map<String, dynamic>> _box(String name) =>
      _store.putIfAbsent(name, () => {});

  @override
  Future<void> init() async {}

  @override
  Future<Map<String, dynamic>?> get(String box, String key) async {
    final raw = _box(box)[key];
    if (raw == null) return null;
    return {...extractData(raw), kSyncKey: raw[kSyncKey]};
  }

  @override
  Future<List<Map<String, dynamic>>> getAll(String box) async {
    return _box(box).values
        .map((raw) {
          final status = extractStatus(raw);
          if (status == SyncStatus.pendingDelete) return null;
          return {...extractData(raw), kSyncKey: raw[kSyncKey]};
        })
        .whereType<Map<String, dynamic>>()
        .toList();
  }

  @override
  Future<List<Map<String, dynamic>>> getDirty(String box) async {
    return _box(box).entries
        .where((e) => extractStatus(e.value).isDirty)
        .map((e) => {
              'key': e.key,
              ...extractData(e.value),
              kSyncKey: e.value[kSyncKey],
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
    _box(box)[key] = wrapEntry(data, status);
  }

  @override
  Future<void> putAll(
    String box,
    Map<String, Map<String, dynamic>> entries, {
    SyncStatus status = SyncStatus.synced,
  }) async {
    final b = _box(box);
    for (final e in entries.entries) {
      b[e.key] = wrapEntry(e.value, status);
    }
  }

  @override
  Future<void> setStatus(String box, String key, SyncStatus status) async {
    final b = _box(box);
    final raw = b[key];
    if (raw == null) return;
    b[key] = {...raw, kSyncKey: status.value};
  }

  @override
  Future<void> delete(String box, String key) async {
    _box(box).remove(key);
  }

  @override
  Future<void> clear(String box) async {
    _box(box).clear();
  }

  @override
  Future<void> clearAll() async {
    _store.clear();
  }

  @override
  Future<void> dispose() async {
    _store.clear();
  }
}
