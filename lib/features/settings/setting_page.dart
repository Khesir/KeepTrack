import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:keep_track/core/ui/app_toast.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:keep_track/core/cache/local_cache.dart';
import 'package:keep_track/core/demo/demo_mode.dart';
import 'package:keep_track/core/restart/app_restart_widget.dart';
import 'package:keep_track/core/di/service_locator.dart';
import 'package:keep_track/features/finance/data/services/finance_initialization_service.dart';
import 'package:keep_track/core/settings/domain/entities/app_settings.dart';
import 'package:keep_track/core/settings/presentation/settings_controller.dart';
import 'package:keep_track/core/state/stream_builder_widget.dart';
import 'package:keep_track/core/state/stream_state.dart';
import 'package:keep_track/core/theme/app_theme.dart';
import 'package:keep_track/features/auth/domain/entities/user.dart';
import 'package:keep_track/features/auth/presentation/screens/auth_settings_screen.dart';
import 'package:keep_track/features/auth/presentation/state/auth_controller.dart';
import 'package:keep_track/core/ui/responsive/responsive_breakpoints.dart';
import 'package:keep_track/features/settings/data/services/backup_service.dart';
import 'package:keep_track/features/settings/settings_dialog.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsPage extends StatefulWidget {
  final String? mode;
  final bool isDialog;
  const SettingsPage({super.key, this.mode, this.isDialog = false});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  late final SettingsController _controller;
  late final AuthController _authController;

  @override
  void initState() {
    super.initState();
    _controller = locator.get<SettingsController>();
    _authController = locator.get<AuthController>();
  }

  static bool get _isDesktop =>
      !kIsWeb && (Platform.isWindows || Platform.isMacOS || Platform.isLinux);

  Future<void> _toggleDemoMode(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await DemoMode.setEnabled(prefs, value);
    if (mounted) {
      // ignore: use_build_context_synchronously
      AppRestartWidget.of(context).restart();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isDialog && _isDesktop) {
      return const SettingsDialogContent();
    }

    final isWideWeb = kIsWeb &&
        MediaQuery.sizeOf(context).width >= ResponsiveBreakpoints.desktop;
    if (isWideWeb) {
      return Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: const SettingsDialogContent(),
      );
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: _isDesktop
          ? null
          : AppBar(
              title: Text(
                'Settings',
                style: AppTextStyles.h4.copyWith(
                  color: isDark
                      ? AppColors.primaryForeground
                      : AppColors.textPrimary,
                ),
              ),
              centerTitle: false,
            ),
      body: AsyncStreamBuilder<AppSettings>(
        state: _controller,
        loadingBuilder: (_) => const Center(child: CircularProgressIndicator()),
        errorBuilder: (_, msg) => Center(child: Text(msg)),
        builder: (context, settings) => ListView(
          padding: EdgeInsets.fromLTRB(16, _isDesktop ? 0 : 8, 16, 32),
          children: [
            if (_isDesktop) ...[
              _DesktopSettingsHeader(isDark: isDark, isDialog: widget.isDialog),
              const SizedBox(height: 8),
            ],
            // ── Profile card ────────────────────────────────────────────
            StreamBuilder<AsyncState<User?>>(
              stream: _authController.stream,
              initialData: _authController.state,
              builder: (_, snap) {
                final state = snap.data;
                final user = state is AsyncData<User?> ? state.data : _authController.currentUser;
                return _ProfileCard(user: user, isDark: isDark);
              },
            ),
            const SizedBox(height: 24),

            // ── Appearance ───────────────────────────────────────────────
            _SectionLabel('Appearance'),
            _SettingsCard(isDark: isDark, children: [
              _SettingsRow(
                isDark: isDark,
                icon: Icons.brightness_4_outlined,
                iconColor: AppColors.accent,
                label: 'Theme',
                value: settings.themeMode.displayName,
                onTap: () => _showThemeSheet(context, settings.themeMode),
              ),
              _Divider(isDark: isDark),
              _SettingsSwitchRow(
                isDark: isDark,
                icon: Icons.wifi_off_rounded,
                iconColor: AppColors.warning,
                label: 'Offline Mode',
                subtitle: settings.forceOfflineMode
                    ? 'Hive only — backend disabled'
                    : 'Online — using backend',
                value: settings.forceOfflineMode,
                onChanged: (v) => _controller.setForceOfflineMode(v),
              ),
              _Divider(isDark: isDark),
              _SettingsRow(
                isDark: isDark,
                icon: Icons.paid_outlined,
                iconColor: AppColors.success,
                label: 'Currency',
                value: '${settings.currency.symbol} ${settings.currency.code}',
                onTap: () => _showCurrencySheet(context, settings.currency),
              ),
            ]),
            const SizedBox(height: 20),

            // ── Budget ───────────────────────────────────────────────────
            _SectionLabel('Budget'),
            _SettingsCard(isDark: isDark, children: [
              _SettingsSwitchRow(
                isDark: isDark,
                icon: settings.budgetSheetMode
                    ? Icons.table_rows_outlined
                    : Icons.view_stream_outlined,
                iconColor: AppColors.info,
                label: 'Budget View',
                subtitle: settings.budgetSheetMode
                    ? 'Sheet mode — full budget sheet'
                    : 'Simple mode — overview with tabs',
                value: settings.budgetSheetMode,
                onChanged: (v) => _controller.updateBudgetSheetMode(v),
              ),
            ]),
            const SizedBox(height: 20),

            // ── Account ──────────────────────────────────────────────────
            _SectionLabel('Account'),
            _SettingsCard(isDark: isDark, children: [
              _SettingsRow(
                isDark: isDark,
                icon: Icons.manage_accounts_outlined,
                iconColor: AppColors.accent,
                label: 'Manage Account',
                subtitle: 'Authentication & security',
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const AuthSettingsScreen()),
                ),
              ),
              _Divider(isDark: isDark),
              _SettingsRow(
                isDark: isDark,
                icon: Icons.logout_rounded,
                iconColor: AppColors.error,
                label: 'Sign Out',
                labelColor: AppColors.error,
                onTap: () => _confirmSignOut(context),
              ),
            ]),
            const SizedBox(height: 20),

            // ── Demo ─────────────────────────────────────────────────────
            _SectionLabel('Demo'),
            _SettingsCard(isDark: isDark, children: [
              _SettingsSwitchRow(
                isDark: isDark,
                icon: Icons.science_outlined,
                iconColor: AppColors.accent,
                label: 'Demo Mode',
                subtitle: DemoMode.enabled
                    ? 'Using sample data — toggle to connect your account'
                    : 'Show sample data to explore all features',
                value: DemoMode.enabled,
                onChanged: _toggleDemoMode,
              ),
            ]),
            const SizedBox(height: 20),

            // ── Backup & Restore ──────────────────────────────────────────
            _SectionLabel('Backup & Restore'),
            _SettingsCard(isDark: isDark, children: [
              _SettingsRow(
                isDark: isDark,
                icon: Icons.file_download_outlined,
                iconColor: AppColors.success,
                label: 'Export to File',
                subtitle: 'Save an encrypted backup to your device',
                onTap: () => _exportToFile(context),
              ),
              _Divider(isDark: isDark),
              _SettingsRow(
                isDark: isDark,
                icon: Icons.cloud_upload_outlined,
                iconColor: AppColors.accent,
                label: 'Sync to Cloud',
                subtitle: 'Upload an encrypted backup to the server',
                onTap: () => _syncToCloud(context),
              ),
              _Divider(isDark: isDark),
              _SettingsRow(
                isDark: isDark,
                icon: Icons.file_upload_outlined,
                iconColor: AppColors.info,
                label: 'Import from File',
                subtitle: 'Restore data from an encrypted backup file',
                onTap: () => _importFromFile(context),
              ),
              _Divider(isDark: isDark),
              _SettingsRow(
                isDark: isDark,
                icon: Icons.cloud_download_outlined,
                iconColor: AppColors.info,
                label: 'Restore from Cloud',
                subtitle: 'Restore data from your cloud backup',
                onTap: () => _restoreFromCloud(context),
              ),
            ]),
            const SizedBox(height: 20),

            // ── Danger Zone ───────────────────────────────────────────────
            _SectionLabel('Danger Zone'),
            _SettingsCard(isDark: isDark, children: [
              _SettingsRow(
                isDark: isDark,
                icon: Icons.restore_rounded,
                iconColor: AppColors.warning,
                label: 'Reset to Defaults',
                subtitle: 'Restore all settings to their original values',
                onTap: () => _confirmReset(context),
              ),
              _Divider(isDark: isDark),
              _SettingsRow(
                isDark: isDark,
                icon: Icons.delete_forever_rounded,
                iconColor: AppColors.error,
                label: 'Wipe All Data',
                labelColor: AppColors.error,
                subtitle: 'Delete all financial data and restore defaults',
                onTap: () => _confirmWipe(context),
              ),
            ]),
            const SizedBox(height: 32),

            // ── Footer ───────────────────────────────────────────────────
            Center(
              child: Text(
                'Keep Track',
                style: GoogleFonts.dmSans(fontSize: 12, color: AppColors.textTertiary, fontWeight: FontWeight.w500),
              ),
            ),
            const SizedBox(height: 4),
            Center(
              child: Text(
                'Zero-based Budgeting',
                style: GoogleFonts.dmSans(fontSize: 11, color: AppColors.textTertiary),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Action sheets ─────────────────────────────────────────────────────────

  void _showThemeSheet(BuildContext context, AppThemeMode current) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _PickerSheet(
        isDark: isDark,
        title: 'Theme',
        items: AppThemeMode.values.map((m) => _PickerItem(
          icon: m.icon,
          label: m.displayName,
          selected: m == current,
          onTap: () { _controller.updateThemeMode(m); Navigator.pop(context); },
        )).toList(),
      ),
    );
  }

  void _showCurrencySheet(BuildContext context, AppCurrency current) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.6,
        maxChildSize: 0.9,
        builder: (ctx, ctrl) => _CurrencyPickerSheet(
          isDark: isDark,
          current: current,
          scrollController: ctrl,
          onSelect: (c) { _controller.updateCurrency(c); Navigator.pop(context); },
        ),
      ),
    );
  }

  void _confirmSignOut(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Sign out?', style: AppTextStyles.h4),
        content: Text('You will be signed out of Keep Track.', style: AppTextStyles.bodySmall),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
            onPressed: () async { Navigator.pop(context); await _authController.signOut(); },
            child: Text('Sign Out', style: TextStyle(color: AppColors.error, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  BackupService _buildBackupService() => BackupService(
        cache: locator.get<LocalCache>(),
        encryption: BackupEncryptionService(),
        remote: BackupRemoteDatasource(),
      );

  Future<String?> _showPasswordDialog(BuildContext context, {bool confirm = false}) {
    final pwdCtrl = TextEditingController();
    final confirmCtrl = TextEditingController();
    var obscure = true;
    String? error;

    return showDialog<String>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => AlertDialog(
          title: Text(confirm ? 'Set Backup Password' : 'Enter Backup Password', style: AppTextStyles.h4),
          content: Column(mainAxisSize: MainAxisSize.min, children: [
            if (confirm) ...[
              Text('Choose a password to encrypt your backup. You will need it to restore.', style: AppTextStyles.bodySmall),
              const SizedBox(height: 12),
            ],
            TextField(
              controller: pwdCtrl,
              obscureText: obscure,
              decoration: InputDecoration(
                labelText: 'Password',
                errorText: error,
                suffixIcon: IconButton(
                  icon: Icon(obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined, size: 18),
                  onPressed: () => setS(() => obscure = !obscure),
                ),
              ),
            ),
            if (confirm) ...[
              const SizedBox(height: 8),
              TextField(
                controller: confirmCtrl,
                obscureText: obscure,
                decoration: const InputDecoration(labelText: 'Confirm Password'),
              ),
            ],
          ]),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            FilledButton(
              onPressed: () {
                final pwd = pwdCtrl.text.trim();
                if (pwd.isEmpty) { setS(() => error = 'Password cannot be empty'); return; }
                if (confirm && pwd != confirmCtrl.text.trim()) { setS(() => error = 'Passwords do not match'); return; }
                Navigator.pop(ctx, pwd);
              },
              child: const Text('Continue'),
            ),
          ],
        ),
      ),
    );
  }

  Future<bool> _showConfirmReplaceDialog(BuildContext context) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Replace all data?', style: AppTextStyles.h4),
        content: Text(
          'This will permanently replace all your current data with the backup. This cannot be undone.',
          style: AppTextStyles.bodySmall,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: AppColors.warning),
            child: const Text('Replace'),
          ),
        ],
      ),
    );
    return result == true;
  }

  void _showBackupError(BuildContext context, Object e) {
    String message;
    if (e is WrongPasswordException) {
      message = 'Wrong password. The backup could not be decrypted.';
    } else if (e is InvalidBackupException) {
      message = 'Invalid backup file. Make sure you selected a valid .ktbak file.';
    } else {
      message = 'Something went wrong: $e';
    }
    if (!context.mounted) return;
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Backup Error', style: AppTextStyles.h4),
        content: Text(message, style: AppTextStyles.bodySmall),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('OK'))],
      ),
    );
  }

  Future<void> _exportToFile(BuildContext context) async {
    final password = await _showPasswordDialog(context, confirm: true);
    if (password == null || !context.mounted) return;
    try {
      final path = await _buildBackupService().exportToFile(password);
      if (!context.mounted) return;
      if (path != null) {
        AppToast.success(context, 'Backup saved to $path');
      }
    } catch (e) {
      _showBackupError(context, e);
    }
  }

  Future<void> _syncToCloud(BuildContext context) async {
    final password = await _showPasswordDialog(context, confirm: true);
    if (password == null || !context.mounted) return;
    try {
      await _buildBackupService().syncToCloud(password);
      if (!context.mounted) return;
      AppToast.success(context, 'Backup synced to cloud');
    } catch (e) {
      _showBackupError(context, e);
    }
  }

  Future<void> _importFromFile(BuildContext context) async {
    final confirmed = await _showConfirmReplaceDialog(context);
    if (!confirmed || !context.mounted) return;
    final password = await _showPasswordDialog(context, confirm: false);
    if (password == null || !context.mounted) return;
    try {
      final imported = await _buildBackupService().importFromFile(password);
      if (imported && context.mounted) AppRestartWidget.of(context).restart();
    } catch (e) {
      // ignore: use_build_context_synchronously
      _showBackupError(context, e);
    }
  }

  Future<void> _restoreFromCloud(BuildContext context) async {
    final confirmed = await _showConfirmReplaceDialog(context);
    if (!confirmed || !context.mounted) return;
    final password = await _showPasswordDialog(context, confirm: false);
    if (password == null || !context.mounted) return;
    try {
      await _buildBackupService().restoreFromCloud(password);
      if (context.mounted) AppRestartWidget.of(context).restart();
    } catch (e) {
      // ignore: use_build_context_synchronously
      _showBackupError(context, e);
    }
  }

  Future<void> _wipeAllData(BuildContext context) async {
    final cache = locator.get<LocalCache>();
    for (final box in [
      'transactions', 'budgets', 'budget_categories', 'month_plans',
      'goals', 'debts', 'planned_payments', 'wallets',
      'subscriptions', 'transaction_plans', 'finance_categories',
      'budget_profiles',
    ]) {
      await cache.clear(box);
    }
    await locator.get<FinanceInitializationService>().initializeDefaultCategories();
    if (context.mounted) {
      AppRestartWidget.of(context).restart();
    }
  }

  void _confirmWipe(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Wipe all data?', style: AppTextStyles.h4),
        content: Text(
          'This will permanently delete all your transactions, budgets, goals, debts, and other financial data. Default categories will be restored. This cannot be undone.',
          style: AppTextStyles.bodySmall,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          FilledButton(
            onPressed: () { Navigator.pop(context); _wipeAllData(context); },
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Wipe All Data'),
          ),
        ],
      ),
    );
  }

  void _confirmReset(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Reset settings?', style: AppTextStyles.h4),
        content: Text('All settings will return to defaults. This cannot be undone.', style: AppTextStyles.bodySmall),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          FilledButton(
            onPressed: () {
              _controller.resetToDefaults();
              Navigator.pop(context);
              AppToast.success(context, 'Settings reset');
            },
            style: FilledButton.styleFrom(backgroundColor: AppColors.warning),
            child: const Text('Reset'),
          ),
        ],
      ),
    );
  }
}

