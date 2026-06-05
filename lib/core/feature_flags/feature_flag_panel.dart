import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:keep_track/core/di/service_locator.dart';
import 'package:keep_track/core/feature_flags/hive_inspector.dart';
import 'package:keep_track/core/services/notification/notification_service.dart';
import 'package:keep_track/core/settings/domain/entities/app_settings.dart';
import 'package:keep_track/core/settings/presentation/settings_controller.dart';
import 'package:keep_track/core/state/stream_state.dart';
import 'package:keep_track/core/theme/app_theme.dart';
import 'package:keep_track/core/ui/app_toast.dart';
import 'package:keep_track/features/auth/presentation/state/auth_controller.dart';

class FeatureFlagPopover extends StatelessWidget {
  final LayerLink link;
  final bool isDark;
  final VoidCallback onDismiss;

  const FeatureFlagPopover({
    super.key,
    required this.link,
    required this.isDark,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    final settings = locator.get<SettingsController>();
    final auth = locator.get<AuthController>();
    final cardBg = isDark ? AppColors.cardDark : AppColors.card;
    final borderColor = isDark
        ? AppColors.border.withValues(alpha: 0.3)
        : AppColors.border.withValues(alpha: 0.7);

    return Stack(
      children: [
        Positioned.fill(
          child: GestureDetector(
            onTap: onDismiss,
            behavior: HitTestBehavior.translucent,
            child: const SizedBox.expand(),
          ),
        ),
        CompositedTransformFollower(
          link: link,
          targetAnchor: Alignment.bottomRight,
          followerAnchor: Alignment.topRight,
          offset: const Offset(0, 4),
          child: Material(
            color: Colors.transparent,
            child: Container(
              width: 260,
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: borderColor, width: 0.5),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.15),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
                    child: Row(
                      children: [
                        Text(
                          'FEATURE FLAGS',
                          style: GoogleFonts.dmSans(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textSecondary,
                            letterSpacing: 1.0,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          'Ctrl+Shift+F',
                          style: GoogleFonts.dmMono(
                            fontSize: 9,
                            color: AppColors.textTertiary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Divider(
                    height: 1,
                    color: isDark
                        ? AppColors.border.withValues(alpha: 0.2)
                        : AppColors.border.withValues(alpha: 0.5),
                  ),
                  StreamBuilder<AsyncState<AppSettings>>(
                    stream: settings.stream,
                    initialData: settings.state,
                    builder: (context, snapshot) {
                      final s = snapshot.data is AsyncData<AppSettings>
                          ? (snapshot.data as AsyncData<AppSettings>).data
                          : const AppSettings();

                      return _FlagTile(
                        isDark: isDark,
                        icon: Icons.wifi_off_rounded,
                        iconColor: AppColors.warning,
                        label: 'Offline Mode',
                        subtitle: s.forceOfflineMode
                            ? 'Hive only – backend disabled'
                            : 'Online – using backend',
                        value: s.forceOfflineMode,
                        onChanged: (v) =>
                            locator.get<SettingsController>().setForceOfflineMode(v),
                      );
                    },
                  ),
                  Divider(
                    height: 1,
                    color: isDark
                        ? AppColors.border.withValues(alpha: 0.2)
                        : AppColors.border.withValues(alpha: 0.5),
                  ),
                  StreamBuilder<AsyncState<dynamic>>(
                    stream: auth.stream,
                    initialData: auth.state,
                    builder: (_, __) => _FlagTile(
                      isDark: isDark,
                      icon: Icons.star_rounded,
                      iconColor: AppColors.accent,
                      label: 'Plus Mode',
                      subtitle: auth.plusOverride
                          ? 'Simulating Plus user'
                          : 'Showing as free user',
                      value: auth.plusOverride,
                      onChanged: auth.setPlusOverride,
                    ),
                  ),
                  Divider(
                    height: 1,
                    color: isDark
                        ? AppColors.border.withValues(alpha: 0.2)
                        : AppColors.border.withValues(alpha: 0.5),
                  ),
                  StreamBuilder<AsyncState<dynamic>>(
                    stream: auth.stream,
                    initialData: auth.state,
                    builder: (_, __) => _FlagTile(
                      isDark: isDark,
                      icon: Icons.visibility_rounded,
                      iconColor: AppColors.success,
                      label: 'Production View',
                      subtitle: auth.productionView
                          ? 'Simulating production'
                          : 'Showing dev UI',
                      value: auth.productionView,
                      onChanged: auth.setProductionView,
                    ),
                  ),
                  Divider(
                    height: 1,
                    color: isDark
                        ? AppColors.border.withValues(alpha: 0.2)
                        : AppColors.border.withValues(alpha: 0.5),
                  ),
                  Divider(
                    height: 1,
                    color: isDark
                        ? AppColors.border.withValues(alpha: 0.2)
                        : AppColors.border.withValues(alpha: 0.5),
                  ),
                  _HealthCheckButton(isDark: isDark),
                  Divider(
                    height: 1,
                    color: isDark
                        ? AppColors.border.withValues(alpha: 0.2)
                        : AppColors.border.withValues(alpha: 0.5),
                  ),
                  _TestNotificationButton(isDark: isDark),
                  Divider(
                    height: 1,
                    color: isDark
                        ? AppColors.border.withValues(alpha: 0.2)
                        : AppColors.border.withValues(alpha: 0.5),
                  ),
                  _InspectButton(isDark: isDark),
                  const SizedBox(height: 4),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _HealthCheckButton extends StatefulWidget {
  final bool isDark;
  const _HealthCheckButton({required this.isDark});

  @override
  State<_HealthCheckButton> createState() => _HealthCheckButtonState();
}

class _HealthCheckButtonState extends State<_HealthCheckButton> {
  static const _apiUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:3000/api/v1',
  );

  bool _checking = false;

  Future<void> _check() async {
    if (_checking) return;
    final toast = CapturedAppToast.capture(context);
    setState(() => _checking = true);
    try {
      final client = HttpClient();
      client.connectionTimeout = const Duration(seconds: 5);
      final req = await client.getUrl(Uri.parse('$_apiUrl/health'));
      final res = await req.close();
      await res.drain<void>();
      client.close();
      if (!mounted) return;
      if (res.statusCode == 200) {
        toast.success('Backend is healthy');
      } else {
        toast.error('Backend returned ${res.statusCode}');
      }
    } catch (_) {
      if (!mounted) return;
      toast.error('Backend is unreachable');
    } finally {
      if (mounted) setState(() => _checking = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final textPrimary = widget.isDark ? AppColors.primaryForeground : AppColors.textPrimary;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: _check,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: AppColors.info.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                alignment: Alignment.center,
                child: Icon(Icons.dns_outlined, size: 15, color: AppColors.info),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Check Backend',
                      style: GoogleFonts.dmSans(fontSize: 13, fontWeight: FontWeight.w500, color: textPrimary),
                    ),
                    Text(
                      _apiUrl,
                      style: GoogleFonts.dmMono(fontSize: 10, color: AppColors.textTertiary),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              if (_checking)
                SizedBox(
                  width: 13,
                  height: 13,
                  child: CircularProgressIndicator(strokeWidth: 1.5, color: AppColors.info),
                )
              else
                Icon(Icons.monitor_heart_outlined, size: 13, color: AppColors.textTertiary),
            ],
          ),
        ),
      ),
    );
  }
}

class _TestNotificationButton extends StatelessWidget {
  final bool isDark;
  const _TestNotificationButton({required this.isDark});

  @override
  Widget build(BuildContext context) {
    final textPrimary = isDark ? AppColors.primaryForeground : AppColors.textPrimary;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () async {
          final service = locator.get<NotificationService>();
          await service.showNotification(
            id: 9999,
            title: 'Test Notification',
            body: 'Notifications are working correctly!',
            payload: 'test',
          );
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: AppColors.info.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                alignment: Alignment.center,
                child: Icon(Icons.notifications_active_outlined, size: 15, color: AppColors.info),
              ),
              const SizedBox(width: 10),
              Text(
                'Send Test Notification',
                style: GoogleFonts.dmSans(fontSize: 13, fontWeight: FontWeight.w500, color: textPrimary),
              ),
              const Spacer(),
              Icon(Icons.send_rounded, size: 13, color: AppColors.textTertiary),
            ],
          ),
        ),
      ),
    );
  }
}

class _InspectButton extends StatelessWidget {
  final bool isDark;
  const _InspectButton({required this.isDark});

  @override
  Widget build(BuildContext context) {
    final textPrimary = isDark ? AppColors.primaryForeground : AppColors.textPrimary;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () => showHiveInspector(context),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: AppColors.info.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                alignment: Alignment.center,
                child: Icon(Icons.storage_rounded, size: 15, color: AppColors.info),
              ),
              const SizedBox(width: 10),
              Text('Inspect Hive', style: GoogleFonts.dmSans(fontSize: 13, fontWeight: FontWeight.w500, color: textPrimary)),
              const Spacer(),
              Icon(Icons.open_in_new_rounded, size: 13, color: AppColors.textTertiary),
            ],
          ),
        ),
      ),
    );
  }
}

class _FlagTile extends StatelessWidget {
  final bool isDark;
  final IconData icon;
  final Color iconColor;
  final String label;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _FlagTile({
    required this.isDark,
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final textPrimary =
        isDark ? AppColors.primaryForeground : AppColors.textPrimary;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            alignment: Alignment.center,
            child: Icon(icon, size: 15, color: iconColor),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.dmSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: textPrimary,
                  ),
                ),
                Text(
                  subtitle,
                  style: GoogleFonts.dmSans(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: iconColor,
            activeTrackColor: iconColor.withValues(alpha: 0.4),
          ),
        ],
      ),
    );
  }
}
