# Core Module

Custom DI container, service locator, and UI base classes for Flutter - built from scratch with zero dependencies.

## What's Inside

### DI System (`di/`)

- **DiContainer** - Core dependency injection container
- **ServiceLocator** - Global singleton service locator
- **ScopedServiceLocator** - Scoped container for limited lifetimes
- **Disposable** - Interface for automatic resource cleanup
- **DILogger** - Toggle-able debug logger
- **AppComposition** - Application dependency setup

### UI Base Classes (`ui/`)

- **ScopedScreen** - StatefulWidget with automatic scope management
- **BaseScreen** - Simple screen with disposal pattern

## Quick Start

### 1. Setup Dependencies

```dart
// lib/main.dart
import 'core/core.dart';

void main() {
  // Register services
  locator.registerSingleton<AuthService>(AuthService());
  locator.registerFactory<LoginUseCase>(() => LoginUseCase(
    authService: locator.get<AuthService>(),
  ));

  runApp(MyApp());
}
```

### 2. Create Screens

```dart
// With scoping
class ProfileScreen extends ScopedScreen {
  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ScopedScreenState<ProfileScreen> {
  @override
  void registerServices() {
    registerSingleton<ProfileCache>(ProfileCache());
  }

  @override
  void onReady() {
    final cache = getService<ProfileCache>();
    // Load data...
  }

  @override
  Widget build(BuildContext context) => Container();
}
```

```dart
// Without scoping
class SimpleScreen extends BaseScreen {
  @override
  State<SimpleScreen> createState() => _SimpleScreenState();
}

class _SimpleScreenState extends BaseScreenState<SimpleScreen> {
  @override
  Widget build(BuildContext context) => Container();
}
```

### 3. Use Services

```dart
// Anywhere in your app (no BuildContext needed!)
final authService = locator.get<AuthService>();
final loginUseCase = locator.get<LoginUseCase>();
```

## Features

### ✅ Service Locator Pattern
- Global access without BuildContext
- Game dev inspired design
- Simple and direct

### ✅ Dependency Injection
- Constructor injection
- Factory functions
- Auto-resolution

### ✅ Service Lifetimes
- **Singleton** - Created immediately, single instance
- **Lazy Singleton** - Created on first access, single instance
- **Factory** - New instance every time
- **Scoped** - Lives within a specific scope (e.g., screen)

### ✅ Automatic Disposal
- `Disposable` interface
- Scoped service cleanup
- Memory leak prevention

### ✅ Debug Logging
- Toggle on/off
- Emoji-based logs
- Track all DI operations

### ✅ Type-Safe
- Full generic support
- Compile-time checks
- No runtime magic

### ✅ Zero Dependencies
- No external packages
- Built from scratch
- Full control

## Documentation

- **[QUICK_START.md](QUICK_START.md)** - Get started in 5 minutes
- **[di/README.md](di/README.md)** - DI system details
- **[ui/README.md](ui/README.md)** - Screen base classes
- **[examples/](examples/)** - Complete examples

## Examples

- `di/examples/usage_example.dart` - DI usage
- `di/examples/flutter_usage_example.dart` - Flutter integration
- `di/examples/testing_example.dart` - Testing patterns
- `ui/examples/scoped_screen_example.dart` - Screen examples
- `ui/examples/advanced_patterns.dart` - Advanced patterns
- `examples/complete_app_example.dart` - Full app example

## Architecture

```
lib/core/
├── core.dart                          # Barrel export
├── QUICK_START.md                     # Quick reference
├── README.md                          # This file
│
├── di/                                # DI System
│   ├── di.dart                        # DI barrel export
│   ├── di_container.dart              # Core container
│   ├── service_locator.dart           # Global + Scoped locators
│   ├── disposable.dart                # Disposal interface
│   ├── di_logger.dart                 # Debug logger
│   ├── app_composition.dart           # App setup
│   ├── README.md                      # DI documentation
│   └── examples/
│       ├── usage_example.dart
│       ├── flutter_usage_example.dart
│       └── testing_example.dart
│
├── ui/                                # UI Base Classes
│   ├── ui.dart                        # UI barrel export
│   ├── scoped_screen.dart             # Scoped screen base
│   ├── base_screen.dart               # Simple screen base
│   ├── README.md                      # UI documentation
│   └── examples/
│       ├── scoped_screen_example.dart
│       ├── advanced_patterns.dart
│       └── testing_example.dart
│
└── examples/
    └── complete_app_example.dart      # Full app example
```

## Import Options

### Import Everything
```dart
import 'package:personal_codex/core/core.dart';
```

### Import DI Only
```dart
import 'package:personal_codex/core/di/di.dart';
```

### Import UI Only
```dart
import 'package:personal_codex/core/ui/ui.dart';
```

### Import Specific
```dart
import 'package:personal_codex/core/di/service_locator.dart';
import 'package:personal_codex/core/ui/scoped_screen.dart';
```

## Design Philosophy

This implementation is inspired by game development patterns where:

1. **Simplicity over complexity** - Direct patterns, no magic
2. **Control over convenience** - Full visibility and control
3. **Performance matters** - Minimal overhead
4. **No hidden dependencies** - Everything explicit
5. **Manual > Automatic** - Predictable behavior

## When to Use

### Use This When:
- Building mobile apps with Flutter
- Want full control over DI
- Prefer service locator pattern
- Need scoped service management
- Want zero external dependencies
- Like game dev design patterns

### Don't Use When:
- You need reactive state management (use Provider/Riverpod)
- You want automatic code generation (use get_it + injectable)
- You prefer purely functional approaches
- You need complex DI features (like decorators, interceptors)

## Memory Management

The system helps prevent memory leaks through:

1. **Disposable Interface** - Automatic cleanup
2. **Scoped Services** - Limited lifetime
3. **Manual Unregister** - Explicit control
4. **Reset Function** - Clean slate

Always:
- Implement `Disposable` for services with resources
- Use `ScopedServiceLocator` for screen-specific services
- Call `locator.reset()` in tests
- Override `onDispose()` in screens for cleanup

## Testing

```dart
void main() {
  setUp(() {
    locator.reset();
    DILogger.enable();
  });

  test('should work', () {
    locator.registerSingleton<MockService>(MockService());
    // Test...
  });

  tearDown(() {
    locator.reset();
  });
}
```

## Contributing

This is a custom implementation for this project. Feel free to modify and extend based on your needs.

## License

Part of Personal Codex project.

## Credits

Inspired by:
- Game development service locator patterns
- GetIt (package architecture)
- Unity's dependency injection
- Clean Architecture principles
