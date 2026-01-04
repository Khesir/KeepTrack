import 'package:flutter/material.dart';
import 'package:keep_track/shared/presentation/theme_mode_indicator.dart';

/// Reusable layout wrapper for non-tabbed screens
/// Provides consistent AppBar, loading overlay, and optional FAB
/// Use this for Settings, Detail pages, and other full-screen routes
class AppLayout extends StatelessWidget {
  final String? title;
  final Widget body;
  final bool loading;
  final PreferredSizeWidget? appBar;

  const AppLayout({
    super.key,
    this.title,
    required this.body,
    this.appBar,
    this.loading = false,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar:
          appBar ??
          AppBar(
            title: Text(
              title ?? '',
              style: TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 24,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            actions: const [
              Padding(
                padding: EdgeInsets.only(right: 16),
                child: ThemeModeIndicator(),
              ),
            ],
          ),
      body: Stack(
        children: [
          body,
          if (loading)
            Container(
              color: Colors.black45,
              child: const Center(child: CircularProgressIndicator()),
            ),
        ],
      ),
    );
  }
}
