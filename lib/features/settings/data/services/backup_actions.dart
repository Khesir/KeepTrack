import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:keep_track/core/cache/local_cache.dart';
import 'package:keep_track/core/di/service_locator.dart';
import 'package:keep_track/core/theme/app_theme.dart';
import 'package:keep_track/core/ui/app_toast.dart';
import 'backup_service.dart';
import 'backup_sync_status.dart';

BackupService _buildBackupService() => BackupService(
      cache: locator.get<LocalCache>(),
      encryption: BackupEncryptionService(),
      remote: BackupRemoteDatasource(),
    );

Future<void> exportToFile(BuildContext context) async {
  final password = await _showPasswordDialog(context, confirm: true);
  if (password == null || !context.mounted) return;
  final toast = CapturedAppToast.capture(context);
  final dismiss = toast.loading('Exporting backup…');
  try {
    await _buildBackupService().exportToFile(password);
    dismiss();
    toast.success('Backup exported successfully');
  } catch (e) {
    dismiss();
    toast.error(_errorMessage(e));
  }
}

Future<void> importFromFile(BuildContext context) async {
  final confirmed = await _showConfirmReplaceDialog(context);
  if (!confirmed || !context.mounted) return;
  final password = await _showPasswordDialog(context, confirm: false);
  if (password == null || !context.mounted) return;
  final toast = CapturedAppToast.capture(context);
  final service = _buildBackupService();
  final dismiss = toast.loading('Importing backup…');
  try {
    final bytes = await service.pickBackupFile();
    if (bytes == null) { dismiss(); return; }
    await service.restoreFromBytes(bytes, password);
    dismiss();
    toast.success('Backup imported successfully');
  } catch (e) {
    dismiss();
    toast.error(_errorMessage(e));
  }
}

Future<bool> _showConfirmReplaceDialog(BuildContext context) async {
  final isDark = Theme.of(context).brightness == Brightness.dark;
  final bg = isDark ? AppColors.cardDark : AppColors.card;
  final border = isDark ? AppColors.border.withValues(alpha: 0.2) : AppColors.border.withValues(alpha: 0.4);
  final textPrimary = isDark ? AppColors.primaryForeground : AppColors.textPrimary;

  final result = await showDialog<bool>(
    context: context,
    barrierColor: Colors.black.withValues(alpha: 0.4),
    builder: (ctx) => Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 400),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: border, width: 0.5),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.12), blurRadius: 24, offset: const Offset(0, 8))],
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Replace existing data?', style: GoogleFonts.dmSans(fontSize: 15, fontWeight: FontWeight.w700, color: textPrimary)),
            const SizedBox(height: 8),
            Text('Importing a backup will replace all your current data. This cannot be undone.', style: GoogleFonts.dmSans(fontSize: 13, color: AppColors.textSecondary, height: 1.5)),
            const SizedBox(height: 20),
            Row(children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  style: OutlinedButton.styleFrom(foregroundColor: AppColors.textSecondary, side: BorderSide(color: border), padding: const EdgeInsets.symmetric(vertical: 12), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                  child: Text('Cancel', style: GoogleFonts.dmSans(fontSize: 13, fontWeight: FontWeight.w500)),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: FilledButton(
                  onPressed: () => Navigator.pop(ctx, true),
                  style: FilledButton.styleFrom(backgroundColor: AppColors.error, padding: const EdgeInsets.symmetric(vertical: 12), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                  child: Text('Replace', style: GoogleFonts.dmSans(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.white)),
                ),
              ),
            ]),
          ],
        ),
      ),
    ),
  );
  return result ?? false;
}

Future<void> syncToCloud(BuildContext context) async {
  final password = await _showPasswordDialog(context);
  if (password == null || !context.mounted) return;

  final toast = CapturedAppToast.capture(context);
  final dismiss = toast.loading('Syncing to cloud…');
  try {
    await _buildBackupService().syncToCloud(password);
    dismiss();
    toast.success('Backup synced to cloud');
    final now = DateTime.now();
    await BackupSyncStatus.instance.update(now);
  } catch (e) {
    dismiss();
    toast.error(_errorMessage(e));
  }
}

