# Custom Error Handling System - Complete Guide

## Overview

This error handling system provides:
- ✅ Type-safe error handling with sealed classes
- ✅ Functional approach with Result type (Either monad)
- ✅ Automatic exception mapping
- ✅ Integration with StreamState
- ✅ Consistent UI error display
- ✅ Zero external dependencies

---

## Core Concepts

### 1. Failure (Domain Errors)

**Failures** represent business-level errors that are part of your domain.

```dart
sealed class Failure {
  final String message;
  final StackTrace? stackTrace;
  final Object? originalError;
}
```

**Available Failures**:
- **Infrastructure**: `NetworkFailure`, `ServerFailure`, `TimeoutFailure`, `DatabaseFailure`
- **Client**: `ValidationFailure`, `NotFoundFailure`, `UnauthorizedFailure`, `ForbiddenFailure`, `ConflictFailure`
- **Business**: `BusinessRuleFailure`, `ConcurrentModificationFailure`
- **Technical**: `ParsingFailure`, `CacheFailure`, `UnknownFailure`

### 2. Result Type (Functional Error Handling)

**Result<T>** is an Either monad - either `Success<T>` or `Error<Failure>`.

```dart
sealed class Result<T> {
  factory Result.success(T data) = Success<T>;
  factory Result.error(Failure failure) = Error<T>;
}
```

**Why Use Result?**
- ✅ Explicit error handling (no silent failures)
- ✅ Composable (map, flatMap, fold)
- ✅ Type-safe pattern matching
- ✅ Forces you to handle errors

---

## Usage Patterns

### Pattern 1: Try-Catch with Failures

**When to use**: Quick operations where you want to throw errors.

```dart
// In Use Case
Future<Task> call(String taskId) async {
  final task = await _repository.getTaskById(taskId);

  if (task == null) {
    throw NotFoundFailure(
      resourceType: 'Task',
      resourceId: taskId,
    );
  }

  if (task.title.isEmpty) {
    throw ValidationFailure('Task title cannot be empty');
  }

  return task;
}
```

**In Controller** (with StreamState):
```dart
Future<void> loadTask(String taskId) async {
  await executeWithErrorHandling(
    () => _getTaskUseCase(taskId),
    context: 'TaskDetailController.loadTask',
  );
}
```

---

### Pattern 2: Result Type (Functional)

**When to use**: Complex operations, composable logic, multiple error paths.

```dart
// In Use Case
Future<Result<Task>> call(String taskId) async {
  return ErrorHandler.handleAsync(() async {
    final task = await _repository.getTaskById(taskId);

    if (task == null) {
      throw NotFoundFailure(
        resourceType: 'Task',
        resourceId: taskId,
      );
    }

    return task;
  });
}
```

**In Controller**:
```dart
Future<void> loadTask(String taskId) async {
  await executeResult(
    () => _getTaskUseCase(taskId),
    context: 'TaskDetailController.loadTask',
  );
}
```

**Composing Results**:
```dart
// Chain operations
Future<Result<UpdatedTask>> updateTask(String id, String newTitle) async {
  return (await getTask(id))
    .flatMapAsync((task) async {
      final updated = task.copyWith(title: newTitle);
      return await saveTask(updated);
    })
    .map((task) => UpdatedTask(task));
}

// Handle inline
final result = await updateTask('123', 'New Title');
result.fold(
  onSuccess: (updated) => print('Success: $updated'),
  onError: (failure) => print('Error: $failure'),
);
```

---

### Pattern 3: ErrorAware Operation Builder

**When to use**: Complex operations with custom callbacks.

```dart
Future<void> loadTasks() async {
  await errorAware(() => _repository.getTasks())
    .withContext('TaskListController.loadTasks')
    .onSuccess((tasks) {
      print('Loaded ${tasks.length} tasks');
    })
    .onError((failure) {
      // Custom error handling
      if (failure is NetworkFailure) {
        // Show offline mode
      }
    })
    .executeToStream(this); // Emits to StreamState
}
```

---

## Integration with Architecture Layers

### 1. Data Layer (Repository Implementation)

**Convert exceptions to Failures**:

