/// Error handling extensions for StreamState
/// Integrates custom error handling with state management
library;

import '../state/stream_state.dart';
import 'error_handler.dart';
import 'exception_mapper.dart';
import 'failure.dart';
import 'result.dart';

/// Extension for StreamState with better error handling
extension StreamStateErrorHandling<T> on StreamState<AsyncState<T>> {
  /// Execute with automatic error mapping to Failure
  Future<void> executeWithErrorHandling(
    Future<T> Function() operation, {
    String? context,
  }) async {
    emit(const AsyncLoading());
    try {
      final result = await operation();
      emit(AsyncData(result));
    } catch (e, stackTrace) {
      final failure = ExceptionMapper.mapException(e, stackTrace);
      ErrorHandler.logError(failure, context: context, stackTrace: stackTrace);
      emit(AsyncError(failure.userMessage, failure));
    }
  }

  /// Execute a Result-returning operation
  Future<void> executeResult(
    Future<Result<T>> Function() operation, {
    String? context,
  }) async {
    emit(const AsyncLoading());
    final result = await operation();

    result.fold(
      onSuccess: (data) => emit(AsyncData(data)),
      onError: (failure) {
        ErrorHandler.logError(failure, context: context);
        emit(AsyncError(failure.userMessage, failure));
      },
    );
  }

  /// Execute with custom error transformation
  Future<void> executeWithCustomError(
    Future<T> Function() operation, {
    String? context,
    Failure Function(Object error, StackTrace stackTrace)? errorTransform,
  }) async {
    emit(const AsyncLoading());
    try {
      final result = await operation();
      emit(AsyncData(result));
    } catch (e, stackTrace) {
      final failure = errorTransform?.call(e, stackTrace) ??
          ExceptionMapper.mapException(e, stackTrace);
      ErrorHandler.logError(failure, context: context, stackTrace: stackTrace);
      emit(AsyncError(failure.userMessage, failure));
    }
  }

  /// Get current failure if in error state
  Failure? get currentFailure {
    final currentState = state;
    if (currentState is AsyncError<T>) {
      final error = currentState.error;
      if (error is Failure) {
        return error;
      }
    }
    return null;
  }

  /// Check if current error is retryable
  bool get canRetry => currentFailure?.isRetryable ?? false;

  /// Get error title for UI
  String? get errorTitle {
    final failure = currentFailure;
    return failure != null ? ErrorHandler.getErrorTitle(failure) : null;
  }
}

/// Helper class for building error-aware operations
class ErrorAwareOperation<T> {
  final Future<T> Function() _operation;
  String? _context;
  void Function(T data)? _onSuccess;
  void Function(Failure failure)? _onError;
  Failure Function(Object error, StackTrace stackTrace)? _errorTransform;

  ErrorAwareOperation(this._operation);

  /// Set context for logging
  ErrorAwareOperation<T> withContext(String context) {
    _context = context;
    return this;
  }

  /// Set success callback
  ErrorAwareOperation<T> onSuccess(void Function(T data) callback) {
    _onSuccess = callback;
    return this;
  }

  /// Set error callback
  ErrorAwareOperation<T> onError(void Function(Failure failure) callback) {
    _onError = callback;
    return this;
  }

  /// Set custom error transformation
  ErrorAwareOperation<T> withErrorTransform(
    Failure Function(Object error, StackTrace stackTrace) transform,
  ) {
    _errorTransform = transform;
    return this;
  }

  /// Execute the operation
  Future<Result<T>> execute() async {
    try {
      final result = await _operation();
      _onSuccess?.call(result);
      return Result.success(result);
    } catch (e, stackTrace) {
      final failure = _errorTransform?.call(e, stackTrace) ??
          ExceptionMapper.mapException(e, stackTrace);

      ErrorHandler.logError(failure, context: _context, stackTrace: stackTrace);
      _onError?.call(failure);

      return Result.error(failure);
    }
  }

  /// Execute and emit to stream state
  Future<void> executeToStream(StreamState<AsyncState<T>> state) async {
    state.emit(const AsyncLoading());

    final result = await execute();

    result.fold(
      onSuccess: (data) => state.emit(AsyncData(data)),
      onError: (failure) => state.emit(AsyncError(failure.userMessage, failure)),
    );
  }
}

/// Helper function to create error-aware operation
ErrorAwareOperation<T> errorAware<T>(Future<T> Function() operation) {
  return ErrorAwareOperation(operation);
}
