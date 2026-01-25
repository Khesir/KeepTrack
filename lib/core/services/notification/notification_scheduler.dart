import 'package:flutter/material.dart';
import 'package:keep_track/core/logging/app_logger.dart';
import 'package:keep_track/core/services/notification/notification_ids.dart';
import 'package:keep_track/core/services/notification/notification_service.dart';

/// Scheduler for managing different notification types
/// Provides high-level scheduling methods for finance and task reminders
class NotificationScheduler {
  final NotificationService _service;

  NotificationScheduler(this._service);

  /// Check if scheduler can schedule notifications
  bool get canSchedule => _service.isInitialized;

  // ============================================
  // Finance Reminders
  // ============================================

  /// Schedule daily finance tracking reminder
  Future<void> scheduleDailyFinanceReminder({
    required TimeOfDay time,
  }) async {
    if (!canSchedule) {
      AppLogger.warning('NotificationScheduler: Cannot schedule - service not initialized');
      return;
    }

    // Cancel existing finance reminder
    await _service.cancelNotification(NotificationIds.financeReminder);

    // Schedule new reminder
    await _service.scheduleDailyNotification(
      id: NotificationIds.financeReminder,
      title: 'Track Your Finances',
      body: 'Take a moment to record today\'s transactions',
      hour: time.hour,
      minute: time.minute,
      channelId: 'finance_reminders',
      payload: 'finance_reminder',
    );

    AppLogger.info('NotificationScheduler: Finance reminder scheduled for ${time.hour}:${time.minute}');
  }

  /// Cancel finance reminder
  Future<void> cancelFinanceReminder() async {
    await _service.cancelNotification(NotificationIds.financeReminder);
  }

  // ============================================
  // Task Reminders
  // ============================================

  /// Schedule morning task reminder
  Future<void> scheduleMorningTaskReminder({
    required TimeOfDay time,
  }) async {
    if (!canSchedule) {
      AppLogger.warning('NotificationScheduler: Cannot schedule - service not initialized');
      return;
    }

    // Cancel existing morning reminder
    await _service.cancelNotification(NotificationIds.taskMorning);

    // Schedule new reminder
    await _service.scheduleDailyNotification(
      id: NotificationIds.taskMorning,
      title: 'Good Morning!',
      body: 'Check your tasks for today',
      hour: time.hour,
      minute: time.minute,
      channelId: 'task_reminders',
      payload: 'task_morning',
    );

    AppLogger.info('NotificationScheduler: Morning reminder scheduled for ${time.hour}:${time.minute}');
  }

  /// Schedule evening task reminder
  Future<void> scheduleEveningTaskReminder({
    required TimeOfDay time,
  }) async {
    if (!canSchedule) {
      AppLogger.warning('NotificationScheduler: Cannot schedule - service not initialized');
      return;
    }

    // Cancel existing evening reminder
    await _service.cancelNotification(NotificationIds.taskEvening);

    // Schedule new reminder
    await _service.scheduleDailyNotification(
      id: NotificationIds.taskEvening,
      title: 'Evening Check-in',
      body: 'Review your progress and plan for tomorrow',
      hour: time.hour,
      minute: time.minute,
      channelId: 'task_reminders',
      payload: 'task_evening',
    );

    AppLogger.info('NotificationScheduler: Evening reminder scheduled for ${time.hour}:${time.minute}');
  }

  /// Cancel morning task reminder
  Future<void> cancelMorningTaskReminder() async {
    await _service.cancelNotification(NotificationIds.taskMorning);
  }

  /// Cancel evening task reminder
  Future<void> cancelEveningTaskReminder() async {
    await _service.cancelNotification(NotificationIds.taskEvening);
  }

  // ============================================
  // Task Due Notifications
  // ============================================

  /// Schedule a task due notification
  /// [taskId] - Unique task identifier
  /// [title] - Task title for the notification
  /// [dueDate] - When the task is due
  /// [reminderBefore] - How long before the due date to send the notification
  Future<void> scheduleTaskDueNotification({
    required String taskId,
    required String title,
    required DateTime dueDate,
    required Duration reminderBefore,
  }) async {
    if (!canSchedule) {
      AppLogger.warning('NotificationScheduler: Cannot schedule - service not initialized');
      return;
    }

    final notificationId = NotificationIds.taskDueNotification(taskId);
    final scheduledTime = dueDate.subtract(reminderBefore);

    // Don't schedule if the reminder time is in the past
    if (scheduledTime.isBefore(DateTime.now())) {
      AppLogger.info('NotificationScheduler: Skipping past task reminder for "$title"');
      return;
    }

    // Cancel existing notification for this task
    await _service.cancelNotification(notificationId);

    // Schedule the notification
    await _service.scheduleNotification(
      id: notificationId,
      title: 'Task Due Soon',
      body: title,
      scheduledTime: scheduledTime,
      channelId: 'task_reminders',
      payload: 'task_due:$taskId',
    );

    AppLogger.info('NotificationScheduler: Task due notification scheduled for "$title" at $scheduledTime');
  }

  /// Cancel a task due notification
  Future<void> cancelTaskDueNotification(String taskId) async {
    final notificationId = NotificationIds.taskDueNotification(taskId);
    await _service.cancelNotification(notificationId);
    AppLogger.info('NotificationScheduler: Task due notification cancelled for task $taskId');
  }

  // ============================================
  // Payment Due Notifications
  // ============================================

