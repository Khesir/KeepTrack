import 'package:flutter/material.dart';
import '../di/service_locator.dart';
import '../di/disposable.dart';

/// Base class for screens that need scoped services and disposal
abstract class ScopedScreen extends StatefulWidget {
  const ScopedScreen({super.key});

  /// Optional scope name. If null, uses the runtime type name
  String? get scopeName => null;
}

/// Base state for ScopedScreen with automatic scope management
abstract class ScopedScreenState<W extends ScopedScreen> extends State<W>
    implements Disposable {
  late final ScopedServiceLocator scope;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();

    // Create scope with widget's name or runtime type
    final name = widget.scopeName ?? widget.runtimeType.toString();
    scope = locator.createScope(name: name);

    // Register scoped services
    registerServices();

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
    // Call subclass disposal first
    if (_isInitialized) {
      onDispose();
    }

    // Dispose the scope (automatically disposes all scoped services)
    scope.dispose();

    super.dispose();
  }

  /// Override to register screen-specific services
  /// Called during initState
  void registerServices() {}

  /// Override for post-build initialization logic
  /// Called after the first frame is rendered
  /// Safe to configure layout
  void onReady() {}

  /// Override to clean up resources
  /// Called before scope disposal
  void onDispose() {}

  /// Get a service from scope (falls back to global)
  T getService<T>({bool useGlobalFallback = true}) {
    return scope.get<T>(useGlobalFallback: useGlobalFallback);
  }

  /// Register a service in this scope
  void registerSingleton<T>(T instance) {
    scope.registerSingleton<T>(instance);
  }

  /// Register a lazy singleton in this scope
  void registerLazySingleton<T>(T Function() factory) {
    scope.registerLazySingleton<T>(factory);
  }

  /// Register a factory in this scope
  void registerFactory<T>(T Function() factory) {
    scope.registerFactory<T>(factory);
  }
}
