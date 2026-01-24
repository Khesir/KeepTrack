/// Notification ID constants for the app
/// Fixed IDs for recurring notifications, dynamic IDs for task-specific notifications
class NotificationIds {
  NotificationIds._();

  /// Fixed ID for daily finance reminder
  static const int financeReminder = 1;

  /// Fixed ID for morning task reminder
  static const int taskMorning = 2;

  /// Fixed ID for evening task reminder
  static const int taskEvening = 3;

  /// Generate a unique ID for task due notifications
  /// Uses hash of task ID to create consistent IDs for the same task
  static int taskDueNotification(String taskId) {
    // Range: 1000 to 10999 (10000 possible IDs)
    return 1000 + (taskId.hashCode.abs() % 10000);
  }
}
