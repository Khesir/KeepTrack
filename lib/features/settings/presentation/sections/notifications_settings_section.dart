import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:keep_track/core/di/service_locator.dart';
import 'package:keep_track/core/services/notification/platform_notification_helper.dart';
import 'package:keep_track/core/state/stream_state.dart';
import 'package:keep_track/core/theme/app_theme.dart';
import 'package:keep_track/features/notifications/domain/entities/notification_settings.dart';
import 'package:keep_track/features/notifications/presentation/state/notification_settings_controller.dart';
import '../widgets/pane_widgets.dart';

class NotificationsSettingsSection extends StatefulWidget {
  final bool isDark;
  const NotificationsSettingsSection({super.key, required this.isDark});

  @override
  State<NotificationsSettingsSection> createState() => _NotificationsSettingsSectionState();
}

class _NotificationsSettingsSectionState extends State<NotificationsSettingsSection>
    with WidgetsBindingObserver {
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
    if (state == AppLifecycleState.resumed) _checkPermissions();
  }

  Future<void> _checkPermissions() async {
    final granted =
        await PlatformNotificationHelper.instance.areNotificationsEnabled();
    if (mounted) setState(() => _permissionsGranted = granted);
  }

  Future<void> _requestPermissions() async {
    final granted =
        await PlatformNotificationHelper.instance.requestPermissions();
    if (mounted) setState(() => _permissionsGranted = granted);
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AsyncState<NotificationSettings>>(
      stream: _controller.stream,
      initialData: _controller.state,
      builder: (context, snapshot) {
        final state = snapshot.data;

        if (state is AsyncLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (state is AsyncError<NotificationSettings>) {
          return Center(child: Text('Error: ${state.error}'));
        }

        final settings = _controller.settings;

        return ListView(
          padding: const EdgeInsets.all(24),
          children: [
            _buildPermissionRow(),
            const SizedBox(height: 20),
            PaneSectionLabel('Reminders'),
            const SizedBox(height: 8),
            _buildReminderRow(
              isDark: widget.isDark,
              icon: Icons.account_balance_wallet_outlined,
              label: 'Finance Reminder',
              subtitle: 'Daily reminder to track your transactions',
              enabled: settings.financeReminderEnabled,
              time: settings.financeReminderTime,
              onToggle: (v) => _controller.updateFinanceReminder(enabled: v),
              onTimeTap: () => _showTimePicker(
                context,
                settings.financeReminderTime,
                (t) => _controller.updateFinanceReminder(time: t),
              ),
            ),
            const SizedBox(height: 4),
            _buildReminderRow(
              isDark: widget.isDark,
              icon: Icons.wb_sunny_outlined,
              label: 'Morning Reminder',
              subtitle: 'Start your day with a finance check-in',
              enabled: settings.morningReminderEnabled,
              time: settings.morningReminderTime,
              onToggle: (v) => _controller.updateMorningReminder(enabled: v),
              onTimeTap: () => _showTimePicker(
                context,
                settings.morningReminderTime,
                (t) => _controller.updateMorningReminder(time: t),
              ),
            ),
            const SizedBox(height: 4),
            _buildReminderRow(
              isDark: widget.isDark,
              icon: Icons.nightlight_outlined,
              label: 'Evening Reminder',
              subtitle: 'Review your progress at end of day',
              enabled: settings.eveningReminderEnabled,
              time: settings.eveningReminderTime,
              onToggle: (v) => _controller.updateEveningReminder(enabled: v),
              onTimeTap: () => _showTimePicker(
                context,
                settings.eveningReminderTime,
                (t) => _controller.updateEveningReminder(time: t),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildPermissionRow() {
    return PaneRow(
      isDark: widget.isDark,
      icon: Icons.notifications_outlined,
      iconColor: _permissionsGranted ? AppColors.success : AppColors.error,
      label: 'Notification Permission',
      subtitle: _permissionsGranted
          ? 'Notifications are enabled'
          : 'Tap to enable notifications',
      onTap: _permissionsGranted ? null : _requestPermissions,
      trailing: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: _permissionsGranted
              ? AppColors.success.withValues(alpha: 0.12)
              : AppColors.error.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          _permissionsGranted ? 'Enabled' : 'Disabled',
          style: GoogleFonts.dmSans(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: _permissionsGranted ? AppColors.success : AppColors.error,
          ),
        ),
      ),
    );
  }

  Widget _buildReminderRow({
    required bool isDark,
    required IconData icon,
    required String label,
    required String subtitle,
    required bool enabled,
    required TimeOfDay time,
    required ValueChanged<bool> onToggle,
    required VoidCallback onTimeTap,
  }) {
    final timeLabel = _formatTime(time);
    return PaneRow(
      isDark: isDark,
      icon: icon,
      iconColor: enabled ? AppColors.info : AppColors.textTertiary,
      label: label,
      subtitle: enabled ? '$subtitle • $timeLabel' : subtitle,
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (enabled)
            GestureDetector(
              onTap: _permissionsGranted ? onTimeTap : null,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.info.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  timeLabel,
                  style: GoogleFonts.dmSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.info,
                  ),
                ),
              ),
            ),
          if (enabled) const SizedBox(width: 8),
          Switch(
            value: enabled,
            onChanged: _permissionsGranted ? onToggle : null,
            activeThumbColor: AppColors.info,
            activeTrackColor: AppColors.info.withValues(alpha: 0.5),
          ),
        ],
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
    ValueChanged<TimeOfDay> onChanged,
  ) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: initialTime,
    );
    if (picked != null) onChanged(picked);
  }
}