// ─── Profile Card ─────────────────────────────────────────────────────────────

class _ProfileCard extends StatelessWidget {
  final User? user;
  final bool isDark;
  const _ProfileCard({required this.user, required this.isDark});

  String _initials(String? name) {
    if (name == null || name.isEmpty) return 'U';
    final parts = name.trim().split(' ');
    if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    return name[0].toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final cardBg = isDark ? const Color(0xFF2C2C2A) : Colors.white;
    final border = isDark ? AppColors.border.withValues(alpha: 0.2) : AppColors.border.withValues(alpha: 0.5);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(color: cardBg, borderRadius: BorderRadius.circular(16), border: Border.all(color: border, width: 0.5)),
      child: Row(children: [
        // Avatar
        user?.photoUrl != null
            ? CircleAvatar(radius: 28, backgroundImage: NetworkImage(user!.photoUrl!))
            : Container(
                width: 56, height: 56,
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [AppColors.accent, AppColors.accentDark], begin: Alignment.topLeft, end: Alignment.bottomRight),
                  borderRadius: BorderRadius.circular(14),
                ),
                alignment: Alignment.center,
                child: Text(_initials(user?.displayName), style: GoogleFonts.dmSans(fontSize: 20, fontWeight: FontWeight.w700, color: Colors.white)),
              ),
        const SizedBox(width: 16),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(
            (user?.displayName?.isNotEmpty == true) ? user!.displayName! : 'Name not set',
            style: AppTextStyles.h4.copyWith(
              color: (user?.displayName?.isNotEmpty == true)
                  ? (isDark ? AppColors.primaryForeground : AppColors.textPrimary)
                  : AppColors.textSecondary,
            ),
            maxLines: 1, overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 3),
          Text(
            (user?.email?.isNotEmpty == true) ? user!.email! : 'No email',
            style: AppTextStyles.caption,
            maxLines: 1, overflow: TextOverflow.ellipsis,
          ),
        ])),
      ]),
    );
  }
}

