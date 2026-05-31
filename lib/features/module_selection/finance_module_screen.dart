import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:keep_track/core/di/service_locator.dart';
import 'package:keep_track/core/logging/log_viewer_screen.dart';
import 'package:keep_track/core/settings/domain/entities/app_settings.dart';
import 'package:keep_track/core/settings/presentation/settings_controller.dart';
import 'package:keep_track/core/theme/app_theme.dart';
import 'package:keep_track/core/ui/app_layout_controller.dart';
import 'package:keep_track/core/ui/responsive/responsive_breakpoints.dart';
import 'package:keep_track/core/state/stream_state.dart';
import 'package:keep_track/features/auth/domain/entities/user.dart';
import 'package:keep_track/features/auth/presentation/state/auth_controller.dart';
import 'package:keep_track/features/finance/presentation/screens/tabs/budget/budget_tab_screen.dart';
import 'package:keep_track/features/finance/presentation/screens/tabs/dashboard/dashboard_tab.dart';
import 'package:keep_track/features/finance/presentation/screens/tabs/savings/savings_tab.dart';
import 'package:keep_track/features/finance/presentation/screens/transaction_planner_screen.dart';
import 'package:keep_track/features/finance/presentation/screens/transactions/create_transaction_sheet.dart';
import 'package:keep_track/features/finance/presentation/state/budget_profile_controller.dart';
import 'package:keep_track/features/finance/presentation/state/transaction_controller.dart';
import '../auth/presentation/screens/auth_settings_screen.dart';
import '../settings/setting_page.dart';

class FinanceModuleScreen extends StatefulWidget {
  const FinanceModuleScreen({super.key});

  @override
  State<FinanceModuleScreen> createState() => _FinanceModuleScreenState();
}

class _FinanceModuleScreenState extends State<FinanceModuleScreen> {
  int _currentIndex = 0;
  bool _navVisible = true;
  final _layoutController = AppLayoutController();

  List<Widget> get _screens => [
    const DashboardTab(),
    const BudgetTabScreen(),
    const SavingsTab(),
    const TransactionPlannerScreen(),
  ];

  static const _navItems = [
    _NavItem(
      icon: Icons.dashboard_outlined,
      activeIcon: Icons.dashboard,
      label: 'Dashboard',
    ),
    _NavItem(
      icon: Icons.calendar_month_outlined,
      activeIcon: Icons.calendar_month,
      label: 'Budget',
    ),
    _NavItem(
      icon: Icons.savings_outlined,
      activeIcon: Icons.savings,
      label: 'Savings',
    ),
    _NavItem(
      icon: Icons.receipt_long_outlined,
      activeIcon: Icons.receipt_long,
      label: 'Transactions',
    ),
  ];

  @override
  void dispose() {
    _layoutController.dispose();
    super.dispose();
  }

  bool _handleScroll(ScrollNotification n) {
    if (_currentIndex == 1) return false; // Budget tab: nav always visible
    if (n is ScrollUpdateNotification) {
      final delta = n.scrollDelta ?? 0;
      if (delta > 3 && _navVisible) {
        setState(() => _navVisible = false);
      } else if (delta < -3 && !_navVisible) {
        setState(() => _navVisible = true);
      }
    }
    if (n is ScrollEndNotification && n.metrics.pixels <= 0) {
      setState(() => _navVisible = true);
    }
    return false;
  }

  void _switchTab(int index) {
    setState(() {
      _currentIndex = index;
      _navVisible = true;
    });
  }

  void _refreshTransactions() {
    final now = DateTime.now();
    locator.get<TransactionController>().loadTransactionsByDateRange(
      DateTime(now.year, now.month, 1),
      DateTime(now.year, now.month + 1, 1),
    );
  }

  String? get _activeProfileId =>
      locator.get<BudgetProfileController>().activeProfileId;

