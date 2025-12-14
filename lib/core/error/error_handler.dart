/// Error handler for consistent error handling across the app
library;

import 'package:flutter/foundation.dart';
import 'exception_mapper.dart';
import 'failure.dart';
import 'result.dart';

/// Error handler - provides consistent error handling
class ErrorHandler {
  /// Log error to console (or external service in production)
  static void logError(
    Failure failure, {
    String? context,
    StackTrace? stackTrace,
  }) {
    if (kDebugMode) {
      print('═══════════════════════════════════════');
      if (context != null) {
        print('Context: $context');
      }
      print('Error: ${failure.runtimeType}');
      print('Message: ${failure.message}');
      if (failure.originalError != null) {
        print('Original: ${failure.originalError}');
      }
      if (stackTrace != null || failure.stackTrace != null) {
        print('Stack Trace:');
        print(stackTrace ?? failure.stackTrace);
      }
      print('═══════════════════════════════════════');
    }

    // TODO: Send to external logging service in production
    // e.g., Sentry, Firebase Crashlytics, etc.
  }

  /// Get user-friendly error message
  static String getUserMessage(Failure failure) {
    // You can customize messages here based on failure type
    return failure.userMessage;
  }

  /// Get title for error dialog
  static String getErrorTitle(Failure failure) {
    return switch (failure) {
      NetworkFailure() => 'Connection Error',
      ServerFailure() => 'Server Error',
      ValidationFailure() => 'Validation Error',
      NotFoundFailure() => 'Not Found',
      UnauthorizedFailure() => 'Authentication Required',
      ForbiddenFailure() => 'Access Denied',
      TimeoutFailure() => 'Timeout',
      DatabaseFailure() => 'Database Error',
      BusinessRuleFailure() => 'Operation Failed',
      _ => 'Error',
    };
  }

  /// Check if error should show retry button
  static bool shouldShowRetry(Failure failure) {
    return failure.isRetryable;
  }

  /// Execute a function and handle errors
  static Result<T> handle<T>(
    T Function() fn, {
    String? context,
  }) {
    try {
      return Result.success(fn());
    } catch (e, stackTrace) {
      final failure = ExceptionMapper.mapException(e, stackTrace);
      logError(failure, context: context, stackTrace: stackTrace);
      return Result.error(failure);
    }
  }

  /// Execute an async function and handle errors
  static Future<Result<T>> handleAsync<T>(
    Future<T> Function() fn, {
    String? context,
  }) async {
    try {
      return Result.success(await fn());
    } catch (e, stackTrace) {
      final failure = ExceptionMapper.mapException(e, stackTrace);
      logError(failure, context: context, stackTrace: stackTrace);
      return Result.error(failure);
    }
  }

  /// Convert a future to Result, catching all errors
  static Future<Result<T>> toResult<T>(
    Future<T> future, {
    String? context,
  }) async {
    return handleAsync(() => future, context: context);
  }
}

/// Extension for easier error handling in repositories and use cases
extension ErrorHandlingExtension<T> on Future<T> {
  /// Convert Future<T> to Future<Result<T>> with automatic error mapping
  Future<Result<T>> toResult({String? context}) {
    return ErrorHandler.handleAsync(() => this, context: context);
  }

  /// Execute future and handle errors, calling onError if it fails
  Future<T?> onErrorReturn(
    T? Function(Failure failure) onError, {
    String? context,
  }) async {
    try {
      return await this;
    } catch (e, stackTrace) {
      final failure = ExceptionMapper.mapException(e, stackTrace);
      ErrorHandler.logError(failure, context: context, stackTrace: stackTrace);
      return onError(failure);
    }
  }

  /// Execute future and handle errors, returning null on error
  Future<T?> onErrorReturnNull({String? context}) async {
    return onErrorReturn((_) => null, context: context);
  }
}

/// Extension for Result type
extension ResultErrorHandling<T> on Result<T> {
  /// Log error if result is error
  Result<T> logOnError({String? context}) {
    if (this is Error<T>) {
      ErrorHandler.logError((this as Error<T>).failure, context: context);
    }
    return this;
  }

  /// Show error message if result is error (for debugging)
  Result<T> printOnError() {
    if (this is Error<T>) {
      if (kDebugMode) {
        print('Error: ${(this as Error<T>).failure.message}');
      }
    }
    return this;
  }
}
