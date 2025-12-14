# Quick Start: Custom State Management

## TL;DR - Get Started in 5 Minutes

### 1. Choose Your Pattern
```dart
// Option A: StreamState (Pure Dart, more portable)
import 'package:personal_codex/core/state/stream_state.dart';

// Option B: NotifierState (Lighter, Flutter-optimized)
import 'package:personal_codex/core/state/notifier_state.dart';
```

### 2. Create a Controller

**Example: `features/tasks/presentation/state/task_list_controller.dart`**

```dart
import '../../../../core/state/stream_state.dart';  // or notifier_state.dart
import '../../domain/entities/task.dart';
import '../../domain/repositories/task_repository.dart';

class TaskListController extends StreamState<AsyncState<List<Task>>> {
  final TaskRepository _repository;

  TaskListController(this._repository) : super(const AsyncLoading()) {
    loadTasks();  // Auto-load on init
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

### 3. Register in DI

**In `features/tasks/tasks_di.dart`:**

```dart
void setupTasksDependencies() {
  // Existing registrations...

  // NEW: Add controller
  locator.registerFactory<TaskListController>(() {
    return TaskListController(locator.get<TaskRepository>());
  });
}
```

### 4. Use in Screen

**In `features/tasks/presentation/screens/task_list_screen.dart`:**

```dart
import '../../../../core/state/stream_builder_widget.dart';
import '../state/task_list_controller.dart';

class _TaskListScreenState extends ScopedScreenState<TaskListScreen> {
  late TaskListController _controller;

  @override
  void onReady() {
    _controller = getService<TaskListController>();
  }

