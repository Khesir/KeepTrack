import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:keep_track/core/routing/app_router.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:keep_track/core/di/service_locator.dart';
import 'package:keep_track/core/settings/domain/entities/app_settings.dart';
import 'package:keep_track/core/settings/presentation/settings_controller.dart';
import 'package:keep_track/core/state/stream_builder_widget.dart';
import 'package:keep_track/core/state/stream_state.dart';
import 'package:keep_track/core/theme/app_theme.dart';
import 'package:keep_track/features/auth/domain/entities/user.dart';
import 'package:keep_track/core/services/notification/platform_notification_helper.dart';
import 'package:keep_track/features/auth/presentation/screens/auth_settings_screen.dart';
import 'package:keep_track/features/auth/presentation/state/auth_controller.dart';
import 'package:keep_track/features/notifications/presentation/screens/notification_settings_screen.dart';
import 'package:keep_track/core/ui/responsive/responsive_breakpoints.dart';
import 'package:keep_track/features/settings/settings_dialog.dart';
import 'domain/controllers/settings_data_controller.dart';
import 'presentation/sections/data_settings_card_section.dart';
import 'presentation/sheets/currency_picker_sheet.dart';
import 'presentation/sheets/picker_sheet.dart';
import 'presentation/widgets/desktop_settings_header.dart';
import 'presentation/widgets/profile_card.dart';
import 'presentation/widgets/settings_card.dart';
import 'presentation/widgets/settings_row.dart';

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
  late final SettingsDataController _dataController;

  @override
  void initState() {
    super.initState();
    _controller = locator.get<SettingsController>();
    _authController = locator.get<AuthController>();
    _dataController = locator.get<SettingsDataController>();
  }

  static bool get _isDesktop =>
      !kIsWeb && (Platform.isWindows || Platform.isMacOS || Platform.isLinux);

  @override
  Widget build(BuildContext context) {
    if (widget.isDialog && _isDesktop) {
      return const SettingsDialogContent();
    }

    final isWideWeb =
        kIsWeb &&
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
              DesktopSettingsHeader(isDark: isDark, isDialog: widget.isDialog),
              const SizedBox(height: 8),
            ],
            StreamBuilder<AsyncState<User?>>(
              stream: _authController.stream,
              initialData: _authController.state,
              builder: (_, snap) {
                final state = snap.data;
                final user = state is AsyncData<User?>
                    ? state.data
                    : _authController.currentUser;
                return ProfileCard(user: user, isDark: isDark);
              },
            ),
            const SizedBox(height: 24),

            SettingsSectionLabel('Appearance'),
            SettingsCard(
              isDark: isDark,
              children: [
                SettingsRow(
                  isDark: isDark,
                  icon: Icons.brightness_4_outlined,
                  iconColor: AppColors.accent,
                  label: 'Theme',
                  value: settings.themeMode.displayName,
                  onTap: () => _showThemeSheet(context, settings.themeMode),
                ),
                SettingsDivider(isDark: isDark),
                SettingsSwitchRow(
                  isDark: isDark,
                  icon: Icons.wifi_off_rounded,
                  iconColor: AppColors.warning,
                  label: 'Offline Mode',
                  subtitle: settings.forceOfflineMode
                      ? 'Hive only – backend disabled'
                      : 'Online – using backend',
                  value: settings.forceOfflineMode,
                  onChanged: (v) => _controller.setForceOfflineMode(v),
                ),
                SettingsDivider(isDark: isDark),
                SettingsRow(
                  isDark: isDark,
                  icon: Icons.paid_outlined,
                  iconColor: AppColors.success,
                  label: 'Currency',
                  value:
                      '${settings.currency.symbol} ${settings.currency.code}',
                  onTap: () => _showCurrencySheet(context, settings.currency),
                ),
              ],
            ),
            const SizedBox(height: 20),

            SettingsSectionLabel('Budget'),
            SettingsCard(
              isDark: isDark,
              children: [
                SettingsSwitchRow(
                  isDark: isDark,
                  icon: settings.budgetSheetMode
                      ? Icons.table_rows_outlined
                      : Icons.view_stream_outlined,
                  iconColor: AppColors.info,
                  label: 'Budget View',
                  subtitle: settings.budgetSheetMode
                      ? 'Sheet mode – full budget sheet'
                      : 'Simple mode – overview with tabs',
                  value: settings.budgetSheetMode,
                  onChanged: (v) => _controller.updateBudgetSheetMode(v),
                ),
                SettingsDivider(isDark: isDark),
                SettingsRow(
                  isDark: isDark,
                  icon: Icons.photo_library_outlined,
                  iconColor: AppColors.accent,
                  label: 'Attachment Gallery',
                  subtitle: 'Browse all transaction receipt photos',
                  onTap: () => Navigator.pushNamed(
                    context,
                    AppRoutes.transactionAttachmentGallery,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            SettingsSectionLabel('Account'),
            SettingsCard(
              isDark: isDark,
              children: [
                SettingsRow(
                  isDark: isDark,
                  icon: Icons.manage_accounts_outlined,
                  iconColor: AppColors.accent,
                  label: 'Manage Account',
                  subtitle: 'Authentication & security',
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const AuthSettingsScreen(),
                    ),
                  ),
                ),
                SettingsDivider(isDark: isDark),
                SettingsRow(
                  isDark: isDark,
                  icon: Icons.logout_rounded,
                  iconColor: AppColors.error,
                  label: 'Sign Out',
                  labelColor: AppColors.error,
                  onTap: () => _confirmSignOut(context),
                ),
              ],
            ),
            const SizedBox(height: 20),

            if (PlatformNotificationHelper.instance.isSupportedPlatform) ...[
              SettingsSectionLabel('Notifications'),
              SettingsCard(
                isDark: isDark,
                children: [
                  SettingsRow(
                    isDark: isDark,
                    icon: Icons.notifications_outlined,
                    iconColor: AppColors.info,
                    label: 'Push Notifications',
                    subtitle: 'Reminders for tasks and finances',
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const NotificationSettingsScreen(),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
            ],

            DataSettingsCardSection(
              isDark: isDark,
              controller: _controller,
              dataController: _dataController,
            ),
            const SizedBox(height: 32),

            Center(
              child: Text(
                'Keep Track',
                style: GoogleFonts.dmSans(
                  fontSize: 12,
                  color: AppColors.textTertiary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            const SizedBox(height: 4),
            Center(
              child: Text(
                'Zero-based Budgeting',
                style: GoogleFonts.dmSans(
                  fontSize: 11,
                  color: AppColors.textTertiary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }


  void _showThemeSheet(BuildContext context, AppThemeMode current) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => PickerSheet(
        isDark: isDark,
        title: 'Theme',
        items: AppThemeMode.values
            .map(
              (m) => PickerItem(
                icon: m.icon,
                label: m.displayName,
                selected: m == current,
                onTap: () {
                  _controller.updateThemeMode(m);
                  Navigator.pop(context);
                },
              ),
            )
            .toList(),
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
        builder: (ctx, ctrl) => CurrencyPickerSheet(
          isDark: isDark,
          current: current,
          scrollController: ctrl,
          onSelect: (c) {
            _controller.updateCurrency(c);
            Navigator.pop(context);
          },
        ),
      ),
    );
  }

  void _confirmSignOut(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Sign out?', style: AppTextStyles.h4),
        content: Text(
          'You will be signed out of Keep Track.',
          style: AppTextStyles.bodySmall,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await _authController.signOut();
            },
            child: Text(
              'Sign Out',
              style: TextStyle(
                color: AppColors.error,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

}

