import 'package:flutter/material.dart';

/// Responsive breakpoints for the app
class ResponsiveBreakpoints {
  /// Breakpoint for desktop layout (large tablets and desktops)
  static const double desktop = 900;

  /// Breakpoint for tablet layout
  static const double tablet = 600;

  /// Breakpoint for mobile layout
  static const double mobile = 0;

  ResponsiveBreakpoints._();
}

/// Extension on BuildContext for responsive utilities
extension ResponsiveContext on BuildContext {
  /// Check if the current screen is desktop size
  bool get isDesktop => MediaQuery.of(this).size.width >= ResponsiveBreakpoints.desktop;

  /// Check if the current screen is tablet size
  bool get isTablet =>
      MediaQuery.of(this).size.width >= ResponsiveBreakpoints.tablet &&
      MediaQuery.of(this).size.width < ResponsiveBreakpoints.desktop;

  /// Check if the current screen is mobile size
  bool get isMobile => MediaQuery.of(this).size.width < ResponsiveBreakpoints.tablet;

  /// Get the current screen width
  double get screenWidth => MediaQuery.of(this).size.width;

  /// Get the current screen height
  double get screenHeight => MediaQuery.of(this).size.height;
}

/// Widget builder for responsive layouts
class ResponsiveBuilder extends StatelessWidget {
  final Widget Function(BuildContext context, bool isDesktop) builder;

  const ResponsiveBuilder({
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