// ─── Settings Card & Rows ─────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 8, left: 4),
    child: Text(text.toUpperCase(),
        style: GoogleFonts.dmSans(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.textSecondary, letterSpacing: 1.0)),
  );
}

class _SettingsCard extends StatelessWidget {
  final bool isDark;
  final List<Widget> children;
  const _SettingsCard({required this.isDark, required this.children});

  @override
  Widget build(BuildContext context) {
    final cardBg = isDark ? const Color(0xFF2C2C2A) : Colors.white;
    final border = isDark ? AppColors.border.withValues(alpha: 0.2) : AppColors.border.withValues(alpha: 0.5);
    return Container(
      decoration: BoxDecoration(color: cardBg, borderRadius: BorderRadius.circular(14), border: Border.all(color: border, width: 0.5)),
      child: Column(children: children),
    );
  }
}

class _Divider extends StatelessWidget {
  final bool isDark;
  const _Divider({required this.isDark});

  @override
  Widget build(BuildContext context) => Divider(
    height: 1, thickness: 0.5, indent: 56,
    color: isDark ? AppColors.border.withValues(alpha: 0.2) : AppColors.border.withValues(alpha: 0.5),
  );
}

class _SettingsRow extends StatelessWidget {
  final bool isDark;
  final IconData icon;
  final Color iconColor;
  final String label;
  final String? subtitle, value;
  final Color? labelColor;
  final VoidCallback? onTap;

