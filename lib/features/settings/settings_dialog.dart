import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:keep_track/core/di/service_locator.dart';
import 'package:keep_track/core/settings/domain/entities/app_settings.dart';
import 'package:keep_track/core/settings/presentation/settings_controller.dart';
import 'package:keep_track/core/state/stream_builder_widget.dart';
import 'package:keep_track/core/theme/app_theme.dart';
import 'package:keep_track/features/auth/presentation/state/auth_controller.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'domain/controllers/settings_data_controller.dart';
import 'presentation/sections/appearance_settings_section.dart';
import 'presentation/sections/budget_settings_section.dart';
import 'presentation/sections/data_settings_section.dart';
import 'presentation/sections/notifications_settings_section.dart';
import 'presentation/sections/profile_settings_section.dart';
import 'presentation/sections/subscription_settings_section.dart';


enum _Section { profile, appearance, budget, subscription, data, notifications }

extension _SectionX on _Section {
  String get label => switch (this) {
        _Section.profile => 'My Profile',
        _Section.appearance => 'Appearance',
        _Section.budget => 'Budget',
        _Section.subscription => 'Subscription',
        _Section.data => 'Data',
        _Section.notifications => 'Notifications',
      };

  IconData get icon => switch (this) {
        _Section.profile => Icons.person_outline_rounded,
        _Section.appearance => Icons.palette_outlined,
        _Section.budget => Icons.account_balance_wallet_outlined,
        _Section.subscription => Icons.star_outline_rounded,
        _Section.data => Icons.storage_outlined,
        _Section.notifications => Icons.notifications_outlined,
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
  _Group('preferences', [_Section.notifications]),
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
          ProfileSettingsSection(isDark: isDark, authController: authController),
        _Section.appearance => AppearanceSettingsSection(
            isDark: isDark, settings: settings, controller: controller),
        _Section.budget =>
          BudgetSettingsSection(isDark: isDark, settings: settings, controller: controller),
        _Section.subscription => SubscriptionSettingsSection(isDark: isDark),
        _Section.data => DataSettingsSection(
            isDark: isDark,
            controller: controller,
            authController: authController,
            dataController: locator.get<SettingsDataController>()),
        _Section.notifications => NotificationsSettingsSection(isDark: isDark),
      };
}
