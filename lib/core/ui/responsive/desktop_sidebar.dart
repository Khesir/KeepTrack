import 'package:flutter/material.dart';
import 'package:keep_track/core/theme/app_theme.dart';

/// Navigation item for the sidebar
class SidebarNavItem {
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final bool isActive;
  final List<SidebarNavItem>? subItems;
  final bool isSubItem;

  const SidebarNavItem({
    required this.label,
    required this.icon,
    required this.onTap,
    this.isActive = false,
    this.subItems,
    this.isSubItem = false,
  });

  /// Check if this item has sub-items
  bool get hasSubItems => subItems != null && subItems!.isNotEmpty;
}

/// Desktop sidebar navigation component (shadcn-inspired)
class DesktopSidebar extends StatelessWidget {
  final List<SidebarNavItem> navItems;
  final Widget? header;
  final Widget? footer;

  const DesktopSidebar({
    super.key,
    required this.navItems,
    this.header,
    this.footer,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 260,
      child: Container(
        decoration: const BoxDecoration(
          color: AppColors.background,
          border: Border(
            right: BorderSide(
              color: AppColors.border,
              width: 1,
            ),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header section
            if (header != null) header!,

            // Navigation items
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.md,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: navItems.map(_buildNavItem).toList(),
                ),
              ),
            ),

            // Footer section
            if (footer != null) footer!,
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem(SidebarNavItem item) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Main nav item
        Container(
          margin: const EdgeInsets.only(bottom: AppSpacing.xs),
          decoration: BoxDecoration(
            color: item.isActive && !item.hasSubItems
                ? AppColors.secondary
                : Colors.transparent,
            borderRadius: AppRadius.circularMd,
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: item.onTap,
              borderRadius: AppRadius.circularMd,
              child: Padding(
                padding: EdgeInsets.only(
                  left: item.isSubItem ? AppSpacing.xl : AppSpacing.md,
                  right: AppSpacing.md,
                  top: AppSpacing.sm + 2,
                  bottom: AppSpacing.sm + 2,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.max,
                  children: [
                    Icon(
                      item.icon,
                      size: item.isSubItem ? 18 : 20,
                      color: item.isActive
                          ? AppColors.textPrimary
                          : AppColors.textSecondary,
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Text(
                        item.label,
                        style: AppTextStyles.bodyMedium.copyWith(
                          fontSize: item.isSubItem ? 13 : 14,
                          color: item.isActive
                              ? AppColors.textPrimary
                              : AppColors.textSecondary,
                          fontWeight: item.isActive
                              ? FontWeight.w500
                              : FontWeight.w400,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        // Sub-items
        if (item.hasSubItems)
          ...item.subItems!.map((subItem) => _buildNavItem(subItem)),
      ],
    );
  }
}

/// Sidebar header with app branding
class SidebarHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget? leading;

  const SidebarHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.leading,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: AppColors.border,
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          if (leading != null) ...[
            leading!,
            const SizedBox(width: AppSpacing.md),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTextStyles.h4,
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle!,
                    style: AppTextStyles.caption,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Sidebar footer with user profile or settings
class SidebarFooter extends StatelessWidget {
  final Widget child;

  const SidebarFooter({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: const BoxDecoration(
        border: Border(
          top: BorderSide(
            color: AppColors.border,
            width: 1,
          ),
        ),
      ),
      child: child,
    );
  }
}
