# UI Base Classes

Base screen classes for Flutter with automatic scoped service management and disposal patterns.

## Overview

Two base classes to streamline screen development:

1. **ScopedScreen** - For screens that need scoped services (automatically managed lifetime)
2. **BaseScreen** - For simple screens that just need disposal pattern

## ScopedScreen

Extends `StatefulWidget` with automatic scope management.

### Features

- **Automatic scope creation/disposal** - Creates scope on init, disposes on widget disposal
- **Scoped service registration** - Register screen-specific services
- **Global service fallback** - Access global services when not found in scope
- **Lifecycle hooks** - `onReady()`, `onDispose()`, `registerServices()`
- **Memory safe** - All scoped services automatically disposed

### Basic Usage

```dart
class ProfileScreen extends ScopedScreen {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ScopedScreenState<ProfileScreen> {
  @override
  void registerServices() {
    // Register screen-specific services
    registerSingleton<ProfileCache>(ProfileCache());
  }

  @override
  void onReady() {
    // Called after first frame is rendered
    _loadData();
  }

  @override
  void onDispose() {
    // Clean up resources before scope disposal
    print('Cleaning up...');
  }

  @override
  Widget build(BuildContext context) {
    // Access scoped or global services
    final cache = getService<ProfileCache>();

    return Scaffold(
      appBar: AppBar(title: Text('Profile')),
      body: Container(),
    );
  }
}
```

### Lifecycle Methods

#### `void registerServices()`
Called during `initState()`. Override to register screen-specific services.

```dart
@override
void registerServices() {
  registerSingleton<ScreenCache>(ScreenCache());
  registerFactory<ApiClient>(() => ApiClient());
  registerLazySingleton<Database>(() => Database());
}
```

#### `void onReady()`
Called after the first frame is rendered. Use for initialization that needs `BuildContext` or after-build logic.

```dart
@override
void onReady() {
  // Load data, show dialogs, navigate, etc.
  _loadInitialData();
}
```

#### `void onDispose()`
Called before scope disposal. Override to clean up resources.

```dart
@override
void onDispose() {
  // Close streams, cancel timers, etc.
  _streamController.close();
}
```

### Service Registration

#### Register in scope
```dart
registerSingleton<T>(instance);
registerLazySingleton<T>(() => T());
registerFactory<T>(() => T());
```

#### Get service
```dart
final service = getService<MyService>();

// Don't fallback to global
final service = getService<MyService>(useGlobalFallback: false);
```

### Custom Scope Name

```dart
class ProfileScreen extends ScopedScreen {
  @override
  String? get scopeName => 'UserProfile';  // Custom name

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}
```

## BaseScreen

Simple base class for screens that need disposal but not scoping.

### Features

- **Lifecycle hooks** - `onReady()`, `onDispose()`
- **Implements Disposable** - Clean disposal pattern
- **Lightweight** - No scope overhead

### Basic Usage

```dart
class CounterScreen extends BaseScreen {
  const CounterScreen({super.key});

  @override
  State<CounterScreen> createState() => _CounterScreenState();
}

class _CounterScreenState extends BaseScreenState<CounterScreen> {
  int _counter = 0;

  @override
  void onReady() {
    print('Screen ready');
  }

  @override
  void onDispose() {
    print('Final count: $_counter');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(child: Text('$_counter')),
    );
  }
}
```

## Lifecycle Comparison

### ScopedScreen Lifecycle
```
initState()
  ↓
createScope(name)
  ↓
registerServices()
  ↓
build()
  ↓
onReady() (post-frame)
  ↓
... widget active ...
  ↓
onDispose()
  ↓
scope.dispose() (auto-disposes all scoped services)
  ↓
dispose()
```

### BaseScreen Lifecycle
```
initState()
  ↓
build()
  ↓
onReady() (post-frame)
  ↓
... widget active ...
  ↓
onDispose()
  ↓
dispose()
```

## Examples

### Example 1: Screen with Scoped Services

