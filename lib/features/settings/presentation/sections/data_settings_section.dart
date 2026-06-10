import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:keep_track/core/demo/demo_mode.dart';
import 'package:keep_track/core/restart/app_restart_widget.dart';
import 'package:keep_track/core/state/stream_builder_widget.dart';
import 'package:keep_track/core/state/stream_state.dart';
import 'package:keep_track/core/theme/app_theme.dart';
import 'package:keep_track/core/ui/app_toast.dart';
import 'package:keep_track/core/settings/presentation/settings_controller.dart';
import 'package:keep_track/features/auth/presentation/state/auth_controller.dart';
import '../../domain/controllers/settings_data_controller.dart';
import '../dialogs/backup_confirm_replace_dialog.dart';
import '../dialogs/backup_password_dialog.dart';
import '../dialogs/reset_settings_dialog.dart';
import '../dialogs/wipe_data_dialog.dart';
import '../helpers/backup_format_helpers.dart';
import '../widgets/pane_widgets.dart';

class DataSettingsSection extends StatefulWidget {
  final bool isDark;
  final SettingsController controller;
  final AuthController authController;
  final SettingsDataController dataController;

  const DataSettingsSection({
    super.key,
    required this.isDark,
    required this.controller,
    required this.authController,
    required this.dataController,
  });

  @override
  State<DataSettingsSection> createState() => _DataSettingsSectionState();
}

class _DataSettingsSectionState extends State<DataSettingsSection> {
  @override
  void initState() {
    super.initState();
    widget.dataController.loadLastSyncedAt();
  }

  Future<void> _toggleDemoMode(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await DemoMode.setEnabled(prefs, value);
    if (mounted) {
      // ignore: use_build_context_synchronously
      AppRestartWidget.of(context).restart();
    }
  }

  Future<void> _exportToFile(BuildContext context) async {
    final password = await showBackupPasswordDialog(context, confirm: true);
    if (password == null || !context.mounted) return;
    final toast = CapturedAppToast.capture(context);
    final dismiss = toast.loading('Exporting backup…');
    try {
      await widget.dataController.exportToFile(password);
      dismiss();
      toast.success('Backup exported successfully');
    } catch (e) {
      dismiss();
      toast.error(SettingsDataController.backupErrorMessage(e));
    }
  }

  Future<void> _syncToCloud(BuildContext context) async {
    final password = await showBackupPasswordDialog(context, confirm: true);
    if (password == null || !context.mounted) return;
    final toast = CapturedAppToast.capture(context);
    final dismiss = toast.loading('Syncing to cloud…');
    try {
      await widget.dataController.syncToCloud(password);
      dismiss();
      toast.success('Backup synced to cloud');
    } catch (e) {
      dismiss();
      toast.error(SettingsDataController.backupErrorMessage(e));
    }
  }

  Future<void> _importFromFile(BuildContext context) async {
    final confirmed = await showBackupConfirmReplaceDialog(context);
    if (!confirmed || !context.mounted) return;
    final password = await showBackupPasswordDialog(context, confirm: false);
    if (password == null || !context.mounted) return;

    final toast = CapturedAppToast.capture(context);
    final dismiss = toast.loading('Importing backup…');

    try {
      final imported = await widget.dataController.importFromFile(password);
      dismiss();
      if (!imported) return;
      toast.success('Backup imported successfully');
      await Future.delayed(const Duration(milliseconds: 1500));
      if (mounted) AppRestartWidget.of(context).restart();
    } catch (e) {
      dismiss();
      toast.error(SettingsDataController.backupErrorMessage(e));
    }
  }

  Future<void> _restoreFromCloud(BuildContext context) async {
    final confirmed = await showBackupConfirmReplaceDialog(context);
    if (!confirmed || !context.mounted) return;
    final password = await showBackupPasswordDialog(context, confirm: false);
    if (password == null || !context.mounted) return;

    final toast = CapturedAppToast.capture(context);
    final dismiss = toast.loading('Restoring from cloud…');

    try {
      await widget.dataController.restoreFromCloud(password);
      dismiss();
      toast.success('Backup restored successfully');
      await Future.delayed(const Duration(milliseconds: 1500));
      if (mounted) AppRestartWidget.of(context).restart();
    } catch (e) {
      dismiss();
      toast.error(SettingsDataController.backupErrorMessage(e));
    }
  }

  Future<void> _wipeAllData(BuildContext context) async {
    await widget.dataController.wipeAllData();
    if (context.mounted) AppRestartWidget.of(context).restart();
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        const PaneLabel('Demo', leftPadding: 0),
        PaneRow(
          isDark: widget.isDark,
          icon: Icons.science_outlined,
          iconColor: AppColors.accent,
          label: 'Demo Mode',
          subtitle: DemoMode.enabled
              ? 'Using sample data – toggle to connect your account'
              : 'Show sample data to explore all features',
          trailing: Switch(
            value: DemoMode.enabled,
            onChanged: _toggleDemoMode,
            activeThumbColor: AppColors.accent,
          ),
        ),
        const PaneLabel('Backup & Restore', leftPadding: 0),
        PaneRow(
          isDark: widget.isDark,
          icon: Icons.file_download_outlined,
          iconColor: AppColors.success,
          label: 'Export to File',
          subtitle: 'Save an encrypted backup to your device',
          onTap: () => _exportToFile(context),
        ),
        PaneRow(
          isDark: widget.isDark,
          icon: Icons.file_upload_outlined,
          iconColor: AppColors.info,
          label: 'Import from File',
          subtitle: 'Restore data from an encrypted backup file',
          onTap: () => _importFromFile(context),
        ),
        if (widget.authController.isEffectivelyPlus)
          StreamStateBuilder<AsyncState<DateTime?>>(
            state: widget.dataController,
            builder: (context, state) {
              final lastSyncedAt =
                  state is AsyncData<DateTime?> ? state.data : null;
              final subtitle = lastSyncedSubtitle(lastSyncedAt);
              return Column(
                children: [
                  PaneRow(
                    isDark: widget.isDark,
                    icon: Icons.cloud_upload_outlined,
                    iconColor: AppColors.accent,
                    label: 'Sync to Cloud',
                    subtitle: subtitle,
                    onTap: () => _syncToCloud(context),
                  ),
                  PaneRow(
                    isDark: widget.isDark,
                    icon: Icons.cloud_download_outlined,
                    iconColor: AppColors.accent,
                    label: 'Restore from Cloud',
                    subtitle: subtitle,
                    onTap: () => _restoreFromCloud(context),
                  ),
                ],
              );
            },
          ),
        const PaneLabel('Danger Zone', leftPadding: 0),
        PaneRow(
          isDark: widget.isDark,
          icon: Icons.restore_rounded,
          iconColor: AppColors.warning,
          label: 'Reset to Defaults',
          subtitle: 'Restore all settings to their original values',
          onTap: () => showResetSettingsDialog(
            context,
            onConfirm: widget.controller.resetToDefaults,
          ),
        ),
        PaneRow(
          isDark: widget.isDark,
          icon: Icons.delete_forever_rounded,
          iconColor: AppColors.error,
          label: 'Wipe All Data',
          labelColor: AppColors.error,
          subtitle: 'Delete all financial data and restore defaults',
          onTap: () => showWipeDataDialog(
            context,
            onConfirm: () => _wipeAllData(context),
          ),
        ),
      ],
    );
  }
}
