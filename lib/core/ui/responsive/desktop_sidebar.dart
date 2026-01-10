import 'package:flutter/material.dart';
import 'package:keep_track/core/theme/app_theme.dart';

/// Navigation item for the sidebar
class SidebarNavItem {
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final bool isActive;

  const SidebarNavItem({
    required this.label,
    required this.icon,
    required this.onTap,
    this.isActive = false,
  });
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
    return Container(
      width: 260,
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
            child: ListView(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.md,
              ),
              children: [
                for (final item in navItems) _buildNavItem(item),
              ],
            ),
          ),

          // Footer section
          if (footer != null) footer!,
        ],
      ),
    );
  }

  Widget _buildNavItem(SidebarNavItem item) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
      child: Material(
        color: item.isActive ? AppColors.secondary : Colors.transparent,
        borderRadius: AppRadius.circularMd,
        child: InkWell(
          onTap: item.onTap,
          borderRadius: AppRadius.circularMd,
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm + 2,
            ),
            child: Row(
              children: [
                Icon(
                  item.icon,
                  size: 20,
                  color: item.isActive
                      ? AppColors.textPrimary
                      : AppColors.textSecondary,
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Text(
                    item.label,
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: item.isActive
                          ? AppColors.textPrimary
                          : AppColors.textSecondary,
                      fontWeight:
                          item.isActive ? FontWeight.w500 : FontWeight.w400,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
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
