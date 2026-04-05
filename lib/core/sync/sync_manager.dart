import 'dart:async';
import 'package:keep_track/core/cache/local_cache.dart';
import 'package:keep_track/core/cache/sync_status.dart';
import 'package:keep_track/core/connectivity/connectivity_service.dart';
import 'package:keep_track/core/logging/app_logger.dart';

typedef SyncHandler = Future<void> Function(Map<String, dynamic> record);

/// Orchestrates dirty-record flushing across all registered boxes.
/// Repositories call [register] to provide per-box sync handlers.
/// On connectivity regained (or manual [flush]), all dirty records are pushed.
class SyncManager {
  SyncManager(this._cache);

  final LocalCache _cache;
  final _connectivity = ConnectivityService.instance;
  StreamSubscription<bool>? _sub;

  // box → {syncStatus → handler}
  final Map<String, Map<SyncStatus, SyncHandler>> _handlers = {};

  void start() {
    _sub = _connectivity.onConnectivityChanged.listen((online) {
      if (online) flush();
    });
  }

  void stop() => _sub?.cancel();

  void register(
    String box, {
    SyncHandler? onCreate,
    SyncHandler? onUpdate,
    SyncHandler? onDelete,
  }) {
    _handlers[box] = {
      if (onCreate != null) SyncStatus.pendingCreate: onCreate,
      if (onUpdate != null) SyncStatus.pendingUpdate: onUpdate,
      if (onDelete != null) SyncStatus.pendingDelete: onDelete,
    };
  }

  Future<void> flush() async {
    for (final entry in _handlers.entries) {
      final box = entry.key;
      final handlers = entry.value;
      try {
        final dirty = await _cache.getDirty(box);
        for (final record in dirty) {
          final status =
              SyncStatusX.fromString(record[kSyncKey] as String?);
          final handler = handlers[status];
          if (handler == null) continue;
          try {
            await handler(record);
          } catch (e) {
            AppLogger.warning('Sync failed [$box]: $e');
          }
        }
      } catch (e) {
        AppLogger.warning('Sync flush error [$box]: $e');
      }
    }
  }
}
