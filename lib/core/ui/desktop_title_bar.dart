import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:keep_track/core/di/service_locator.dart';
import 'package:keep_track/core/feature_flags/feature_flag_panel.dart';
import 'package:keep_track/features/inbox/domain/controller/inbox_controller.dart';
import 'package:keep_track/features/inbox/domain/entities/announcement.dart';
import 'package:keep_track/core/navigation/app_navigator.dart';
import 'package:keep_track/core/settings/domain/entities/app_settings.dart';
import 'package:keep_track/core/settings/presentation/settings_controller.dart';
import 'package:keep_track/core/state/stream_state.dart';
import 'package:keep_track/core/theme/app_theme.dart';
import 'package:keep_track/core/ui/app_toast.dart';
import 'package:keep_track/core/ui/inbox_popover_widget.dart';
import 'package:keep_track/features/auth/presentation/state/auth_controller.dart';
import 'package:keep_track/features/settings/data/datasources/backup_sync_status.dart';
import 'package:keep_track/features/settings/domain/controllers/settings_data_controller.dart';
import 'package:keep_track/features/settings/presentation/dialogs/backup_password_dialog.dart';
import 'package:keep_track/features/settings/setting_page.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:window_manager/window_manager.dart';

class DesktopTitleBar extends StatelessWidget {
  static const double height = 40;
  static const String _helpUrl = 'https://keep-track.khesir.com/docs/';

  final bool? isDarkOverride;

  const DesktopTitleBar({super.key, this.isDarkOverride});

  static bool get isDesktopPlatform =>
      Platform.isWindows || Platform.isMacOS || Platform.isLinux;

  @override
  Widget build(BuildContext context) {
    final isDark =
        isDarkOverride ?? (Theme.of(context).brightness == Brightness.dark);
    final theme = Theme.of(context);
    final bg = isDark ? theme.scaffoldBackgroundColor : Colors.white;
    final borderColor = isDark ? Colors.white.withValues(alpha: 0.08) : AppColors.border;

    return Container(
      height: height,
      decoration: BoxDecoration(
        color: bg,
        border: Border(bottom: BorderSide(color: borderColor)),
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: DragToMoveArea(child: const SizedBox.expand()),
          ),
          Row(
            children: [
              const Spacer(),
              _OfflineIndicator(isDark: isDark),
              if (kDebugMode) _FeatureFlagButton(isDark: isDark),
              _SyncStatusChip(isDark: isDark),
              _InboxButton(isDark: isDark),
              _HelpButton(isDark: isDark, url: _helpUrl),
              _SettingsButton(isDark: isDark),
              const SizedBox(width: 4),
              _WindowControls(isDark: isDark),
            ],
          ),
        ],
      ),
    );
  }
}

class _InboxButton extends StatefulWidget {
  final bool isDark;
  const _InboxButton({required this.isDark});

  @override
  State<_InboxButton> createState() => _InboxButtonState();
}

class _InboxButtonState extends State<_InboxButton> {
  final _layerLink = LayerLink();
  OverlayEntry? _overlay;
  bool _isOpen = false;

  void _toggle() => _isOpen ? _close() : _open();

  void _open() {
    locator.get<InboxController>().load();
    _overlay = OverlayEntry(
      builder: (_) => InboxPopoverWidget(
        link: _layerLink,
        isDark: widget.isDark,
        onDismiss: _close,
      ),
    );
    Overlay.of(context).insert(_overlay!);
    setState(() => _isOpen = true);
  }

  void _close() {
    _overlay?.remove();
    _overlay = null;
    if (mounted) setState(() => _isOpen = false);
  }

