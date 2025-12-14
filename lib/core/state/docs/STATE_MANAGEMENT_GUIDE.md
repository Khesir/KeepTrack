# Custom State Management Guide

## Overview

This codebase implements **two custom state management patterns** that are:
- ✅ **Framework-agnostic** (minimal Flutter dependency)
- ✅ **Portable** (reusable across apps)
- ✅ **No external packages** (just like the custom DI system)
- ✅ **Clean Architecture compatible**
- ✅ **Type-safe and testable**

---

## Option 1: StreamState (Pure Dart Streams)

**Location**: `core/state/stream_state.dart`

### When to Use
- Need reactive, real-time updates
- Want zero Flutter dependency in controller logic
- Building multi-listener scenarios
- Want to emit events that can be consumed by multiple widgets

### Pros
- ✅ Pure Dart (no Flutter imports in controller)
- ✅ Broadcast streams support multiple listeners
- ✅ Can be used outside Flutter (CLI tools, backend, etc.)
- ✅ More powerful for complex async scenarios

### Cons
- ⚠️ More boilerplate
- ⚠️ Manual stream disposal required
- ⚠️ Slightly heavier than ChangeNotifier

### Example Controller

```dart
import '../../../../core/state/stream_state.dart';

class TaskListController extends StreamState<AsyncState<List<Task>>> {
  final TaskRepository _repository;

  TaskListController(this._repository) : super(const AsyncLoading()) {
    loadTasks();
  }

  Future<void> loadTasks() async {
    await execute(() => _repository.getTasks());
  }

  Future<void> deleteTask(String id) async {
    try {
      await _repository.deleteTask(id);
      await loadTasks();
    } catch (e) {
      emit(AsyncError('Failed to delete: $e', e));
    }
  }
}
```

### Example UI Usage

```dart
import '../../../../core/state/stream_builder_widget.dart';

class MyScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final controller = getService<TaskListController>();

    return AsyncStreamBuilder<List<Task>>(
      state: controller,
      builder: (context, tasks) {
        // Build UI with tasks
        return ListView.builder(...);
      },
      errorBuilder: (context, message) {
        return ErrorWidget(message);
      },
      loadingBuilder: (context) {
        return LoadingSpinner();
      },
    );
  }
}
```

---

## Option 2: NotifierState (ChangeNotifier)

**Location**: `core/state/notifier_state.dart`

### When to Use
- Simple state management needs
- Want lightweight solution
- Don't need multi-listener scenarios
- Prefer Flutter's built-in optimization

### Pros
- ✅ Lighter weight than streams
- ✅ Uses Flutter's optimized listener pattern
- ✅ Less boilerplate
- ✅ Automatic rebuild optimization via AnimatedBuilder

### Cons
- ⚠️ Requires Flutter import (ChangeNotifier is from flutter/foundation)
- ⚠️ Not usable outside Flutter apps

### Example Controller

```dart
import '../../../../core/state/notifier_state.dart';

class TaskListController extends NotifierState<AsyncState<List<Task>>> {
  final TaskRepository _repository;

  TaskListController(this._repository) : super(const AsyncLoading()) {
    loadTasks();
  }

  Future<void> loadTasks() async {
    await execute(() => _repository.getTasks());
  }

  Future<void> deleteTask(String id) async {
    try {
      await _repository.deleteTask(id);
      await loadTasks();
    } catch (e) {
      emit(AsyncError('Failed to delete: $e', e));
    }
  }
}
```

### Example UI Usage

```dart
import '../../../../core/state/notifier_state.dart';

class MyScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final controller = getService<TaskListController>();

    return NotifierStateBuilder<AsyncState<List<Task>>>(
      state: controller,
      builder: (context, asyncState) {
        return switch (asyncState) {
          AsyncLoading() => LoadingSpinner(),
          AsyncData(data: final tasks) => ListView.builder(...),
          AsyncError(message: final msg) => ErrorWidget(msg),
        };
      },
    );
  }
}
```

---

## Comparison Table

| Feature | StreamState | NotifierState |
|---------|------------|---------------|
| **Dependencies** | Pure Dart | Flutter (foundation) |
| **Performance** | Good | Slightly better |
| **Complexity** | Medium | Simple |
| **Portability** | 100% (CLI, backend) | Flutter only |
| **Multi-listener** | Yes (broadcast) | Yes (via notifyListeners) |
| **Testability** | Excellent | Excellent |
| **Boilerplate** | More | Less |
| **Memory** | Higher | Lower |

---

## AsyncState Pattern

Both options use the same `AsyncState<T>` sealed class for handling loading/success/error states:

```dart
sealed class AsyncState<T> {}
class AsyncLoading<T> extends AsyncState<T> {}
class AsyncData<T> extends AsyncState<T> { final T data; }
class AsyncError<T> extends AsyncState<T> { final String message; }
```

### Benefits
- ✅ Type-safe pattern matching with `switch`
- ✅ Compiler ensures all states are handled
- ✅ No forgotten error handling
- ✅ Clean separation of concerns

