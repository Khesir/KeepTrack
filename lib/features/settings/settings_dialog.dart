import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:keep_track/core/cache/local_cache.dart';
import 'package:keep_track/core/ui/app_toast.dart';
import 'package:keep_track/core/demo/demo_mode.dart';
import 'package:keep_track/core/di/service_locator.dart';
import 'package:keep_track/core/restart/app_restart_widget.dart';
import 'package:keep_track/features/finance/data/services/finance_initialization_service.dart';
import 'package:keep_track/core/settings/domain/entities/app_settings.dart';
import 'package:keep_track/core/settings/presentation/settings_controller.dart';
import 'package:keep_track/core/state/stream_builder_widget.dart';
import 'package:keep_track/core/state/stream_state.dart';
import 'package:keep_track/core/theme/app_theme.dart';
import 'package:keep_track/features/auth/domain/entities/user.dart';
import 'package:keep_track/core/network/api_client.dart';
import 'package:keep_track/features/auth/presentation/state/auth_controller.dart';
import 'package:keep_track/features/auth/presentation/widgets/login_dialog.dart';
import 'dart:io';
import 'package:intl/intl.dart';
import 'package:keep_track/core/settings/utils/currency_formatter.dart';
import 'package:keep_track/core/utils/transaction_image_service.dart';
import 'package:keep_track/features/finance/modules/budget/presentation/sheets/transaction_detail_sheet.dart';
import 'package:keep_track/features/finance/modules/transaction/domain/entities/transaction.dart';
import 'package:keep_track/features/finance/presentation/state/transaction_controller.dart';
import 'package:keep_track/core/services/notification/platform_notification_helper.dart';
import 'package:keep_track/features/notifications/presentation/screens/notification_settings_screen.dart';
import 'package:keep_track/features/settings/data/services/backup_service.dart';
import 'package:keep_track/features/settings/data/services/backup_sync_status.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';


enum _Section { profile, appearance, budget, subscription, data }

extension _SectionX on _Section {
  String get label => switch (this) {
        _Section.profile => 'My Profile',
        _Section.appearance => 'Appearance',
        _Section.budget => 'Budget',
        _Section.subscription => 'Subscription',
        _Section.data => 'Data',
      };

  IconData get icon => switch (this) {
        _Section.profile => Icons.person_outline_rounded,
        _Section.appearance => Icons.palette_outlined,
        _Section.budget => Icons.account_balance_wallet_outlined,
        _Section.subscription => Icons.star_outline_rounded,
        _Section.data => Icons.storage_outlined,
      };
}

class _Group {
  final String label;
  final List<_Section> sections;
  const _Group(this.label, this.sections);
}

const _groups = [
  _Group('account', [_Section.profile]),
  _Group('experience', [_Section.appearance, _Section.budget]),
  _Group('billing', [_Section.subscription]),
  _Group('activity', [_Section.data]),
];


class SettingsDialogContent extends StatefulWidget {
  const SettingsDialogContent({super.key});

  @override
  State<SettingsDialogContent> createState() => _SettingsDialogContentState();
}

class _SettingsDialogContentState extends State<SettingsDialogContent> {
  _Section _selected = _Section.profile;
  late final SettingsController _controller;
  late final AuthController _authController;