  /// Schedule payment due notifications (3 days, 2 days, 1 day before)
  /// [paymentId] - Unique payment identifier
  /// [name] - Payment name for the notification
  /// [amount] - Payment amount to display
  /// [dueDate] - When the payment is due
  /// [notifyDaysBefore] - List of days before to notify (default: [3, 2, 1])
  /// [notifyHour] - Hour to send notification (default: 9 AM)
  Future<void> schedulePaymentDueNotifications({
    required String paymentId,
    required String name,
    required double amount,
    required DateTime dueDate,
    List<int> notifyDaysBefore = const [3, 2, 1],
    int notifyHour = 9,
  }) async {
    if (!canSchedule) {
      AppLogger.warning('NotificationScheduler: Cannot schedule - service not initialized');
      return;
    }

    for (final daysBefore in notifyDaysBefore) {
      final notificationId = NotificationIds.plannedPaymentDueNotification(paymentId, daysBefore);
      final scheduledDate = DateTime(
        dueDate.year,
        dueDate.month,
        dueDate.day - daysBefore,
        notifyHour,
        0,
      );

      // Skip if the scheduled time is in the past
      if (scheduledDate.isBefore(DateTime.now())) {
        continue;
      }

      final daysText = daysBefore == 1 ? 'tomorrow' : 'in $daysBefore days';

      await _service.scheduleNotification(
        id: notificationId,
        title: 'Payment Due $daysText',
        body: '$name - \$${amount.toStringAsFixed(2)}',
        scheduledTime: scheduledDate,
        channelId: 'payment_reminders',
        payload: 'payment_due:$paymentId',
      );
    }

    AppLogger.info('NotificationScheduler: Payment notifications scheduled for "$name"');
  }

  /// Cancel all payment due notifications for a specific payment
  Future<void> cancelPaymentDueNotifications(String paymentId) async {
    for (final daysBefore in [1, 2, 3]) {
      final notificationId = NotificationIds.plannedPaymentDueNotification(paymentId, daysBefore);
      await _service.cancelNotification(notificationId);
    }
    AppLogger.info('NotificationScheduler: Payment notifications cancelled for $paymentId');
  }

  // ============================================
  // Debt Due Notifications
  // ============================================

  /// Schedule debt due notifications (3 days, 2 days, 1 day before)
  /// [debtId] - Unique debt identifier
  /// [personName] - Person name for the notification
  /// [amount] - Remaining debt amount to display
  /// [dueDate] - When the debt is due
  /// [notifyDaysBefore] - List of days before to notify (default: [3, 2, 1])
  /// [notifyHour] - Hour to send notification (default: 9 AM)
  Future<void> scheduleDebtDueNotifications({
    required String debtId,
    required String personName,
    required double amount,
    required DateTime dueDate,
    List<int> notifyDaysBefore = const [3, 2, 1],
    int notifyHour = 9,
  }) async {
    if (!canSchedule) {
      AppLogger.warning('NotificationScheduler: Cannot schedule - service not initialized');
      return;
    }

    for (final daysBefore in notifyDaysBefore) {
      final notificationId = NotificationIds.debtDueNotification(debtId, daysBefore);
      final scheduledDate = DateTime(
        dueDate.year,
        dueDate.month,
        dueDate.day - daysBefore,
        notifyHour,
        0,
      );

      // Skip if the scheduled time is in the past
      if (scheduledDate.isBefore(DateTime.now())) {
        continue;
      }

      final daysText = daysBefore == 1 ? 'tomorrow' : 'in $daysBefore days';

      await _service.scheduleNotification(
        id: notificationId,
        title: 'Debt Due $daysText',
        body: '$personName - \$${amount.toStringAsFixed(2)} remaining',
        scheduledTime: scheduledDate,
        channelId: 'payment_reminders',
        payload: 'debt_due:$debtId',
      );
    }

    AppLogger.info('NotificationScheduler: Debt notifications scheduled for "$personName"');
  }

  /// Cancel all debt due notifications for a specific debt
  Future<void> cancelDebtDueNotifications(String debtId) async {
    for (final daysBefore in [1, 2, 3]) {
      final notificationId = NotificationIds.debtDueNotification(debtId, daysBefore);
      await _service.cancelNotification(notificationId);
    }
    AppLogger.info('NotificationScheduler: Debt notifications cancelled for $debtId');
  }

  // ============================================
  // Utility Methods
  // ============================================

  /// Cancel all scheduled notifications
  Future<void> cancelAllNotifications() async {
    await _service.cancelAllNotifications();
  }

  /// Reschedule all daily reminders based on settings
  Future<void> rescheduleAllDailyReminders({
    bool financeEnabled = false,
    TimeOfDay? financeTime,
    bool morningEnabled = false,
    TimeOfDay? morningTime,
    bool eveningEnabled = false,
    TimeOfDay? eveningTime,
  }) async {
    // Cancel all daily reminders first
    await cancelFinanceReminder();
    await cancelMorningTaskReminder();
    await cancelEveningTaskReminder();

    // Reschedule if enabled
    if (financeEnabled && financeTime != null) {
      await scheduleDailyFinanceReminder(time: financeTime);
    }

    if (morningEnabled && morningTime != null) {
      await scheduleMorningTaskReminder(time: morningTime);
    }

    if (eveningEnabled && eveningTime != null) {
      await scheduleEveningTaskReminder(time: eveningTime);
    }

    AppLogger.info('NotificationScheduler: All daily reminders rescheduled');
  }
}
