import 'package:flutter/material.dart';

/// User preferences for notifications
class NotificationSettings {
  // Finance reminder settings
  final bool financeReminderEnabled;
  final TimeOfDay financeReminderTime;

  // Morning task reminder settings
  final bool morningReminderEnabled;
  final TimeOfDay morningReminderTime;

  // Evening task reminder settings
  final bool eveningReminderEnabled;
  final TimeOfDay eveningReminderTime;

  // Task due reminder settings
  final bool taskDueReminderEnabled;
  final TaskDueReminderDuration taskDueReminderDuration;

  // Pomodoro session notification settings
  final bool pomodoroNotificationsEnabled;

  const NotificationSettings({
    this.financeReminderEnabled = false,
    this.financeReminderTime = const TimeOfDay(hour: 20, minute: 0), // 8:00 PM
    this.morningReminderEnabled = false,
    this.morningReminderTime = const TimeOfDay(hour: 8, minute: 0), // 8:00 AM
    this.eveningReminderEnabled = false,
    this.eveningReminderTime = const TimeOfDay(hour: 18, minute: 0), // 6:00 PM
    this.taskDueReminderEnabled = false,
    this.taskDueReminderDuration = TaskDueReminderDuration.oneHour,
    this.pomodoroNotificationsEnabled = true, // Enabled by default
  });

  /// Copy with method for immutability
  NotificationSettings copyWith({
    bool? financeReminderEnabled,
    TimeOfDay? financeReminderTime,
    bool? morningReminderEnabled,
    TimeOfDay? morningReminderTime,
    bool? eveningReminderEnabled,
    TimeOfDay? eveningReminderTime,
    bool? taskDueReminderEnabled,
    TaskDueReminderDuration? taskDueReminderDuration,
    bool? pomodoroNotificationsEnabled,
  }) {
    return NotificationSettings(
      financeReminderEnabled: financeReminderEnabled ?? this.financeReminderEnabled,
      financeReminderTime: financeReminderTime ?? this.financeReminderTime,
      morningReminderEnabled: morningReminderEnabled ?? this.morningReminderEnabled,
      morningReminderTime: morningReminderTime ?? this.morningReminderTime,
      eveningReminderEnabled: eveningReminderEnabled ?? this.eveningReminderEnabled,
      eveningReminderTime: eveningReminderTime ?? this.eveningReminderTime,
      taskDueReminderEnabled: taskDueReminderEnabled ?? this.taskDueReminderEnabled,
      taskDueReminderDuration: taskDueReminderDuration ?? this.taskDueReminderDuration,
      pomodoroNotificationsEnabled: pomodoroNotificationsEnabled ?? this.pomodoroNotificationsEnabled,
    );
  }

  /// Convert to JSON for storage
  Map<String, dynamic> toJson() {
    return {
      'financeReminderEnabled': financeReminderEnabled,
      'financeReminderHour': financeReminderTime.hour,
      'financeReminderMinute': financeReminderTime.minute,
      'morningReminderEnabled': morningReminderEnabled,
      'morningReminderHour': morningReminderTime.hour,
      'morningReminderMinute': morningReminderTime.minute,
      'eveningReminderEnabled': eveningReminderEnabled,
      'eveningReminderHour': eveningReminderTime.hour,
      'eveningReminderMinute': eveningReminderTime.minute,
      'taskDueReminderEnabled': taskDueReminderEnabled,
      'taskDueReminderDuration': taskDueReminderDuration.name,
      'pomodoroNotificationsEnabled': pomodoroNotificationsEnabled,
    };
  }

  /// Create from JSON
  factory NotificationSettings.fromJson(Map<String, dynamic> json) {
    return NotificationSettings(
      financeReminderEnabled: json['financeReminderEnabled'] as bool? ?? false,
      financeReminderTime: TimeOfDay(
        hour: json['financeReminderHour'] as int? ?? 20,
        minute: json['financeReminderMinute'] as int? ?? 0,
      ),
      morningReminderEnabled: json['morningReminderEnabled'] as bool? ?? false,
      morningReminderTime: TimeOfDay(
        hour: json['morningReminderHour'] as int? ?? 8,
        minute: json['morningReminderMinute'] as int? ?? 0,
      ),
      eveningReminderEnabled: json['eveningReminderEnabled'] as bool? ?? false,
      eveningReminderTime: TimeOfDay(
        hour: json['eveningReminderHour'] as int? ?? 18,
        minute: json['eveningReminderMinute'] as int? ?? 0,
      ),
      taskDueReminderEnabled: json['taskDueReminderEnabled'] as bool? ?? false,
      taskDueReminderDuration: TaskDueReminderDuration.values.firstWhere(
        (e) => e.name == json['taskDueReminderDuration'],
        orElse: () => TaskDueReminderDuration.oneHour,
      ),
      pomodoroNotificationsEnabled: json['pomodoroNotificationsEnabled'] as bool? ?? true,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is NotificationSettings &&
          runtimeType == other.runtimeType &&
          financeReminderEnabled == other.financeReminderEnabled &&
          financeReminderTime == other.financeReminderTime &&
          morningReminderEnabled == other.morningReminderEnabled &&
          morningReminderTime == other.morningReminderTime &&
          eveningReminderEnabled == other.eveningReminderEnabled &&
          eveningReminderTime == other.eveningReminderTime &&
          taskDueReminderEnabled == other.taskDueReminderEnabled &&
          taskDueReminderDuration == other.taskDueReminderDuration &&
          pomodoroNotificationsEnabled == other.pomodoroNotificationsEnabled;

  @override
  int get hashCode => Object.hash(
        financeReminderEnabled,
        financeReminderTime,
        morningReminderEnabled,
        morningReminderTime,
        eveningReminderEnabled,
        eveningReminderTime,
        taskDueReminderEnabled,
        taskDueReminderDuration,
        pomodoroNotificationsEnabled,
      );
}

/// Duration before task due date to send reminder
enum TaskDueReminderDuration {
  thirtyMinutes,
  oneHour,
  twoHours,
  oneDay;

  String get displayName {
    switch (this) {
      case TaskDueReminderDuration.thirtyMinutes:
        return '30 minutes';
      case TaskDueReminderDuration.oneHour:
        return '1 hour';
      case TaskDueReminderDuration.twoHours:
        return '2 hours';
      case TaskDueReminderDuration.oneDay:
        return '1 day';
    }
  }

  Duration get duration {
    switch (this) {
      case TaskDueReminderDuration.thirtyMinutes:
        return const Duration(minutes: 30);
      case TaskDueReminderDuration.oneHour:
        return const Duration(hours: 1);
      case TaskDueReminderDuration.twoHours:
        return const Duration(hours: 2);
      case TaskDueReminderDuration.oneDay:
        return const Duration(days: 1);
    }
  }
}
