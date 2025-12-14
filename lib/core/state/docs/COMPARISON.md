# State Management: Before vs After

## Before: setState() Pattern

### Screen Code (118 lines)
```dart
class _TaskListScreenState extends ScopedScreenState<TaskListScreen> {
  late TaskRepository _taskRepository;
  List<Task> _tasks = [];              // ❌ Manual state
  bool _isLoading = false;              // ❌ Manual loading flag
  TaskStatus? _filterStatus;            // ❌ Manual filter state

  @override
  void onReady() {
    _taskRepository = getService<TaskRepository>();
    _loadTasks();
  }

  Future<void> _loadTasks() async {
    setState(() => _isLoading = true);  // ❌ Manual setState
    try {
      final tasks = _filterStatus != null
          ? await _taskRepository.getTasksByStatus(_filterStatus!)
          : await _taskRepository.getTasks();
      setState(() {                     // ❌ Manual setState
        _tasks = tasks;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false); // ❌ Manual setState
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')), // ❌ Raw exception
        );
      }
    }
  }

  void _filterByStatus(TaskStatus? status) {
    setState(() => _filterStatus = status); // ❌ Manual setState
    _loadTasks();
  }

  Future<void> _toggleComplete(Task task) async {
    try {
      final updated = task.copyWith(  // ❌ Business logic in UI
        status: task.isCompleted ? TaskStatus.todo : TaskStatus.completed,
        completedAt: task.isCompleted ? null : DateTime.now(),
        updatedAt: DateTime.now(),
      );
      await _taskRepository.updateTask(updated);
      _loadTasks();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating task: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _isLoading                  // ❌ Manual loading check
          ? const Center(child: CircularProgressIndicator())
          : _tasks.isEmpty              // ❌ Manual empty check
              ? Center(child: Text('No tasks'))
              : ListView.builder(
                  itemCount: _tasks.length,
                  itemBuilder: (context, index) {
                    final task = _tasks[index];
                    return TaskListItem(
                      task: task,
                      onToggleComplete: () => _toggleComplete(task),
                    );
                  },
                ),
    );
  }
}
```

### Problems
- ❌ **118 lines** of mixed concerns
- ❌ Business logic in UI layer
- ❌ Manual state management everywhere
- ❌ Repeated `setState()` calls (6 times)
- ❌ Error handling duplicated
- ❌ No separation of concerns
- ❌ Hard to test
- ❌ No caching or state reuse

---

## After: StreamState/NotifierState Pattern

### Controller (Pure Business Logic - 58 lines)
```dart
class TaskListController extends StreamState<AsyncState<List<Task>>> {
  final TaskRepository _repository;
  TaskStatus? _filterStatus;

  TaskListController(this._repository) : super(const AsyncLoading()) {
    loadTasks();
  }

  Future<void> loadTasks() async {
    await execute(() async {           // ✅ Automatic loading/error
      if (_filterStatus != null) {
        return await _repository.getTasksByStatus(_filterStatus!);
      }
      return await _repository.getTasks();
    });
  }

  Future<void> filterByStatus(TaskStatus? status) async {
    _filterStatus = status;
    await loadTasks();                 // ✅ No setState
  }

  Future<void> toggleTaskCompletion(Task task) async {
    try {
      final newStatus = task.isCompleted
          ? TaskStatus.inProgress
          : TaskStatus.completed;

      final updated = task.copyWith(   // ✅ Business logic in controller
        status: newStatus,
        completedAt: newStatus == TaskStatus.completed
            ? DateTime.now()
            : null,
        updatedAt: DateTime.now(),
      );

      await _repository.updateTask(updated);
      await loadTasks();
    } catch (e) {
      emit(AsyncError('Failed to update task: $e', e)); // ✅ Type-safe error
    }
  }

  Future<void> deleteTask(String taskId) async {
    try {
      await _repository.deleteTask(taskId);
      await loadTasks();
    } catch (e) {
      emit(AsyncError('Failed to delete task: $e', e));
    }
  }
}
```

### Screen (Clean UI - 65 lines)
```dart
class _TaskListScreenRefactoredState
    extends ScopedScreenState<TaskListScreenRefactored> {
  late TaskListController _controller;

  @override
  void registerServices() {
    scopedLocator.registerFactory<TaskListController>(
      () => createTaskListController(scopedLocator),
    );
  }

  @override
  void onReady() {
    _controller = getService<TaskListController>();
  }

  @override
  void dispose() {
    _controller.dispose();             // ✅ Automatic cleanup
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tasks'),
        actions: [
          PopupMenuButton<TaskStatus?>(
            icon: const Icon(Icons.filter_list),
            onSelected: _controller.filterByStatus, // ✅ Direct method call
            itemBuilder: (context) => [
              const PopupMenuItem(value: null, child: Text('All')),
              ...TaskStatus.values.map((status) =>
                PopupMenuItem(value: status, child: Text(status.displayName))),
            ],
          ),
        ],
      ),
      body: AsyncStreamBuilder<List<Task>>(  // ✅ Reactive builder
        state: _controller,
        builder: (context, tasks) {          // ✅ Only called with data
          if (tasks.isEmpty) {
            return Center(child: Text('No tasks'));
          }
          return RefreshIndicator(
            onRefresh: _controller.loadTasks,
            child: ListView.builder(
              itemCount: tasks.length,
              itemBuilder: (context, index) {
                final task = tasks[index];
                return TaskListItem(
                  task: task,
                  onToggleComplete: () => _controller.toggleTaskCompletion(task),
                  onDelete: () => _controller.deleteTask(task.id),
                );
              },
            ),
          );
        },
        errorBuilder: (context, message) => // ✅ Centralized error UI
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
                SizedBox(height: 16),
                Text('Error loading tasks'),
                Text(message),
                ElevatedButton(
                  onPressed: _controller.loadTasks,
                  child: Text('Retry'),
                ),
              ],
            ),
          ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _createTask,
        child: const Icon(Icons.add),
      ),
    );
  }
}
```

