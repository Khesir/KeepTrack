import 'package:flutter/material.dart';
import 'package:keep_track/core/theme/app_theme.dart';
import 'package:keep_track/core/ui/responsive/responsive_breakpoints.dart';

/// A widget that makes screens aware of desktop mode and provides layout helpers
class DesktopAwareScreen extends StatelessWidget {
  final Widget Function(BuildContext context, bool isDesktop) builder;

  const DesktopAwareScreen({
    super.key,
    required this.builder,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = constraints.maxWidth >= ResponsiveBreakpoints.desktop;
        return builder(context, isDesktop);
      },
    );
  }
}

/// Desktop-optimized card widget with shadcn styling
class DesktopCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets? padding;
  final String? title;
  final List<Widget>? actions;
  final Color? backgroundColor;

  const DesktopCard({
    super.key,
    required this.child,
    this.padding,
    this.title,
    this.actions,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: backgroundColor ?? AppColors.card,
        borderRadius: AppRadius.circularLg,
        border: Border.all(color: AppColors.border),
        boxShadow: const [AppShadows.subtle],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title != null || actions != null)
            Container(
              padding: const EdgeInsets.all(AppSpacing.lg),
              decoration: const BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: AppColors.border),
                ),
              ),
              child: Row(
                children: [
                  if (title != null)
                    Expanded(
                      child: Text(
                        title!,
                        style: AppTextStyles.h4,
                      ),
                    ),
                  if (actions != null) ...actions!,
                ],
              ),
            ),
          Padding(
            padding: padding ?? const EdgeInsets.all(AppSpacing.lg),
            child: child,
          ),
        ],
      ),
    );
  }
}

/// Grid layout helper for desktop
class DesktopGrid extends StatelessWidget {
  final List<Widget> children;
  final int crossAxisCount;
  final double spacing;
  final double childAspectRatio;

  const DesktopGrid({
    super.key,
    required this.children,
    this.crossAxisCount = 2,
    this.spacing = AppSpacing.lg,
    this.childAspectRatio = 1.5,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: spacing,
        mainAxisSpacing: spacing,
        childAspectRatio: childAspectRatio,
      ),
      itemCount: children.length,
      itemBuilder: (context, index) => children[index],
    );
  }
}

/// Responsive grid that adjusts columns based on screen size
class ResponsiveGrid extends StatelessWidget {
  final List<Widget> children;
  final double spacing;
  final double mobileChildAspectRatio;
  final double desktopChildAspectRatio;

  const ResponsiveGrid({
    super.key,
    required this.children,
    this.spacing = AppSpacing.md,
    this.mobileChildAspectRatio = 1.0,
    this.desktopChildAspectRatio = 1.5,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = constraints.maxWidth >= ResponsiveBreakpoints.desktop;
        final isTablet = constraints.maxWidth >= ResponsiveBreakpoints.tablet;

        int crossAxisCount = 1;
        double childAspectRatio = mobileChildAspectRatio;

        if (isDesktop) {
          crossAxisCount = 3;
          childAspectRatio = desktopChildAspectRatio;
        } else if (isTablet) {
          crossAxisCount = 2;
          childAspectRatio = desktopChildAspectRatio;
        }

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: spacing,
            mainAxisSpacing: spacing,
            childAspectRatio: childAspectRatio,
          ),
          itemCount: children.length,
          itemBuilder: (context, index) => children[index],
        );
      },
    );
  }
}

/// Section header widget for desktop layouts
class DesktopSectionHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final List<Widget>? actions;

  const DesktopSectionHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.actions,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.lg),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTextStyles.h2),
                if (subtitle != null) ...[
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    subtitle!,
                    style: AppTextStyles.muted,
                  ),
                ],
              ],
            ),
          ),
          if (actions != null)
            Row(
              mainAxisSize: MainAxisSize.min,
              children: actions!,
            ),
        ],
      ),
    );
  }
}

/// Stats card widget for dashboards
class StatsCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color? color;
  final String? trend;
  final bool? isPositiveTrend;

  const StatsCard({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    this.color,
    this.trend,
    this.isPositiveTrend,
  });

  @override
  Widget build(BuildContext context) {
    final cardColor = color ?? AppColors.primary;

    return DesktopCard(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(AppSpacing.sm),
                decoration: BoxDecoration(
                  color: cardColor.withOpacity(0.1),
                  borderRadius: AppRadius.circularMd,
                ),
                child: Icon(
                  icon,
                  color: cardColor,
                  size: 24,
                ),
              ),
              const Spacer(),
              if (trend != null)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: (isPositiveTrend ?? true)
                        ? AppColors.successLight
                        : AppColors.errorLight,
                    borderRadius: AppRadius.circularSm,
                  ),
                  child: Text(
                    trend!,
                    style: AppTextStyles.caption.copyWith(
                      color: (isPositiveTrend ?? true)
                          ? AppColors.success
                          : AppColors.error,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            value,
            style: AppTextStyles.h2.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            label,
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