```dart
class TaskRepositoryImpl implements TaskRepository {
  @override
  Future<Task?> getTaskById(String id) async {
    try {
      final model = await _dataSource.getTaskById(id);
      return model.toEntity();
    } on Exception catch (e, stackTrace) {
      // Map exception to failure
      throw ExceptionMapper.mapException(e, stackTrace);
    }
  }

  @override
  Future<Task> createTask(Task task) async {
    try {
      final model = TaskModel.fromEntity(task);
      final created = await _dataSource.createTask(model);
      return created.toEntity();
    } catch (e, stackTrace) {
      // Specific error mapping
      if (e.toString().contains('duplicate')) {
        throw ConflictFailure(message: 'Task already exists');
      }
      throw ExceptionMapper.mapException(e, stackTrace);
    }
  }
}
```

**Or use Result type**:

```dart
@override
Future<Result<Task>> createTask(Task task) async {
  return ErrorHandler.handleAsync(() async {
    final model = TaskModel.fromEntity(task);
    final created = await _dataSource.createTask(model);
    return created.toEntity();
  }, context: 'TaskRepositoryImpl.createTask');
}
```

---

### 2. Domain Layer (Use Cases)

**Throw domain-specific failures**:

```dart
class CreateTaskUseCase {
  Future<Task> call(CreateTaskParams params) async {
    // Validation
    if (params.title.trim().isEmpty) {
      throw ValidationFailure('Task title cannot be empty');
    }

    if (params.title.length > 255) {
      throw ValidationFailure('Task title cannot exceed 255 characters');
    }

    if (params.dueDate != null && params.dueDate!.isBefore(DateTime.now())) {
      throw ValidationFailure('Due date cannot be in the past');
    }

    // Business logic
    final task = Task(
      id: '',
      title: params.title.trim(),
      description: params.description?.trim(),
      status: params.status,
      priority: params.priority,
      dueDate: params.dueDate,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    return await _repository.createTask(task);
  }
}
```

**Or return Result**:

```dart
class CreateTaskUseCase {
  Future<Result<Task>> call(CreateTaskParams params) async {
    return ErrorHandler.handleAsync(() async {
      // Validation
      _validateParams(params);

      // Create task
      final task = _buildTask(params);

      // Save
      return await _repository.createTask(task);
    }, context: 'CreateTaskUseCase');
  }

  void _validateParams(CreateTaskParams params) {
    if (params.title.trim().isEmpty) {
      throw ValidationFailure('Task title cannot be empty');
    }
    // ... more validation
  }
}
```

---

### 3. Presentation Layer (Controllers)

**Option A: Try-Catch with executeWithErrorHandling**:

```dart
class TaskDetailController extends StreamState<AsyncState<Task>> {
  final GetTaskUseCase _getTaskUseCase;
  final UpdateTaskUseCase _updateTaskUseCase;

  Future<void> loadTask(String taskId) async {
    await executeWithErrorHandling(
      () => _getTaskUseCase(taskId),
      context: 'TaskDetailController.loadTask',
    );
  }

  Future<void> updateTask(Task task) async {
    try {
      final updated = await _updateTaskUseCase(task);
      emit(AsyncData(updated));
    } catch (e, stackTrace) {
      final failure = ExceptionMapper.mapException(e, stackTrace);
      ErrorHandler.logError(failure, context: 'updateTask', stackTrace: stackTrace);
      emit(AsyncError(failure.userMessage, failure));
    }
  }
}
```

**Option B: Result type with executeResult**:

```dart
class TaskDetailController extends StreamState<AsyncState<Task>> {
  Future<void> loadTask(String taskId) async {
    await executeResult(
      () => _getTaskUseCase(taskId),
      context: 'TaskDetailController.loadTask',
    );
  }
}
```

**Access current failure**:

```dart
// In controller
if (currentFailure != null && currentFailure!.isRetryable) {
  // Show retry button
}

// Get error title
final title = errorTitle; // "Network Error", "Validation Error", etc.

// Check if can retry
if (canRetry) {
  // Show retry UI
}
```

---

### 4. UI Layer (Widgets)

**Display errors with ErrorDisplay**:

```dart
AsyncStreamBuilder<Task>(
  state: controller,
  builder: (context, task) {
    return TaskDetailView(task: task);
  },
  errorBuilder: (context, message) {
    return ErrorDisplay(
      failure: controller.currentFailure!,
      onRetry: () => controller.loadTask(taskId),
      showDetails: true, // Show technical details in debug
    );
  },
)
```

