# Error Handling Quick Reference

## Available Failure Types

### Infrastructure Failures
```dart
NetworkFailure()               // No internet connection
ServerFailure(statusCode: 500) // Server error (5xx)
TimeoutFailure()               // Request timed out
DatabaseFailure()              // Database operation failed
```

### Client Failures
```dart
ValidationFailure('Message', fieldErrors: {'field': 'error'})
NotFoundFailure(resourceType: 'Task', resourceId: '123')
UnauthorizedFailure()          // 401 - Not logged in
ForbiddenFailure()             // 403 - No permission
ConflictFailure()              // 409 - Resource exists
```

### Business Failures
```dart
BusinessRuleFailure(rule: 'Cannot do X', message: 'Custom message')
ConcurrentModificationFailure() // Data changed elsewhere
```

### Technical Failures
```dart
ParsingFailure()               // JSON parsing failed
CacheFailure()                 // Cache operation failed
UnknownFailure()               // Catch-all
```

---

## Usage Patterns

### 1. Repository Layer - Map Exceptions

```dart
@override
Future<Task> getTaskById(String id) async {
  try {
    final model = await _dataSource.getTaskById(id);
    return model.toEntity();
  } catch (e, stackTrace) {
    throw ExceptionMapper.mapException(e, stackTrace);
  }
}
```

### 2. Use Case Layer - Throw Business Failures

```dart
Future<Task> call(String taskId) async {
  final task = await _repository.getTaskById(taskId);

  if (task == null) {
    throw NotFoundFailure(resourceType: 'Task', resourceId: taskId);
  }

  if (task.title.isEmpty) {
    throw ValidationFailure('Title cannot be empty');
  }

  return task;
}
```

### 3. Controller Layer - Handle Errors

**Option A: executeWithErrorHandling**
```dart
Future<void> loadTask(String taskId) async {
  await executeWithErrorHandling(
    () => _getTaskUseCase(taskId),
    context: 'TaskController.loadTask',
  );
}
```

**Option B: Manual try-catch**
```dart
Future<void> loadTask(String taskId) async {
  emit(const AsyncLoading());
  try {
    final task = await _getTaskUseCase(taskId);
    emit(AsyncData(task));
  } catch (e, stackTrace) {
    final failure = ExceptionMapper.mapException(e, stackTrace);
    ErrorHandler.logError(failure, context: 'loadTask', stackTrace: stackTrace);
    emit(AsyncError(failure.userMessage, failure));
  }
}
```

**Option C: Result type**
```dart
Future<void> loadTask(String taskId) async {
  await executeResult(
    () => _getTaskUseCase(taskId),
    context: 'TaskController.loadTask',
  );
}
```

### 4. UI Layer - Display Errors

**Full error page**
```dart
AsyncStreamBuilder<Task>(
  state: controller,
  builder: (context, task) => TaskView(task),
  errorBuilder: (context, message) => ErrorDisplay(
    failure: controller.currentFailure!,
    onRetry: () => controller.loadTask(taskId),
  ),
)
```

**Error card**
```dart
if (controller.state is AsyncError) {
  ErrorCard(
    failure: controller.currentFailure!,
    onRetry: controller.canRetry ? controller.reload : null,
  )
}
```

**Snackbar**
```dart
showErrorSnackBar(
  context,
  failure,
  onRetry: () => controller.reload(),
);
```

**Dialog**
```dart
showErrorDialog(
  context,
  failure,
  onRetry: () => controller.reload(),
);
```

---

## Result Type

### Create Result
```dart
Result.success(data)
Result.error(failure)

// From function
resultOf(() => someFunction())
await resultOfAsync(() => someAsyncFunction())
```

### Check Result
```dart
if (result.isSuccess) { ... }
if (result.isError) { ... }

final data = result.dataOrNull;  // null if error
final failure = result.failureOrNull;  // null if success
```

### Transform Result
```dart
// Map success value
result.map((data) => transformedData)

// Chain operations (flatMap)
result.flatMap((data) => anotherResult(data))

// Handle both cases
result.fold(
  onSuccess: (data) => handleSuccess(data),
  onError: (failure) => handleError(failure),
)
```

