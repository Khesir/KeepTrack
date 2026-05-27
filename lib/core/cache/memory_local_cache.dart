import 'local_cache.dart';

/// In-memory cache — used on web (no persistence by design).
class MemoryLocalCache implements LocalCache {
  final Map<String, Map<String, Map<String, dynamic>>> _store = {};

  Map<String, Map<String, dynamic>> _box(String name) =>
      _store.putIfAbsent(name, () => {});

  @override
  Future<void> init() async {}

  @override
  Future<Map<String, dynamic>?> get(String box, String key) async {
    return _box(box)[key];
  }

  @override
  Future<List<Map<String, dynamic>>> getAll(String box) async {
    return _box(box).values.toList();
  }

  @override
  Future<void> put(
    String box,
    String key,
    Map<String, dynamic> data,
  ) async {
    _box(box)[key] = data;
  }

  @override
  Future<void> putAll(
    String box,
    Map<String, Map<String, dynamic>> entries,
  ) async {
    final b = _box(box);
    for (final e in entries.entries) {
      b[e.key] = e.value;
    }
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
