# Quick Start Guide

Complete guide to using the custom DI system with Flutter screens.

## Installation

No external dependencies needed! Everything is built from scratch.

## Setup (3 steps)

### 1. Register Dependencies

```dart
// lib/core/setup.dart
import 'di/service_locator.dart';

void setupDependencies() {
  // Core services
  locator.registerSingleton<AuthService>(AuthService());
  locator.registerLazySingleton<Database>(() => Database());

  // Repositories
  locator.registerFactory<UserRepository>(() => UserRepository(
    authService: locator.get<AuthService>(),
  ));

  // Use cases
  locator.registerFactory<LoginUseCase>(() => LoginUseCase(
    repository: locator.get<UserRepository>(),
  ));
}
```

### 2. Initialize in Main

```dart
// lib/main.dart
import 'core/setup.dart';

void main() {
  setupDependencies();
  runApp(MyApp());
}
```

### 3. Use in Screens

```dart
// lib/screens/login_screen.dart
import 'package:flutter/material.dart';
import '../core/ui/scoped_screen.dart';
import '../core/di/service_locator.dart';

class LoginScreen extends ScopedScreen {
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ScopedScreenState<LoginScreen> {
  @override
  void onReady() {
    final loginUseCase = getService<LoginUseCase>();
    // Use it...
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Login')),
      body: Container(),
    );
  }
}
```

## Common Patterns

### Pattern 1: Global Service

```dart
// Setup
locator.registerSingleton<AuthService>(AuthService());

// Use anywhere
final auth = locator.get<AuthService>();
```

### Pattern 2: Scoped Service (Screen-specific)

```dart
class ProfileScreen extends ScopedScreen {
  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ScopedScreenState<ProfileScreen> {
  @override
  void registerServices() {
    // This cache only lives while screen is active
    registerSingleton<ProfileCache>(ProfileCache());
  }

  @override
  void onDispose() {
    // Cache automatically disposed when screen is popped
  }

  @override
  Widget build(BuildContext context) {
    final cache = getService<ProfileCache>();
    return Container();
  }
}
```

### Pattern 3: Disposable Service

```dart
class DatabaseService implements Disposable {
  void connect() { /* ... */ }

  @override
  void dispose() {
    // Automatically called when unregistered
    print('Database connection closed');
  }
}

// Register
locator.registerSingleton<DatabaseService>(DatabaseService());

// Unregister (dispose called automatically)
locator.unregister<DatabaseService>();
```

### Pattern 4: Factory (New instance each time)

```dart
// Setup
locator.registerFactory<HttpClient>(() => HttpClient());

// Each call creates new instance
final client1 = locator.get<HttpClient>();
final client2 = locator.get<HttpClient>();
// client1 != client2
```

### Pattern 5: Lazy Singleton (Created on first access)

```dart
// Setup (not created yet)
locator.registerLazySingleton<Database>(() {
  print('Database created!');
  return Database();
});

// First access creates it
final db = locator.get<Database>();  // Prints: "Database created!"

// Subsequent access returns same instance
final db2 = locator.get<Database>(); // No print
```

## Screen Base Classes

### ScopedScreen - With scoped services

```dart
class MyScreen extends ScopedScreen {
  @override
  State<MyScreen> createState() => _MyScreenState();
}

class _MyScreenState extends ScopedScreenState<MyScreen> {
  // Register screen-specific services
  @override
  void registerServices() {
    registerSingleton<ScreenCache>(ScreenCache());
  }

  // Called after first frame
  @override
  void onReady() {
    _loadData();
  }

  // Called before disposal
  @override
  void onDispose() {
    // Cleanup
  }

  @override
  Widget build(BuildContext context) {
    final cache = getService<ScreenCache>();
    return Container();
  }
}
```

### BaseScreen - Without scoping

