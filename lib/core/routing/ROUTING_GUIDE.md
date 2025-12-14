# Routing Guide

## Two Approaches: Named Routes vs Direct Navigation

### Approach 1: Named Routes (Current Implementation) ✅

**What we're using**: Named routes with `onGenerateRoute`

**Pros**:
- ✅ Centralized routing logic
- ✅ Type-safe route names (constants)
- ✅ Easier to refactor (change one place)
- ✅ Better for deep linking (future web support)
- ✅ Clean separation of concerns
- ✅ Testable routing

**Example**:

```dart
// In AppRouter (core/routing/app_router.dart)
class AppRoutes {
  static const String taskList = '/tasks';
  static const String taskDetail = '/tasks/detail';
}

static Route<dynamic>? onGenerateRoute(RouteSettings settings) {
  switch (settings.name) {
    case AppRoutes.taskDetail:
      final task = settings.arguments as Task?;
      return MaterialPageRoute(
        builder: (_) => TaskDetailScreen(task: task),
      );
  }
}

// Usage in screens
Navigator.pushNamed(
  context,
  AppRoutes.taskDetail,
  arguments: task,
);

// Or using extension
context.goToTaskDetail(task);
```

---

### Approach 2: Direct Navigation (Alternative)

**What it is**: Directly instantiating widgets and pushing

**Pros**:
- ✅ Simple and straightforward
- ✅ Type-safe arguments (compile-time checking)
- ✅ Less boilerplate
- ✅ Easier for small apps

**Cons**:
- ❌ Navigation logic scattered across app
- ❌ Hard to refactor routes
- ❌ No centralized route management
- ❌ Difficult to add route guards/middleware

**Example**:

```dart
// Direct approach
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => TaskDetailScreen(task: task),
  ),
);

// With helper
void goToTaskDetail(BuildContext context, Task task) {
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => TaskDetailScreen(task: task),
    ),
  );
}
```

---

## Current Implementation Details

### 1. Route Definitions

```dart
// core/routing/app_router.dart
class AppRoutes {
  static const String home = '/';
  static const String taskList = '/tasks';
  static const String taskDetail = '/tasks/detail';
  static const String taskCreate = '/tasks/create';
}
```

### 2. Route Generator

```dart
static Route<dynamic>? onGenerateRoute(RouteSettings settings) {
  switch (settings.name) {
    case AppRoutes.taskDetail:
      final task = settings.arguments as Task?;
      return MaterialPageRoute(
        builder: (_) => TaskDetailScreen(task: task),
        settings: settings, // Preserve route settings
      );

    default:
      return MaterialPageRoute(
        builder: (_) => const UnknownRouteScreen(),
      );
  }
}
```

### 3. Navigation Helpers

```dart
// Helper class
class AppRouter {
  static Future<T?> push<T>(
    BuildContext context,
    String routeName, {
    Object? arguments,
  }) {
    return Navigator.pushNamed<T>(
      context,
      routeName,
      arguments: arguments,
    );
  }

  static Future<T?> replace<T>(
    BuildContext context,
    String routeName, {
    Object? arguments,
  }) {
    return Navigator.pushReplacementNamed<T, Object?>(
      context,
      routeName,
      arguments: arguments,
    );
  }
}

// Extension methods
extension NavigationExtensions on BuildContext {
  Future<void> goToTaskDetail(Task task) {
    return AppRouter.push(this, AppRoutes.taskDetail, arguments: task);
  }

  void goBack<T>([T? result]) {
    AppRouter.pop(this, result);
  }
}
```

### 4. Usage in Screens

```dart
// Method 1: Using Navigator directly
await Navigator.pushNamed(
  context,
  AppRoutes.taskDetail,
  arguments: task,
);

// Method 2: Using AppRouter helper
await AppRouter.push(
  context,
  AppRoutes.taskDetail,
  arguments: task,
);

// Method 3: Using extension (cleanest)
await context.goToTaskDetail(task);
```

---

## Migration Guide

### If You Want to Switch to Direct Navigation

**Before** (Named Routes):
```dart
// Navigation
context.goToTaskDetail(task);

// Router definition needed
static Route<dynamic>? onGenerateRoute(RouteSettings settings) {
  switch (settings.name) {
    case AppRoutes.taskDetail:
      final task = settings.arguments as Task?;
      return MaterialPageRoute(builder: (_) => TaskDetailScreen(task: task));
  }
}
```

