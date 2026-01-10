import 'package:flutter/material.dart';
import 'package:keep_track/core/theme/app_theme.dart';
import 'package:keep_track/core/ui/responsive/desktop_navbar.dart';
import 'package:keep_track/core/ui/responsive/desktop_sidebar.dart';
import 'package:keep_track/core/ui/responsive/responsive_breakpoints.dart';

/// Configuration for responsive layout
class ResponsiveLayoutConfig {
  final List<ResponsiveNavItem> navItems;
  final int currentIndex;
  final ValueChanged<int> onNavIndexChanged;
  final String? title;
  final List<Widget>? actions;
  final Widget? sidebarHeader;
  final Widget? sidebarFooter;
  final FloatingActionButton? floatingActionButton;

  const ResponsiveLayoutConfig({
    required this.navItems,
    required this.currentIndex,
    required this.onNavIndexChanged,
    this.title,
    this.actions,
    this.sidebarHeader,
    this.sidebarFooter,
    this.floatingActionButton,
  });
}

/// Navigation item that works for both mobile and desktop
class ResponsiveNavItem {
  final String label;
  final IconData icon;
  final Widget screen;

  const ResponsiveNavItem({
    required this.label,
    required this.icon,
    required this.screen,
  });
}

/// Responsive layout wrapper that switches between mobile and desktop UI
class ResponsiveLayoutWrapper extends StatelessWidget {
  final ResponsiveLayoutConfig config;

  const ResponsiveLayoutWrapper({
    super.key,
    required this.config,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = constraints.maxWidth >= ResponsiveBreakpoints.desktop;

        if (isDesktop) {
          return _buildDesktopLayout(context);
        } else {
          return _buildMobileLayout(context);
        }
      },
    );
  }

  /// Build desktop layout with sidebar and navbar
  Widget _buildDesktopLayout(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          // Sidebar navigation
          DesktopSidebar(
            header: config.sidebarHeader,
            footer: config.sidebarFooter,
            navItems: config.navItems
                .asMap()
                .entries
                .map(
                  (entry) => SidebarNavItem(
                    label: entry.value.label,
                    icon: entry.value.icon,
                    isActive: entry.key == config.currentIndex,
                    onTap: () => config.onNavIndexChanged(entry.key),
                  ),
                )
                .toList(),
          ),

          // Main content area
          Expanded(
            child: Column(
              children: [
                // Top navbar
                DesktopNavbar(
                  title: config.title,
                  actions: config.actions,
                ),

                // Content
                Expanded(
                  child: config.navItems[config.currentIndex].screen,
                ),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: config.floatingActionButton,
    );
  }

  /// Build mobile layout with bottom navigation
  Widget _buildMobileLayout(BuildContext context) {
    return Scaffold(
      appBar: _buildMobileAppBar(context),
      body: config.navItems[config.currentIndex].screen,
      bottomNavigationBar: _buildBottomNavigationBar(),
      floatingActionButton: config.floatingActionButton,
    );
  }

  /// Build mobile app bar
  PreferredSizeWidget _buildMobileAppBar(BuildContext context) {
    return AppBar(
      title: Text(config.title ?? config.navItems[config.currentIndex].label),
      actions: config.actions,
    );
  }

  /// Build bottom navigation bar for mobile
  Widget _buildBottomNavigationBar() {
    return Container(
      decoration: const BoxDecoration(
        border: Border(
          top: BorderSide(
            color: AppColors.border,
            width: 1,
          ),
        ),
      ),
      child: BottomNavigationBar(
        currentIndex: config.currentIndex,
        onTap: config.onNavIndexChanged,
        type: BottomNavigationBarType.fixed,
        backgroundColor: AppColors.background,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.textSecondary,
        selectedFontSize: 12,
        unselectedFontSize: 12,
        selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500),
        elevation: 0,
        items: config.navItems
            .map(
              (item) => BottomNavigationBarItem(
                icon: Icon(item.icon),
                label: item.label,
              ),
            )
            .toList(),
      ),
    );
  }
}
