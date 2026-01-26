import 'package:flutter/material.dart';
import 'package:keep_track/core/logging/app_logger.dart';
import 'package:keep_track/core/services/notification/notification_scheduler.dart';
import 'package:keep_track/core/state/stream_state.dart';
import 'package:keep_track/features/notifications/data/repositories/notification_settings_repository.dart';
import 'package:keep_track/features/notifications/domain/entities/notification_settings.dart';

/// Controller for managing notification settings state
class NotificationSettingsController
    extends StreamState<AsyncState<NotificationSettings>> {
  final NotificationSettingsRepository _repository;
  final NotificationScheduler _scheduler;

  NotificationSettingsController(this._repository, this._scheduler)
      : super(const AsyncLoading());

  /// Get current settings or defaults
  NotificationSettings get settings {
    final currentState = state;
    if (currentState is AsyncData<NotificationSettings>) {
      return currentState.data;
    }
    return const NotificationSettings();
  }

  /// Load settings from storage and apply to scheduler
  Future<void> loadAndApplySettings() async {
    await execute(() async {
      final settings = _repository.load();
      await _applySettings(settings);
      return settings;
    });
  }

  /// Load settings from storage without applying
  Future<void> loadSettings() async {
    await execute(() async {
      return _repository.load();
    });
  }

  /// Update finance reminder settings
  Future<void> updateFinanceReminder({
    bool? enabled,
    TimeOfDay? time,
  }) async {
    final newSettings = settings.copyWith(
      financeReminderEnabled: enabled,
      financeReminderTime: time,
    );
    await _saveAndApply(newSettings);
  }

  /// Update morning task reminder settings
  Future<void> updateMorningReminder({
    bool? enabled,
    TimeOfDay? time,
  }) async {
    final newSettings = settings.copyWith(
      morningReminderEnabled: enabled,
      morningReminderTime: time,
    );
    await _saveAndApply(newSettings);
  }

  /// Update evening task reminder settings
  Future<void> updateEveningReminder({
    bool? enabled,
    TimeOfDay? time,
  }) async {
    final newSettings = settings.copyWith(
      eveningReminderEnabled: enabled,
      eveningReminderTime: time,
    );
    await _saveAndApply(newSettings);
  }

  /// Update task due reminder settings
  Future<void> updateTaskDueReminder({
    bool? enabled,
    TaskDueReminderDuration? duration,
  }) async {
    final newSettings = settings.copyWith(
      taskDueReminderEnabled: enabled,
      taskDueReminderDuration: duration,
    );
    await _saveAndApply(newSettings);
  }

  /// Update pomodoro notifications settings
  Future<void> updatePomodoroNotifications({bool? enabled}) async {
    final newSettings = settings.copyWith(
      pomodoroNotificationsEnabled: enabled,
    );
    await _saveAndApply(newSettings);
  }

  /// Save and apply new settings
  Future<void> _saveAndApply(NotificationSettings newSettings) async {
    await execute(() async {
      await _repository.save(newSettings);
      await _applySettings(newSettings);
      return newSettings;
    });
  }

  /// Apply settings to scheduler
  Future<void> _applySettings(NotificationSettings settings) async {
    try {
      await _scheduler.rescheduleAllDailyReminders(
        financeEnabled: settings.financeReminderEnabled,
        financeTime: settings.financeReminderTime,
        morningEnabled: settings.morningReminderEnabled,
        morningTime: settings.morningReminderTime,
        eveningEnabled: settings.eveningReminderEnabled,
        eveningTime: settings.eveningReminderTime,
      );
      AppLogger.info('NotificationSettingsController: Settings applied');
    } catch (e, stackTrace) {
      // Log but don't fail - settings can still be saved even if scheduling fails
      AppLogger.error(
        'NotificationSettingsController: Failed to apply notification schedules',
        e,
        stackTrace,
      );
    }
  }

  /// Reset all settings to defaults
  Future<void> resetToDefaults() async {
    await execute(() async {
      await _repository.clear();
      const defaults = NotificationSettings();
      await _applySettings(defaults);
      return defaults;
    });
  }
}