  @override
  void initState() {
    super.initState();
    _controller = locator.get<SettingsController>();
    _authController = locator.get<AuthController>();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final sidebarBg =
        isDark ? AppColors.void_ : const Color(0xFFEBE9E1);
    final contentBg = isDark ? const Color(0xFF242422) : Colors.white;
    final borderColor = isDark
        ? AppColors.border.withValues(alpha: 0.2)
        : AppColors.border.withValues(alpha: 0.5);

    return Row(
      children: [
        _Sidebar(
          selected: _selected,
          isDark: isDark,
          bg: sidebarBg,
          borderColor: borderColor,
          onSelect: (s) => setState(() => _selected = s),
        ),
        VerticalDivider(width: 1, color: borderColor),
        Expanded(
          child: Container(
            color: contentBg,
            child: Column(
              children: [
                _ContentHeader(title: _selected.label, isDark: isDark),
                Expanded(
                  child: AsyncStreamBuilder<AppSettings>(
                    state: _controller,
                    loadingBuilder: (_) =>
                        const Center(child: CircularProgressIndicator()),
                    errorBuilder: (_, msg) => Center(child: Text(msg)),
                    builder: (_, settings) => _ContentPane(
                      section: _selected,
                      settings: settings,
                      isDark: isDark,
                      controller: _controller,
                      authController: _authController,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}


class _Sidebar extends StatelessWidget {
  final _Section selected;
  final bool isDark;
  final Color bg;
  final Color borderColor;
  final void Function(_Section) onSelect;

  const _Sidebar({
    required this.selected,
    required this.isDark,
    required this.bg,
    required this.borderColor,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 220,
      color: bg,
      child: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(8, 16, 8, 8),
              children: [
                for (final group in _groups) ...[
                  Padding(
                    padding: const EdgeInsets.fromLTRB(8, 8, 8, 4),
                    child: Text(
                      group.label.toUpperCase(),
                      style: GoogleFonts.dmSans(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textSecondary,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ),
                  for (final section in group.sections)
                    _SidebarItem(
                      section: section,
                      selected: selected == section,
                      isDark: isDark,
                      onTap: () => onSelect(section),
                    ),
                  const SizedBox(height: 4),
                ],
              ],
            ),
          ),
          Divider(height: 1, color: borderColor),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: FutureBuilder<PackageInfo>(
              future: PackageInfo.fromPlatform(),
              builder: (_, snap) => Row(
                children: [
                  Text(
                    snap.hasData ? 'Keep Track v${snap.data!.version}' : 'Keep Track',
                    style: GoogleFonts.dmSans(
                      fontSize: 11,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SidebarItem extends StatefulWidget {
  final _Section section;
  final bool selected;
  final bool isDark;
  final VoidCallback onTap;

  const _SidebarItem({
    required this.section,
    required this.selected,
    required this.isDark,
    required this.onTap,
  });

  @override
  State<_SidebarItem> createState() => _SidebarItemState();
}

class _SidebarItemState extends State<_SidebarItem> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final selectedBg =
        AppColors.accent.withValues(alpha: widget.isDark ? 0.15 : 0.10);
    final hoverBg = widget.isDark
        ? Colors.white.withValues(alpha: 0.05)
        : Colors.black.withValues(alpha: 0.04);
    final iconColor =
        widget.selected ? AppColors.accent : AppColors.textSecondary;
    final textColor = widget.selected
        ? AppColors.accent
        : (widget.isDark ? AppColors.primaryForeground : AppColors.textPrimary);

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          height: 36,
          margin: const EdgeInsets.only(bottom: 1),
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            color: widget.selected
                ? selectedBg
                : (_hovered ? hoverBg : Colors.transparent),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Row(
            children: [
              Icon(widget.section.icon, size: 16, color: iconColor),
              const SizedBox(width: 10),
              Text(
                widget.section.label,
                style: GoogleFonts.dmSans(
                  fontSize: 13,
                  fontWeight: widget.selected ? FontWeight.w600 : FontWeight.w400,
                  color: textColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}


class _ContentHeader extends StatelessWidget {
  final String title;
  final bool isDark;

  const _ContentHeader({required this.title, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final borderColor = isDark
        ? AppColors.border.withValues(alpha: 0.2)
        : AppColors.border.withValues(alpha: 0.5);

    return Container(
      height: 52,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: borderColor, width: 0.5)),
      ),
      child: Row(
        children: [
          Text(
            title,
            style: AppTextStyles.h4.copyWith(
              color: isDark ? AppColors.primaryForeground : AppColors.textPrimary,
            ),
          ),
          const Spacer(),
          MouseRegion(
            cursor: SystemMouseCursors.click,
            child: GestureDetector(
              onTap: () => Navigator.of(context).pop(),
              child: Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.07)
                      : Colors.black.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(6),
                ),
                alignment: Alignment.center,
                child: Icon(
                  Icons.close_rounded,
                  size: 16,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}


class _ContentPane extends StatelessWidget {
  final _Section section;
  final AppSettings settings;
  final bool isDark;
  final SettingsController controller;
  final AuthController authController;

  const _ContentPane({
    required this.section,
    required this.settings,
    required this.isDark,
    required this.controller,
    required this.authController,
  });

  @override
  Widget build(BuildContext context) => switch (section) {
        _Section.profile =>
          _ProfilePane(isDark: isDark, authController: authController),
        _Section.appearance => _AppearancePane(
            isDark: isDark, settings: settings, controller: controller),
        _Section.budget =>
          _BudgetPane(isDark: isDark, settings: settings, controller: controller),
        _Section.subscription => _SubscriptionComingSoonPane(isDark: isDark),
        _Section.data => _DataPane(
            isDark: isDark,
            controller: controller,
            authController: authController),
      };
}


class _ProfilePane extends StatefulWidget {
  final bool isDark;
  final AuthController authController;

  const _ProfilePane({required this.isDark, required this.authController});

  @override
  State<_ProfilePane> createState() => _ProfilePaneState();
}

class _ProfilePaneState extends State<_ProfilePane> {
  final _nameCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();

  bool _nameExpanded = false;
  bool _nameLoading = false;
  String? _nameError;

  bool _passwordExpanded = false;
  bool _passwordLoading = false;
  bool _obscurePwd = true;
  bool _obscureConfirm = true;
  String? _passwordError;
  String? _passwordSuccess;

  @override
  void initState() {
    super.initState();
    _nameCtrl.text = widget.authController.currentUser?.displayName ?? '';
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _saveName() async {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) {
      setState(() => _nameError = 'Display name cannot be empty');
      return;
    }
    setState(() { _nameLoading = true; _nameError = null; });
    try {
      await ApiClient.instance.patch('/users/me', data: {'displayName': name});
      setState(() { _nameLoading = false; _nameExpanded = false; });
    } catch (e) {
      setState(() { _nameLoading = false; _nameError = 'Failed to update name'; });
    }
  }

  Future<void> _savePassword() async {
    final pwd = _passwordCtrl.text;
    if (pwd.isEmpty) {
      setState(() => _passwordError = 'Password cannot be empty');
      return;
    }
    if (pwd.length < 6) {
      setState(() => _passwordError = 'Password must be at least 6 characters');
      return;
    }
    if (pwd != _confirmCtrl.text) {
      setState(() => _passwordError = 'Passwords do not match');
      return;
    }
    setState(() { _passwordLoading = true; _passwordError = null; _passwordSuccess = null; });
    try {
      await ApiClient.instance.patch('/auth/password', data: {'password': pwd});
      _passwordCtrl.clear();
      _confirmCtrl.clear();
      setState(() {
        _passwordLoading = false;
        _passwordSuccess = 'Password updated';
        _passwordExpanded = false;
      });
    } catch (e) {
      setState(() { _passwordLoading = false; _passwordError = 'Failed to update password'; });
    }
  }

  String _initials(String? name, String email) {
    if (name != null && name.isNotEmpty) {
      final parts = name.trim().split(' ');
      if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
      return name[0].toUpperCase();
    }
    return email.isNotEmpty ? email[0].toUpperCase() : 'U';
  }

  String _formatDate(DateTime dt) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${months[dt.month - 1]} ${dt.day}, ${dt.year}';
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AsyncState<User?>>(
      stream: widget.authController.stream,
      initialData: widget.authController.state,
      builder: (_, snap) {
        final state = snap.data;
        final user = state is AsyncData<User?> ? state.data : widget.authController.currentUser;
        return user == null ? _buildUnauthenticated(context) : _buildContent(context, user);
      },
    );
  }

  Widget _buildContent(BuildContext context, User user) {
    final isDark = widget.isDark;
    final border = isDark ? AppColors.border.withValues(alpha: 0.2) : AppColors.border.withValues(alpha: 0.5);
    final cardBg = isDark ? AppColors.cardDark : AppColors.card;
    final initials = _initials(user.displayName, user.email);

    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppColors.accent, AppColors.accentDark],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            children: [
              Container(
                width: 60, height: 60,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.18),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.5), width: 2),
                ),
                alignment: Alignment.center,
                child: user.photoUrl != null
                    ? ClipOval(child: Image.network(user.photoUrl!, width: 60, height: 60, fit: BoxFit.cover))
                    : Text(initials, style: GoogleFonts.dmSans(fontSize: 22, fontWeight: FontWeight.w700, color: Colors.white)),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          user.displayName?.isNotEmpty == true ? user.displayName! : user.email.split('@').first,
                          style: GoogleFonts.dmSans(fontSize: 17, fontWeight: FontWeight.w700, color: Colors.white),
                        ),
                        if (user.isPlus) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(5),
                            ),
                            child: Text('PLUS', style: GoogleFonts.dmSans(fontSize: 9, fontWeight: FontWeight.w700, color: Colors.white, letterSpacing: 0.8)),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(user.email, style: GoogleFonts.dmSans(fontSize: 12, color: Colors.white.withValues(alpha: 0.75))),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        _PaneSectionLabel('Account Information'),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(color: cardBg, borderRadius: BorderRadius.circular(12), border: Border.all(color: border, width: 0.5)),
          child: Column(
            children: [
              _InfoField(label: 'Email address', value: user.email, isDark: isDark),
              Divider(height: 1, thickness: 0.5, indent: 16, endIndent: 16, color: border),
              _InfoField(label: 'Member since', value: _formatDate(user.createdAt), isDark: isDark),
            ],
          ),
        ),
        const SizedBox(height: 20),

        _PaneSectionLabel('Profile'),
        const SizedBox(height: 8),
        _InlineEditCard(
          isDark: isDark,
          label: 'Display name',
          value: user.displayName?.isNotEmpty == true ? user.displayName! : 'Not set',
          expanded: _nameExpanded,
          onToggle: () => setState(() { _nameExpanded = !_nameExpanded; _nameError = null; }),
          child: _nameExpanded ? _NameEditFields(
            controller: _nameCtrl,
            error: _nameError,
            loading: _nameLoading,
            isDark: isDark,
            onSave: _saveName,
            onCancel: () => setState(() { _nameExpanded = false; _nameError = null; }),
          ) : null,
        ),
        const SizedBox(height: 20),

        _PaneSectionLabel('Security'),
        const SizedBox(height: 8),
        _InlineEditCard(
          isDark: isDark,
          label: 'Password',
          value: _passwordSuccess ?? '••••••••',
          valueColor: _passwordSuccess != null ? AppColors.success : null,
          expanded: _passwordExpanded,
          onToggle: () => setState(() { _passwordExpanded = !_passwordExpanded; _passwordError = null; _passwordSuccess = null; }),
          child: _passwordExpanded ? _PasswordEditFields(
            passwordCtrl: _passwordCtrl,
            confirmCtrl: _confirmCtrl,
            obscurePwd: _obscurePwd,
            obscureConfirm: _obscureConfirm,
            onTogglePwd: () => setState(() => _obscurePwd = !_obscurePwd),
            onToggleConfirm: () => setState(() => _obscureConfirm = !_obscureConfirm),
            error: _passwordError,
            loading: _passwordLoading,
            isDark: isDark,
            onSave: _savePassword,
            onCancel: () => setState(() { _passwordExpanded = false; _passwordError = null; }),
          ) : null,
        ),
        const SizedBox(height: 20),

        if (PlatformNotificationHelper.instance.isSupportedPlatform) ...[
          _PaneSectionLabel('Notifications'),
          const SizedBox(height: 8),
          _PaneRow(
            isDark: isDark,
            icon: Icons.notifications_outlined,
            iconColor: AppColors.info,
            label: 'Push Notifications',
            subtitle: 'Reminders for tasks and finances',
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const NotificationSettingsScreen()),
            ),
          ),
          const SizedBox(height: 20),
        ],

        _PaneSectionLabel('Session'),
        const SizedBox(height: 8),
        _PaneRow(
          isDark: isDark,
          icon: Icons.logout_rounded,
          iconColor: AppColors.error,
          label: 'Sign Out',
          labelColor: AppColors.error,
          onTap: () => _confirmSignOut(context),
        ),
      ],
    );
  }

  Widget _buildUnauthenticated(BuildContext context) {
    final isDark = widget.isDark;
    final cardBg = isDark ? Colors.white.withValues(alpha: 0.04) : AppColors.backgroundSecondary;
    final borderColor = isDark ? AppColors.border.withValues(alpha: 0.15) : AppColors.border.withValues(alpha: 0.4);
    final fg = isDark ? AppColors.primaryForeground : AppColors.textPrimary;

    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Text('Account', style: GoogleFonts.dmSans(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textSecondary, letterSpacing: 0.3)),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: cardBg, borderRadius: BorderRadius.circular(10), border: Border.all(color: borderColor, width: 0.5)),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Your account', style: GoogleFonts.dmSans(fontSize: 14, fontWeight: FontWeight.w600, color: fg)),
                    const SizedBox(height: 4),
                    Text("You're not logged in. Sign in to sync your data across devices.",
                        style: GoogleFonts.dmSans(fontSize: 12, color: AppColors.textSecondary)),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Row(
                children: [
                  _OutlineButton(label: 'Log in', isDark: isDark, onTap: () => LoginDialog.show(context)),
                  const SizedBox(width: 8),
                  _OutlineButton(label: 'Sign up', isDark: isDark, onTap: () => LoginDialog.show(context, signUp: true), primary: true),
                ],
              ),
            ],
          ),
        ),
      ],
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
            onPressed: () async { Navigator.pop(context); await widget.authController.signOut(); },
            child: Text('Sign Out', style: TextStyle(color: AppColors.error, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
}


class _PaneSectionLabel extends StatelessWidget {
  final String text;
  const _PaneSectionLabel(this.text);

  @override
  Widget build(BuildContext context) => Text(
        text.toUpperCase(),
        style: GoogleFonts.dmSans(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.textSecondary, letterSpacing: 1.0),
      );
}

class _InfoField extends StatelessWidget {
  final String label;
  final String value;
  final bool isDark;
  const _InfoField({required this.label, required this.value, required this.isDark});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label.toUpperCase(), style: GoogleFonts.dmSans(fontSize: 10, fontWeight: FontWeight.w600, color: AppColors.textSecondary, letterSpacing: 0.6)),
            const SizedBox(height: 4),
            Text(value, style: GoogleFonts.dmSans(fontSize: 13, fontWeight: FontWeight.w500, color: isDark ? AppColors.primaryForeground : AppColors.textPrimary)),
          ],
        ),
      );
}

class _InlineEditCard extends StatelessWidget {
  final bool isDark;
  final String label;
  final String value;
  final Color? valueColor;
  final bool expanded;
  final VoidCallback onToggle;
  final Widget? child;

  const _InlineEditCard({
    required this.isDark,
    required this.label,
    required this.value,
    required this.expanded,
    required this.onToggle,
    this.valueColor,
    this.child,
  });

  @override
  Widget build(BuildContext context) {
    final bg = isDark ? AppColors.cardDark : AppColors.card;
    final border = isDark ? AppColors.border.withValues(alpha: 0.2) : AppColors.border.withValues(alpha: 0.5);

    return Container(
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(12), border: Border.all(color: border, width: 0.5)),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 12, 12),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(label.toUpperCase(), style: GoogleFonts.dmSans(fontSize: 10, fontWeight: FontWeight.w600, color: AppColors.textSecondary, letterSpacing: 0.6)),
                      const SizedBox(height: 4),
                      Text(value, style: GoogleFonts.dmSans(fontSize: 13, fontWeight: FontWeight.w500,
                          color: valueColor ?? (isDark ? AppColors.primaryForeground : AppColors.textPrimary))),
                    ],
                  ),
                ),
                MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: GestureDetector(
                    onTap: onToggle,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: isDark ? Colors.white.withValues(alpha: 0.07) : AppColors.background,
                        borderRadius: BorderRadius.circular(7),
                        border: Border.all(color: border),
                      ),
                      child: Text(
                        expanded ? 'Cancel' : 'Edit',
                        style: GoogleFonts.dmSans(fontSize: 12, fontWeight: FontWeight.w600,
                            color: expanded ? AppColors.textSecondary : AppColors.accent),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (child != null) ...[
            Divider(height: 1, thickness: 0.5, color: border),
            child!,
          ],
        ],
      ),
    );
  }
}

class _NameEditFields extends StatelessWidget {
  final TextEditingController controller;
  final String? error;
  final bool loading;
  final bool isDark;
  final VoidCallback onSave;
  final VoidCallback onCancel;