### Benefits
- ✅ **123 total lines** vs 118, but split into testable layers
- ✅ Business logic separated from UI
- ✅ Zero `setState()` calls
- ✅ Automatic loading/error handling
- ✅ Type-safe error states
- ✅ Reactive, efficient updates
- ✅ Easy to test controller independently
- ✅ Reusable controller logic
- ✅ Clean separation of concerns

---

## Code Comparison Side-by-Side

| Aspect | Before (setState) | After (StreamState) |
|--------|------------------|---------------------|
| **Lines in Screen** | 118 lines | 65 lines (46% reduction) |
| **Business Logic** | In UI layer | In Controller (58 lines) |
| **setState() calls** | 6 times | 0 times |
| **Error Handling** | Try-catch + SnackBar repeated | Centralized AsyncError |
| **Loading State** | Manual bool flag | Automatic AsyncLoading |
| **Testability** | Hard (UI coupled) | Easy (pure logic) |
| **Reusability** | None | Controller reusable |
| **Type Safety** | Low (raw exceptions) | High (sealed AsyncState) |
| **State Updates** | Manual tracking | Reactive streams |

---

## Testing Comparison

### Before: Hard to Test
```dart
// Can't easily test UI logic without widget testing
testWidgets('should load tasks', (tester) async {
  await tester.pumpWidget(TaskListScreen());  // ❌ Full widget tree needed
  await tester.pump();                        // ❌ Timing issues
  expect(find.byType(CircularProgressIndicator), findsOneWidget);
  await tester.pumpAndSettle();               // ❌ Wait for setState
  expect(find.byType(TaskListItem), findsWidgets);
});
```

### After: Easy Unit Tests
```dart
// Pure unit test, no widgets needed
test('should load tasks on init', () async {
  // Arrange
  final mockRepo = MockTaskRepository();
  when(() => mockRepo.getTasks()).thenAnswer((_) async => [testTask]);

  // Act
  final controller = TaskListController(mockRepo);
  await controller.loadTasks();

  // Assert
  expect(controller.state, isA<AsyncData<List<Task>>>());
  expect(controller.data, equals([testTask]));
  verify(() => mockRepo.getTasks()).called(1);  // ✅ Fast, reliable
});
```

---

## Performance Comparison

| Metric | setState | StreamState | NotifierState |
|--------|----------|-------------|---------------|
| **Rebuild Scope** | Entire widget | Only builder | Only builder |
| **Unnecessary Rebuilds** | Common | Rare | Rare |
| **Memory** | Low | Medium | Low |
| **CPU** | High (full builds) | Low (targeted) | Low (targeted) |
| **Latency** | Immediate | ~1 frame | Immediate |

---

## Migration Effort

### Step 1: Create Controller (10 min per screen)
```dart
class [Screen]Controller extends StreamState<AsyncState<[Data]>> {
  final [Repository] _repository;

  [Screen]Controller(this._repository) : super(const AsyncLoading()) {
    load[Data]();
  }

  Future<void> load[Data]() async {
    await execute(() => _repository.get[Data]());
  }
}
```

### Step 2: Update DI Registration (5 min)
```dart
// In [feature]_di.dart
locator.registerFactory<[Screen]Controller>(() {
  return [Screen]Controller(locator.get<[Repository]>());
});
```

### Step 3: Refactor Screen (15 min per screen)
```dart
// Remove: Manual state variables, setState calls, try-catch blocks
// Add: Controller, AsyncStreamBuilder
```

### Total Per Screen: ~30 minutes

### ROI
- ✅ More testable code
- ✅ Cleaner architecture
- ✅ Easier to maintain
- ✅ Better performance
- ✅ Reusable patterns

---

## Final Verdict

### Use StreamState/NotifierState if:
- ✅ You want clean, testable code
- ✅ You're building features with complex state
- ✅ You want to separate business logic from UI
- ✅ You care about maintainability
- ✅ You want reactive updates
- ✅ You're following Clean Architecture

### Stick with setState if:
- ⚠️ Prototyping simple demos
- ⚠️ Single-use throwaway screens
- ⚠️ Very simple forms with no logic

---

## Recommendation

**Migrate to StreamState** because:
1. Your project already follows Clean Architecture
2. You built a custom DI system (same philosophy)
3. Better testability aligns with production code
4. Scales better as features grow
5. Minimal Flutter dependency keeps code portable
