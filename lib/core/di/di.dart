/// Dependency Injection & Service Locator
///
/// A lightweight DI container and service locator implementation.
///
/// ## Quick Start
/// ```dart
/// // Setup
/// locator.registerSingleton<AuthService>(AuthService());
/// locator.registerLazySingleton<DatabaseService>(() => DatabaseService());
/// locator.registerFactory<UserRepository>(() => UserRepository());
///
/// // Use
/// final auth = locator.get<AuthService>();
///
/// // Scoped
/// final scope = locator.createScope(name: 'MyScreen');
/// scope.registerSingleton<ScreenCache>(ScreenCache());
/// scope.dispose();
/// ```
library;

export 'di_container.dart';
export 'service_locator.dart';
export 'disposable.dart';
export 'di_logger.dart';
export 'app_composition.dart';
