import 'package:flutter/material.dart';
import 'package:keep_track/core/theme/app_theme.dart';
import '../widgets/backup_dialog_shell.dart';
import '../widgets/themed_text_field.dart';

Future<String?> showBackupPasswordDialog(
  BuildContext context, {
  bool confirm = false,
}) {
  final isDark = Theme.of(context).brightness == Brightness.dark;
  final pwdCtrl = TextEditingController();
  final confirmCtrl = TextEditingController();
  var obscure = true;
  String? error;

  return showDialog<String>(
    context: context,
    barrierColor: Colors.black.withValues(alpha: 0.4),
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setS) => BackupDialogShell(
        isDark: isDark,
        icon: Icons.lock_outline_rounded,
        iconColor: AppColors.accent,
        title: confirm ? 'Set Backup Password' : 'Enter Backup Password',
        subtitle: confirm
            ? 'Choose a password to encrypt your backup. You will need it to restore.'
            : 'Enter the password used to encrypt this backup.',
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ThemedTextField(
              controller: pwdCtrl,
              label: 'Password',
              obscure: obscure,
              isDark: isDark,
              error: error,
              onToggleObscure: () => setS(() => obscure = !obscure),
            ),
            if (confirm) ...[
              const SizedBox(height: 10),
              ThemedTextField(
                controller: confirmCtrl,
                label: 'Confirm Password',
                obscure: obscure,
                isDark: isDark,
                onToggleObscure: () => setS(() => obscure = !obscure),
              ),
            ],
          ],
        ),
        cancelLabel: 'Cancel',
        confirmLabel: 'Continue',
        confirmColor: AppColors.accent,
        onCancel: () => Navigator.pop(ctx),
        onConfirm: () {
          final pwd = pwdCtrl.text.trim();
          if (pwd.isEmpty) {
            setS(() => error = 'Password cannot be empty');
            return;
          }
          if (confirm && pwd != confirmCtrl.text.trim()) {
            setS(() => error = 'Passwords do not match');
            return;
          }
          Navigator.pop(ctx, pwd);
        },
      ),
    ),
  );
}