**Compact error card**:

```dart
if (controller.state is AsyncError) {
  return ErrorCard(
    failure: controller.currentFailure!,
    onRetry: controller.canRetry ? controller.loadTask : null,
    onDismiss: () => Navigator.pop(context),
  );
}
```

**Error snackbar**:

```dart
controller.stream.listen((state) {
  if (state is AsyncError && mounted) {
    final failure = controller.currentFailure;
    if (failure != null) {
      showErrorSnackBar(
        context,
        failure,
        onRetry: controller.canRetry ? controller.loadTask : null,
      );
    }
  }
});
```

**Error dialog**:

```dart
void _handleError(Failure failure) {
  showErrorDialog(
    context,
    failure,
    onRetry: () => controller.loadTask(taskId),
  );
}
```

**Error banner**:

```dart
ErrorBanner.show(
  context,
  failure,
  onRetry: () => controller.loadTask(taskId),
);
```

---

## Advanced Patterns

### Pattern 1: Custom Failures Per Feature

```dart
// features/tasks/domain/failures/task_failures.dart
sealed class TaskFailure extends Failure {
  const TaskFailure(String message) : super(message: message);
}

class TaskNotFoundFailure extends TaskFailure {
  final String taskId;

  TaskNotFoundFailure(this.taskId)
      : super('Task not found: $taskId');
}

class TaskAlreadyCompletedFailure extends TaskFailure {
  TaskAlreadyCompletedFailure()
      : super('Task is already completed');
}

class InvalidTaskStatusTransitionFailure extends TaskFailure {
  final TaskStatus from;
  final TaskStatus to;

  InvalidTaskStatusTransitionFailure(this.from, this.to)
      : super('Cannot transition from ${from.name} to ${to.name}');
}
```

### Pattern 2: Validation with Field Errors

```dart
class CreateTaskUseCase {
  Future<Task> call(CreateTaskParams params) async {
    final fieldErrors = <String, String>{};

    // Validate fields
    if (params.title.trim().isEmpty) {
      fieldErrors['title'] = 'Title is required';
    }
    if (params.title.length > 255) {
      fieldErrors['title'] = 'Title is too long (max 255 characters)';
    }
    if (params.description != null && params.description!.length > 2000) {
      fieldErrors['description'] = 'Description is too long (max 2000 characters)';
    }

    // Throw if any errors
    if (fieldErrors.isNotEmpty) {
      throw ValidationFailure(
        'Please fix the following errors',
        fieldErrors: fieldErrors,
      );
    }

    // Proceed with creation
    return await _repository.createTask(_buildTask(params));
  }
}

// In UI
if (failure is ValidationFailure) {
  final titleError = failure.getFieldError('title');
  if (titleError != null) {
    // Show error under title field
  }
}
```

### Pattern 3: Retry with Exponential Backoff

```dart
class RetryableOperation<T> {
  final Future<T> Function() operation;
  final int maxRetries;
  final Duration initialDelay;

  Future<Result<T>> execute() async {
    var retries = 0;
    var delay = initialDelay;

    while (retries < maxRetries) {
      final result = await ErrorHandler.handleAsync(operation);

      if (result.isSuccess) {
        return result;
      }

      final failure = result.failure;
      if (!failure.isRetryable) {
        return result; // Don't retry non-retryable errors
      }

      retries++;
      if (retries < maxRetries) {
        await Future.delayed(delay);
        delay *= 2; // Exponential backoff
      }
    }

    return Result.error(
      UnknownFailure(message: 'Operation failed after $maxRetries retries'),
    );
  }
}

// Usage
final result = await RetryableOperation(
  operation: () => _repository.getData(),
  maxRetries: 3,
  initialDelay: Duration(seconds: 1),
).execute();
```

### Pattern 4: Multiple Error Types

```dart
Future<void> loadData() async {
  final result = await _useCase();

  result.fold(
    onSuccess: (data) {
      emit(AsyncData(data));
    },
    onError: (failure) {
      // Handle different errors differently
      switch (failure) {
        case NetworkFailure():
          // Show offline mode
          _enableOfflineMode();
          emit(AsyncError('No connection - showing cached data', failure));

        case UnauthorizedFailure():
          // Redirect to login
          _logout();

        case ValidationFailure():
          // Show validation errors
          emit(AsyncError(failure.message, failure));

        default:
          // Generic error
          emit(AsyncError('An error occurred', failure));
      }

      ErrorHandler.logError(failure, context: 'loadData');
    },
  );
}
```

