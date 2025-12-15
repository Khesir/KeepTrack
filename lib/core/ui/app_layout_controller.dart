import 'package:flutter/material.dart';

/// Controls the main app layout (AppBar, FAB, etc.)
/// Screens can use this to customize the layout
class AppLayoutController extends ChangeNotifier {
  String _title = '';
  List<Widget> _actions = [];
  Widget? _floatingActionButton;
  bool _showBottomNav = true;

  String get title => _title;
  List<Widget> get actions => _actions;
  Widget? get floatingActionButton => _floatingActionButton;
  bool get showBottomNav => _showBottomNav;

  /// Update the app bar title
  void setTitle(String title) {
    _title = title;
    notifyListeners();
  }

  /// Update app bar actions
  void setActions(List<Widget> actions) {
    _actions = actions;
    notifyListeners();
  }

  /// Update floating action button
  void setFab(Widget? fab) {
    _floatingActionButton = fab;
    notifyListeners();
  }

  /// Show/hide bottom navigation
  void setBottomNavVisibility(bool show) {
    _showBottomNav = show;
    notifyListeners();
  }

  /// Reset to defaults
  void reset() {
    _title = '';
    _actions = [];
    _floatingActionButton = null;
    _showBottomNav = true;
    notifyListeners();
  }
}

/// Screen mixin that provides easy access to layout controller
mixin AppLayoutControlled<T extends StatefulWidget> on State<T> {
  AppLayoutController? _layoutController;

  AppLayoutController get layoutController {
    if (_layoutController == null) {
      // Try to get from InheritedWidget
      _layoutController = AppLayoutProvider.of(context);
    }
    return _layoutController!;
  }

  /// Configure the layout when screen is displayed
  void configureLayout({
    String? title,
    List<Widget>? actions,
    Widget? fab,
    bool showBottomNav = true,
  }) {
    if (title != null) layoutController.setTitle(title);
    if (actions != null) layoutController.setActions(actions);
    layoutController.setFab(fab);
    layoutController.setBottomNavVisibility(showBottomNav);
  }

  @override
  void dispose() {
    // Reset layout when screen is disposed
    layoutController.reset();
    super.dispose();
  }
}

/// Provides AppLayoutController to widget tree
class AppLayoutProvider extends InheritedWidget {
  final AppLayoutController controller;

  const AppLayoutProvider({
    super.key,
    required this.controller,
    required super.child,
  });

  static AppLayoutController of(BuildContext context) {
    final provider = context
        .dependOnInheritedWidgetOfExactType<AppLayoutProvider>();
    if (provider == null) {
      throw Exception('No AppLayoutProvider found in context');
    }
    return provider.controller;
  }

  @override
  bool updateShouldNotify(AppLayoutProvider oldWidget) {
    return controller != oldWidget.controller;
  }
}