  @override
  void dispose() {
    _overlay?.remove();
    _overlay = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final inbox = locator.get<InboxController>();
    return StreamBuilder<AsyncState<List<Announcement>>>(
      stream: inbox.stream,
      initialData: inbox.state,
      builder: (_, __) {
        final count = inbox.unreadCount;
        return CompositedTransformTarget(
          link: _layerLink,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              _TitleBarIconButton(
                isDark: widget.isDark,
                isActive: _isOpen,
                tooltip: 'Inbox',
                onTap: _toggle,
                icon: Icons.inbox_outlined,
                activeColor: AppColors.accent,
              ),
              if (count > 0)
                Positioned(
                  top: 4,
                  right: 4,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: AppColors.error,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _OfflineIndicator extends StatelessWidget {
  final bool isDark;
  const _OfflineIndicator({required this.isDark});

  @override
  Widget build(BuildContext context) {
    final settings = locator.get<SettingsController>();

    return StreamBuilder<AsyncState<AppSettings>>(
      stream: settings.stream,
      initialData: settings.state,
      builder: (context, snapshot) {
        final isOffline = snapshot.data is AsyncData<AppSettings>
            ? (snapshot.data as AsyncData<AppSettings>).data.forceOfflineMode
            : false;

        if (!isOffline) return const SizedBox.shrink();

        return Container(
          margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: AppColors.warning.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: AppColors.warning.withValues(alpha: 0.25),
              width: 0.5,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.wifi_off_rounded, size: 11, color: AppColors.warning),
              const SizedBox(width: 4),
              Text(
                'OFFLINE',
                style: GoogleFonts.dmMono(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: AppColors.warning,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _FeatureFlagButton extends StatefulWidget {
  final bool isDark;
  const _FeatureFlagButton({required this.isDark});

  @override
  State<_FeatureFlagButton> createState() => _FeatureFlagButtonState();
}

class _FeatureFlagButtonState extends State<_FeatureFlagButton> {
  final _layerLink = LayerLink();
  OverlayEntry? _overlay;
  bool _isOpen = false;

  @override
  void initState() {
    super.initState();
    HardwareKeyboard.instance.addHandler(_handleKey);
  }

  @override
  void dispose() {
    HardwareKeyboard.instance.removeHandler(_handleKey);
    _overlay?.remove();
    _overlay = null;
    super.dispose();
  }

  bool _handleKey(KeyEvent event) {
    if (event is KeyDownEvent &&
        HardwareKeyboard.instance.isControlPressed &&
        HardwareKeyboard.instance.isShiftPressed &&
        event.logicalKey == LogicalKeyboardKey.keyF) {
      _toggle();
      return true;
    }
    return false;
  }

  void _toggle() => _isOpen ? _close() : _open();

  void _open() {
    _overlay = OverlayEntry(
      builder: (_) => FeatureFlagPopover(
        link: _layerLink,
        isDark: widget.isDark,
        onDismiss: _close,
      ),
    );
    Overlay.of(context).insert(_overlay!);
    setState(() => _isOpen = true);
  }

  void _close() {
    _overlay?.remove();
    _overlay = null;
    if (mounted) setState(() => _isOpen = false);
  }

  @override
  Widget build(BuildContext context) {
    return CompositedTransformTarget(
      link: _layerLink,
      child: _TitleBarIconButton(
        isDark: widget.isDark,
        isActive: _isOpen,
        tooltip: 'Feature Flags (Ctrl+Shift+F)',
        onTap: _toggle,
        icon: Icons.tune_rounded,
        activeColor: AppColors.warning,
      ),
    );
  }
}

class _HelpButton extends StatelessWidget {
  final bool isDark;
  final String url;
  const _HelpButton({required this.isDark, required this.url});

  @override
  Widget build(BuildContext context) {
    return _TitleBarIconButton(
      isDark: isDark,
      tooltip: 'Help',
      onTap: () => launchUrl(Uri.parse(url)),
      icon: Icons.help_outline_rounded,
    );
  }
}

class _SettingsButton extends StatelessWidget {
  final bool isDark;
  const _SettingsButton({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return _TitleBarIconButton(
      isDark: isDark,
      tooltip: 'Settings',
      icon: Icons.settings_outlined,
      onTap: () {
        final ctx = AppNavigator.context;
        if (ctx == null) return;
        showDialog<void>(
          context: ctx,
          barrierColor: Colors.black.withValues(alpha: 0.5),
          builder: (_) => Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            insetPadding: const EdgeInsets.all(48),
            clipBehavior: Clip.antiAlias,
            child: const SizedBox(
              width: 980,
              height: 680,
              child: SettingsPage(isDialog: true),
            ),
          ),
        );
      },
    );
  }
}

class _TitleBarIconButton extends StatefulWidget {
  final bool isDark;
  final bool isActive;
  final VoidCallback onTap;
  final IconData icon;
  final Color? activeColor;
  final String? tooltip;

  const _TitleBarIconButton({
    required this.isDark,
    required this.onTap,
    required this.icon,
    this.isActive = false,
    this.activeColor,
    this.tooltip,
  });

  @override
  State<_TitleBarIconButton> createState() => _TitleBarIconButtonState();
}

class _TitleBarIconButtonState extends State<_TitleBarIconButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final restBg = widget.isDark
        ? Colors.white.withValues(alpha: 0.04)
        : Colors.black.withValues(alpha: 0.04);
    final hoverBg = widget.isDark
        ? Colors.white.withValues(alpha: 0.10)
        : Colors.black.withValues(alpha: 0.07);
    final activeBg = AppColors.accent.withValues(
      alpha: widget.isDark ? 0.18 : 0.10,
    );
    final iconColor = widget.isActive
        ? (widget.activeColor ?? AppColors.accent)
        : (widget.isDark
              ? const Color(0xFFA0A09A)
              : AppColors.textSecondary);

    final button = MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: Container(
          width: 34,
          height: 34,
          margin: const EdgeInsets.symmetric(vertical: 3),
          decoration: BoxDecoration(
            color: widget.isActive
                ? activeBg
                : (_hovered ? hoverBg : restBg),
            borderRadius: BorderRadius.circular(6),
          ),
          alignment: Alignment.center,
          child: Icon(widget.icon, size: 16, color: iconColor),
        ),
      ),
    );

    if (widget.tooltip != null) {
      return Tooltip(
        message: widget.tooltip!,
        preferBelow: true,
        child: button,
      );
    }
    return button;
  }
}



Future<void> _syncToCloud(BuildContext context) async {
  final password = await showBackupPasswordDialog(context, confirm: true);
  if (password == null || !context.mounted) return;

  final toast = CapturedAppToast.capture(context);
  final dismiss = toast.loading('Syncing to cloud…');
  try {
    await locator.get<SettingsDataController>().syncToCloud(password);
    dismiss();
    toast.success('Backup synced to cloud');
  } catch (e) {
    dismiss();
    toast.error(SettingsDataController.backupErrorMessage(e));
  }
}

class _SyncStatusChip extends StatefulWidget {
  final bool isDark;
  const _SyncStatusChip({required this.isDark});

  @override
  State<_SyncStatusChip> createState() => _SyncStatusChipState();
}

class _SyncStatusChipState extends State<_SyncStatusChip> {
  late final AuthController _auth;

  @override
  void initState() {
    super.initState();
    _auth = locator.get<AuthController>();
    BackupSyncStatus.instance.load();
    BackupSyncStatus.instance.notifier.addListener(_onChanged);
  }

  void _onChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    BackupSyncStatus.instance.notifier.removeListener(_onChanged);
    super.dispose();
  }

  String _format(DateTime ts) {
    final diff = DateTime.now().difference(ts.toLocal());
    if (diff.inSeconds < 60) return 'SYNCED JUST NOW';
    if (diff.inMinutes < 60) return 'SYNCED ${diff.inMinutes}M AGO';
    if (diff.inHours < 24) return 'SYNCED ${diff.inHours}H AGO';
    final d = ts.toLocal();
    final months = ['', 'JAN', 'FEB', 'MAR', 'APR', 'MAY', 'JUN', 'JUL', 'AUG', 'SEP', 'OCT', 'NOV', 'DEC'];
    return 'SYNCED ${d.day} ${months[d.month]}';
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AsyncState<dynamic>>(
      stream: _auth.stream,
      initialData: _auth.state,
      builder: (_, __) {
        if (!_auth.isEffectivelyPlus) return const SizedBox.shrink();

        final ts = BackupSyncStatus.instance.notifier.value;
        final synced = ts != null;
        final color = synced ? AppColors.success : AppColors.textTertiary;

        return MouseRegion(
          cursor: SystemMouseCursors.click,
          child: GestureDetector(
            onTap: () {
              final ctx = AppNavigator.context;
              if (ctx != null) _syncToCloud(ctx);
            },
            child: Container(
              margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: color.withValues(alpha: 0.3), width: 0.5),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(synced ? Icons.cloud_done_outlined : Icons.cloud_off_outlined, size: 11, color: color),
                  const SizedBox(width: 4),
                  Text(
                    synced ? _format(ts) : 'NOT SYNCED',
                    style: GoogleFonts.dmMono(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: color,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}


class _WindowControls extends StatelessWidget {
  final bool isDark;
  const _WindowControls({required this.isDark});

  @override
  Widget build(BuildContext context) {
    final iconColor =
        isDark ? const Color(0xFFA0A09A) : AppColors.textSecondary;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _WindowButton(
          isDark: isDark,
          onTap: () => windowManager.minimize(),
          child: Container(width: 10, height: 1.5, color: iconColor),
        ),
        _MaximizeButton(isDark: isDark),
        _WindowButton(
          isDark: isDark,
          isClose: true,
          onTap: () => windowManager.close(),
          child: Icon(Icons.close, size: 14, color: iconColor),
        ),
      ],
    );
  }
}

class _MaximizeButton extends StatefulWidget {
  final bool isDark;
  const _MaximizeButton({required this.isDark});

  @override
  State<_MaximizeButton> createState() => _MaximizeButtonState();
}

class _MaximizeButtonState extends State<_MaximizeButton>
    with WindowListener {
  bool _isMaximized = false;

  @override
  void initState() {
    super.initState();
    windowManager.addListener(this);
    windowManager.isMaximized().then((v) {
      if (mounted) setState(() => _isMaximized = v);
    });
  }

  @override
  void dispose() {
    windowManager.removeListener(this);
    super.dispose();
  }

  @override
  void onWindowMaximize() => setState(() => _isMaximized = true);

  @override
  void onWindowUnmaximize() => setState(() => _isMaximized = false);

  @override
  Widget build(BuildContext context) {
    final iconColor =
        widget.isDark ? const Color(0xFFA0A09A) : AppColors.textSecondary;

    return _WindowButton(
      isDark: widget.isDark,
      onTap: () async {
        if (await windowManager.isMaximized()) {
          await windowManager.unmaximize();
        } else {
          await windowManager.maximize();
        }
      },
      child: _isMaximized
          ? Icon(Icons.filter_none, size: 11, color: iconColor)
          : Icon(Icons.crop_square_outlined, size: 14, color: iconColor),
    );
  }
}

class _WindowButton extends StatefulWidget {
  final bool isDark;
  final bool isClose;
  final VoidCallback onTap;
  final Widget child;

  const _WindowButton({
    required this.isDark,
    required this.onTap,
    required this.child,
    this.isClose = false,
  });

  @override
  State<_WindowButton> createState() => _WindowButtonState();
}

class _WindowButtonState extends State<_WindowButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final Color hoverBg = widget.isClose
        ? AppColors.error
        : (widget.isDark
              ? Colors.white.withValues(alpha: 0.12)
              : Colors.black.withValues(alpha: 0.08));

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: Container(
          width: 44,
          height: 40,
          color: _hovered ? hoverBg : Colors.transparent,
          alignment: Alignment.center,
          child: widget.child,
        ),
      ),
    );
  }
}
