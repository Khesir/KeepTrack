import 'package:keep_track/core/di/service_locator.dart';
import 'package:keep_track/core/logging/app_logger.dart';
import 'package:keep_track/core/services/notification/notification_service.dart';
import 'package:keep_track/core/services/notification/platform_notification_helper.dart';
import 'package:keep_track/features/notifications/data/repositories/notification_settings_repository.dart';
import 'package:keep_track/features/tasks/modules/pomodoro/domain/entities/pomodoro_session.dart';

/// Helper class for managing pomodoro session notifications
/// Safe to use on any platform - no-ops on unsupported platforms
class PomodoroNotificationHelper {
  PomodoroNotificationHelper._();

  static final PomodoroNotificationHelper _instance = PomodoroNotificationHelper._();
  static PomodoroNotificationHelper get instance => _instance;

  /// Notification ID for pomodoro session completion
  static const int _pomodoroNotificationId = 50000;

  /// Show notification when a pomodoro session completes
  Future<void> showSessionCompleteNotification(PomodoroSession session) async {
    // Skip on unsupported platforms
    if (!PlatformNotificationHelper.instance.isSupportedPlatform) {
      return;
    }

    // Skip for stopwatch sessions (no auto-complete notification needed)
    if (session.isStopwatch) {
      return;
    }

    try {
      // Check if pomodoro notifications are enabled
      final settingsRepo = locator.get<NotificationSettingsRepository>();
      final settings = settingsRepo.load();

      if (!settings.pomodoroNotificationsEnabled) {
        AppLogger.info('PomodoroNotificationHelper: Pomodoro notifications disabled, skipping');
        return;
      }

      // Get notification details based on session type
      final (title, body) = _getNotificationContent(session.type);

      // Show the notification
      final notificationService = NotificationService.instance;
      if (!notificationService.isInitialized) {
        AppLogger.warning('PomodoroNotificationHelper: Notification service not initialized');
        return;
      }

      await notificationService.showNotification(
        id: _pomodoroNotificationId + session.type.index,
        title: title,
        body: body,
        channelId: 'task_reminders',
        payload: 'pomodoro_complete:${session.type.name}',
      );

      AppLogger.info('PomodoroNotificationHelper: Notification shown for ${session.type.displayName}');
    } catch (e) {
      // Silently fail - notification services might not be registered on this platform
      AppLogger.warning('PomodoroNotificationHelper: Could not show notification - $e');
    }
  }

  /// Get notification content based on session type
  (String title, String body) _getNotificationContent(PomodoroSessionType type) {
    switch (type) {
      case PomodoroSessionType.pomodoro:
        return ('Pomodoro Complete!', 'Great work! Time for a break.');
      case PomodoroSessionType.shortBreak:
        return ('Short Break Over', 'Ready to get back to work?');
      case PomodoroSessionType.longBreak:
        return ('Long Break Over', 'Feeling refreshed? Let\'s continue!');
      case PomodoroSessionType.stopwatch:
        return ('Session Complete', 'Your session has ended.');
    }
  }
}
