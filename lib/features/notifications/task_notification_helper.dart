import 'package:keep_track/core/di/service_locator.dart';
import 'package:keep_track/core/logging/app_logger.dart';
import 'package:keep_track/core/services/notification/notification_scheduler.dart';
import 'package:keep_track/core/services/notification/platform_notification_helper.dart';
import 'package:keep_track/features/notifications/data/repositories/notification_settings_repository.dart';
import 'package:keep_track/features/tasks/modules/tasks/domain/entities/task.dart';

/// Helper class for managing task-related notifications
/// Safe to use on any platform - no-ops on unsupported platforms
class TaskNotificationHelper {
  TaskNotificationHelper._();

  static final TaskNotificationHelper _instance = TaskNotificationHelper._();
  static TaskNotificationHelper get instance => _instance;

  /// Schedule a notification for a task's due date
  /// Call this when a task is created or updated with a due date
  Future<void> scheduleTaskDueNotification(Task task) async {
    // Skip on unsupported platforms
    if (!PlatformNotificationHelper.instance.isSupportedPlatform) {
      return;
    }

    // Skip if task has no id, no due date, or is already completed
    if (task.id == null || task.dueDate == null || task.isCompleted) {
      return;
    }

    try {
      // Check if task due notifications are enabled
      final settingsRepo = locator.get<NotificationSettingsRepository>();
      final settings = settingsRepo.load();

      if (!settings.taskDueReminderEnabled) {
        AppLogger.info('TaskNotificationHelper: Task due reminders disabled, skipping');
        return;
      }

      // Get the scheduler and schedule the notification
      final scheduler = locator.get<NotificationScheduler>();
      await scheduler.scheduleTaskDueNotification(
        taskId: task.id!,
        title: task.title,
        dueDate: task.dueDate!,
        reminderBefore: settings.taskDueReminderDuration.duration,
      );
    } catch (e) {
      // Silently fail - notification services might not be registered on this platform
      AppLogger.warning('TaskNotificationHelper: Could not schedule notification - $e');
    }
  }

  /// Cancel a task's due notification
  /// Call this when a task is completed or deleted
  Future<void> cancelTaskDueNotification(String taskId) async {
    // Skip on unsupported platforms
    if (!PlatformNotificationHelper.instance.isSupportedPlatform) {
      return;
    }

    try {
      final scheduler = locator.get<NotificationScheduler>();
      await scheduler.cancelTaskDueNotification(taskId);
    } catch (e) {
      // Silently fail
      AppLogger.warning('TaskNotificationHelper: Could not cancel notification - $e');
    }
  }

  /// Update notification for a task (reschedule or cancel based on task state)
  Future<void> updateTaskNotification(Task task) async {
    if (task.id == null) return;

    if (task.isCompleted || task.dueDate == null) {
      // Cancel notification if task is completed or has no due date
      await cancelTaskDueNotification(task.id!);
    } else {
      // Reschedule notification
      await scheduleTaskDueNotification(task);
    }
  }
}