### Side Effects
```dart
result
  .onSuccess((data) => print('Success: $data'))
  .onError((failure) => print('Error: $failure'))
```

---

## StreamState Extensions

### In Controller
```dart
// Access current failure
final failure = currentFailure;  // Failure? or null

// Check if can retry
if (canRetry) { /* show retry */ }

// Get error title
final title = errorTitle;  // "Network Error", etc.
```

### Execute with error handling
```dart
// Automatic error mapping
await executeWithErrorHandling(() => useCase());

// With Result
await executeResult(() => useCaseReturningResult());

// With custom error transform
await executeWithCustomError(
  () => useCase(),
  errorTransform: (e, stackTrace) => CustomFailure(),
);
```

---

## Error Helpers

### Log Error
```dart
ErrorHandler.logError(failure, context: 'ClassName.method');
```

### Get User Message
```dart
final message = ErrorHandler.getUserMessage(failure);
final title = ErrorHandler.getErrorTitle(failure);
```

### Check Retry
```dart
if (ErrorHandler.shouldShowRetry(failure)) {
  // Show retry button
}

// Or use extension
if (failure.isRetryable) { ... }
```

---

## Common Patterns

### Validation with Field Errors
```dart
final errors = <String, String>{};

if (title.isEmpty) errors['title'] = 'Required';
if (title.length > 255) errors['title'] = 'Too long';

if (errors.isNotEmpty) {
  throw ValidationFailure('Fix errors', fieldErrors: errors);
}

// In UI
if (failure is ValidationFailure) {
  final titleError = failure.getFieldError('title');
}
```

### Custom Feature Failures
```dart
// features/tasks/domain/failures/task_failures.dart
class TaskNotFoundFailure extends NotFoundFailure {
  TaskNotFoundFailure(String taskId)
      : super(resourceType: 'Task', resourceId: taskId);
}
```

### ErrorAware Builder
```dart
await errorAware(() => repository.getData())
  .withContext('loadData')
  .onSuccess((data) => print('Loaded $data'))
  .onError((failure) => showError(failure))
  .executeToStream(this);
```

---

## Testing

```dart
// Test throwing failure
expect(
  () => useCase(invalid),
  throwsA(isA<ValidationFailure>()),
);

// Test Result
final result = await useCase(params);
expect(result.isError, true);
expect(result.failure, isA<NotFoundFailure>());

// Test controller error state
await controller.loadTask('invalid');
expect(controller.state, isA<AsyncError>());
expect(controller.currentFailure, isA<TaskNotFoundFailure>());
expect(controller.canRetry, false);
```

---

## Best Practices

### ✅ DO
- Use specific Failure types
- Include context when logging
- Show retry for retryable errors
- Map exceptions at repository layer
- Throw business failures in use cases
- Log all errors

### ❌ DON'T
- Don't show raw exceptions to users
- Don't catch and ignore errors silently
- Don't use generic Exception
- Don't handle errors in multiple layers
- Don't forget to dispose controllers

---

## Checklist for New Feature

- [ ] Define feature-specific failures (extend core Failures)
- [ ] Repository maps exceptions to Failures
- [ ] Use cases throw business Failures
- [ ] Controller uses executeWithErrorHandling
- [ ] UI displays errors with ErrorDisplay or ErrorCard
- [ ] Add tests for error cases
- [ ] Log errors with context
- [ ] Show retry for retryable errors

---

## Files Reference

```
core/error/
├── failure.dart                      # Failure types
├── result.dart                       # Result type (Either)
├── exception_mapper.dart             # Exception → Failure
├── error_handler.dart                # Error logging/handling
├── stream_state_error_handling.dart  # StreamState extensions
├── error_widgets.dart                # UI widgets
├── error.dart                        # Barrel export
├── ERROR_HANDLING_GUIDE.md           # Full guide
└── QUICK_REFERENCE.md                # This file
```

---

## Import

```dart
import 'package:personal_codex/core/error/error.dart';
```

This imports everything you need!
