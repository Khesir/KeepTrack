# Dependency Injection & Service Locator

A lightweight, custom DI container and service locator implementation for Flutter, inspired by game development design patterns.

## Features

- **Service Locator Pattern** - Global service access without context
- **DI Container** - Dependency injection with auto-resolution
- **Scoped Services** - Manage service lifetime per screen/feature
- **Disposable Interface** - Automatic cleanup of resources
- **Toggle Logger** - Debug your dependency graph
- **Zero Dependencies** - No external packages required

## Components

### 1. DiContainer (`di_container.dart`)

Core container for managing service registration and resolution.

**Registration Types:**
- `registerSingleton<T>()` - Single instance created immediately
- `registerLazySingleton<T>()` - Single instance created on first access
- `registerFactory<T>()` - New instance created on each access

**Features:**
- `get<T>()` - Resolve a service
- `isRegistered<T>()` - Check if service exists
- `unregister<T>()` - Remove service and dispose if Disposable
- `reset()` - Clear all services and dispose Disposables
- `getRegistrationInfo()` - Get info about all registered services

### 2. ServiceLocator (`service_locator.dart`)

Global singleton wrapper around DiContainer.

```dart
// Global instance
final locator = ServiceLocator.instance;

// Usage
locator.registerSingleton<AuthService>(AuthService());
final auth = locator.get<AuthService>();
```

### 3. ScopedServiceLocator (`service_locator.dart`)

Scoped container for managing service lifetime within a specific context (e.g., a screen).

```dart
// Create scope
final scope = locator.createScope(name: 'ProfileScreen');

// Register scoped services
scope.registerSingleton<FileService>(FileService());

// Get service (falls back to global if not in scope)
final fileService = scope.get<FileService>();

// Dispose scope and all its services
scope.dispose();
```

### 4. Disposable Interface (`disposable.dart`)

Interface for services that need cleanup.

```dart
class DatabaseService implements Disposable {
  @override
  void dispose() {
    // Close connections, free resources, etc.
  }
}
```

### 5. DILogger (`di_logger.dart`)

Toggle-able logger for debugging dependency operations.

```dart
// Enable logging
DILogger.enable();

// Disable logging
DILogger.disable();

// Toggle
DILogger.toggle();
```

## Quick Start

### 1. Setup Dependencies

```dart
// lib/core/setup_dependencies.dart
import 'di/service_locator.dart';

void setupDependencies() {
  // Core services
  locator.registerSingleton<AuthService>(AuthService());

  locator.registerLazySingleton<DatabaseService>(() {
    final db = DatabaseService();
    db.connect();
    return db;
  });

  // Repositories with dependencies
  locator.registerFactory<UserRepository>(() => UserRepository(
    authService: locator.get<AuthService>(),
    databaseService: locator.get<DatabaseService>(),
  ));

  // Use cases
  locator.registerFactory<LoginUseCase>(() => LoginUseCase(
    repository: locator.get<UserRepository>(),
  ));
}
```

### 2. Initialize in Main

```dart
void main() {
  setupDependencies();

  // Optional: Enable logging in debug mode
  // DILogger.enable();

  runApp(MyApp());
}
```

### 3. Use in Widgets

```dart
class LoginPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: _handleLogin,
      child: Text('Login'),
    );
  }

  Future<void> _handleLogin() async {
    // Get service from locator
    final loginUseCase = locator.get<LoginUseCase>();
    final user = await loginUseCase.execute('email', 'password');
  }
}
```

### 4. Use Scoped Services

```dart
class ProfilePage extends StatefulWidget {
  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  late ScopedServiceLocator _scope;

  @override
  void initState() {
    super.initState();

    // Create scope for this page
    _scope = locator.createScope(name: 'ProfilePage');

    // Register page-specific services
    _scope.registerSingleton<ProfileCache>(ProfileCache());
  }

  @override
  void dispose() {
    // Automatically disposes all scoped services
    _scope.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Use scoped service
    final cache = _scope.get<ProfileCache>();

    // Can still access global services
    final auth = _scope.get<AuthService>();

    return Container();
  }
}
```

## Usage Patterns

### Singleton Services

For services that should have only one instance throughout the app.

```dart
locator.registerSingleton<AuthService>(AuthService());
```

### Lazy Singletons

For expensive services that should be created only when first needed.

```dart
locator.registerLazySingleton<DatabaseService>(() {
  final db = DatabaseService();
  db.connect();
  return db;
});
```

### Factories

For services that should create a new instance each time.

```dart
locator.registerFactory<HttpClient>(() => HttpClient());
```

### Disposable Services

Services that implement `Disposable` are automatically cleaned up.

```dart
class CacheService implements Disposable {
  @override
  void dispose() {
    // Clear cache, close connections, etc.
  }
}

locator.registerSingleton<CacheService>(CacheService());

// When unregistered, dispose() is called automatically
locator.unregister<CacheService>();
```

### Scoped Services

For services with limited lifetime (e.g., per screen, per feature).

```dart
// In StatefulWidget
@override
void initState() {
  super.initState();
  _scope = locator.createScope(name: 'MyScreen');
  _scope.registerSingleton<ScreenCache>(ScreenCache());
}

@override
void dispose() {
  _scope.dispose(); // Cleans up all scoped services
  super.dispose();
}
```

## Memory Management

### Preventing Memory Leaks

1. **Use Scoped Services** for screen-specific or feature-specific services
2. **Implement Disposable** for services with resources (connections, streams, etc.)
3. **Unregister** services when no longer needed
4. **Reset** the container on app termination

```dart
class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.detached) {
      // Clean up all services
      locator.reset();
    }
  }

  @override
  Widget build(BuildContext context) => MaterialApp();
}
```

## Debugging

Enable logging to see what's happening:

```dart
void main() {
  DILogger.enable();
  setupDependencies();
  runApp(MyApp());
}
```

Output:
```
[DI] 📦 Registered singleton: AuthService
[DI] 💤 Registered lazy singleton: DatabaseService
[DI] 🏭 Registered factory: UserRepository
[DI] ✅ Resolved: AuthService
[DI] 🔷 Created scope: ProfilePage
[DI] ❌ Unregistered: AuthService
[DI] 🗑️  Disposed: DatabaseService
```

## Testing

Reset the container between tests:

```dart
void main() {
  setUp(() {
    locator.reset();
  });

  test('should login user', () {
    // Register test dependencies
    locator.registerSingleton<AuthService>(MockAuthService());

    // Test code...
  });
}
```

## Why This Approach?

- **No BuildContext needed** - Access services anywhere
- **Clean architecture** - Separates concerns (UI, business logic, data)
- **Testable** - Easy to mock dependencies
- **Lightweight** - No external dependencies
- **Game dev inspired** - Simple, direct patterns
- **Memory safe** - Built-in disposal and scoping

## Examples

See the `examples/` directory for:
- `example_services.dart` - Sample services and use cases
- `usage_example.dart` - Console usage examples
- `flutter_usage_example.dart` - Complete Flutter app example
