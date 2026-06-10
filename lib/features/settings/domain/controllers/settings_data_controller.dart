import 'package:keep_track/core/cache/local_cache.dart';
import 'package:keep_track/core/state/stream_state.dart';
import 'package:keep_track/features/finance/data/services/finance_initialization_service.dart';
import '../../data/datasources/backup_sync_status.dart';
import '../../data/repositories/backup_service.dart';

const _wipeBoxes = [
  'transactions',
  'budgets',
  'budget_categories',
  'month_plans',
  'goals',
  'debts',
  'planned_payments',
  'wallets',
  'subscriptions',
  'transaction_plans',
  'finance_categories',
  'budget_profiles',
];

class SettingsDataController extends StreamState<AsyncState<DateTime?>> {
  final BackupService _backupService;
  final LocalCache _cache;
  final FinanceInitializationService _financeInit;

  SettingsDataController({
    required BackupService backupService,
    required LocalCache cache,
    required FinanceInitializationService financeInit,
  })  : _backupService = backupService,
        _cache = cache,
        _financeInit = financeInit,
        super(const AsyncData(null));

  Future<void> loadLastSyncedAt() => executeSilent(() async {
        final ts = await _backupService.fetchLastSyncedAt();
        if (ts != null) await BackupSyncStatus.instance.update(ts);
        return ts;
      });

  Future<String?> exportToFile(String password) =>
      _backupService.exportToFile(password);

  Future<void> syncToCloud(String password) async {
    await _backupService.syncToCloud(password);
    final now = DateTime.now();
    await BackupSyncStatus.instance.update(now);
    emit(AsyncData(now));
  }

  Future<bool> importFromFile(String password) async {
    final bytes = await _backupService.pickBackupFile();
    if (bytes == null) return false;
    await _backupService.restoreFromBytes(bytes, password);
    return true;
  }

  Future<void> restoreFromCloud(String password) =>
      _backupService.restoreFromCloud(password);

  Future<void> wipeAllData() async {
    for (final box in _wipeBoxes) {
      await _cache.clear(box);
    }
    await _financeInit.initializeDefaultCategories();
  }

  static String backupErrorMessage(Object e) => switch (e) {
        WrongPasswordException() =>
          'Wrong password – backup could not be decrypted.',
        InvalidBackupException() =>
          'Invalid backup file. Select a valid .ktbak file.',
        _ => 'Something went wrong: $e',
      };
}