  @override
  void dispose() {
    _controller.dispose();  // ⚠️ Important: Clean up
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Tasks')),
      body: AsyncStreamBuilder<List<Task>>(
        state: _controller,
        builder: (context, tasks) {
          return ListView.builder(
            itemCount: tasks.length,
            itemBuilder: (context, index) {
              return TaskItem(task: tasks[index]);
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _controller.loadTasks(),
        child: Icon(Icons.refresh),
      ),
    );
  }
}
```

---

## Common Patterns

### Pattern 1: Simple Data Loading

```dart
class DataController extends StreamState<AsyncState<MyData>> {
  final MyRepository _repo;

  DataController(this._repo) : super(const AsyncLoading()) {
    load();
  }

  Future<void> load() async {
    await execute(() => _repo.getData());  // ✅ Auto loading/error handling
  }
}
```

### Pattern 2: Filtering/Searching

```dart
class SearchController extends StreamState<AsyncState<List<Item>>> {
  final ItemRepository _repo;
  String _query = '';

  SearchController(this._repo) : super(const AsyncData([]));

  Future<void> search(String query) async {
    _query = query;
    if (query.isEmpty) {
      emit(const AsyncData([]));
      return;
    }
    await execute(() => _repo.search(query));
  }
}
```

### Pattern 3: Optimistic Updates

```dart
class TodoController extends StreamState<AsyncState<List<Todo>>> {
  final TodoRepository _repo;

  TodoController(this._repo) : super(const AsyncLoading()) {
    loadTodos();
  }

  Future<void> toggleTodo(Todo todo) async {
    final current = data ?? [];

    // Optimistic update
    final updated = todo.copyWith(completed: !todo.completed);
    final optimistic = current.map((t) => t.id == todo.id ? updated : t).toList();
    emit(AsyncData(optimistic));

    try {
      await _repo.update(updated);
    } catch (e) {
      // Revert on error
      emit(AsyncData(current));
      emit(AsyncError('Update failed: $e', e));
    }
  }

  Future<void> loadTodos() async {
    await execute(() => _repo.getTodos());
  }
}
```

### Pattern 4: Multiple States

```dart
class MultiStateController {
  final tasks = StreamState<AsyncState<List<Task>>>(const AsyncLoading());
  final filter = StreamState<TaskFilter>(TaskFilter.all);

  MultiStateController(TaskRepository repo) {
    // Listen to filter changes
    filter.stream.listen((_) => _loadTasks());
    _loadTasks();
  }

  Future<void> _loadTasks() async {
    await tasks.execute(() => _repo.getFiltered(filter.state));
  }

  void dispose() {
    tasks.dispose();
    filter.dispose();
  }
}
```

---

## UI Patterns

### Pattern 1: Basic Async Builder

```dart
AsyncStreamBuilder<List<Task>>(
  state: controller,
  builder: (context, tasks) {
    return ListView(children: tasks.map((t) => TaskTile(t)).toList());
  },
)
```

### Pattern 2: Custom Loading/Error UI

```dart
AsyncStreamBuilder<List<Task>>(
  state: controller,
  builder: (context, tasks) => TaskList(tasks),
  loadingBuilder: (context) => Shimmer.loading(),
  errorBuilder: (context, msg) => ErrorCard(
    message: msg,
    onRetry: controller.loadTasks,
  ),
)
```

### Pattern 3: Manual State Handling (with Switch)

```dart
StreamStateBuilder<AsyncState<List<Task>>>(
  state: controller,
  builder: (context, state) {
    return switch (state) {
      AsyncLoading() => LoadingSpinner(),
      AsyncData(data: final tasks) => TaskList(tasks),
      AsyncError(message: final msg) => ErrorMessage(msg),
    };
  },
)
```

### Pattern 4: Combining Multiple States

```dart
StreamStateBuilder<AsyncState<List<Task>>>(
  state: taskController,
  builder: (context, taskState) {
    return StreamStateBuilder<TaskFilter>(
      state: filterController,
      builder: (context, filter) {
        return Column(
          children: [
            FilterChips(filter: filter),
            switch (taskState) {
              AsyncData(data: final tasks) => TaskList(tasks),
              AsyncLoading() => LoadingSpinner(),
              AsyncError(message: final msg) => ErrorMessage(msg),
            },
          ],
        );
      },
    );
  },
)
```

---

## Common Gotchas

### ❌ Forgetting to Dispose
```dart
@override
void dispose() {
  _controller.dispose();  // ⚠️ MUST call dispose()
  super.dispose();
}
```

### ❌ Creating Controller in build()
```dart
// BAD
Widget build(BuildContext context) {
  final controller = TaskController(repo);  // ❌ Creates new instance every build!
  return AsyncStreamBuilder(state: controller, ...);
}

// GOOD
late TaskController _controller;

@override
void onReady() {
  _controller = getService<TaskController>();  // ✅ Created once
}
```

### ❌ Not Checking mounted Before Navigator
```dart
Future<void> deleteTask(String id) async {
  await _repo.delete(id);
  if (mounted) {  // ✅ Always check mounted
    Navigator.pop(context);
  }
}
```

### ❌ Using setState with StreamState
```dart
// BAD
setState(() => _controller.loadTasks());  // ❌ Unnecessary

// GOOD
_controller.loadTasks();  // ✅ StreamState handles updates
```

---

## Testing Quick Reference

### Unit Test Controller

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockTaskRepository extends Mock implements TaskRepository {}

void main() {
  late TaskListController controller;
  late MockTaskRepository mockRepo;

  setUp(() {
    mockRepo = MockTaskRepository();
    controller = TaskListController(mockRepo);
  });

  tearDown(() {
    controller.dispose();
  });

  test('loads tasks on init', () async {
    // Arrange
    final tasks = [Task(id: '1', title: 'Test')];
    when(() => mockRepo.getTasks()).thenAnswer((_) async => tasks);

    // Act
    await controller.loadTasks();

    // Assert
    expect(controller.state, isA<AsyncData<List<Task>>>());
    expect(controller.data, equals(tasks));
  });

  test('handles errors', () async {
    // Arrange
    when(() => mockRepo.getTasks()).thenThrow(Exception('Network error'));

    // Act
    await controller.loadTasks();

    // Assert
    expect(controller.state, isA<AsyncError>());
    expect(controller.errorMessage, contains('Network error'));
  });

  test('deletes task and reloads', () async {
    // Arrange
    when(() => mockRepo.deleteTask('1')).thenAnswer((_) async {});
    when(() => mockRepo.getTasks()).thenAnswer((_) async => []);

    // Act
    await controller.deleteTask('1');

    // Assert
    verify(() => mockRepo.deleteTask('1')).called(1);
    verify(() => mockRepo.getTasks()).called(1);
  });
}
```

---

## Cheat Sheet

| Task | StreamState | NotifierState |
|------|-------------|---------------|
| **Import** | `core/state/stream_state.dart` | `core/state/notifier_state.dart` |
| **Extend** | `StreamState<AsyncState<T>>` | `NotifierState<AsyncState<T>>` |
| **Builder** | `AsyncStreamBuilder<T>` | `NotifierStateBuilder<AsyncState<T>>` |
| **Get value** | `controller.state` | `controller.state` |
| **Get data** | `controller.data` | `controller.data` |
| **Emit state** | `controller.emit(value)` | `controller.emit(value)` |
| **Async execute** | `controller.execute(() => ...)` | `controller.execute(() => ...)` |
| **Dispose** | `controller.dispose()` | `controller.dispose()` |
| **Listen** | `controller.stream.listen(...)` | `controller.addListener(...)` |

---

## Next Steps

1. **Start Small**: Migrate one screen first (TaskListScreen recommended)
2. **Test**: Write unit tests for the controller
3. **Expand**: Apply pattern to other screens
4. **Refine**: Add caching, debouncing, etc. as needed

For detailed examples, see:
- `features/tasks/presentation/state/task_list_controller.dart`
- `features/tasks/presentation/screens/task_list_screen_refactored.dart`
- `core/state/STATE_MANAGEMENT_GUIDE.md`
- `core/state/COMPARISON.md`
