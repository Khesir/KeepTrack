/// Custom error handling system
///
/// Provides:
/// - Failure types for domain errors
/// - Result type for functional error handling
/// - Exception mapping
/// - Error logging and handling
/// - UI widgets for error display
///
/// Example usage:
/// ```dart
/// // In Use Case
/// Future<Result<Task>> call(String id) async {
///   return ErrorHandler.handleAsync(() async {
///     final task = await _repository.getTaskById(id);
///     if (task == null) {
///       throw NotFoundFailure(resourceType: 'Task', resourceId: id);
///     }
///     return task;
///   });
/// }
///
/// // In Controller
/// Future<void> loadTask(String id) async {
///   await executeWithErrorHandling(
///     () => _getTaskUseCase(id),
///     context: 'TaskDetailController.loadTask',
///   );
/// }
///
/// // In UI
/// AsyncStreamBuilder<Task>(
///   state: controller,
///   builder: (context, task) => TaskDetail(task),
///   errorBuilder: (context, message) => ErrorDisplay(
///     failure: controller.currentFailure!,
///     onRetry: () => controller.loadTask(taskId),
///   ),
/// )
/// ```
library;

export 'failure.dart';
export 'result.dart';
export 'exception_mapper.dart';
export 'error_handler.dart';
export 'stream_state_error_handling.dart';
export 'error_widgets.dart';
