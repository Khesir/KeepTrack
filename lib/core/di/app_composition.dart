import 'service_locator.dart';
import 'di_logger.dart';

/// Application dependency composition root
///
/// This is where you register all global services.
/// Call [setupDependencies] in your main() function before runApp().
class AppComposition {
  static bool _isInitialized = false;

  /// Setup all application dependencies
  static void setupDependencies({bool enableLogging = false}) {
    if (_isInitialized) {
      throw Exception('Dependencies already initialized. Call reset() first if needed.');
    }

    if (enableLogging) {
      DILogger.enable();
    }

    _registerCoreServices();
    _registerRepositories();
    _registerUseCases();

    _isInitialized = true;
  }

  /// Register core services (auth, storage, network, etc.)
  static void _registerCoreServices() {
    // Example:
    // locator.registerSingleton<AuthService>(AuthService());
    // locator.registerSingleton<StorageService>(StorageService());
    // locator.registerLazySingleton<DatabaseService>(() => DatabaseService());
  }

  /// Register data layer repositories
  static void _registerRepositories() {
    // Example:
    // locator.registerFactory<UserRepository>(() => UserRepository(
    //   authService: locator.get<AuthService>(),
    // ));
  }

  /// Register domain layer use cases
  static void _registerUseCases() {
    // Example:
    // locator.registerFactory<LoginUseCase>(() => LoginUseCase(
    //   repository: locator.get<UserRepository>(),
    // ));
  }

  /// Reset all dependencies (useful for testing or app restart)
  static void reset() {
    locator.reset();
    DILogger.disable();
    _isInitialized = false;
  }

  /// Check if dependencies are initialized
  static bool get isInitialized => _isInitialized;
}

/// Shorthand function to setup dependencies
void setupDependencies({bool enableLogging = false}) {
  AppComposition.setupDependencies(enableLogging: enableLogging);
}
