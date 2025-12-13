import 'di_container.dart';
import 'di_logger.dart';

/// Global service locator
class ServiceLocator {
  ServiceLocator._();

  static final ServiceLocator _instance = ServiceLocator._();
  static ServiceLocator get instance => _instance;

  final DiContainer _container = DiContainer();

  /// Register a singleton instance
  void registerSingleton<T>(T instance) {
    _container.registerSingleton<T>(instance);
  }

  /// Register a lazy singleton
  void registerLazySingleton<T>(T Function() factory) {
    _container.registerLazySingleton<T>(factory);
  }

  /// Register a factory
  void registerFactory<T>(T Function() factory) {
    _container.registerFactory<T>(factory);
  }

  /// Get a service
  T get<T>() {
    return _container.get<T>();
  }

  /// Check if registered
  bool isRegistered<T>() {
    return _container.isRegistered<T>();
  }

  /// Unregister a service
  void unregister<T>() {
    _container.unregister<T>();
  }

  /// Reset all services
  void reset() {
    _container.reset();
  }

  /// Get registration info
  Map<Type, String> getRegistrationInfo() {
    return _container.getRegistrationInfo();
  }

  /// Create a scoped service locator
  ScopedServiceLocator createScope({String? name}) {
    DILogger.createScope(name);
    return ScopedServiceLocator(name: name);
  }
}

/// Scoped service locator for managing service lifetime within a scope
class ScopedServiceLocator {
  final DiContainer _container = DiContainer();
  final String? name;
  bool _isDisposed = false;

  ScopedServiceLocator({this.name});

  /// Register a singleton in this scope
  void registerSingleton<T>(T instance) {
    _throwIfDisposed();
    _container.registerSingleton<T>(instance);
  }

  /// Register a lazy singleton in this scope
  void registerLazySingleton<T>(T Function() factory) {
    _throwIfDisposed();
    _container.registerLazySingleton<T>(factory);
  }

  /// Register a factory in this scope
  void registerFactory<T>(T Function() factory) {
    _throwIfDisposed();
    _container.registerFactory<T>(factory);
  }

  /// Get a service from this scope, fallback to global if not found
  T get<T>({bool useGlobalFallback = true}) {
    _throwIfDisposed();

    if (_container.isRegistered<T>()) {
      return _container.get<T>();
    }

    if (useGlobalFallback) {
      return ServiceLocator.instance.get<T>();
    }

    throw Exception('Service of type $T not found in scope ${name ?? "anonymous"}');
  }

  /// Check if registered in this scope
  bool isRegistered<T>() {
    _throwIfDisposed();
    return _container.isRegistered<T>();
  }

  /// Unregister a service from this scope
  void unregister<T>() {
    _throwIfDisposed();
    _container.unregister<T>();
  }

  /// Dispose this scope and all its services
  void dispose() {
    if (_isDisposed) return;

    DILogger.disposeScope(name);
    _container.reset();
    _isDisposed = true;
  }

  /// Get registration info for this scope
  Map<Type, String> getRegistrationInfo() {
    _throwIfDisposed();
    return _container.getRegistrationInfo();
  }

  void _throwIfDisposed() {
    if (_isDisposed) {
      throw Exception('Scope ${name ?? "anonymous"} has been disposed');
    }
  }
}

/// Shorthand for global service locator
final locator = ServiceLocator.instance;