  const _SettingsRow({required this.isDark, required this.icon, required this.iconColor, required this.label, this.subtitle, this.value, this.labelColor, this.onTap});

  @override
  Widget build(BuildContext context) {
    final textPrimary = isDark ? AppColors.primaryForeground : AppColors.textPrimary;

    return MouseRegion(
      cursor: onTap != null ? SystemMouseCursors.click : SystemMouseCursors.basic,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
          child: Row(children: [
            Container(width: 34, height: 34, decoration: BoxDecoration(color: iconColor.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(9)),
                alignment: Alignment.center, child: Icon(icon, size: 17, color: iconColor)),
            const SizedBox(width: 13),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(label, style: GoogleFonts.dmSans(fontSize: 14, fontWeight: FontWeight.w500, color: labelColor ?? textPrimary)),
              if (subtitle != null) ...[
                const SizedBox(height: 1),
                Text(subtitle!, style: GoogleFonts.dmSans(fontSize: 12, color: AppColors.textSecondary)),
              ],
            ])),
            if (value != null) ...[
              const SizedBox(width: 8),
              Text(value!, style: GoogleFonts.dmSans(fontSize: 13, color: AppColors.textSecondary, fontWeight: FontWeight.w500)),
            ],
            const SizedBox(width: 4),
            Icon(Icons.chevron_right_rounded, size: 18, color: AppColors.textTertiary),
          ]),
        ),
      ),
    );
  }
}

