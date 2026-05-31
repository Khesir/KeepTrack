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
import 'package:keep_track/features/auth/presentation/screens/auth_settings_screen.dart';
import 'package:keep_track/features/auth/presentation/state/auth_controller.dart';
import 'package:keep_track/features/auth/presentation/widgets/login_dialog.dart';
import 'package:keep_track/core/navigation/app_navigator.dart';
import 'package:keep_track/core/routing/app_router.dart';
import 'package:keep_track/features/settings/data/services/backup_service.dart';
import 'package:keep_track/features/settings/data/services/backup_sync_status.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ─── Section model ────────────────────────────────────────────────────────────

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

// ─── Root widget ──────────────────────────────────────────────────────────────

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
        isDark ? const Color(0xFF1E1E1C) : const Color(0xFFEBE9E1);
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

// ─── Sidebar ──────────────────────────────────────────────────────────────────

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

// ─── Content header ───────────────────────────────────────────────────────────

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

// ─── Content pane router ──────────────────────────────────────────────────────

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
        _Section.subscription => _SubscriptionPane(isDark: isDark),
        _Section.data => _DataPane(
            isDark: isDark,
            controller: controller,
            authController: authController),
      };
}

// ─── Profile pane ─────────────────────────────────────────────────────────────

class _ProfilePane extends StatelessWidget {
  final bool isDark;
  final AuthController authController;

  const _ProfilePane({required this.isDark, required this.authController});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AsyncState<User?>>(
      stream: authController.stream,
      initialData: authController.state,
      builder: (_, snap) {
        final state = snap.data;
        final user = state is AsyncData<User?> ? state.data : authController.currentUser;
        return _buildContent(context, user);
      },
    );
  }

  Widget _buildContent(BuildContext context, User? user) {
    if (user == null) return _buildUnauthenticated(context);

    final fg = isDark ? AppColors.primaryForeground : AppColors.textPrimary;
    final initials = _initials(user.displayName);

    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Row(
          children: [
            user.photoUrl != null
                ? CircleAvatar(
                    radius: 36,
                    backgroundImage: NetworkImage(user.photoUrl!),
                  )
                : Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [AppColors.accent, AppColors.accentDark],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      initials,
                      style: GoogleFonts.dmSans(
                        fontSize: 26,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user.displayName?.isNotEmpty == true
                        ? user.displayName!
                        : 'No name set',
                    style: GoogleFonts.dmSans(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: fg,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    user.email,
                    style: GoogleFonts.dmSans(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 28),
        _PaneRow(
          isDark: isDark,
          icon: Icons.manage_accounts_outlined,
          iconColor: AppColors.accent,
          label: 'Manage Account',
          subtitle: 'Authentication & profile',
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const AuthSettingsScreen()),
          ),
        ),
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
    final cardBg = isDark
        ? Colors.white.withValues(alpha: 0.04)
        : AppColors.backgroundSecondary;
    final borderColor = isDark
        ? AppColors.border.withValues(alpha: 0.15)
        : AppColors.border.withValues(alpha: 0.4);
    final fg = isDark ? AppColors.primaryForeground : AppColors.textPrimary;

    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Text(
          'Account',
          style: GoogleFonts.dmSans(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondary,
            letterSpacing: 0.3,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: borderColor, width: 0.5),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Your account',
                      style: GoogleFonts.dmSans(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: fg,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "You're not logged in. Sign in to sync your data across devices.",
                      style: GoogleFonts.dmSans(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Row(
                children: [
                  _OutlineButton(
                    label: 'Log in',
                    isDark: isDark,
                    onTap: () => LoginDialog.show(context),
                  ),
                  const SizedBox(width: 8),
                  _OutlineButton(
                    label: 'Sign up',
                    isDark: isDark,
                    onTap: () => LoginDialog.show(context, signUp: true),
                    primary: true,
                  ),
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
              await authController.signOut();
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

  String _initials(String? name) {
    if (name == null || name.isEmpty) return 'U';
    final parts = name.trim().split(' ');
    if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    return name[0].toUpperCase();
  }
}

// ─── Outline button for unauthenticated account pane ─────────────────────────

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

// ─── Appearance pane ──────────────────────────────────────────────────────────

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

// ─── Budget pane ──────────────────────────────────────────────────────────────

class _BudgetPane extends StatelessWidget {
  final bool isDark;
  final AppSettings settings;
  final SettingsController controller;

  const _BudgetPane({
    required this.isDark,
    required this.settings,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        _PaneRow(
          isDark: isDark,
          icon: settings.budgetSheetMode
              ? Icons.table_rows_outlined
              : Icons.view_stream_outlined,
          iconColor: AppColors.info,
          label: 'Budget View',
          subtitle: settings.budgetSheetMode
              ? 'Sheet mode — full budget sheet'
              : 'Simple mode — overview with tabs',
          trailing: Switch(
            value: settings.budgetSheetMode,
            onChanged: controller.updateBudgetSheetMode,
            activeThumbColor: AppColors.accent,
          ),
        ),
      ],
    );
  }
}

// ─── Subscription pane ────────────────────────────────────────────────────────

class _SubscriptionPane extends StatelessWidget {
  final bool isDark;

  const _SubscriptionPane({required this.isDark});

  @override
  Widget build(BuildContext context) {
    final fg = isDark ? AppColors.primaryForeground : AppColors.textPrimary;

    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppColors.accent.withValues(alpha: 0.12),
                AppColors.accentDark.withValues(alpha: 0.06),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppColors.accent.withValues(alpha: 0.2),
              width: 0.5,
            ),
          ),
          child: Row(
            children: [
              Icon(Icons.star_rounded, color: AppColors.accent, size: 28),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Keep Track Free',
                      style: GoogleFonts.dmSans(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: fg,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'You\'re on the free plan.',
                      style: GoogleFonts.dmSans(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'Pro features coming soon.',
          style: GoogleFonts.dmSans(
            fontSize: 13,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}

// ─── Data pane ────────────────────────────────────────────────────────────────

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
              ? 'Using sample data — toggle to connect your account'
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
          icon: Icons.cloud_upload_outlined,
          iconColor: AppColors.accent,
          label: 'Sync to Cloud',
          subtitle: _lastSyncedSubtitle,
          onTap: () => _syncToCloud(context),
        ),
        _PaneRow(
          isDark: widget.isDark,
          icon: Icons.file_upload_outlined,
          iconColor: AppColors.info,
          label: 'Import from File',
          subtitle: 'Restore data from an encrypted backup file',
          onTap: () => _importFromFile(context),
        ),
        _PaneRow(
          isDark: widget.isDark,
          icon: Icons.cloud_download_outlined,
          iconColor: AppColors.info,
          label: 'Restore from Cloud',
          subtitle: _lastSyncedSubtitle,
          onTap: () => _restoreFromCloud(context),
        ),
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
    WrongPasswordException() => 'Wrong password — backup could not be decrypted.',
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
      _goToDashboard();
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
      _goToDashboard();
    } catch (e) {
      dismiss();
      toast.error(_backupErrorMessage(e));
    }
  }

  void _goToDashboard() {
    AppNavigator.key.currentState?.pushNamedAndRemoveUntil(
      AppRoutes.financeModule,
      (_) => false,
    );
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

// ─── Shared pane widgets ──────────────────────────────────────────────────────

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
