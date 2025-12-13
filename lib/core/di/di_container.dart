import 'disposable.dart';
import 'di_logger.dart';

class DiContainer {
  final _services = <Type, dynamic>{};
  final _factories = <Type, Function>{};
  final _registrationTypes = <Type, _RegistrationType>{};

  /// Register a singleton instance
  void registerSingleton<T>(T instance) {
    _services[T] = instance;
    _registrationTypes[T] = _RegistrationType.singleton;
    DILogger.registerSingleton(T);
  }

  /// Register a lazy singleton (created on first access)
  void registerLazySingleton<T>(T Function() factory) {
    _factories[T] = () {
      DILogger.resolve(T);
      final instance = factory();
      _services[T] = instance;
      _factories.remove(T);
      _registrationTypes[T] = _RegistrationType.singleton;
      return instance;
    };
    _registrationTypes[T] = _RegistrationType.lazySingleton;
    DILogger.registerLazySingleton(T);
  }

  /// Register a factory (new instance on each get)
  void registerFactory<T>(T Function() factory) {
    _factories[T] = factory;
    _registrationTypes[T] = _RegistrationType.factory;
    DILogger.registerFactory(T);
  }

  /// Get a registered service
  T get<T>() {
    if (_services.containsKey(T)) {
      DILogger.resolve(T);
      return _services[T] as T;
    }
    if (_factories.containsKey(T)) {
      DILogger.resolve(T);
      return _factories[T]!() as T;
    }

    final error = 'Service of type $T not registered';
    DILogger.error(error);
    throw Exception(error);
  }

  /// Check if a type is registered
  bool isRegistered<T>() {
    return _services.containsKey(T) || _factories.containsKey(T);
  }

  /// Unregister a service and dispose if implements Disposable
  void unregister<T>() {
    if (_services.containsKey(T)) {
      final instance = _services[T];
      if (instance is Disposable) {
        DILogger.dispose(T);
        instance.dispose();
      }
      _services.remove(T);
    }
    _factories.remove(T);
    _registrationTypes.remove(T);
    DILogger.unregister(T);
  }

  /// Unregister by Type
  void unregisterByType(Type type) {
    if (_services.containsKey(type)) {
      final instance = _services[type];
      if (instance is Disposable) {
        DILogger.dispose(type);
        instance.dispose();
      }
      _services.remove(type);
    }
    _factories.remove(type);
    _registrationTypes.remove(type);
    DILogger.unregister(type);
  }

  /// Reset container and dispose all services
  void reset() {
    // Dispose all Disposable services
    for (final entry in _services.entries) {
      if (entry.value is Disposable) {
        DILogger.dispose(entry.key);
        (entry.value as Disposable).dispose();
      }
    }

    _services.clear();
    _factories.clear();
    _registrationTypes.clear();
  }

  /// Get all registered types
  List<Type> get registeredTypes => [
        ..._services.keys,
        ..._factories.keys,
      ];

  /// Get registration info
  Map<Type, String> getRegistrationInfo() {
    final info = <Type, String>{};
    for (final type in registeredTypes) {
      final regType = _registrationTypes[type];
      info[type] = regType?.name ?? 'unknown';
    }
    return info;
  }
}

enum _RegistrationType {
  singleton,
  lazySingleton,
  factory,
}