class _SettingsSwitchRow extends StatelessWidget {
  final bool isDark;
  final IconData icon;
  final Color iconColor;
  final String label;
  final String? subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _SettingsSwitchRow({required this.isDark, required this.icon, required this.iconColor, required this.label, required this.value, required this.onChanged, this.subtitle});

  @override
  Widget build(BuildContext context) {
    final textPrimary = isDark ? AppColors.primaryForeground : AppColors.textPrimary;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Row(children: [
        Container(width: 34, height: 34, decoration: BoxDecoration(color: iconColor.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(9)),
            alignment: Alignment.center, child: Icon(icon, size: 17, color: iconColor)),
        const SizedBox(width: 13),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: GoogleFonts.dmSans(fontSize: 14, fontWeight: FontWeight.w500, color: textPrimary)),
          if (subtitle != null) ...[
            const SizedBox(height: 1),
            Text(subtitle!, style: GoogleFonts.dmSans(fontSize: 12, color: AppColors.textSecondary)),
          ],
        ])),
        Switch(
          value: value,
          onChanged: onChanged,
          activeThumbColor: AppColors.accent,
          activeTrackColor: AppColors.accent.withValues(alpha: 0.4),
        ),
      ]),
    );
  }
}

// ─── Theme Picker Sheet ───────────────────────────────────────────────────────

