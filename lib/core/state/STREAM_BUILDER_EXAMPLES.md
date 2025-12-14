# StreamBuilder Widget Usage Examples

## Basic Usage

### Example 1: Simple AsyncStreamBuilder

```dart
import 'package:flutter/material.dart';
import '../state/stream_builder_widget.dart';
import '../state/stream_state.dart';

class TaskListScreen extends StatelessWidget {
  final TaskListController controller;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Tasks')),
      body: AsyncStreamBuilder<List<Task>>(
        state: controller,  // Your StreamState controller
        builder: (context, tasks) {
          // This builder is ONLY called when data is available
          return ListView.builder(
            itemCount: tasks.length,
            itemBuilder: (context, index) {
              return TaskTile(task: tasks[index]);
            },
          );
        },
      ),
    );
  }
}
```

**What happens**:
- When `AsyncLoading` → Shows CircularProgressIndicator
- When `AsyncData<List<Task>>` → Calls your builder with tasks
- When `AsyncError` → Shows "Error: message"

---

### Example 2: Custom Loading/Error UI

```dart
AsyncStreamBuilder<List<Task>>(
  state: controller,
  builder: (context, tasks) {
    // Build your UI with data
    return TaskList(tasks: tasks);
  },
  // Custom loading widget
  loadingBuilder: (context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text('Loading tasks...'),
        ],
      ),
    );
  },
  // Custom error widget
  errorBuilder: (context, message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64, color: Colors.red),
          SizedBox(height: 16),
          Text(message),
          SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => controller.loadTasks(),
            child: Text('Retry'),
          ),
        ],
      ),
    );
  },
)
```

---

### Example 3: With Error Handling Integration

```dart
import '../error/error_widgets.dart';

AsyncStreamBuilder<List<Task>>(
  state: controller,
  builder: (context, tasks) {
    if (tasks.isEmpty) {
      return EmptyState(message: 'No tasks yet');
    }
    return ListView(
      children: tasks.map((task) => TaskTile(task)).toList(),
    );
  },
  errorBuilder: (context, message) {
    // Use custom ErrorDisplay widget
    return ErrorDisplay(
      failure: controller.currentFailure!,
      onRetry: controller.canRetry ? controller.loadTasks : null,
      showDetails: true, // Show technical details in debug
    );
  },
)
```

---

### Example 4: StreamStateBuilder (Manual Control)

For when you need more control over the state:

```dart
StreamStateBuilder<AsyncState<List<Task>>>(
  state: controller,
  builder: (context, asyncState) {
    // Manual pattern matching
    return switch (asyncState) {
      AsyncLoading() => _buildLoading(),
      AsyncData(data: final tasks) => _buildTaskList(tasks),
      AsyncError(message: final msg) => _buildError(msg),
    };
  },
)
```

---

### Example 5: Multiple States (Combining)

```dart
class MyScreen extends StatelessWidget {
  final TaskController taskController;
  final FilterController filterController;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // Filter state (simple value)
          StreamStateBuilder<TaskFilter>(
            state: filterController,
            builder: (context, filter) {
              return FilterChips(
                currentFilter: filter,
                onFilterChanged: filterController.setFilter,
              );
            },
          ),

          // Task list state (async)
          Expanded(
            child: AsyncStreamBuilder<List<Task>>(
              state: taskController,
              builder: (context, tasks) {
                return TaskList(tasks: tasks);
              },
            ),
          ),
        ],
      ),
    );
  }
}
```

---

### Example 6: Pull-to-Refresh

```dart
AsyncStreamBuilder<List<Task>>(
  state: controller,
  builder: (context, tasks) {
    return RefreshIndicator(
      onRefresh: controller.loadTasks,  // Returns Future<void>
      child: tasks.isEmpty
          ? _buildEmptyState()
          : ListView.builder(
              itemCount: tasks.length,
              itemBuilder: (context, index) => TaskTile(tasks[index]),
            ),
    );
  },
)
```

---

### Example 7: Nested AsyncStreamBuilder

```dart
class TaskDetailScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AsyncStreamBuilder<Task>(
        state: taskController,
        builder: (context, task) {
          // Task loaded, now load related project
          return Column(
            children: [
              TaskHeader(task: task),

              // Nested async builder for project
              if (task.projectId != null)
                AsyncStreamBuilder<Project>(
                  state: projectController,
                  builder: (context, project) {
                    return ProjectBadge(project: project);
                  },
                  loadingBuilder: (context) => ShimmerBadge(),
                ),

              TaskDetails(task: task),
            ],
          );
        },
      ),
    );
  }
}
```