### Example Usage

```dart
return switch (asyncState) {
  AsyncLoading() => CircularProgressIndicator(),
  AsyncData(data: final items) => ListView(items),
  AsyncError(message: final msg) => ErrorMessage(msg),
};
```

---

## Integration with DI System

Both patterns integrate perfectly with the existing custom DI:

### Register in Feature DI

```dart
// tasks_di.dart
void setupTasksDependencies() {
  // Existing repository registration
  locator.registerFactory<TaskRepository>(() {
    final dataSource = locator.get<TaskDataSource>();
    return TaskRepositoryImpl(dataSource);
  });

  // NEW: Register controller
  locator.registerFactory<TaskListController>(() {
    final repository = locator.get<TaskRepository>();
    return TaskListController(repository);
  });
}
```

### Use in Scoped Screen

```dart
class _TaskListScreenState extends ScopedScreenState<TaskListScreen> {
  late TaskListController _controller;

  @override
  void registerServices() {
    // Option 1: Register in scope
    scopedLocator.registerFactory<TaskListController>(
      () => TaskListController(scopedLocator.get<TaskRepository>()),
    );
  }

  @override
  void onReady() {
    _controller = getService<TaskListController>();
  }

  @override
  void dispose() {
    _controller.dispose(); // Clean up
    super.dispose();
  }
}
```

---

## Migration from setState

### Before (Old Pattern)

```dart
class _TaskListScreenState extends State<TaskListScreen> {
  List<Task> _tasks = [];
  bool _isLoading = false;

  Future<void> _loadTasks() async {
    setState(() => _isLoading = true);
    try {
      final tasks = await _repository.getTasks();
      setState(() {
        _tasks = tasks;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return _isLoading
        ? CircularProgressIndicator()
        : ListView.builder(
            itemCount: _tasks.length,
            itemBuilder: (context, index) => TaskItem(_tasks[index]),
          );
  }
}
```

### After (With StreamState/NotifierState)

```dart
class _TaskListScreenState extends ScopedScreenState<TaskListScreen> {
  late TaskListController _controller;

  @override
  void onReady() {
    _controller = getService<TaskListController>();
  }

  @override
  Widget build(BuildContext context) {
    return AsyncStreamBuilder<List<Task>>(  // or NotifierStateBuilder
      state: _controller,
      builder: (context, tasks) {
        return ListView.builder(
          itemCount: tasks.length,
          itemBuilder: (context, index) => TaskItem(tasks[index]),
        );
      },
    );
  }
}
```

### Key Improvements
- ✅ No manual loading/error state management
- ✅ Business logic moved to controller
- ✅ Automatic error handling
- ✅ Cleaner, more testable code
- ✅ Separation of concerns

---

## Testing

Both patterns are highly testable:

```dart
// test/features/tasks/presentation/task_list_controller_test.dart
void main() {
  group('TaskListController', () {
    late MockTaskRepository mockRepository;
    late TaskListController controller;

    setUp(() {
      mockRepository = MockTaskRepository();
      controller = TaskListController(mockRepository);
    });

    tearDown(() {
      controller.dispose();
    });

    test('should load tasks on init', () async {
      // Arrange
      final tasks = [Task(id: '1', title: 'Test')];
      when(() => mockRepository.getTasks()).thenAnswer((_) async => tasks);

      // Act
      await controller.loadTasks();

      // Assert
      expect(controller.state, isA<AsyncData<List<Task>>>());
      expect(controller.data, equals(tasks));
      verify(() => mockRepository.getTasks()).called(1);
    });

    test('should handle errors', () async {
      // Arrange
      when(() => mockRepository.getTasks()).thenThrow(Exception('Network error'));

      // Act
      await controller.loadTasks();

      // Assert
      expect(controller.state, isA<AsyncError<List<Task>>>());
      expect(controller.errorMessage, contains('Network error'));
    });
  });
}
```

---

## Recommendation

**For this project**: I recommend **StreamState** because:
1. ✅ Matches your philosophy (custom, no heavy dependencies)
2. ✅ More portable for potential CLI tools or backend services
3. ✅ Future-proof for complex reactive scenarios
4. ✅ Pure Dart controllers (better architecture)

**Use NotifierState if**:
- You want something lighter weight
- Don't need non-Flutter portability
- Prefer simpler code with less boilerplate

---

## Next Steps

1. ✅ Files created:
   - `core/state/stream_state.dart`
   - `core/state/stream_builder_widget.dart`
   - `core/state/notifier_state.dart`
   - `features/tasks/presentation/state/task_list_controller.dart`
   - `features/tasks/presentation/screens/task_list_screen_refactored.dart`

2. To migrate:
   - Create controllers for each screen
   - Register in feature DI files
   - Replace setState() with AsyncStreamBuilder/NotifierStateBuilder
   - Move business logic from screens to controllers

3. Pattern to repeat:
   - Every screen gets a controller
   - Controllers extend StreamState or NotifierState
   - UI uses builder widgets for reactive updates
   - Automatic cleanup via dispose()
