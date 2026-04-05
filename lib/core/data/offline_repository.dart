import 'package:keep_track/core/cache/local_cache.dart';
import 'package:keep_track/core/cache/sync_status.dart';
import 'package:keep_track/core/connectivity/connectivity_service.dart';
import 'package:keep_track/core/logging/app_logger.dart';
import 'package:uuid/uuid.dart';

/// Base class that gives repositories offline-first behaviour:
///
///   • Reads  — served from local cache; refreshed from remote when online
///   • Writes — written to cache first (dirty), then pushed immediately if
///              online; the sync manager retries failures later
///
/// Subclasses provide:
///   [box]          — the Hive/memory box name (e.g. "accounts")
///   [fetchRemote]  — full list pull from NestJS
///   [createRemote] — POST to NestJS
///   [updateRemote] — PATCH to NestJS
///   [deleteRemote] — DELETE on NestJS
///   [toJson]       — domain entity → JSON map (NestJS body format)
///   [fromJson]     — JSON map → domain entity
abstract class OfflineRepository<T> {
  final LocalCache cache;
  final ConnectivityService _connectivity = ConnectivityService.instance;
  final _uuid = const Uuid();

  OfflineRepository(this.cache);

  String get box;

  Future<List<Map<String, dynamic>>> fetchRemote();
  Future<Map<String, dynamic>> createRemote(Map<String, dynamic> data);
  Future<Map<String, dynamic>> updateRemote(String id, Map<String, dynamic> data);
  Future<void> deleteRemote(String id);

  Map<String, dynamic> toJson(T entity);
  T fromJson(Map<String, dynamic> json);
  String? getId(T entity);

  // ── Read ──────────────────────────────────────────────────────────────────

  Future<List<T>> getAll() async {
    // Kick off a background refresh if online
    if (await _connectivity.isOnline) _refreshCache();
    final raw = await cache.getAll(box);
    return raw.map(_strip).map(fromJson).toList();
  }

  Future<T?> getById(String id) async {
    final raw = await cache.get(box, id);
    if (raw == null) return null;
    return fromJson(_strip(raw));
  }

  Future<void> _refreshCache() async {
    try {
      final remoteList = await fetchRemote();
      final entries = <String, Map<String, dynamic>>{};
      for (final item in remoteList) {
        final id = item['id'] as String?;
        if (id != null) entries[id] = item;
      }
      await cache.putAll(box, entries, status: SyncStatus.synced);
    } catch (e) {
      AppLogger.warning('[$box] background refresh failed: $e');
    }
  }

  // ── Write ─────────────────────────────────────────────────────────────────

  Future<T> create(T entity) async {
    final json = toJson(entity);
    final localId = _uuid.v4();
    final localJson = {...json, 'id': localId};

    // Save to cache immediately as dirty
    await cache.put(box, localId, localJson, status: SyncStatus.pendingCreate);

    if (await _connectivity.isOnline) {
      try {
        final created = await createRemote(json);
        // Replace local record with server record
        await cache.delete(box, localId);
        await cache.put(box, created['id'] as String, created,
            status: SyncStatus.synced);
        return fromJson(created);
      } catch (e) {
        AppLogger.warning('[$box] create sync failed (will retry): $e');
      }
    }

    return fromJson(localJson);
  }

  Future<T> update(String id, T entity) async {
    final json = {...toJson(entity), 'id': id};
    await cache.put(box, id, json, status: SyncStatus.pendingUpdate);

    if (await _connectivity.isOnline) {
      try {
        final updated = await updateRemote(id, toJson(entity));
        await cache.put(box, id, updated, status: SyncStatus.synced);
        return fromJson(updated);
      } catch (e) {
        AppLogger.warning('[$box] update sync failed (will retry): $e');
      }
    }

    return fromJson(json);
  }

  Future<void> delete(String id) async {
    // Mark as pending delete in cache
    await cache.setStatus(box, id, SyncStatus.pendingDelete);

    if (await _connectivity.isOnline) {
      try {
        await deleteRemote(id);
        await cache.delete(box, id);
      } catch (e) {
        AppLogger.warning('[$box] delete sync failed (will retry): $e');
      }
    }
  }

  // ── Sync helpers (called by SyncManager) ─────────────────────────────────

  Future<void> syncCreate(Map<String, dynamic> record) async {
    final localId = record['id'] as String?;
    final data = _strip(record);
    data.remove('id'); // let server assign real id
    final created = await createRemote(data);
    if (localId != null) await cache.delete(box, localId);
    await cache.put(box, created['id'] as String, created,
        status: SyncStatus.synced);
  }

  Future<void> syncUpdate(Map<String, dynamic> record) async {
    final id = record['id'] as String;
    final created = await updateRemote(id, _strip(record)..remove('id'));
    await cache.put(box, id, created, status: SyncStatus.synced);
  }

  Future<void> syncDelete(Map<String, dynamic> record) async {
    final id = record['id'] as String;
    await deleteRemote(id);
    await cache.delete(box, id);
  }

  // ── Private ───────────────────────────────────────────────────────────────

  Map<String, dynamic> _strip(Map<String, dynamic> raw) {
    final result = Map<String, dynamic>.from(raw);
    result.remove(kSyncKey);
    result.remove(kDataKey);
    return result;
  }
}
