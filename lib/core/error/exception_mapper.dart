/// Maps exceptions to domain failures
/// Converts technical exceptions to user-friendly failures
library;

import 'failure.dart';

/// Exception mapper - converts exceptions to failures
class ExceptionMapper {
  /// Convert any exception to a Failure
  static Failure mapException(Object error, [StackTrace? stackTrace]) {
    // Already a Failure - return as-is
    if (error is Failure) {
      return error;
    }

    // Map common exceptions
    if (error is TypeError || error is NoSuchMethodError) {
      return UnknownFailure(
        message: 'Application error. Please contact support.',
        stackTrace: stackTrace,
        originalError: error,
      );
    }

    if (error is FormatException || error is TypeError) {
      return ParsingFailure(
        message: 'Failed to process data.',
        stackTrace: stackTrace,
        originalError: error,
      );
    }

    if (error is TimeoutException) {
      return TimeoutFailure(
        stackTrace: stackTrace,
        originalError: error,
      );
    }

    if (error is StateError) {
      return UnknownFailure(
        message: 'Invalid state. Please restart the application.',
        stackTrace: stackTrace,
        originalError: error,
      );
    }

    // HTTP status code mapping (if you add http package later)
    if (error is Exception) {
      final message = error.toString();

      // Check for common error patterns
      if (message.contains('SocketException') ||
          message.contains('Network') ||
          message.contains('connection')) {
        return NetworkFailure(
          stackTrace: stackTrace,
          originalError: error,
        );
      }

      if (message.contains('not found') || message.contains('404')) {
        return NotFoundFailure(
          stackTrace: stackTrace,
          originalError: error,
        );
      }

      if (message.contains('timeout')) {
        return TimeoutFailure(
          stackTrace: stackTrace,
          originalError: error,
        );
      }

      if (message.contains('unauthorized') || message.contains('401')) {
        return UnauthorizedFailure(
          stackTrace: stackTrace,
          originalError: error,
        );
      }

      if (message.contains('forbidden') || message.contains('403')) {
        return ForbiddenFailure(
          stackTrace: stackTrace,
          originalError: error,
        );
      }
    }

    // Default: Unknown failure
    return UnknownFailure(
      message: error.toString(),
      stackTrace: stackTrace,
      originalError: error,
    );
  }

  /// Map HTTP status code to failure
  static Failure mapHttpStatus(int statusCode, {String? message}) {
    return switch (statusCode) {
      400 => ValidationFailure(message ?? 'Invalid request'),
      401 => UnauthorizedFailure(message: message),
      403 => ForbiddenFailure(message: message),
      404 => NotFoundFailure(message: message),
      409 => ConflictFailure(message: message),
      408 => TimeoutFailure(message: message),
      >= 500 => ServerFailure(statusCode: statusCode, message: message),
      _ => UnknownFailure(message: message ?? 'Request failed'),
    };
  }
}

/// Timeout exception
class TimeoutException implements Exception {
  final String message;

  TimeoutException([this.message = 'Operation timed out']);

  @override
  String toString() => message;
}

/// Custom exception for expected errors
/// Use this when you want to throw domain-specific errors
class DomainException implements Exception {
  final Failure failure;

  DomainException(this.failure);

  @override
  String toString() => failure.toString();
}