  const _NameEditFields({required this.controller, required this.error, required this.loading, required this.isDark, required this.onSave, required this.onCancel});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _ProfileTextField(controller: controller, label: 'New display name', isDark: isDark, error: error),
          const SizedBox(height: 12),
          _ProfileFormActions(loading: loading, onSave: onSave, onCancel: onCancel, isDark: isDark),
        ],
      ),
    );
  }
}

class _PasswordEditFields extends StatelessWidget {
  final TextEditingController passwordCtrl;
  final TextEditingController confirmCtrl;
  final bool obscurePwd;
  final bool obscureConfirm;
  final VoidCallback onTogglePwd;
  final VoidCallback onToggleConfirm;
  final String? error;
  final bool loading;
  final bool isDark;
  final VoidCallback onSave;
  final VoidCallback onCancel;

  const _PasswordEditFields({
    required this.passwordCtrl, required this.confirmCtrl,
    required this.obscurePwd, required this.obscureConfirm,
    required this.onTogglePwd, required this.onToggleConfirm,
    required this.error, required this.loading, required this.isDark,
    required this.onSave, required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _ProfileTextField(controller: passwordCtrl, label: 'New password', obscure: obscurePwd, onToggleObscure: onTogglePwd, isDark: isDark, error: error),
          const SizedBox(height: 10),
          _ProfileTextField(controller: confirmCtrl, label: 'Confirm new password', obscure: obscureConfirm, onToggleObscure: onToggleConfirm, isDark: isDark),
          const SizedBox(height: 12),
          _ProfileFormActions(loading: loading, onSave: onSave, onCancel: onCancel, isDark: isDark),
        ],
      ),
    );
  }
}

