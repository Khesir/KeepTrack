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
  final List<ResponsiveNavItem>? subItems;

  const ResponsiveNavItem({
    required this.label,
    required this.icon,
    required this.screen,
    this.subItems,
  });

  /// Check if this item has sub-items
  bool get hasSubItems => subItems != null && subItems!.isNotEmpty;
}

/// Responsive layout wrapper that switches between mobile and desktop UI
class ResponsiveLayoutWrapper extends StatefulWidget {
  final ResponsiveLayoutConfig config;

  const ResponsiveLayoutWrapper({
    super.key,
    required this.config,
  });

  @override
  State<ResponsiveLayoutWrapper> createState() =>
      _ResponsiveLayoutWrapperState();
}

class _ResponsiveLayoutWrapperState extends State<ResponsiveLayoutWrapper> {
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

  /// Flatten nav items (including sub-items) for index tracking
  List<ResponsiveNavItem> _flattenNavItems(List<ResponsiveNavItem> items) {
    final flattened = <ResponsiveNavItem>[];
    for (final item in items) {
      flattened.add(item);
      if (item.hasSubItems) {
        flattened.addAll(item.subItems!);
      }
    }
    return flattened;
  }

  /// Convert ResponsiveNavItem to SidebarNavItem with proper nesting
  List<SidebarNavItem> _buildSidebarNavItems() {
    var globalIndex = 0;

    return widget.config.navItems.map((item) {
      final itemIndex = globalIndex++;
      final isParentActive = itemIndex == widget.config.currentIndex;

      List<SidebarNavItem>? subItems;
      if (item.hasSubItems) {
        subItems = item.subItems!.map((subItem) {
          final subIndex = globalIndex++;
          return SidebarNavItem(
            label: subItem.label,
            icon: subItem.icon,
            isActive: subIndex == widget.config.currentIndex,
            onTap: () => widget.config.onNavIndexChanged(subIndex),
            isSubItem: true,
          );
        }).toList();
      }

      return SidebarNavItem(
        label: item.label,
        icon: item.icon,
        isActive: isParentActive,
        onTap: () => widget.config.onNavIndexChanged(itemIndex),
        subItems: subItems,
      );
    }).toList();
  }

  /// Build desktop layout with sidebar and navbar
  Widget _buildDesktopLayout(BuildContext context) {
    final flatItems = _flattenNavItems(widget.config.navItems);

    return Scaffold(
      body: Row(
        children: [
          // Sidebar navigation
          DesktopSidebar(
            header: widget.config.sidebarHeader,
            footer: widget.config.sidebarFooter,
            navItems: _buildSidebarNavItems(),
          ),

          // Main content area
          Expanded(
            child: Column(
              children: [
                // Top navbar
                DesktopNavbar(
                  title: widget.config.title,
                  actions: widget.config.actions,
                ),

                // Content with desktop wrapper
                Expanded(
                  child: DesktopContentWrapper(
                    child: flatItems[widget.config.currentIndex].screen,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: widget.config.floatingActionButton,
    );
  }

  /// Build mobile layout with bottom navigation
  Widget _buildMobileLayout(BuildContext context) {
    return Scaffold(
      appBar: _buildMobileAppBar(context),
      body: widget.config.navItems[widget.config.currentIndex].screen,
      bottomNavigationBar: _buildBottomNavigationBar(),
      floatingActionButton: widget.config.floatingActionButton,
    );
  }

  /// Build mobile app bar
  PreferredSizeWidget _buildMobileAppBar(BuildContext context) {
    return AppBar(
      title: Text(widget.config.title ??
          widget.config.navItems[widget.config.currentIndex].label),
      actions: widget.config.actions,
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
        currentIndex: widget.config.currentIndex,
        onTap: widget.config.onNavIndexChanged,
        type: BottomNavigationBarType.fixed,
        backgroundColor: AppColors.background,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.textSecondary,
        selectedFontSize: 12,
        unselectedFontSize: 12,
        selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500),
        elevation: 0,
        items: widget.config.navItems
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

/// Desktop content wrapper that provides proper spacing and max-width
class DesktopContentWrapper extends StatelessWidget {
  final Widget child;
  final double maxWidth;
  final EdgeInsets padding;

  const DesktopContentWrapper({
    super.key,
    required this.child,
    this.maxWidth = 1400,
    this.padding = const EdgeInsets.all(AppSpacing.lg),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.backgroundSecondary,
      child: SingleChildScrollView(
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxWidth),
            child: Padding(
              padding: padding,
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}
