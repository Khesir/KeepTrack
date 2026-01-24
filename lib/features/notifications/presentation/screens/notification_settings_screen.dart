import 'package:flutter/material.dart';
import 'package:keep_track/core/di/service_locator.dart';
import 'package:keep_track/core/services/notification/platform_notification_helper.dart';
import 'package:keep_track/core/state/stream_state.dart';
import 'package:keep_track/core/theme/gcash_theme.dart';
import 'package:keep_track/features/notifications/domain/entities/notification_settings.dart';
import 'package:keep_track/features/notifications/presentation/state/notification_settings_controller.dart';

/// Screen for managing notification settings
/// Only available on mobile platforms
class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  State<NotificationSettingsScreen> createState() =>
      _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState
    extends State<NotificationSettingsScreen> {
  late final NotificationSettingsController _controller;
  bool _permissionsGranted = false;

  @override
  void initState() {
    super.initState();
    _controller = locator.get<NotificationSettingsController>();
    _checkPermissions();
  }

  Future<void> _checkPermissions() async {
    final granted =
        await PlatformNotificationHelper.instance.areNotificationsEnabled();
    if (mounted) {
      setState(() {
        _permissionsGranted = granted;
      });
    }
  }

  Future<void> _requestPermissions() async {
    final granted =
        await PlatformNotificationHelper.instance.requestPermissions();
    if (mounted) {
      setState(() {
        _permissionsGranted = granted;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notification Settings'),
        backgroundColor: GCashColors.primary,
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<AsyncState<NotificationSettings>>(
        stream: _controller.stream,
        initialData: _controller.state,
        builder: (context, snapshot) {
          final state = snapshot.data;

          if (state is AsyncLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is AsyncError<NotificationSettings>) {
            return Center(
              child: Text('Error loading settings: ${state.error}'),
            );
          }

          final settings = _controller.settings;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Permission status card
                if (!_permissionsGranted) _buildPermissionCard(),
                if (!_permissionsGranted) const SizedBox(height: 16),

                // Finance reminder section
                _buildSectionCard(
                  icon: Icons.account_balance_wallet,
                  title: 'Finance Reminder',
                  subtitle: 'Daily reminder to track your transactions',
                  enabled: settings.financeReminderEnabled,
                  time: settings.financeReminderTime,
                  onToggle: (value) {
                    _controller.updateFinanceReminder(enabled: value);
                  },
                  onTimeChange: (time) {
                    _controller.updateFinanceReminder(time: time);
                  },
                ),
                const SizedBox(height: 16),

                // Morning task reminder section
                _buildSectionCard(
                  icon: Icons.wb_sunny,
                  title: 'Morning Task Reminder',
                  subtitle: 'Start your day with your task list',
                  enabled: settings.morningReminderEnabled,
                  time: settings.morningReminderTime,
                  onToggle: (value) {
                    _controller.updateMorningReminder(enabled: value);
                  },
                  onTimeChange: (time) {
                    _controller.updateMorningReminder(time: time);
                  },
                ),
                const SizedBox(height: 16),

                // Evening task reminder section
                _buildSectionCard(
                  icon: Icons.nightlight_round,
                  title: 'Evening Task Reminder',
                  subtitle: 'Review your progress at the end of the day',
                  enabled: settings.eveningReminderEnabled,
                  time: settings.eveningReminderTime,
                  onToggle: (value) {
                    _controller.updateEveningReminder(enabled: value);
                  },
                  onTimeChange: (time) {
                    _controller.updateEveningReminder(time: time);
                  },
                ),
                const SizedBox(height: 16),

                // Task due reminder section
                _buildTaskDueCard(
                  enabled: settings.taskDueReminderEnabled,
                  duration: settings.taskDueReminderDuration,
                  onToggle: (value) {
                    _controller.updateTaskDueReminder(enabled: value);
                  },
                  onDurationChange: (duration) {
                    _controller.updateTaskDueReminder(duration: duration);
                  },
                ),
                const SizedBox(height: 16),

                // Pomodoro notifications section
                _buildPomodoroCard(
                  enabled: settings.pomodoroNotificationsEnabled,
                  onToggle: (value) {
                    _controller.updatePomodoroNotifications(enabled: value);
                  },
                ),
                const SizedBox(height: 24),

                // Reset button
                Center(
                  child: TextButton.icon(
                    onPressed: () => _showResetConfirmation(context),
                    icon: const Icon(Icons.restore),
                    label: const Text('Reset to Defaults'),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildPermissionCard() {
    return Card(
      color: Colors.orange.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.warning_amber_rounded, color: Colors.orange.shade700),
                const SizedBox(width: 8),
                Text(
                  'Notifications Disabled',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.orange.shade900,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Enable notifications to receive reminders for your tasks and finances.',
              style: TextStyle(color: Colors.orange.shade900),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                ElevatedButton(
                  onPressed: _requestPermissions,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Enable Notifications'),
                ),
                const SizedBox(width: 8),
                TextButton(
                  onPressed: () {
                    PlatformNotificationHelper.instance.openNotificationSettings();
                  },
                  child: const Text('Open Settings'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool enabled,
    required TimeOfDay time,
    required ValueChanged<bool> onToggle,
    required ValueChanged<TimeOfDay> onTimeChange,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: GCashColors.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                Switch(
                  value: enabled,
                  onChanged: _permissionsGranted ? onToggle : null,
                  activeTrackColor: GCashColors.primary.withValues(alpha: 0.5),
                  activeThumbColor: GCashColors.primary,
                ),
              ],
            ),
            if (enabled) ...[
              const Divider(height: 24),
              InkWell(
                onTap: _permissionsGranted
                    ? () => _showTimePicker(context, time, onTimeChange)
                    : null,
                child: Row(
                  children: [
                    Icon(
                      Icons.access_time,
                      size: 20,
                      color: Colors.grey.shade600,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Reminder time: ${_formatTime(time)}',
                      style: const TextStyle(fontSize: 14),
                    ),
                    const Spacer(),
                    Icon(
                      Icons.chevron_right,
                      color: Colors.grey.shade400,
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTaskDueCard({
    required bool enabled,
    required TaskDueReminderDuration duration,
    required ValueChanged<bool> onToggle,
    required ValueChanged<TaskDueReminderDuration> onDurationChange,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.alarm, color: GCashColors.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Task Due Reminders',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Get notified before tasks are due',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                Switch(
                  value: enabled,
                  onChanged: _permissionsGranted ? onToggle : null,
                  activeTrackColor: GCashColors.primary.withValues(alpha: 0.5),
                  activeThumbColor: GCashColors.primary,
                ),
              ],
            ),
            if (enabled) ...[
              const Divider(height: 24),
              const Text(
                'Remind me before:',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: TaskDueReminderDuration.values.map((d) {
                  final isSelected = d == duration;
                  return ChoiceChip(
                    label: Text(d.displayName),
                    selected: isSelected,
                    onSelected: _permissionsGranted
                        ? (selected) {
                            if (selected) onDurationChange(d);
                          }
                        : null,
                    selectedColor: GCashColors.primary.withValues(alpha: 0.2),
                    labelStyle: TextStyle(
                      color: isSelected ? GCashColors.primary : null,
                      fontWeight: isSelected ? FontWeight.bold : null,
                    ),
                  );
                }).toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPomodoroCard({
    required bool enabled,
    required ValueChanged<bool> onToggle,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(Icons.timer, color: GCashColors.primary),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Pomodoro Session Alerts',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'Get notified when pomodoro, short break, or long break ends',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
            Switch(
              value: enabled,
              onChanged: _permissionsGranted ? onToggle : null,
              activeTrackColor: GCashColors.primary.withValues(alpha: 0.5),
              activeThumbColor: GCashColors.primary,
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(TimeOfDay time) {
    final hour = time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod;
    final minute = time.minute.toString().padLeft(2, '0');
    final period = time.period == DayPeriod.am ? 'AM' : 'PM';
    return '$hour:$minute $period';
  }

  Future<void> _showTimePicker(
    BuildContext context,
    TimeOfDay initialTime,
    ValueChanged<TimeOfDay> onTimeChange,
  ) async {
    final time = await showTimePicker(
      context: context,
      initialTime: initialTime,
    );
    if (time != null) {
      onTimeChange(time);
    }
  }

  void _showResetConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset to Defaults?'),
        content: const Text(
          'This will reset all notification settings to their default values.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _controller.resetToDefaults();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Reset'),
          ),
        ],
      ),
    );
  }
}