class _ProfileTextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final bool obscure;
  final VoidCallback? onToggleObscure;
  final String? error;
  final bool isDark;

  const _ProfileTextField({required this.controller, required this.label, required this.isDark, this.obscure = false, this.onToggleObscure, this.error});

  @override
  Widget build(BuildContext context) {
    final border = isDark ? AppColors.border.withValues(alpha: 0.3) : AppColors.border;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: controller,
          obscureText: obscure,
          style: GoogleFonts.dmSans(fontSize: 13, color: isDark ? AppColors.primaryForeground : AppColors.textPrimary),
          decoration: InputDecoration(
            labelText: label,
            labelStyle: GoogleFonts.dmSans(fontSize: 12, color: AppColors.textSecondary),
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            filled: true,
            fillColor: isDark ? Colors.white.withValues(alpha: 0.05) : AppColors.background,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: border)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: border, width: 0.5)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppColors.accent, width: 1.5)),
            suffixIcon: onToggleObscure != null
                ? IconButton(icon: Icon(obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined, size: 15, color: AppColors.textSecondary), onPressed: onToggleObscure)
                : null,
          ),
        ),
        if (error != null) ...[
          const SizedBox(height: 5),
          Text(error!, style: GoogleFonts.dmSans(fontSize: 11, color: AppColors.error)),
        ],
      ],
    );
  }
}