class _PickerSheet extends StatelessWidget {
  final bool isDark;
  final String title;
  final List<_PickerItem> items;
  const _PickerSheet({required this.isDark, required this.title, required this.items});

  @override
  Widget build(BuildContext context) {
    final bg = isDark ? const Color(0xFF2C2C2A) : Colors.white;
    final border = isDark ? AppColors.border.withValues(alpha: 0.2) : AppColors.border.withValues(alpha: 0.5);
    final textPrimary = isDark ? AppColors.primaryForeground : AppColors.textPrimary;

    return Container(
      decoration: BoxDecoration(color: bg, borderRadius: const BorderRadius.vertical(top: Radius.circular(20))),
      child: SafeArea(top: false, child: Column(mainAxisSize: MainAxisSize.min, children: [
        const SizedBox(height: 10),
        Container(width: 36, height: 4, decoration: BoxDecoration(color: AppColors.textTertiary.withValues(alpha: 0.4), borderRadius: BorderRadius.circular(2))),
        Padding(padding: const EdgeInsets.fromLTRB(20, 14, 20, 4), child: Row(children: [
          Text(title, style: GoogleFonts.dmSans(fontSize: 16, fontWeight: FontWeight.w700, color: textPrimary)),
          const Spacer(),
          GestureDetector(onTap: () => Navigator.pop(context), child: Padding(padding: const EdgeInsets.all(4), child: Icon(Icons.close_rounded, size: 18, color: AppColors.textSecondary))),
        ])),
        Divider(height: 16, color: border),
        ...items.map((item) => MouseRegion(
          cursor: SystemMouseCursors.click,
          child: GestureDetector(
            onTap: item.onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Row(children: [
                Icon(item.icon, size: 20, color: item.selected ? AppColors.accent : AppColors.textSecondary),
                const SizedBox(width: 14),
                Expanded(child: Text(item.label, style: GoogleFonts.dmSans(fontSize: 14, fontWeight: item.selected ? FontWeight.w600 : FontWeight.w400, color: item.selected ? AppColors.accent : textPrimary))),
                if (item.selected) Icon(Icons.check_rounded, size: 18, color: AppColors.accent),
              ]),
            ),
          ),
        )),
        const SizedBox(height: 8),
      ])),
    );
  }
}

class _PickerItem {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _PickerItem({required this.icon, required this.label, required this.selected, required this.onTap});
}

// ─── Currency Picker Sheet ────────────────────────────────────────────────────

class _CurrencyPickerSheet extends StatefulWidget {
  final bool isDark;
  final AppCurrency current;
  final ScrollController scrollController;
  final void Function(AppCurrency) onSelect;
  const _CurrencyPickerSheet({required this.isDark, required this.current, required this.scrollController, required this.onSelect});

  @override
  State<_CurrencyPickerSheet> createState() => _CurrencyPickerSheetState();
}

class _CurrencyPickerSheetState extends State<_CurrencyPickerSheet> {
  String _search = '';