---

## Testing

### Test Failures

```dart
test('should throw ValidationFailure for empty title', () async {
  // Arrange
  final useCase = CreateTaskUseCase(mockRepository);
  final params = CreateTaskParams(title: '');

  // Act & Assert
  expect(
    () => useCase(params),
    throwsA(isA<ValidationFailure>()),
  );
});

test('should return error Result for empty title', () async {
  // Arrange
  final useCase = CreateTaskUseCase(mockRepository);
  final params = CreateTaskParams(title: '');

  // Act
  final result = await useCase(params);

  // Assert
  expect(result.isError, true);
  expect(result.failure, isA<ValidationFailure>());
  expect(result.failure.message, contains('title'));
});
```

### Test Error Handling

```dart
test('controller should handle errors correctly', () async {
  // Arrange
  final mockUseCase = MockGetTaskUseCase();
  final controller = TaskDetailController(getTaskUseCase: mockUseCase);

  when(() => mockUseCase('123'))
      .thenThrow(NotFoundFailure(resourceType: 'Task', resourceId: '123'));

  // Act
  await controller.loadTask('123');

  // Assert
  expect(controller.state, isA<AsyncError>());
  expect(controller.currentFailure, isA<NotFoundFailure>());
  expect(controller.canRetry, false); // NotFoundFailure is not retryable
});
```

---

## Best Practices

### 1. Use Specific Failures
```dart
// ❌ Bad
throw Exception('Task not found');

// ✅ Good
throw NotFoundFailure(resourceType: 'Task', resourceId: taskId);
```

### 2. Include Context
```dart
// ❌ Bad
await executeWithErrorHandling(() => _useCase());

// ✅ Good
await executeWithErrorHandling(
  () => _useCase(),
  context: 'TaskListController.loadTasks',
);
```

### 3. Handle Errors at Right Layer
```dart
// ✅ Repository: Convert technical exceptions
try {
  return await _dataSource.getData();
} catch (e) {
  throw ExceptionMapper.mapException(e);
}

// ✅ Use Case: Throw business failures
if (task == null) {
  throw NotFoundFailure(resourceType: 'Task', resourceId: id);
}

// ✅ Controller: Display errors to user
catch (e) {
  final failure = ExceptionMapper.mapException(e);
  emit(AsyncError(failure.userMessage, failure));
}
```

### 4. Always Log Errors
```dart
ErrorHandler.logError(failure, context: 'ClassName.methodName');
```

### 5. Show Retry for Retryable Errors
```dart
if (controller.canRetry) {
  ElevatedButton(
    onPressed: controller.reload,
    child: Text('Retry'),
  );
}
```

---

## Migration from Current Code

### Before (Try-Catch with Generic Exceptions)

```dart
Future<void> loadTasks() async {
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
      SnackBar(content: Text('Error: $e')), // ❌ Raw exception
    );
  }
}
```

### After (With Custom Error Handling)

```dart
Future<void> loadTasks() async {
  await executeWithErrorHandling(
    () => _getTasksUseCase(),
    context: 'TaskListController.loadTasks',
  );
}

// In UI
AsyncStreamBuilder<List<Task>>(
  state: controller,
  builder: (context, tasks) => TaskList(tasks),
  errorBuilder: (context, message) => ErrorDisplay(
    failure: controller.currentFailure!,
    onRetry: controller.loadTasks,
  ),
)
```

---

## Summary

Your error handling system now has:

1. ✅ **Type-safe failures** - Sealed classes with pattern matching
2. ✅ **Result type** - Functional error handling (Either monad)
3. ✅ **Automatic mapping** - Exceptions → Failures
4. ✅ **Logging** - Consistent error logging
5. ✅ **StreamState integration** - Works with your custom state management
6. ✅ **UI widgets** - Consistent error display
7. ✅ **Zero dependencies** - Pure Dart/Flutter

**Use this system throughout your architecture:**
- **Repository**: Map exceptions to failures
- **Use Case**: Throw domain-specific failures
- **Controller**: Handle errors with StreamState extensions
- **UI**: Display errors with ErrorDisplay widgets
