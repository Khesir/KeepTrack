/// Abstract local cache — platform implementations below.
///
/// Each "box" is a named collection (e.g. "accounts", "tasks").
/// Each entry is a plain Map<String, dynamic> (model JSON).
abstract class LocalCache {
  // ── Read ──────────────────────────────────────────────────────────────────

  Future<Map<String, dynamic>?> get(String box, String key);

  Future<List<Map<String, dynamic>>> getAll(String box);

  // ── Write ─────────────────────────────────────────────────────────────────

  Future<void> put(
    String box,
    String key,
    Map<String, dynamic> data,
  );

  Future<void> putAll(
    String box,
    Map<String, Map<String, dynamic>> entries,
  );

  Future<void> delete(String box, String key);

  Future<void> clear(String box);

  Future<void> clearAll();

  // ── Lifecycle ─────────────────────────────────────────────────────────────

  Future<void> init();

  Future<void> dispose();
}