  @override
  Widget build(BuildContext context) {
    final bg = widget.isDark ? const Color(0xFF2C2C2A) : Colors.white;
    final border = widget.isDark ? AppColors.border.withValues(alpha: 0.2) : AppColors.border.withValues(alpha: 0.5);
    final textPrimary = widget.isDark ? AppColors.primaryForeground : AppColors.textPrimary;
    final filtered = AppCurrency.values.where((c) =>
        c.displayName.toLowerCase().contains(_search.toLowerCase()) ||
        c.code.toLowerCase().contains(_search.toLowerCase())).toList();

    return Container(
      decoration: BoxDecoration(color: bg, borderRadius: const BorderRadius.vertical(top: Radius.circular(20))),
      child: Column(children: [
        const SizedBox(height: 10),
        Container(width: 36, height: 4, decoration: BoxDecoration(color: AppColors.textTertiary.withValues(alpha: 0.4), borderRadius: BorderRadius.circular(2))),
        Padding(padding: const EdgeInsets.fromLTRB(20, 14, 20, 10), child: Row(children: [
          Text('Currency', style: GoogleFonts.dmSans(fontSize: 16, fontWeight: FontWeight.w700, color: textPrimary)),
          const Spacer(),
          GestureDetector(onTap: () => Navigator.pop(context), child: Padding(padding: const EdgeInsets.all(4), child: Icon(Icons.close_rounded, size: 18, color: AppColors.textSecondary))),
        ])),
        Padding(padding: const EdgeInsets.fromLTRB(16, 0, 16, 10), child: TextField(
          onChanged: (v) => setState(() => _search = v),
          decoration: InputDecoration(
            hintText: 'Search currency…',
            prefixIcon: const Icon(Icons.search_rounded, size: 18),
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            isDense: true,
          ),
        )),
        Divider(height: 1, color: border),
        Expanded(
          child: ListView.separated(
            controller: widget.scrollController,
            itemCount: filtered.length,
            separatorBuilder: (_, __) => Divider(height: 1, color: border, indent: 20, endIndent: 20),
            itemBuilder: (_, i) {
              final c = filtered[i];
              final isSel = c == widget.current;
              return MouseRegion(
                cursor: SystemMouseCursors.click,
                child: GestureDetector(
                  onTap: () => widget.onSelect(c),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    child: Row(children: [
                      Container(width: 36, height: 36, decoration: BoxDecoration(color: AppColors.success.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(9)),
                          alignment: Alignment.center,
                          child: Text(c.symbol, style: GoogleFonts.dmMono(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.success))),
                      const SizedBox(width: 12),
                      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(c.displayName, style: GoogleFonts.dmSans(fontSize: 14, fontWeight: isSel ? FontWeight.w600 : FontWeight.w400, color: isSel ? AppColors.accent : textPrimary)),
                        Text(c.code, style: GoogleFonts.dmSans(fontSize: 12, color: AppColors.textSecondary)),
                      ])),
                      if (isSel) Icon(Icons.check_rounded, size: 18, color: AppColors.accent),
                    ]),
                  ),
                ),
              );
            },
          ),
        ),
      ]),
    );
  }
}

class _DesktopSettingsHeader extends StatelessWidget {
  final bool isDark;
  final bool isDialog;
  const _DesktopSettingsHeader({
    required this.isDark,
    this.isDialog = false,
  });

  @override
  Widget build(BuildContext context) {
    final borderColor = isDark
        ? AppColors.border.withValues(alpha: 0.25)
        : AppColors.border.withValues(alpha: 0.5);
    final fg =
        isDark ? AppColors.primaryForeground : AppColors.textPrimary;

    return Container(
      height: 52,
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: borderColor, width: 0.5)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          if (!isDialog)
            MouseRegion(
              cursor: SystemMouseCursors.click,
              child: GestureDetector(
                onTap: () => Navigator.of(context).pop(),
                child: Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: Icon(Icons.arrow_back_rounded, size: 18, color: fg),
                ),
              ),
            ),
          Text('Settings', style: AppTextStyles.h4.copyWith(color: fg)),
          if (isDialog) ...[
            const Spacer(),
            MouseRegion(
              cursor: SystemMouseCursors.click,
              child: GestureDetector(
                onTap: () => Navigator.of(context).pop(),
                child: Icon(Icons.close_rounded, size: 18, color: AppColors.textSecondary),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