class _ProfileFormActions extends StatelessWidget {
  final bool loading;
  final VoidCallback onSave;
  final VoidCallback onCancel;
  final bool isDark;

  const _ProfileFormActions({required this.loading, required this.onSave, required this.onCancel, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: onCancel,
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.textSecondary,
              side: BorderSide(color: isDark ? AppColors.border.withValues(alpha: 0.3) : AppColors.border),
              padding: const EdgeInsets.symmetric(vertical: 10),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: Text('Cancel', style: GoogleFonts.dmSans(fontSize: 12, fontWeight: FontWeight.w500)),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: FilledButton(
            onPressed: loading ? null : onSave,
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.accent,
              padding: const EdgeInsets.symmetric(vertical: 10),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: loading
                ? const SizedBox(height: 14, width: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : Text('Save changes', style: GoogleFonts.dmSans(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white)),
          ),
        ),
      ],
    );
  }
}


class _OutlineButton extends StatefulWidget {
  final String label;
  final bool isDark;
  final bool primary;
  final VoidCallback onTap;

  const _OutlineButton({
    required this.label,
    required this.isDark,
    required this.onTap,
    this.primary = false,
  });

  @override
  State<_OutlineButton> createState() => _OutlineButtonState();
}

class _OutlineButtonState extends State<_OutlineButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final bg = widget.primary
        ? AppColors.accent
        : (widget.isDark
            ? Colors.white.withValues(alpha: _hovered ? 0.1 : 0.06)
            : AppColors.textPrimary.withValues(alpha: _hovered ? 0.08 : 0.05));
    final fg = widget.primary ? Colors.white : (widget.isDark ? AppColors.primaryForeground : AppColors.textPrimary);

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 100),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            widget.label,
            style: GoogleFonts.dmSans(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: fg,
            ),
          ),
        ),
      ),
    );
  }
}


class _AppearancePane extends StatefulWidget {
  final bool isDark;
  final AppSettings settings;
  final SettingsController controller;

  const _AppearancePane({
    required this.isDark,
    required this.settings,
    required this.controller,
  });

  @override
  State<_AppearancePane> createState() => _AppearancePaneState();
}

class _AppearancePaneState extends State<_AppearancePane> {
  String _search = '';