```dart
class SettingsScreen extends ScopedScreen {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ScopedScreenState<SettingsScreen> {
  late SettingsRepository _repository;

  @override
  void registerServices() {
    // Register screen-specific cache
    registerSingleton<SettingsCache>(SettingsCache());

    // Register repository with dependency
    final cache = getService<SettingsCache>();
    registerSingleton<SettingsRepository>(SettingsRepository(cache));
  }

  @override
  void onReady() {
    _repository = getService<SettingsRepository>();
    _loadSettings();
  }

  @override
  void onDispose() {
    _repository.saveAll();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Settings')),
      body: Container(),
    );
  }
}
```

### Example 2: Accessing Global Services

```dart
class DashboardScreen extends ScopedScreen {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ScopedScreenState<DashboardScreen> {
  @override
  void registerServices() {
    // Register scoped services
    registerSingleton<DashboardCache>(DashboardCache());
  }

  @override
  Widget build(BuildContext context) {
    // Access global service (registered in main)
    final authService = getService<AuthService>();

    // Access scoped service
    final cache = getService<DashboardCache>();

    return Scaffold(
      appBar: AppBar(title: Text('Dashboard')),
      body: Text(authService.isAuthenticated ? 'Logged In' : 'Not Logged In'),
    );
  }
}
```

### Example 3: Simple Screen without Scoping

```dart
class AboutScreen extends BaseScreen {
  const AboutScreen({super.key});

  @override
  State<AboutScreen> createState() => _AboutScreenState();
}

class _AboutScreenState extends BaseScreenState<AboutScreen> {
  @override
  void onReady() {
    // Log analytics
    print('About screen opened');
  }

  @override
  void onDispose() {
    print('About screen closed');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('About')),
      body: Center(child: Text('Version 1.0.0')),
    );
  }
}
```

## When to Use What?

### Use ScopedScreen when:
- Screen needs its own services (cache, API clients, controllers)
- Services should be disposed when leaving the screen
- You want automatic memory management
- Screen has complex state/logic that benefits from DI

### Use BaseScreen when:
- Simple screens with minimal logic
- No need for scoped services
- Just need disposal pattern for cleanup
- Want lightweight base class

### Use neither when:
- Very simple static screens
- No disposal needed
- Direct StatelessWidget/StatefulWidget is sufficient

## Memory Management

### Automatic Disposal
All scoped services are automatically disposed when the screen is disposed:

```dart
@override
void registerServices() {
  // This service implements Disposable
  registerSingleton<DatabaseConnection>(DatabaseConnection());
}

// When screen is popped/disposed:
// 1. onDispose() is called
// 2. scope.dispose() is called
// 3. DatabaseConnection.dispose() is called automatically
```

### Manual Cleanup
Use `onDispose()` for manual cleanup:

```dart
@override
void onDispose() {
  _streamController.close();
  _timer?.cancel();
  _animationController.dispose();
}
```

## Best Practices

1. **Register services in `registerServices()`**, not in `initState()`
2. **Use `onReady()` for post-build logic**, not `initState()`
3. **Clean up in `onDispose()`**, not in `dispose()`
4. **Implement `Disposable`** for services that need cleanup
5. **Use scoped services** for screen-specific logic
6. **Access global services** for app-wide state
7. **Don't store `BuildContext`** in state fields

## Integration with DI System

```dart
// main.dart
void main() {
  // Register global services
  locator.registerSingleton<AuthService>(AuthService());
  locator.registerSingleton<ApiClient>(ApiClient());

  runApp(MyApp());
}

// profile_screen.dart
class _ProfileScreenState extends ScopedScreenState<ProfileScreen> {
  @override
  void registerServices() {
    // Scoped services with global dependencies
    final apiClient = getService<ApiClient>();  // From global
    registerSingleton<ProfileRepository>(ProfileRepository(apiClient));
  }

  @override
  Widget build(BuildContext context) {
    // Access both scoped and global
    final auth = getService<AuthService>();  // Global
    final repo = getService<ProfileRepository>();  // Scoped

    return Container();
  }
}
```

## Testing

```dart
void main() {
  testWidgets('ProfileScreen test', (tester) async {
    // Setup global services
    locator.registerSingleton<AuthService>(MockAuthService());

    await tester.pumpWidget(MaterialApp(home: ProfileScreen()));

    // Scoped services are automatically registered and disposed

    // Cleanup
    locator.reset();
  });
}
```

## See Also

- `../di/` - DI container and service locator implementation
- `examples/scoped_screen_example.dart` - Complete examples