```dart
class SimpleScreen extends BaseScreen {
  @override
  State<SimpleScreen> createState() => _SimpleScreenState();
}

class _SimpleScreenState extends BaseScreenState<SimpleScreen> {
  @override
  void onReady() {
    print('Screen ready');
  }

  @override
  void onDispose() {
    print('Screen disposing');
  }

  @override
  Widget build(BuildContext context) {
    return Container();
  }
}
```

## Debugging

Enable logging to see what's happening:

```dart
import 'core/di/di_logger.dart';

void main() {
  DILogger.enable();  // See all DI operations
  setupDependencies();
  runApp(MyApp());
}
```

Output:
```
[DI] 📦 Registered singleton: AuthService
[DI] 💤 Registered lazy singleton: Database
[DI] 🏭 Registered factory: UserRepository
[DI] ✅ Resolved: AuthService
[DI] 🔷 Created scope: ProfileScreen
[DI] ❌ Unregistered: AuthService
[DI] 🗑️  Disposed: DatabaseService
```

Toggle logging:
```dart
DILogger.toggle();  // Turn on/off
DILogger.disable(); // Turn off
```

## Complete Example

```dart
// ===== Setup =====
void setupDependencies() {
  locator.registerSingleton<AuthService>(AuthService());
  locator.registerFactory<LoginUseCase>(() => LoginUseCase(
    authService: locator.get<AuthService>(),
  ));
}

void main() {
  setupDependencies();
  runApp(MaterialApp(home: LoginScreen()));
}

// ===== Screen =====
class LoginScreen extends ScopedScreen {
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ScopedScreenState<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void onDispose() {
    _emailController.dispose();
    _passwordController.dispose();
  }

  Future<void> _login() async {
    final loginUseCase = getService<LoginUseCase>();
    await loginUseCase.execute(
      _emailController.text,
      _passwordController.text,
    );
    // Navigate...
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          TextField(controller: _emailController),
          TextField(controller: _passwordController),
          ElevatedButton(onPressed: _login, child: Text('Login')),
        ],
      ),
    );
  }
}
```

## Testing

```dart
void main() {
  setUp(() {
    locator.reset();  // Clean slate
  });

  test('should login', () {
    // Register mocks
    locator.registerSingleton<AuthService>(MockAuthService());

    // Test...
  });
}
```

## Memory Management Checklist

- ✅ Use `Disposable` interface for services with resources
- ✅ Use `ScopedServiceLocator` for screen-specific services
- ✅ Unregister services when no longer needed
- ✅ Call `locator.reset()` on app termination
- ✅ Override `onDispose()` for manual cleanup

## Architecture

```
lib/
├── core/
│   ├── di/
│   │   ├── di_container.dart          # Core DI container
│   │   ├── service_locator.dart       # Global + Scoped locators
│   │   ├── disposable.dart            # Disposal interface
│   │   ├── di_logger.dart             # Debug logger
│   │   └── app_composition.dart       # Setup function
│   └── ui/
│       ├── scoped_screen.dart         # Screen with scoping
│       └── base_screen.dart           # Screen without scoping
├── services/                          # Core services
├── repositories/                      # Data layer
├── use_cases/                         # Domain layer
└── screens/                           # Presentation layer
```

## Next Steps

1. Read `core/di/README.md` for DI details
2. Read `core/ui/README.md` for screen base classes
3. Check `core/examples/complete_app_example.dart` for full example
4. Look at `core/ui/examples/advanced_patterns.dart` for patterns

## Cheat Sheet

| Action | Code |
|--------|------|
| Register singleton | `locator.registerSingleton<T>(instance)` |
| Register lazy singleton | `locator.registerLazySingleton<T>(() => T())` |
| Register factory | `locator.registerFactory<T>(() => T())` |
| Get service | `locator.get<T>()` |
| Unregister | `locator.unregister<T>()` |
| Reset all | `locator.reset()` |
| Create scope | `locator.createScope(name: 'Name')` |
| Enable logging | `DILogger.enable()` |
| Scoped screen | `extends ScopedScreen` + `ScopedScreenState` |
| Simple screen | `extends BaseScreen` + `BaseScreenState` |
