import 'package:flutter/material.dart';

class NotificationSettings {
  final bool financeReminderEnabled;
  final TimeOfDay financeReminderTime;
  final bool morningReminderEnabled;
  final TimeOfDay morningReminderTime;
  final bool eveningReminderEnabled;
  final TimeOfDay eveningReminderTime;

  const NotificationSettings({
    this.financeReminderEnabled = false,
    this.financeReminderTime = const TimeOfDay(hour: 20, minute: 0),
    this.morningReminderEnabled = false,
    this.morningReminderTime = const TimeOfDay(hour: 8, minute: 0),
    this.eveningReminderEnabled = false,
    this.eveningReminderTime = const TimeOfDay(hour: 18, minute: 0),
  });

  NotificationSettings copyWith({
    bool? financeReminderEnabled,
    TimeOfDay? financeReminderTime,
    bool? morningReminderEnabled,
    TimeOfDay? morningReminderTime,
    bool? eveningReminderEnabled,
    TimeOfDay? eveningReminderTime,
  }) {
    return NotificationSettings(
      financeReminderEnabled: financeReminderEnabled ?? this.financeReminderEnabled,
      financeReminderTime: financeReminderTime ?? this.financeReminderTime,
      morningReminderEnabled: morningReminderEnabled ?? this.morningReminderEnabled,
      morningReminderTime: morningReminderTime ?? this.morningReminderTime,
      eveningReminderEnabled: eveningReminderEnabled ?? this.eveningReminderEnabled,
      eveningReminderTime: eveningReminderTime ?? this.eveningReminderTime,
    );
  }

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
    };
  }

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
          eveningReminderTime == other.eveningReminderTime;

  @override
  int get hashCode => Object.hash(
        financeReminderEnabled,
        financeReminderTime,
        morningReminderEnabled,
        morningReminderTime,
        eveningReminderEnabled,
        eveningReminderTime,
      );
}
