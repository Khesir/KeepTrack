import 'package:flutter/material.dart';
import 'package:keep_track/core/theme/app_theme.dart';

/// Desktop top navbar component (shadcn-inspired)
class DesktopNavbar extends StatelessWidget {
  final String? title;
  final List<Widget>? actions;
  final Widget? leading;

  const DesktopNavbar({super.key, this.title, this.actions, this.leading});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final borderColor = isDark
        ? Colors.white.withOpacity(0.08)
        : Colors.black.withOpacity(0.06);

    return Container(
      height: 64,
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        border: Border(bottom: BorderSide(color: borderColor, width: 1)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        child: Row(
          children: [
            // Leading widget (e.g., breadcrumbs)
            if (leading != null) ...[
              leading!,
              const SizedBox(width: AppSpacing.md),
            ],

            // Title
            if (title != null) Text(title!, style: AppTextStyles.h3),

            const Spacer(),

            // Actions
            if (actions != null && actions!.isNotEmpty)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (int i = 0; i < actions!.length; i++) ...[
                    actions![i],
                    if (i < actions!.length - 1)
                      const SizedBox(width: AppSpacing.sm),
                  ],
                ],
              ),
          ],
        ),
      ),
    );
  }
}

/// Breadcrumb item for navigation trail
class BreadcrumbItem {
  final String label;
  final VoidCallback? onTap;

  const BreadcrumbItem({required this.label, this.onTap});
}

/// Breadcrumb navigation component
class Breadcrumbs extends StatelessWidget {
  final List<BreadcrumbItem> items;

  const Breadcrumbs({super.key, required this.items});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textColor =
        theme.textTheme.bodyMedium?.color ?? theme.colorScheme.onSurface;
    final secondaryTextColor =
        theme.textTheme.bodySmall?.color ??
        theme.colorScheme.onSurface.withOpacity(0.6);
    return Row(
      children: [
        for (int i = 0; i < items.length; i++) ...[
          if (i > 0) ...[
            const SizedBox(width: AppSpacing.xs),
            Icon(Icons.chevron_right, size: 16, color: secondaryTextColor),
            const SizedBox(width: AppSpacing.xs),
          ],
          _buildBreadcrumbItem(
            context,
            items[i],
            isLast: i == items.length - 1,
          ),
        ],
      ],
    );
  }

  Widget _buildBreadcrumbItem(
    BuildContext context,
    BreadcrumbItem item, {
    required bool isLast,
  }) {
    final theme = Theme.of(context);
    final textColor =
        theme.textTheme.bodyMedium?.color ?? theme.colorScheme.onSurface;
    final secondaryTextColor =
        theme.textTheme.bodySmall?.color ??
        theme.colorScheme.onSurface.withOpacity(0.6);
    final textStyle = isLast
        ? AppTextStyles.bodyMedium.copyWith(
            color: textColor,
            fontWeight: FontWeight.w500,
          )
        : AppTextStyles.bodyMedium.copyWith(color: secondaryTextColor);

    if (item.onTap != null && !isLast) {
      return InkWell(
        onTap: item.onTap,
        borderRadius: AppRadius.circularSm,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.xs,
            vertical: 2,
          ),
          child: Text(item.label, style: textStyle),
        ),
      );
    }

    return Text(item.label, style: textStyle);
  }
}

/// Search bar for desktop navbar
class NavbarSearchBar extends StatelessWidget {
  final String? hintText;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onTap;

  const NavbarSearchBar({super.key, this.hintText, this.onChanged, this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return Container(
      width: 300,
      height: 36,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF18181B) : AppColors.backgroundSecondary,
        borderRadius: AppRadius.circularMd,
        border: Border.all(color: theme.dividerColor),
      ),
      child: TextField(
        onChanged: onChanged,
        onTap: onTap,
        style: AppTextStyles.bodySmall,
        decoration: InputDecoration(
          hintText: hintText ?? 'Search...',
          hintStyle: AppTextStyles.muted.copyWith(fontSize: 13),
          prefixIcon: const Icon(
            Icons.search,
            size: 18,
            color: AppColors.textSecondary,
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm,
            vertical: AppSpacing.xs,
          ),
        ),
      ),
    );
  }
}
