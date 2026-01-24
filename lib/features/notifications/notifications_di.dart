import 'package:shared_preferences/shared_preferences.dart';
import 'package:keep_track/core/di/service_locator.dart';
import 'package:keep_track/core/services/notification/notification_scheduler.dart';
import 'package:keep_track/core/services/notification/notification_service.dart';
import 'package:keep_track/core/services/notification/platform_notification_helper.dart';
import 'package:keep_track/features/notifications/data/repositories/notification_settings_repository.dart';
import 'package:keep_track/features/notifications/finance_notification_helper.dart';
import 'package:keep_track/features/notifications/presentation/state/notification_settings_controller.dart';

/// Setup notification dependencies
/// Only registers on supported platforms (mobile)
void setupNotificationDependencies() {
  final helper = PlatformNotificationHelper.instance;

  // Only register notification services on supported platforms
  if (!helper.isSupportedPlatform) {
    return;
  }

  // Register notification service (singleton instance)
  locator.registerLazySingleton<NotificationService>(() {
    return NotificationService.instance;
  });

  // Register notification scheduler
  locator.registerLazySingleton<NotificationScheduler>(() {
    return NotificationScheduler(locator.get<NotificationService>());
  });

  // Register notification settings repository
  locator.registerLazySingleton<NotificationSettingsRepository>(() {
    return NotificationSettingsRepository(locator.get<SharedPreferences>());
  });

  // Register notification settings controller
  locator.registerLazySingleton<NotificationSettingsController>(() {
    return NotificationSettingsController(
      locator.get<NotificationSettingsRepository>(),
      locator.get<NotificationScheduler>(),
    );
  });

  // Register finance notification helper
  // Note: This depends on finance controllers which are registered separately
  locator.registerLazySingleton<FinanceNotificationHelper>(() {
    return FinanceNotificationHelper();
  });
}

/// Initialize notification services after DI setup
/// Call this in main.dart after _setupDependencies
Future<void> initializeNotifications() async {
  final helper = PlatformNotificationHelper.instance;

  // Skip on unsupported platforms
  if (!helper.isSupportedPlatform) {
    return;
  }

  // Initialize notification service
  final service = locator.get<NotificationService>();
  await service.initialize();

  // Request permissions
  await helper.requestPermissions();

  // Load and apply saved notification settings
  final controller = locator.get<NotificationSettingsController>();
  await controller.loadAndApplySettings();
}
