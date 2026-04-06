import 'sync_status.dart';

/// Abstract local cache — platform implementations below.
///
/// Each "box" is a named collection (e.g. "accounts", "tasks").
/// Each entry is a plain Map<String, dynamic> (model JSON + sync metadata).
abstract class LocalCache {
  // ── Read ──────────────────────────────────────────────────────────────────

  Future<Map<String, dynamic>?> get(String box, String key);

  Future<List<Map<String, dynamic>>> getAll(String box);

  /// All records in [box] that have a non-synced status (dirty)
  Future<List<Map<String, dynamic>>> getDirty(String box);

  // ── Write ─────────────────────────────────────────────────────────────────

  Future<void> put(
    String box,
    String key,
    Map<String, dynamic> data, {
    SyncStatus status = SyncStatus.synced,
  });

  Future<void> putAll(
    String box,
    Map<String, Map<String, dynamic>> entries, {
    SyncStatus status = SyncStatus.synced,
  });

  Future<void> setStatus(String box, String key, SyncStatus status);

  Future<void> delete(String box, String key);

  Future<void> clear(String box);

  Future<void> clearAll();

  // ── Lifecycle ─────────────────────────────────────────────────────────────

  Future<void> init();

  Future<void> dispose();
}

// ── Internal helpers shared by all implementations ────────────────────────────

const String kSyncKey = '__sync';
const String kDataKey = '__data';

Map<String, dynamic> wrapEntry(
  Map<String, dynamic> data,
  SyncStatus status,
) =>
    {kDataKey: data, kSyncKey: status.value};

SyncStatus extractStatus(Map<String, dynamic> raw) =>
    SyncStatusX.fromString(raw[kSyncKey] as String?);

Map<String, dynamic> extractData(Map<String, dynamic> raw) =>
    (raw[kDataKey] as Map?)?.cast<String, dynamic>() ?? {};
