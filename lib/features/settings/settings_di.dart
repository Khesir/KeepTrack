import 'package:keep_track/core/cache/local_cache.dart';
import 'package:keep_track/core/di/service_locator.dart';
import 'package:keep_track/features/finance/data/services/finance_initialization_service.dart';
import 'data/repositories/backup_service.dart';
import 'domain/controllers/settings_data_controller.dart';

void setupSettingsDependencies() {
  locator.registerLazySingleton<BackupRemoteDatasource>(
    () => BackupRemoteDatasource(),
  );

  locator.registerLazySingleton<BackupEncryptionService>(
    () => BackupEncryptionService(),
  );

  locator.registerLazySingleton<BackupService>(
    () => BackupService(
      cache: locator.get<LocalCache>(),
      encryption: locator.get<BackupEncryptionService>(),
      remote: locator.get<BackupRemoteDatasource>(),
    ),
  );

  locator.registerLazySingleton<SettingsDataController>(
    () => SettingsDataController(
      backupService: locator.get<BackupService>(),
      cache: locator.get<LocalCache>(),
      financeInit: locator.get<FinanceInitializationService>(),
    ),
  );
}
