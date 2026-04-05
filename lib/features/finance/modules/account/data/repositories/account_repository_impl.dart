import 'package:keep_track/core/cache/local_cache.dart';
import 'package:keep_track/core/cache/sync_status.dart';
import 'package:keep_track/core/connectivity/connectivity_service.dart';
import 'package:keep_track/core/error/failure.dart';
import 'package:keep_track/core/error/result.dart';
import 'package:keep_track/core/logging/app_logger.dart';
import 'package:keep_track/features/finance/modules/account/data/datasources/account_datasource.dart';
import 'package:keep_track/features/finance/modules/account/domain/entities/account.dart';
import 'package:keep_track/features/finance/modules/account/domain/entities/account_enums.dart';
import 'package:uuid/uuid.dart';

import '../../domain/repositories/account_repository.dart';
import '../models/account_model.dart';

class AccountRepositoryImpl implements AccountRepository {
  final AccountDataSource _remote;
  final LocalCache _cache;
  final ConnectivityService _conn = ConnectivityService.instance;
  final _uuid = const Uuid();

  static const _box = 'accounts';

  AccountRepositoryImpl(this._remote, this._cache);

  // ── Read ──────────────────────────────────────────────────────────────────

  @override
  Future<Result<List<Account>>> getAccounts() async {
    if (await _conn.isOnline) _refreshCache();
    return resultOfAsync(() async {
      final raw = await _cache.getAll(_box);
      return raw.map((j) => AccountModel.fromJson(_strip(j))).toList();
    });
  }

  @override
  Future<Result<Account>> getAccountById(String id) async {
    return resultOfAsync(() async {
      final raw = await _cache.get(_box, id);
      if (raw != null) return AccountModel.fromJson(_strip(raw));
      final model = await _remote.getAccountById(id);
      if (model == null) throw NotFoundFailure(message: 'Account not found: $id');
      await _cache.put(_box, id, model.toJson());
      return model;
    });
  }

  Future<void> _refreshCache() async {
    try {
      final list = await _remote.getAccounts();
      final entries = {for (final m in list) m.id!: m.toJson()};
      await _cache.putAll(_box, entries, status: SyncStatus.synced);
    } catch (e) {
      AppLogger.warning('[accounts] refresh failed: $e');
    }
  }

  // ── Write ─────────────────────────────────────────────────────────────────

  @override
  Future<Result<Account>> createAccount(Account account) async {
    return resultOfAsync(() async {
      final model = AccountModel.fromEntity(account);
      final localId = _uuid.v4();
      final localJson = {...model.toJson(), 'id': localId};
      await _cache.put(_box, localId, localJson, status: SyncStatus.pendingCreate);

      if (await _conn.isOnline) {
        try {
          final created = await _remote.createAccount(model);
          await _cache.delete(_box, localId);
          await _cache.put(_box, created.id!, created.toJson());
          return created;
        } catch (e) {
          AppLogger.warning('[accounts] create sync failed (will retry): $e');
        }
      }
      return AccountModel.fromJson(localJson);
    });
  }

  @override
  Future<Result<Account>> updateAccount(Account account) async {
    return resultOfAsync(() async {
      final model = AccountModel.fromEntity(account);
      final json = {...model.toJson(), 'id': account.id};
      await _cache.put(_box, account.id!, json, status: SyncStatus.pendingUpdate);

      if (await _conn.isOnline) {
        try {
          final updated = await _remote.updateAccount(model);
          await _cache.put(_box, updated.id!, updated.toJson());
          return updated;
        } catch (e) {
          AppLogger.warning('[accounts] update sync failed (will retry): $e');
        }
      }
      return AccountModel.fromJson(json);
    });
  }

  @override
  Future<Result<void>> deleteAccount(String id) async {
    return resultOfAsync(() async {
      await _cache.setStatus(_box, id, SyncStatus.pendingDelete);
      if (await _conn.isOnline) {
        try {
          await _remote.deleteAccount(id);
          await _cache.delete(_box, id);
        } catch (e) {
          AppLogger.warning('[accounts] delete sync failed (will retry): $e');
        }
      }
    });
  }

  // ── Higher-level ops ──────────────────────────────────────────────────────

  @override
  Future<Result<Account>> archiveAccount(String id) async {
    final r = await getAccountById(id);
    if (r.isError) return r;
    return updateAccount(r.data.copyWith(isArchived: true, updatedAt: DateTime.now()));
  }

  @override
  Future<Result<Account>> unarchiveAccount(String id) async {
    final r = await getAccountById(id);
    if (r.isError) return r;
    return updateAccount(r.data.copyWith(isArchived: false, updatedAt: DateTime.now()));
  }

  @override
  Future<Result<Account>> adjustBalance(String id, double amount) async {
    final r = await getAccountById(id);
    if (r.isError) return r;
    return updateAccount(r.data.copyWith(balance: r.data.balance + amount, updatedAt: DateTime.now()));
  }

  @override
  Future<Result<Account>> setBalance(String id, double balance) async {
    final r = await getAccountById(id);
    if (r.isError) return r;
    return updateAccount(r.data.copyWith(balance: balance, updatedAt: DateTime.now()));
  }

  Map<String, dynamic> _strip(Map<String, dynamic> raw) {
    final r = Map<String, dynamic>.from(raw);
    r.remove(kSyncKey);
    r.remove(kDataKey);
    return r;
  }
}
