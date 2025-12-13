import 'package:flutter/material.dart';
import '../di/disposable.dart';

/// Base class for screens that need disposal but not scoping
abstract class BaseScreen extends StatefulWidget {
  const BaseScreen({super.key});
}

/// Base state with disposal pattern
abstract class BaseScreenState<W extends BaseScreen> extends State<W>
    implements Disposable {
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _isInitialized = true;

    // Post-frame callback for initialization logic
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        onReady();
      }
    });
  }

  @override
  void dispose() {
    if (_isInitialized) {
      onDispose();
    }
    super.dispose();
  }

  /// Override for post-build initialization logic
  /// Called after the first frame is rendered
  void onReady() {}

  /// Override to clean up resources
  void onDispose() {}
}