---

### Example 8: Listening to State Changes

```dart
class _TaskListScreenState extends State<TaskListScreen> {
  late StreamSubscription _subscription;

  @override
  void initState() {
    super.initState();

    // Listen to state changes for side effects
    _subscription = controller.stream.listen((state) {
      if (state is AsyncError && mounted) {
        // Show snackbar on error
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(state.message)),
        );
      }

      if (state is AsyncData<List<Task>> && mounted) {
        // Track analytics
        Analytics.log('tasks_loaded', {'count': state.data.length});
      }
    });
  }

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AsyncStreamBuilder<List<Task>>(
      state: controller,
      builder: (context, tasks) => TaskList(tasks),
    );
  }
}
```

---

### Example 9: Conditional Rendering Based on State

```dart
AsyncStreamBuilder<List<Task>>(
  state: controller,
  builder: (context, tasks) {
    // Different UI based on data
    if (tasks.isEmpty) {
      return EmptyStateWidget(
        icon: Icons.task_alt,
        message: 'No tasks yet',
        action: ElevatedButton(
          onPressed: () => Navigator.pushNamed(context, '/task/create'),
          child: Text('Create First Task'),
        ),
      );
    }

    // Group by status
    final todoTasks = tasks.where((t) => t.status == TaskStatus.todo).toList();
    final inProgressTasks = tasks.where((t) => t.status == TaskStatus.inProgress).toList();
    final completedTasks = tasks.where((t) => t.status == TaskStatus.completed).toList();

    return ListView(
      children: [
        if (todoTasks.isNotEmpty) TaskSection(title: 'To Do', tasks: todoTasks),
        if (inProgressTasks.isNotEmpty) TaskSection(title: 'In Progress', tasks: inProgressTasks),
        if (completedTasks.isNotEmpty) TaskSection(title: 'Completed', tasks: completedTasks),
      ],
    );
  },
)
```

---

### Example 10: Optimistic Updates

```dart
class _TaskListScreenState extends State<TaskListScreen> {
  @override
  Widget build(BuildContext context) {
    return AsyncStreamBuilder<List<Task>>(
      state: controller,
      builder: (context, tasks) {
        return ListView.builder(
          itemCount: tasks.length,
          itemBuilder: (context, index) {
            final task = tasks[index];
            return Dismissible(
              key: Key(task.id),
              onDismissed: (direction) async {
                // Optimistic update - task already removed from list
                // If delete fails, controller will reload and restore
                await controller.deleteTask(task.id);

                // Show undo snackbar
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Task deleted'),
                    action: SnackBarAction(
                      label: 'Undo',
                      onPressed: () => controller.createTask(task),
                    ),
                  ),
                );
              },
              child: TaskTile(task: task),
            );
          },
        );
      },
    );
  }
}
```

---

## Common Patterns

### Pattern: Empty State
```dart
builder: (context, items) {
  if (items.isEmpty) {
    return EmptyStateWidget();
  }
  return ItemList(items);
}
```

### Pattern: Search Results
```dart
builder: (context, results) {
  if (results.isEmpty) {
    return Center(
      child: Text('No results found for "${searchQuery}"'),
    );
  }
  return ResultsList(results);
}
```

### Pattern: Infinite Scroll
```dart
builder: (context, items) {
  return ListView.builder(
    itemCount: items.length + 1, // +1 for loading indicator
    itemBuilder: (context, index) {
      if (index == items.length) {
        // Load more
        controller.loadMore();
        return LoadingIndicator();
      }
      return ItemTile(items[index]);
    },
  );
}
```

---

## Tips

1. **AsyncStreamBuilder** automatically handles loading/error/data states
2. **Custom builders** give you full control over UI
3. **StreamStateBuilder** for manual pattern matching
4. **Always check isEmpty** in your builder for empty states
5. **Use errorBuilder** with ErrorDisplay widget for consistent error UI
6. **Combine with RefreshIndicator** for pull-to-refresh
7. **Listen to stream** for side effects (snackbars, analytics)
8. **Dispose subscriptions** if you manually listen to stream