Future<String?> _showPasswordDialog(BuildContext context, {bool confirm = true}) {
  final isDark = Theme.of(context).brightness == Brightness.dark;
  final pwdCtrl = TextEditingController();
  final confirmCtrl = TextEditingController();
  var obscure = true;
  String? error;

  return showDialog<String>(
    context: context,
    barrierColor: Colors.black.withValues(alpha: 0.4),
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setS) {
        final bg = isDark ? AppColors.cardDark : AppColors.card;
        final border = isDark ? AppColors.border.withValues(alpha: 0.2) : AppColors.border.withValues(alpha: 0.4);
        final textPrimary = isDark ? AppColors.primaryForeground : AppColors.textPrimary;
        final fieldBorder = isDark ? AppColors.border.withValues(alpha: 0.3) : AppColors.border;

        return Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            constraints: const BoxConstraints(maxWidth: 400),
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: border, width: 0.5),
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.12), blurRadius: 24, offset: const Offset(0, 8))],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                  child: Row(children: [
                    Container(
                      width: 36, height: 36,
                      decoration: BoxDecoration(color: AppColors.accent.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(10)),
                      alignment: Alignment.center,
                      child: const Icon(Icons.cloud_upload_outlined, size: 18, color: AppColors.accent),
                    ),
                    const SizedBox(width: 12),
                    Expanded(child: Text(confirm ? 'Set Backup Password' : 'Enter Backup Password', style: GoogleFonts.dmSans(fontSize: 15, fontWeight: FontWeight.w700, color: textPrimary))),
                  ]),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
                  child: Text(
                    confirm
                        ? 'Choose a password to encrypt your backup. You will need it to restore.'
                        : 'Enter the password you used when creating this backup.',
                    style: GoogleFonts.dmSans(fontSize: 13, color: AppColors.textSecondary, height: 1.5),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    _PasswordField(controller: pwdCtrl, label: 'Password', obscure: obscure, isDark: isDark, error: error, fieldBorder: fieldBorder, textPrimary: textPrimary, onToggle: () => setS(() => obscure = !obscure)),
                    if (confirm) ...[
                      const SizedBox(height: 10),
                      _PasswordField(controller: confirmCtrl, label: 'Confirm Password', obscure: obscure, isDark: isDark, fieldBorder: fieldBorder, textPrimary: textPrimary, onToggle: () => setS(() => obscure = !obscure)),
                    ],
                  ]),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
                  child: Row(children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(ctx),
                        style: OutlinedButton.styleFrom(foregroundColor: AppColors.textSecondary, side: BorderSide(color: border), padding: const EdgeInsets.symmetric(vertical: 12), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                        child: Text('Cancel', style: GoogleFonts.dmSans(fontSize: 13, fontWeight: FontWeight.w500)),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: FilledButton(
                        onPressed: () {
                          final pwd = pwdCtrl.text.trim();
                          if (pwd.isEmpty) { setS(() => error = 'Password cannot be empty'); return; }
                          if (confirm && pwd != confirmCtrl.text.trim()) { setS(() => error = 'Passwords do not match'); return; }
                          Navigator.pop(ctx, pwd);
                        },
                        style: FilledButton.styleFrom(backgroundColor: AppColors.accent, padding: const EdgeInsets.symmetric(vertical: 12), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                        child: Text('Continue', style: GoogleFonts.dmSans(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.white)),
                      ),
                    ),
                  ]),
                ),
              ],
            ),
          ),
        );
      },
    ),
  );
}

String _errorMessage(Object e) => switch (e) {
  WrongPasswordException() => 'Wrong password – backup could not be decrypted.',
  InvalidBackupException() => 'Invalid backup file. Select a valid .ktbak file.',
  _ => 'Something went wrong: $e',
};

class _PasswordField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final bool obscure;
  final bool isDark;
  final String? error;
  final Color fieldBorder;
  final Color textPrimary;
  final VoidCallback onToggle;

  const _PasswordField({
    required this.controller,
    required this.label,
    required this.obscure,
    required this.isDark,
    required this.fieldBorder,
    required this.textPrimary,
    required this.onToggle,
    this.error,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      style: GoogleFonts.dmSans(fontSize: 14, color: textPrimary),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.dmSans(fontSize: 13, color: AppColors.textSecondary),
        errorText: error,
        errorStyle: GoogleFonts.dmSans(fontSize: 12, color: AppColors.error),
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        filled: true,
        fillColor: isDark ? Colors.white.withValues(alpha: 0.05) : AppColors.background,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: fieldBorder)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: fieldBorder, width: 0.5)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.accent, width: 1.5)),
        errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.error)),
        suffixIcon: IconButton(
          icon: Icon(obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined, size: 16, color: AppColors.textSecondary),
          onPressed: onToggle,
        ),
      ),
    );
  }
}