  String get _currentMonthKey {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}';
  }

  // Savings tab (index 2) has no FAB
  @override
  Widget build(BuildContext context) {
    return AppLayoutProvider(
      controller: _layoutController,
      child: AnimatedBuilder(
        animation: _layoutController,
        builder: (context, _) {
          final isDesktop =
              MediaQuery.sizeOf(context).width >= ResponsiveBreakpoints.desktop;
          return isDesktop ? _buildDesktop() : _buildMobile();
        },
      ),
    );
  }

  Widget _buildDesktop() {
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: () => CreateTransactionSheet.show(context, onCreated: _refreshTransactions, initialProfileId: _activeProfileId, initialMonthKey: _currentMonthKey),
        backgroundColor: AppColors.accent,
        foregroundColor: Colors.white,
        child: const Icon(Icons.add),
      ),
      body: Row(
        children: [
          _AppSidebar(
            currentIndex: _currentIndex,
            items: _navItems,
            layoutController: _layoutController,
            onSelect: _switchTab,
          ),
          Expanded(
            child: NotificationListener<ScrollNotification>(
              onNotification: _handleScroll,
              child: _screens[_currentIndex],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMobile() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      extendBody: true,
      appBar: _buildMobileAppBar(isDark),
      body: NotificationListener<ScrollNotification>(
        onNotification: _handleScroll,
        child: _screens[_currentIndex],
      ),
      bottomNavigationBar: AnimatedSlide(
        offset: _navVisible ? Offset.zero : const Offset(0, 1.5),
        duration: const Duration(milliseconds: 260),
        curve: Curves.easeInOut,
        child: AnimatedOpacity(
          opacity: _navVisible ? 1.0 : 0.0,
          duration: const Duration(milliseconds: 200),
          child: _buildFloatingNav(isDark),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildMobileAppBar(bool isDark) {
    final textPrimary = isDark ? AppColors.primaryForeground : AppColors.textPrimary;
    return AppBar(
      titleSpacing: 16,
      title: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Image.asset('assets/icon/app_icon.png', width: 26, height: 26),
          const SizedBox(width: 8),
          Text(
            'Keep Track',
            style: GoogleFonts.dmSans(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: textPrimary,
            ),
          ),
        ],
      ),
      actions: [
        _ThemeToggle(layoutController: _layoutController),
        GestureDetector(
          onTap: () => Navigator.pushNamed(context, '/settings'),
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Icon(
              Icons.settings_outlined,
              size: 18,
              color: AppColors.textSecondary,
            ),
          ),
        ),
        const SizedBox(width: 4),
      ],
    );
  }

  Widget _buildFloatingNav(bool isDark) {
    final navBg = isDark
        ? const Color(0xFF2C2C2A).withValues(alpha: 0.82)
        : Colors.white.withValues(alpha: 0.82);
    final shadowColor = isDark
        ? Colors.black.withValues(alpha: 0.5)
        : Colors.black.withValues(alpha: 0.12);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(22),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
                  child: Container(
                    height: 62,
                    decoration: BoxDecoration(
                      color: navBg,
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.06)
                            : Colors.white.withValues(alpha: 0.9),
                        width: 0.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: shadowColor,
                          blurRadius: 24,
                          offset: const Offset(0, 6),
                        ),
                        BoxShadow(
                          color: shadowColor.withValues(alpha: shadowColor.a * 0.5),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      children: _navItems.asMap().entries.map((e) {
                        final selected = e.key == _currentIndex;
                        final color = selected
                            ? AppColors.accent
                            : AppColors.textTertiary;
                        return Expanded(
                          child: GestureDetector(
                            onTap: () => _switchTab(e.key),
                            behavior: HitTestBehavior.opaque,
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                AnimatedSwitcher(
                                  duration: const Duration(milliseconds: 180),
                                  child: Icon(
                                    selected ? e.value.activeIcon : e.value.icon,
                                    key: ValueKey(selected),
                                    size: 22,
                                    color: color,
                                  ),
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  e.value.label,
                                  style: GoogleFonts.dmSans(
                                    fontSize: 10,
                                    fontWeight: selected
                                        ? FontWeight.w600
                                        : FontWeight.w400,
                                    color: color,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            GestureDetector(
              onTap: () => CreateTransactionSheet.show(context, onCreated: _refreshTransactions, initialProfileId: _activeProfileId, initialMonthKey: _currentMonthKey),
              child: Container(
                width: 62,
                height: 62,
                decoration: BoxDecoration(
                  color: AppColors.accent,
                  borderRadius: BorderRadius.circular(22),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.accent.withValues(alpha: 0.35),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Icon(Icons.add, color: Colors.white, size: 26),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Sidebar ──────────────────────────────────────────────────────────────────
class _AppSidebar extends StatefulWidget {
  final int currentIndex;
  final List<_NavItem> items;
  final AppLayoutController layoutController;
  final void Function(int) onSelect;

  const _AppSidebar({
    required this.currentIndex,
    required this.items,
    required this.layoutController,
    required this.onSelect,
  });

  @override
  State<_AppSidebar> createState() => _AppSidebarState();
}

class _AppSidebarState extends State<_AppSidebar> {
  int? _hovered;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF242422) : Colors.white;
    final borderColor = isDark
        ? AppColors.border.withValues(alpha: 0.25)
        : AppColors.border.withValues(alpha: 0.6);

    return Container(
      width: 232,
      decoration: BoxDecoration(
        color: bg,
        border: Border(right: BorderSide(color: borderColor, width: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SidebarHeader(isDark: isDark),
          const SizedBox(height: 4),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Column(
                children: widget.items
                    .asMap()
                    .entries
                    .map(
                      (e) => _SidebarNavItem(
                        item: e.value,
                        isSelected: widget.currentIndex == e.key,
                        isHovered: _hovered == e.key,
                        isDark: isDark,
                        onTap: () => widget.onSelect(e.key),
                        onHover: (v) =>
                            setState(() => _hovered = v ? e.key : null),
                      ),
                    )
                    .toList(),
              ),
            ),
          ),
          _SidebarDivider(isDark: isDark),
          _SidebarFooter(isDark: isDark),
        ],
      ),
    );
  }
}

class _SidebarHeader extends StatelessWidget {
  final bool isDark;
  const _SidebarHeader({required this.isDark});

  @override
  Widget build(BuildContext context) {
    final textPrimary = isDark ? AppColors.primaryForeground : AppColors.textPrimary;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 14),
      child: Row(
        children: [
          Image.asset('assets/icon/app_icon.png', width: 36, height: 36),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Keep Track',
                style: GoogleFonts.dmSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: textPrimary,
                ),
              ),
              Text(
                'Zero-based budgeting',
                style: GoogleFonts.dmSans(
                  fontSize: 10,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SidebarNavItem extends StatelessWidget {
  final _NavItem item;
  final bool isSelected, isHovered, isDark;
  final VoidCallback onTap;
  final void Function(bool) onHover;

  const _SidebarNavItem({
    required this.item,
    required this.isSelected,
    required this.isHovered,
    required this.isDark,
    required this.onTap,
    required this.onHover,
  });

  @override
  Widget build(BuildContext context) {
    final Color selectedBg = isDark
        ? AppColors.accent.withValues(alpha: 0.15)
        : AppColors.accent.withValues(alpha: 0.08);
    final Color hoveredBg = isDark
        ? Colors.white.withValues(alpha: 0.04)
        : AppColors.textPrimary.withValues(alpha: 0.04);
    final Color iconColor = isSelected
        ? AppColors.accent
        : (isDark ? AppColors.textSecondary : AppColors.textTertiary);
    final Color textColor = isSelected
        ? AppColors.accent
        : (isDark ? AppColors.textSecondary : AppColors.textSecondary);

    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: MouseRegion(
        onEnter: (_) => onHover(true),
        onExit: (_) => onHover(false),
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 120),
            height: 40,
            padding: const EdgeInsets.symmetric(horizontal: 10),
            decoration: BoxDecoration(
              color: isSelected
                  ? selectedBg
                  : (isHovered ? hoveredBg : Colors.transparent),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(
                  isSelected ? item.activeIcon : item.icon,
                  size: 18,
                  color: iconColor,
                ),
                const SizedBox(width: 10),
                Text(
                  item.label,
                  style: GoogleFonts.dmSans(
                    fontSize: 13,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                    color: textColor,
                  ),
                ),
                if (isSelected) ...[
                  const Spacer(),
                  Container(
                    width: 4,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.accent,
                      shape: BoxShape.circle,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SidebarDivider extends StatelessWidget {
  final bool isDark;
  const _SidebarDivider({required this.isDark});

  @override
  Widget build(BuildContext context) => Divider(
    height: 1,
    thickness: 0.5,
    color: isDark
        ? AppColors.border.withValues(alpha: 0.25)
        : AppColors.border.withValues(alpha: 0.6),
  );
}

class _SidebarFooter extends StatefulWidget {
  final bool isDark;

  const _SidebarFooter({required this.isDark});

  @override
  State<_SidebarFooter> createState() => _SidebarFooterState();
}

class _SidebarFooterState extends State<_SidebarFooter> {
  late final AuthController _authController;

  @override
  void initState() {
    super.initState();
    _authController = locator.get<AuthController>();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AsyncState<User?>>(
      stream: _authController.stream,
      initialData: _authController.state,
      builder: (context, snapshot) {
        final state = snapshot.data;
        final user = state is AsyncData<User?>
            ? state.data
            : _authController.currentUser;
        return _FooterContent(user: user, isDark: widget.isDark);
      },
    );
  }
}

class _FooterContent extends StatefulWidget {
  final User? user;
  final bool isDark;

  const _FooterContent({required this.user, required this.isDark});

  @override
  State<_FooterContent> createState() => _FooterContentState();
}

class _FooterContentState extends State<_FooterContent> {
  final _layerLink = LayerLink();
  OverlayEntry? _overlay;
  bool _isOpen = false;

  void _toggle() => _isOpen ? _dismiss() : _show();

  void _show() {
    _overlay = OverlayEntry(
      builder: (_) => _UserMenuOverlay(
        link: _layerLink,
        user: widget.user,
        isDark: widget.isDark,
        onDismiss: _dismiss,
        onAction: _handleAction,
      ),
    );
    Overlay.of(context).insert(_overlay!);
    setState(() => _isOpen = true);
  }

  void _dismiss() {
    _overlay?.remove();
    _overlay = null;
    if (mounted) setState(() => _isOpen = false);
  }

  Future<void> _handleAction(String action) async {
    _dismiss();
    if (!mounted) return;
    switch (action) {
      case 'theme':
        locator.get<SettingsController>().updateThemeMode(
          widget.isDark ? AppThemeMode.light : AppThemeMode.dark,
        );
      case 'settings':
        final isDesktop =
            MediaQuery.of(context).size.width >= ResponsiveBreakpoints.desktop;
        if (isDesktop) {
          showDialog<void>(
            context: context,
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
        } else {
          Navigator.of(context).pushNamed('/settings');
        }
      case 'account':
        Navigator.of(
          context,
        ).push(MaterialPageRoute(builder: (_) => const AuthSettingsScreen()));
      case 'logs':
        Navigator.of(
          context,
        ).push(MaterialPageRoute(builder: (_) => const LogViewerScreen()));
      case 'signout':
        final ok = await showDialog<bool>(
          context: context,
          builder: (_) => AlertDialog(
            title: Text('Sign out?', style: AppTextStyles.h4),
            content: Text(
              'You will be signed out of Keep Track.',
              style: AppTextStyles.bodySmall,
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: Text(
                  'Sign out',
                  style: TextStyle(
                    color: AppColors.error,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        );
        if (ok == true && mounted)
          await locator.get<AuthController>().signOut();
    }
  }

  @override
  void dispose() {
    _dismiss();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final borderColor = widget.isDark
        ? AppColors.border.withValues(alpha: 0.25)
        : AppColors.border.withValues(alpha: 0.6);

    if (widget.user == null) {
      return _buildGuestFooter(borderColor);
    }

    final initials = _initials(widget.user?.displayName);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 6),
          child: MouseRegion(
            cursor: SystemMouseCursors.click,
            child: GestureDetector(
              onTap: () => locator.get<SettingsController>().updateThemeMode(
                widget.isDark ? AppThemeMode.light : AppThemeMode.dark,
              ),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: BoxDecoration(
                  color: widget.isDark
                      ? Colors.white.withValues(alpha: 0.03)
                      : AppColors.background,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    Icon(
                      widget.isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
                      size: 16,
                      color: AppColors.textSecondary,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        widget.isDark ? 'Light mode' : 'Dark mode',
                        style: GoogleFonts.dmSans(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        Divider(height: 1, thickness: 0.5, color: borderColor),
        Padding(
          padding: const EdgeInsets.all(12),
          child: CompositedTransformTarget(
            link: _layerLink,
            child: MouseRegion(
              cursor: SystemMouseCursors.click,
              child: GestureDetector(
                onTap: _toggle,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 120),
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
                  decoration: BoxDecoration(
                    color: _isOpen
                        ? (widget.isDark
                              ? Colors.white.withValues(alpha: 0.07)
                              : AppColors.accent.withValues(alpha: 0.06))
                        : (widget.isDark
                              ? Colors.white.withValues(alpha: 0.03)
                              : AppColors.background),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: _isOpen
                          ? AppColors.accent.withValues(alpha: 0.25)
                          : Colors.transparent,
                    ),
                  ),
                  child: Row(
                    children: [
                      _Avatar(initials: initials, photoUrl: widget.user?.photoUrl),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              widget.user?.displayName ?? 'User',
                              style: GoogleFonts.dmSans(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: widget.isDark
                                    ? AppColors.primaryForeground
                                    : AppColors.textPrimary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              widget.user?.email ?? '',
                              style: GoogleFonts.dmSans(
                                fontSize: 10,
                                color: AppColors.textSecondary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      AnimatedRotation(
                        turns: _isOpen ? 0.5 : 0,
                        duration: const Duration(milliseconds: 150),
                        child: Icon(
                          Icons.keyboard_arrow_up_rounded,
                          size: 16,
                          color: AppColors.textTertiary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildGuestFooter(Color borderColor) {
    final isDesktop =
        MediaQuery.of(context).size.width >= ResponsiveBreakpoints.desktop;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 6),
          child: MouseRegion(
            cursor: SystemMouseCursors.click,
            child: GestureDetector(
              onTap: () => locator.get<SettingsController>().updateThemeMode(
                widget.isDark ? AppThemeMode.light : AppThemeMode.dark,
              ),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: BoxDecoration(
                  color: widget.isDark
                      ? Colors.white.withValues(alpha: 0.03)
                      : AppColors.background,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    Icon(
                      widget.isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
                      size: 16,
                      color: AppColors.textSecondary,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        widget.isDark ? 'Light mode' : 'Dark mode',
                        style: GoogleFonts.dmSans(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        Divider(height: 1, thickness: 0.5, color: borderColor),
        Padding(
          padding: const EdgeInsets.all(12),
          child: MouseRegion(
            cursor: SystemMouseCursors.click,
            child: GestureDetector(
              onTap: () {
                if (isDesktop) {
                  showDialog<void>(
                    context: context,
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
                } else {
                  Navigator.of(context).pushNamed('/settings');
                }
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
                decoration: BoxDecoration(
                  color: widget.isDark
                      ? Colors.white.withValues(alpha: 0.03)
                      : AppColors.background,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.settings_outlined,
                      size: 16,
                      color: AppColors.textSecondary,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Settings',
                        style: GoogleFonts.dmSans(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  String _initials(String? name) {
    if (name == null || name.isEmpty) return 'U';
    final parts = name.trim().split(' ');
    if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    return name[0].toUpperCase();
  }
}

class _UserMenuOverlay extends StatelessWidget {
  final LayerLink link;
  final User? user;
  final bool isDark;
  final VoidCallback onDismiss;
  final void Function(String) onAction;

  const _UserMenuOverlay({
    required this.link,
    required this.user,
    required this.isDark,
    required this.onDismiss,
    required this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final cardBg = isDark ? const Color(0xFF2C2C2A) : Colors.white;
    final borderColor = isDark
        ? AppColors.border.withValues(alpha: 0.3)
        : AppColors.border.withValues(alpha: 0.7);
    final initials = _initials(user?.displayName);

    return Stack(
      children: [
        // Dismiss barrier
        Positioned.fill(
          child: GestureDetector(
            onTap: onDismiss,
            behavior: HitTestBehavior.translucent,
            child: const SizedBox.expand(),
          ),
        ),
        // Positioned card above the trigger
        CompositedTransformFollower(
          link: link,
          targetAnchor: Alignment.topLeft,
          followerAnchor: Alignment.bottomLeft,
          offset: const Offset(0, -8),
          child: Material(
            color: Colors.transparent,
            child: Container(
              width: 208,
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: borderColor, width: 0.5),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.4 : 0.1),
                    blurRadius: 20,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // User info header
                  Padding(
                    padding: const EdgeInsets.all(14),
                    child: Row(
                      children: [
                        _Avatar(initials: initials, photoUrl: user?.photoUrl),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                user?.displayName ?? 'User',
                                style: GoogleFonts.dmSans(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: isDark
                                      ? AppColors.primaryForeground
                                      : AppColors.textPrimary,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                user?.email ?? '',
                                style: GoogleFonts.dmSans(
                                  fontSize: 11,
                                  color: AppColors.textSecondary,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Divider(height: 1, thickness: 0.5, color: borderColor),
                  const SizedBox(height: 4),
                  _MenuItem(
                    icon: isDark
                        ? Icons.light_mode_outlined
                        : Icons.dark_mode_outlined,
                    label: isDark ? 'Light mode' : 'Dark mode',
                    isDark: isDark,
                    onTap: () => onAction('theme'),
                  ),
                  Divider(height: 1, thickness: 0.5, color: borderColor),
                  const SizedBox(height: 4),
                  _MenuItem(
                    icon: Icons.settings_outlined,
                    label: 'Settings',
                    isDark: isDark,
                    onTap: () => onAction('settings'),
                  ),
                  _MenuItem(
                    icon: Icons.manage_accounts_outlined,
                    label: 'Account',
                    isDark: isDark,
                    onTap: () => onAction('account'),
                  ),
                  _MenuItem(
                    icon: Icons.bug_report_outlined,
                    label: 'Debug logs',
                    isDark: isDark,
                    onTap: () => onAction('logs'),
                  ),
                  const SizedBox(height: 4),
                  Divider(height: 1, thickness: 0.5, color: borderColor),
                  const SizedBox(height: 4),
                  _MenuItem(
                    icon: Icons.logout_rounded,
                    label: 'Sign out',
                    isDark: isDark,
                    color: AppColors.error,
                    onTap: () => onAction('signout'),
                  ),
                  const SizedBox(height: 4),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  String _initials(String? name) {
    if (name == null || name.isEmpty) return 'U';
    final parts = name.trim().split(' ');
    if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    return name[0].toUpperCase();
  }
}

class _MenuItem extends StatefulWidget {
  final IconData icon;
  final String label;
  final bool isDark;
  final Color? color;
  final VoidCallback onTap;

  const _MenuItem({
    required this.icon,
    required this.label,
    required this.isDark,
    required this.onTap,
    this.color,
  });

  @override
  State<_MenuItem> createState() => _MenuItemState();
}

class _MenuItemState extends State<_MenuItem> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final fg =
        widget.color ??
        (widget.isDark ? AppColors.primaryForeground : AppColors.textPrimary);
    final hoverBg = widget.isDark
        ? Colors.white.withValues(alpha: 0.05)
        : AppColors.textPrimary.withValues(alpha: 0.04);

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: Container(
          height: 36,
          margin: const EdgeInsets.symmetric(horizontal: 6),
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            color: _hovered ? hoverBg : Colors.transparent,
            borderRadius: BorderRadius.circular(7),
          ),
          child: Row(
            children: [
              Icon(widget.icon, size: 15, color: fg),
              const SizedBox(width: 10),
              Text(
                widget.label,
                style: GoogleFonts.dmSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w400,
                  color: fg,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  final String initials;
  final String? photoUrl;

  const _Avatar({required this.initials, required this.photoUrl});

  @override
  Widget build(BuildContext context) {
    if (photoUrl != null) {
      return CircleAvatar(radius: 16, backgroundImage: NetworkImage(photoUrl!));
    }
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.accent, AppColors.accentDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      alignment: Alignment.center,
      child: Text(
        initials,
        style: GoogleFonts.dmSans(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: Colors.white,
        ),
      ),
    );
  }
}

class _ThemeToggle extends StatelessWidget {
  final AppLayoutController layoutController;
  const _ThemeToggle({required this.layoutController});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: () => locator.get<SettingsController>().updateThemeMode(
        isDark ? AppThemeMode.light : AppThemeMode.dark,
      ),
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Icon(
          isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
          size: 18,
          color: AppColors.textSecondary,
        ),
      ),
    );
  }
}

// ─── Data types ───────────────────────────────────────────────────────────────

class _NavItem {
  final IconData icon, activeIcon;
  final String label;
  const _NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
  });
}
