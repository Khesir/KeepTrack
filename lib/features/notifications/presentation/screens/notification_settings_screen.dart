import 'package:flutter/material.dart';
import 'package:keep_track/core/di/service_locator.dart';
import 'package:keep_track/core/services/notification/notification_service.dart';
import 'package:keep_track/core/services/notification/platform_notification_helper.dart';
import 'package:keep_track/core/state/stream_state.dart';
import 'package:keep_track/core/theme/app_theme.dart';
import 'package:keep_track/core/theme/gcash_theme.dart';
import 'package:keep_track/features/notifications/domain/entities/notification_settings.dart';
import 'package:keep_track/features/notifications/presentation/state/notification_settings_controller.dart';

class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  State<NotificationSettingsScreen> createState() =>
      _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState
    extends State<NotificationSettingsScreen> with WidgetsBindingObserver {
  late final NotificationSettingsController _controller;
  bool _permissionsGranted = false;

  @override
  void initState() {
    super.initState();
    _controller = locator.get<NotificationSettingsController>();
    WidgetsBinding.instance.addObserver(this);
    _checkPermissions();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkPermissions();
    }
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
        foregroundColor: AppColors.textPrimaryDark,
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
                _buildPermissionCard(),
                const SizedBox(height: 16),
                _buildSectionCard(
                  icon: Icons.account_balance_wallet,
                  title: 'Finance Reminder',
                  subtitle: 'Daily reminder to track your transactions',
                  enabled: settings.financeReminderEnabled,
                  time: settings.financeReminderTime,
                  onToggle: (value) =>
                      _controller.updateFinanceReminder(enabled: value),
                  onTimeChange: (time) =>
                      _controller.updateFinanceReminder(time: time),
                ),
                const SizedBox(height: 16),
                _buildSectionCard(
                  icon: Icons.wb_sunny,
                  title: 'Morning Reminder',
                  subtitle: 'Start your day with a finance check-in',
                  enabled: settings.morningReminderEnabled,
                  time: settings.morningReminderTime,
                  onToggle: (value) =>
                      _controller.updateMorningReminder(enabled: value),
                  onTimeChange: (time) =>
                      _controller.updateMorningReminder(time: time),
                ),
                const SizedBox(height: 16),
                _buildSectionCard(
                  icon: Icons.nightlight_round,
                  title: 'Evening Task Reminder',
                  subtitle: 'Review your progress at the end of the day',
                  enabled: settings.eveningReminderEnabled,
                  time: settings.eveningReminderTime,
                  onToggle: (value) =>
                      _controller.updateEveningReminder(enabled: value),
                  onTimeChange: (time) =>
                      _controller.updateEveningReminder(time: time),
                ),
                const SizedBox(height: 24),
                Padding(
                  padding: const EdgeInsets.only(left: 4, bottom: 8),
                  child: Text(
                    'Feature Flags',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade500,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                _buildTestNotificationCard(),
                const SizedBox(height: 16),
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
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.notifications_outlined, color: GCashColors.primary),
                const SizedBox(width: 8),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Notification Permission',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Allow the app to send push notifications',
                        style: TextStyle(fontSize: 12),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: _permissionsGranted
                        ? Colors.green.shade100
                        : Colors.red.shade100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _permissionsGranted ? 'Enabled' : 'Disabled',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: _permissionsGranted
                          ? Colors.green.shade700
                          : Colors.red.shade700,
                    ),
                  ),
                ),
              ],
            ),
            if (!_permissionsGranted) ...[
              const Divider(height: 24),
              Row(
                children: [
                  ElevatedButton(
                    onPressed: _requestPermissions,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: GCashColors.primary,
                      foregroundColor: AppColors.textPrimaryDark,
                    ),
                    child: const Text('Enable'),
                  ),
                  const SizedBox(width: 8),
                  TextButton(
                    onPressed: () =>
                        PlatformNotificationHelper.instance
                            .openNotificationSettings(),
                    child: const Text('Open Settings'),
                  ),
                ],
              ),
            ],
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
                    Icon(Icons.chevron_right, color: Colors.grey.shade400),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTestNotificationCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(Icons.science_outlined, color: GCashColors.primary),
            const SizedBox(width: 8),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Test Notification',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'Send a sample notification to verify setup',
                    style: TextStyle(fontSize: 12),
                  ),
                ],
              ),
            ),
            ElevatedButton(
              onPressed: _permissionsGranted ? _sendTestNotification : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: GCashColors.primary,
                foregroundColor: AppColors.textPrimaryDark,
              ),
              child: const Text('Send Test'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _sendTestNotification() async {
    final service = locator.get<NotificationService>();
    await service.showNotification(
      id: 9999,
      title: 'Test Notification',
      body: 'Notifications are working correctly!',
      payload: 'test',
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
              foregroundColor: AppColors.textPrimaryDark,
            ),
            child: const Text('Reset'),
          ),
        ],
      ),
    );
  }
}
