import '../service_locator.dart';
import '../di_logger.dart';
import 'example_services.dart';

void main() {
  // Enable logging to see what's happening
  DILogger.enable();

  print('\n=== Basic Service Locator Usage ===\n');
  basicUsage();

  print('\n=== Scoped Service Locator Usage ===\n');
  scopedUsage();

  print('\n=== Disposal Example ===\n');
  disposalExample();

  print('\n=== Factory Example ===\n');
  factoryExample();
}

void basicUsage() {
  // Register services
  locator.registerSingleton<AuthService>(AuthService());
  locator.registerLazySingleton<DatabaseService>(() {
    final db = DatabaseService();
    db.connect();
    return db;
  });

  // Register with dependencies
  locator.registerFactory<UserRepository>(() => UserRepository(
        authService: locator.get<AuthService>(),
        databaseService: locator.get<DatabaseService>(),
      ));

  locator.registerFactory<LoginUseCase>(() => LoginUseCase(
        repository: locator.get<UserRepository>(),
      ));

  // Use services
  final loginUseCase = locator.get<LoginUseCase>();
  print('LoginUseCase retrieved successfully');

  // Check registration
  print('AuthService registered: ${locator.isRegistered<AuthService>()}');

  // Get info
  print('Registered services: ${locator.getRegistrationInfo()}');
}

void scopedUsage() {
  // Create a scope for a feature or screen
  final scope = locator.createScope(name: 'ProfileScreen');

  // Register services specific to this scope
  scope.registerSingleton<FileStorageService>(FileStorageService());

  // Use scoped service
  final fileStorage = scope.get<FileStorageService>();
  fileStorage.openFile('profile.jpg');

  // Can still access global services
  final authService = scope.get<AuthService>();
  print('Auth from scope: ${authService.isAuthenticated}');

  // Dispose the scope when done (e.g., when leaving the screen)
  scope.dispose();
  print('Scope disposed - all scoped services cleaned up');
}

void disposalExample() {
  // Register a disposable service
  final dbService = DatabaseService();
  dbService.connect();
  locator.registerSingleton<DatabaseService>(dbService);

  // Use it
  final db = locator.get<DatabaseService>();
  db.query('SELECT * FROM users');

  // Unregister and it will automatically dispose
  locator.unregister<DatabaseService>();
  print('DatabaseService unregistered and disposed');
}

void factoryExample() {
  // Factory creates new instance each time
  locator.registerFactory<UserRepository>(() {
    print('Creating new UserRepository instance');
    return UserRepository(
      authService: locator.get<AuthService>(),
      databaseService: locator.get<DatabaseService>(),
    );
  });

  // Each get creates a new instance
  final repo1 = locator.get<UserRepository>();
  final repo2 = locator.get<UserRepository>();

  print('Are they the same instance? ${identical(repo1, repo2)}'); // false
}