**After** (Direct Navigation):
```dart
// Navigation
Navigator.push(
  context,
  MaterialPageRoute(builder: (_) => TaskDetailScreen(task: task)),
);

// No router definition needed
// Just remove onGenerateRoute from MaterialApp
```

---

## Advanced Patterns

### Pattern 1: Route Guards (Authentication)

```dart
static Route<dynamic>? onGenerateRoute(RouteSettings settings) {
  // Check authentication for protected routes
  final isAuthenticated = AuthService.isLoggedIn;

  if (!isAuthenticated && _requiresAuth(settings.name)) {
    return MaterialPageRoute(
      builder: (_) => const LoginScreen(),
    );
  }

  // Regular routing
  switch (settings.name) {
    case AppRoutes.taskDetail:
      final task = settings.arguments as Task?;
      return MaterialPageRoute(builder: (_) => TaskDetailScreen(task: task));
  }
}

static bool _requiresAuth(String? routeName) {
  return routeName != AppRoutes.login && routeName != AppRoutes.home;
}
```

### Pattern 2: Transitions

```dart
static Route<dynamic>? onGenerateRoute(RouteSettings settings) {
  switch (settings.name) {
    case AppRoutes.taskDetail:
      final task = settings.arguments as Task?;
      return PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) {
          return TaskDetailScreen(task: task);
        },
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(1, 0),
              end: Offset.zero,
            ).animate(animation),
            child: child,
          );
        },
      );
  }
}
```

### Pattern 3: Typed Arguments

```dart
// Define route arguments
class TaskDetailArguments {
  final Task? task;
  final bool isEditing;

  TaskDetailArguments({this.task, this.isEditing = false});
}

// In router
case AppRoutes.taskDetail:
  final args = settings.arguments as TaskDetailArguments;
  return MaterialPageRoute(
    builder: (_) => TaskDetailScreen(
      task: args.task,
      isEditing: args.isEditing,
    ),
  );

// Usage
context.goToTaskDetail(TaskDetailArguments(task: task, isEditing: true));
```

### Pattern 4: Result Handling

```dart
// Navigate and wait for result
final result = await Navigator.pushNamed<bool>(
  context,
  AppRoutes.taskCreate,
);

if (result == true) {
  // Task was created successfully
  _reloadTasks();
}

// In TaskCreateScreen, when done:
Navigator.pop(context, true); // Return true
```

### Pattern 5: Deep Linking (Future Web Support)

```dart
// When you need deep linking (web URLs like /tasks/123)
static Route<dynamic>? onGenerateRoute(RouteSettings settings) {
  final uri = Uri.parse(settings.name ?? '/');

  // Parse /tasks/:id
  if (uri.pathSegments.length == 2 && uri.pathSegments[0] == 'tasks') {
    final taskId = uri.pathSegments[1];
    return MaterialPageRoute(
      builder: (_) => TaskDetailScreen(taskId: taskId),
    );
  }

  // Regular routes
  switch (settings.name) {
    // ...
  }
}
```

---

## Recommendation

**For your project**, I recommend **keeping named routes** because:

1. ✅ You're building a complex app with multiple features
2. ✅ Clean Architecture benefits from centralized routing
3. ✅ Easier to add middleware/guards later (auth, analytics)
4. ✅ Better for testing navigation
5. ✅ Future-proof for web deep linking
6. ✅ Consistent with your custom DI and state management

---

## Quick Reference

### Navigate to screen
```dart
// Method 1
Navigator.pushNamed(context, AppRoutes.taskDetail, arguments: task);

// Method 2
AppRouter.push(context, AppRoutes.taskDetail, arguments: task);

// Method 3 (cleanest)
context.goToTaskDetail(task);
```

### Replace screen
```dart
AppRouter.replace(context, AppRoutes.login);
```

### Go back
```dart
// Method 1
Navigator.pop(context);

// Method 2
context.goBack();

// With result
context.goBack<bool>(true);
```

### Pop to root
```dart
AppRouter.popUntilRoot(context);
```

### Get arguments
```dart
final task = ModalRoute.of(context)?.settings.arguments as Task?;
```

---

## Files

```
core/routing/
├── app_router.dart       # Router implementation
└── ROUTING_GUIDE.md      # This file
```

## Import

```dart
import 'package:personal_codex/core/routing/app_router.dart';
```