  @override
  Widget build(BuildContext context) {
    final filtered = AppCurrency.values
        .where((c) =>
            c.displayName.toLowerCase().contains(_search.toLowerCase()) ||
            c.code.toLowerCase().contains(_search.toLowerCase()))
        .toList();
    final borderColor = widget.isDark
        ? AppColors.border.withValues(alpha: 0.15)
        : AppColors.border.withValues(alpha: 0.4);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _PaneLabel('Theme'),
        ...AppThemeMode.values.map((mode) => _ThemeOptionRow(
              mode: mode,
              selected: widget.settings.themeMode == mode,
              isDark: widget.isDark,
              onTap: () => widget.controller.updateThemeMode(mode),
            )),
        Divider(height: 24, indent: 24, endIndent: 24, color: borderColor),
        _PaneLabel('Currency'),
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 4, 24, 8),
          child: TextField(
            onChanged: (v) => setState(() => _search = v),
            style: GoogleFonts.dmSans(fontSize: 13),
            decoration: InputDecoration(
              hintText: 'Search currency…',
              hintStyle: GoogleFonts.dmSans(
                fontSize: 13,
                color: AppColors.textSecondary,
              ),
              prefixIcon: const Icon(Icons.search_rounded, size: 16),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 10,
              ),
              isDense: true,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: borderColor),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: borderColor),
              ),
            ),
          ),
        ),
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
            itemCount: filtered.length,
            separatorBuilder: (_, __) =>
                Divider(height: 1, color: borderColor),
            itemBuilder: (_, i) {
              final c = filtered[i];
              final isSel = c == widget.settings.currency;
              return MouseRegion(
                cursor: SystemMouseCursors.click,
                child: GestureDetector(
                  onTap: () => widget.controller.updateCurrency(c),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    child: Row(
                      children: [
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color:
                                AppColors.success.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            c.symbol,
                            style: GoogleFonts.dmMono(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppColors.success,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            c.displayName,
                            style: GoogleFonts.dmSans(
                              fontSize: 13,
                              fontWeight: isSel
                                  ? FontWeight.w600
                                  : FontWeight.w400,
                              color: isSel
                                  ? AppColors.accent
                                  : (widget.isDark
                                        ? AppColors.primaryForeground
                                        : AppColors.textPrimary),
                            ),
                          ),
                        ),
                        Text(
                          c.code,
                          style: GoogleFonts.dmSans(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        if (isSel) ...[
                          const SizedBox(width: 8),
                          Icon(Icons.check_rounded,
                              size: 16, color: AppColors.accent),
                        ],
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _ThemeOptionRow extends StatefulWidget {
  final AppThemeMode mode;
  final bool selected;
  final bool isDark;
  final VoidCallback onTap;

  const _ThemeOptionRow({
    required this.mode,
    required this.selected,
    required this.isDark,
    required this.onTap,
  });

  @override
  State<_ThemeOptionRow> createState() => _ThemeOptionRowState();
}

class _ThemeOptionRowState extends State<_ThemeOptionRow> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final fg =
        widget.isDark ? AppColors.primaryForeground : AppColors.textPrimary;
    final hoverBg = widget.isDark
        ? Colors.white.withValues(alpha: 0.04)
        : Colors.black.withValues(alpha: 0.03);

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: Container(
          color: _hovered ? hoverBg : Colors.transparent,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
          child: Row(
            children: [
              Icon(widget.mode.icon, size: 18, color: AppColors.textSecondary),
              const SizedBox(width: 14),
              Text(
                widget.mode.displayName,
                style: GoogleFonts.dmSans(fontSize: 14, color: fg),
              ),
              const Spacer(),
              if (widget.selected)
                Icon(Icons.check_rounded, size: 18, color: AppColors.accent),
            ],
          ),
        ),
      ),
    );
  }
}


class _BudgetPane extends StatefulWidget {
  final bool isDark;
  final AppSettings settings;
  final SettingsController controller;

  const _BudgetPane({
    required this.isDark,
    required this.settings,
    required this.controller,
  });

  @override
  State<_BudgetPane> createState() => _BudgetPaneState();
}

class _BudgetPaneState extends State<_BudgetPane> {
  bool _showGallery = false;

  @override
  Widget build(BuildContext context) {
    return _showGallery
        ? _GalleryPane(
            isDark: widget.isDark,
            onBack: () => setState(() => _showGallery = false),
          )
        : ListView(
            padding: const EdgeInsets.all(24),
            children: [
              _PaneRow(
                isDark: widget.isDark,
                icon: widget.settings.budgetSheetMode
                    ? Icons.table_rows_outlined
                    : Icons.view_stream_outlined,
                iconColor: AppColors.info,
                label: 'Budget View',
                subtitle: widget.settings.budgetSheetMode
                    ? 'Sheet mode – full budget sheet'
                    : 'Simple mode – overview with tabs',
                trailing: Switch(
                  value: widget.settings.budgetSheetMode,
                  onChanged: widget.controller.updateBudgetSheetMode,
                  activeThumbColor: AppColors.accent,
                ),
              ),
              _PaneRow(
                isDark: widget.isDark,
                icon: Icons.photo_library_outlined,
                iconColor: AppColors.accent,
                label: 'Attachment Gallery',
                subtitle: 'Browse all transaction receipt photos',
                onTap: () => setState(() => _showGallery = true),
              ),
            ],
          );
  }
}

class _GalleryPane extends StatefulWidget {
  final bool isDark;
  final VoidCallback onBack;

  const _GalleryPane({required this.isDark, required this.onBack});

  @override
  State<_GalleryPane> createState() => _GalleryPaneState();
}

class _GalleryPaneState extends State<_GalleryPane> {
  late final TransactionController _controller;

  @override
  void initState() {
    super.initState();
    _controller = locator.get<TransactionController>();
    if (_controller.data == null) _controller.loadAllTransactions();
  }

  List<({Transaction transaction, String path})> _buildEntries(
    List<Transaction> transactions,
  ) {
    final entries = <({Transaction transaction, String path})>[];
    for (final tx in transactions) {
      for (final path in tx.imagePaths) {
        if (TransactionImageService.fileExists(path)) {
          entries.add((transaction: tx, path: path));
        }
      }
    }
    entries.sort((a, b) => b.transaction.date.compareTo(a.transaction.date));
    return entries;
  }

  void _openViewer(String path) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.85),
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: EdgeInsets.zero,
        child: Stack(
          children: [
            SizedBox(
              width: double.infinity,
              height: double.infinity,
              child: InteractiveViewer(
                child: Image.file(File(path), fit: BoxFit.contain, width: double.infinity),
              ),
            ),
            Positioned(
              top: 48,
              right: 16,
              child: GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.5),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.close_rounded, color: Colors.white, size: 18),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final fg = widget.isDark ? AppColors.primaryForeground : AppColors.textPrimary;
    final borderColor = widget.isDark
        ? AppColors.border.withValues(alpha: 0.2)
        : AppColors.border.withValues(alpha: 0.4);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Row(
            children: [
              MouseRegion(
                cursor: SystemMouseCursors.click,
                child: GestureDetector(
                  onTap: widget.onBack,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.arrow_back_ios_rounded, size: 14, color: AppColors.textSecondary),
                      const SizedBox(width: 4),
                      Text(
                        'Budget',
                        style: GoogleFonts.dmSans(fontSize: 13, color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Icon(Icons.chevron_right_rounded, size: 14, color: AppColors.textTertiary),
              const SizedBox(width: 4),
              Text(
                'Attachment Gallery',
                style: GoogleFonts.dmSans(fontSize: 13, fontWeight: FontWeight.w600, color: fg),
              ),
            ],
          ),
        ),
        Divider(height: 1, color: borderColor),
        Expanded(
          child: AsyncStreamBuilder<List<Transaction>>(
            state: _controller,
            loadingBuilder: (_) => const Center(child: CircularProgressIndicator()),
            errorBuilder: (_, msg) => Center(
              child: Text(msg, style: GoogleFonts.dmSans(fontSize: 13, color: AppColors.textSecondary)),
            ),
            builder: (context, transactions) {
              final entries = _buildEntries(transactions);
              if (entries.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.photo_library_outlined, size: 40, color: AppColors.textTertiary),
                      const SizedBox(height: 10),
                      Text(
                        'No attachments yet',
                        style: GoogleFonts.dmSans(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.textSecondary),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Add images when creating a transaction',
                        style: GoogleFonts.dmSans(fontSize: 12, color: AppColors.textTertiary),
                      ),
                    ],
                  ),
                );
              }
              return GridView.builder(
                padding: const EdgeInsets.all(4),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: 3,
                  mainAxisSpacing: 3,
                ),
                itemCount: entries.length,
                itemBuilder: (context, index) {
                  final entry = entries[index];
                  final tx = entry.transaction;
                  final isIncome = tx.type == TransactionType.income;
                  final isTransfer = tx.type == TransactionType.transfer;
                  final amountColor = isTransfer
                      ? AppColors.info
                      : (isIncome ? AppColors.success : AppColors.error);
                  final sign = isTransfer ? '↔' : (isIncome ? '+' : '-');
                  return MouseRegion(
                    cursor: SystemMouseCursors.click,
                    child: GestureDetector(
                      onTap: () => _openViewer(entry.path),
                      onSecondaryTap: () => TransactionDetailSheet.show(context, transaction: tx),
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          Image.file(File(entry.path), fit: BoxFit.cover),
                          Positioned(
                            left: 0,
                            right: 0,
                            bottom: 0,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 5),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.bottomCenter,
                                  end: Alignment.topCenter,
                                  colors: [
                                    Colors.black.withValues(alpha: 0.65),
                                    Colors.transparent,
                                  ],
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    tx.description ?? DateFormat('MMM d').format(tx.date),
                                    style: GoogleFonts.dmSans(fontSize: 10, fontWeight: FontWeight.w500, color: Colors.white),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  Text(
                                    '$sign${currencyFormatter.format(tx.amount)}',
                                    style: GoogleFonts.dmMono(fontSize: 10, fontWeight: FontWeight.w700, color: amountColor),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}


class _SubscriptionComingSoonPane extends StatelessWidget {
  final bool isDark;
  const _SubscriptionComingSoonPane({required this.isDark});

  @override
  Widget build(BuildContext context) {
    final fg = isDark ? AppColors.primaryForeground : AppColors.textPrimary;
    final cardBg = isDark
        ? Colors.white.withValues(alpha: 0.04)
        : AppColors.backgroundSecondary;
    final borderColor = isDark
        ? AppColors.border.withValues(alpha: 0.15)
        : AppColors.border.withValues(alpha: 0.4);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: AppColors.accent.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: AppColors.accent.withValues(alpha: 0.2),
                  width: 0.5,
                ),
              ),
              alignment: Alignment.center,
              child: Icon(Icons.star_outline_rounded, size: 26, color: AppColors.accent),
            ),
            const SizedBox(height: 16),
            Text(
              'Keep Track Plus',
              style: GoogleFonts.dmSans(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: fg,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Coming soon – cloud sync, AI insights,\nand more. Stay tuned.',
              style: GoogleFonts.dmSans(
                fontSize: 13,
                color: AppColors.textSecondary,
                height: 1.6,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: borderColor, width: 0.5),
              ),
              child: Text(
                'You\'re on the free plan – all features unlocked.',
                style: GoogleFonts.dmSans(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DataPane extends StatefulWidget {
  final bool isDark;
  final SettingsController controller;
  final AuthController authController;

  const _DataPane({
    required this.isDark,
    required this.controller,
    required this.authController,
  });

  @override
  State<_DataPane> createState() => _DataPaneState();
}

class _DataPaneState extends State<_DataPane> {
  DateTime? _lastSyncedAt;

  @override
  void initState() {
    super.initState();
    _loadLastSyncedAt();
  }

  Future<void> _loadLastSyncedAt() async {
    final ts = await BackupService(
      cache: locator.get<LocalCache>(),
      encryption: BackupEncryptionService(),
      remote: BackupRemoteDatasource(),
    ).fetchLastSyncedAt();
    if (mounted) setState(() => _lastSyncedAt = ts);
    if (ts != null) BackupSyncStatus.instance.update(ts);
  }

  String get _lastSyncedSubtitle {
    if (_lastSyncedAt == null) return 'No cloud backup yet';
    final local = _lastSyncedAt!.toLocal();
    final now = DateTime.now();
    final diff = now.difference(local);
    if (diff.inSeconds < 60) return 'Last synced: just now';
    if (diff.inHours < 1) return 'Last synced: ${diff.inMinutes}m ago';
    if (diff.inDays < 1) return 'Last synced: ${diff.inHours}h ago';
    final day = '${local.day} ${_month(local.month)} ${local.year}';
    return 'Last synced: $day';
  }

  String _month(int m) => const [
    '', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ][m];

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
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        _PaneLabel('Demo', leftPadding: 0),
        _PaneRow(
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
        _PaneLabel('Backup & Restore', leftPadding: 0),
        _PaneRow(
          isDark: widget.isDark,
          icon: Icons.file_download_outlined,
          iconColor: AppColors.success,
          label: 'Export to File',
          subtitle: 'Save an encrypted backup to your device',
          onTap: () => _exportToFile(context),
        ),
        _PaneRow(
          isDark: widget.isDark,
          icon: Icons.file_upload_outlined,
          iconColor: AppColors.info,
          label: 'Import from File',
          subtitle: 'Restore data from an encrypted backup file',
          onTap: () => _importFromFile(context),
        ),
        if (widget.authController.isEffectivelyPlus) ...[
          _PaneRow(
            isDark: widget.isDark,
            icon: Icons.cloud_upload_outlined,
            iconColor: AppColors.accent,
            label: 'Sync to Cloud',
            subtitle: _lastSyncedSubtitle,
            onTap: () => _syncToCloud(context),
          ),
          _PaneRow(
            isDark: widget.isDark,
            icon: Icons.cloud_download_outlined,
            iconColor: AppColors.accent,
            label: 'Restore from Cloud',
            subtitle: _lastSyncedSubtitle,
            onTap: () => _restoreFromCloud(context),
          ),
        ],
        _PaneLabel('Danger Zone', leftPadding: 0),
        _PaneRow(
          isDark: widget.isDark,
          icon: Icons.restore_rounded,
          iconColor: AppColors.warning,
          label: 'Reset to Defaults',
          subtitle: 'Restore all settings to their original values',
          onTap: () => _confirmReset(context),
        ),
        _PaneRow(
          isDark: widget.isDark,
          icon: Icons.delete_forever_rounded,
          iconColor: AppColors.error,
          label: 'Wipe All Data',
          labelColor: AppColors.error,
          subtitle: 'Delete all financial data and restore defaults',
          onTap: () => _confirmWipe(context),
        ),
      ],
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

  String _backupErrorMessage(Object e) => switch (e) {
    WrongPasswordException() => 'Wrong password – backup could not be decrypted.',
    InvalidBackupException() => 'Invalid backup file. Select a valid .ktbak file.',
    _ => 'Something went wrong: $e',
  };

  Future<void> _exportToFile(BuildContext context) async {
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
      toast.error(_backupErrorMessage(e));
    }
  }

  Future<void> _syncToCloud(BuildContext context) async {
    final password = await _showPasswordDialog(context, confirm: true);
    if (password == null || !context.mounted) return;
    final toast = CapturedAppToast.capture(context);
    final dismiss = toast.loading('Syncing to cloud…');
    try {
      await _buildBackupService().syncToCloud(password);
      dismiss();
      toast.success('Backup synced to cloud');
      final now = DateTime.now();
      if (mounted) setState(() => _lastSyncedAt = now);
      BackupSyncStatus.instance.update(now);
    } catch (e) {
      dismiss();
      toast.error(_backupErrorMessage(e));
    }
  }

  Future<void> _importFromFile(BuildContext context) async {
    final confirmed = await _showConfirmReplaceDialog(context);
    if (!confirmed || !context.mounted) return;
    final password = await _showPasswordDialog(context, confirm: false);
    if (password == null || !context.mounted) return;

    final toast = CapturedAppToast.capture(context);
    final service = _buildBackupService();
    final dismiss = toast.loading('Importing backup…');

    try {
      final bytes = await service.pickBackupFile();
      if (bytes == null) {
        dismiss();
        return;
      }
      await service.restoreFromBytes(bytes, password);
      dismiss();
      toast.success('Backup imported successfully');
      await Future.delayed(const Duration(milliseconds: 1500));
      if (mounted) AppRestartWidget.of(context).restart();
    } catch (e) {
      dismiss();
      toast.error(_backupErrorMessage(e));
    }
  }

  Future<void> _restoreFromCloud(BuildContext context) async {
    final confirmed = await _showConfirmReplaceDialog(context);
    if (!confirmed || !context.mounted) return;
    final password = await _showPasswordDialog(context, confirm: false);
    if (password == null || !context.mounted) return;

    final toast = CapturedAppToast.capture(context);
    final dismiss = toast.loading('Restoring from cloud…');

    try {
      await _buildBackupService().restoreFromCloud(password);
      dismiss();
      toast.success('Backup restored successfully');
      await Future.delayed(const Duration(milliseconds: 1500));
      if (mounted) AppRestartWidget.of(context).restart();
    } catch (e) {
      dismiss();
      toast.error(_backupErrorMessage(e));
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
    if (context.mounted) AppRestartWidget.of(context).restart();
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
        content: Text(
          'All settings will return to defaults. This cannot be undone.',
          style: AppTextStyles.bodySmall,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              widget.controller.resetToDefaults();
              Navigator.pop(context);
            },
            style:
                FilledButton.styleFrom(backgroundColor: AppColors.warning),
            child: const Text('Reset'),
          ),
        ],
      ),
    );
  }
}


class _PaneLabel extends StatelessWidget {
  final String text;
  final double leftPadding;
  const _PaneLabel(this.text, {this.leftPadding = 24});

  @override
  Widget build(BuildContext context) => Padding(
        padding: EdgeInsets.fromLTRB(leftPadding, 16, 24, 4),
        child: Text(
          text.toUpperCase(),
          style: GoogleFonts.dmSans(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            color: AppColors.textSecondary,
            letterSpacing: 0.8,
          ),
        ),
      );
}

class _PaneRow extends StatefulWidget {
  final bool isDark;
  final IconData icon;
  final Color iconColor;
  final String label;
  final String? subtitle;
  final Color? labelColor;
  final VoidCallback? onTap;
  final Widget? trailing;

  const _PaneRow({
    required this.isDark,
    required this.icon,
    required this.iconColor,
    required this.label,
    this.subtitle,
    this.labelColor,
    this.onTap,
    this.trailing,
  });

  @override
  State<_PaneRow> createState() => _PaneRowState();
}

class _PaneRowState extends State<_PaneRow> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final fg =
        widget.isDark ? AppColors.primaryForeground : AppColors.textPrimary;
    final hoverBg = widget.isDark
        ? Colors.white.withValues(alpha: 0.04)
        : Colors.black.withValues(alpha: 0.03);

    return MouseRegion(
      cursor: widget.onTap != null
          ? SystemMouseCursors.click
          : SystemMouseCursors.basic,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 100),
          padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 12),
          decoration: BoxDecoration(
            color: _hovered && widget.onTap != null
                ? hoverBg
                : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: widget.iconColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(9),
                ),
                alignment: Alignment.center,
                child: Icon(widget.icon, size: 17, color: widget.iconColor),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.label,
                      style: GoogleFonts.dmSans(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: widget.labelColor ?? fg,
                      ),
                    ),
                    if (widget.subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        widget.subtitle!,
                        style: GoogleFonts.dmSans(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (widget.trailing != null)
                widget.trailing!
              else if (widget.onTap != null)
                Icon(
                  Icons.chevron_right_rounded,
                  size: 18,
                  color: AppColors.textTertiary,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
