import 'package:flutter/material.dart';
import 'package:keep_track/core/theme/app_theme.dart';
import '../widgets/backup_dialog_shell.dart';

Future<bool> showBackupConfirmReplaceDialog(BuildContext context) async {
  final isDark = Theme.of(context).brightness == Brightness.dark;
  final result = await showDialog<bool>(
    context: context,
    barrierColor: Colors.black.withValues(alpha: 0.4),
    builder: (_) => BackupDialogShell(
      isDark: isDark,
      icon: Icons.warning_amber_rounded,
      iconColor: AppColors.warning,
      title: 'Replace all data?',
      subtitle:
          'This will permanently replace all your current data with the backup. This cannot be undone.',
      cancelLabel: 'Cancel',
      confirmLabel: 'Replace',
      confirmColor: AppColors.warning,
      onCancel: () => Navigator.pop(context, false),
      onConfirm: () => Navigator.pop(context, true),
    ),
  );
  return result == true;
}
