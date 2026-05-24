import 'package:hive_flutter/hive_flutter.dart';
import 'local_cache.dart';

dynamic _deepCast(dynamic value) {
  if (value is Map) {
    return Map<String, dynamic>.fromEntries(
      value.entries.map((e) => MapEntry(e.key.toString(), _deepCast(e.value))),
    );
  }
  if (value is List) {
    return value.map(_deepCast).toList();
  }
  return value;
}

// Unwraps legacy entries that were stored with {__data: {...}, __sync: '...'} wrapper.
Map<String, dynamic> _unwrap(Map<String, dynamic> entry) {
  if (entry.containsKey('__data') && entry['__data'] is Map) {
    return _deepCast(entry['__data']) as Map<String, dynamic>;
  }
  return entry;
}

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
    return _unwrap(_deepCast(raw) as Map<String, dynamic>);
  }

  @override
  Future<List<Map<String, dynamic>>> getAll(String box) async {
    final b = await _box(box);
    return b.values
        .map((raw) => _unwrap(_deepCast(raw) as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<void> put(
    String box,
    String key,
    Map<String, dynamic> data,
  ) async {
    final b = await _box(box);
    await b.put(key, data);
  }

  @override
  Future<void> putAll(
    String box,
    Map<String, Map<String, dynamic>> entries,
  ) async {
    final b = await _box(box);
    await b.putAll(entries);
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
  Future<void> clearAll() async {
    for (final b in _boxes.values) {
      await b.clear();
    }
  }

  @override
  Future<void> dispose() async {
    for (final b in _boxes.values) {
      await b.close();
    }
    _boxes.clear();
  }
}
