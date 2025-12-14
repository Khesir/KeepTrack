/// Base failure class for all errors in the application
/// Failures are domain-level errors that represent business problems
library;

/// Base class for all failures
/// Use sealed class for exhaustive pattern matching
sealed class Failure {
  final String message;
  final StackTrace? stackTrace;
  final Object? originalError;

  const Failure({
    required this.message,
    this.stackTrace,
    this.originalError,
  });

  @override
  String toString() => message;
}

// ============================================================
// INFRASTRUCTURE FAILURES
// ============================================================

/// Network connectivity failure
class NetworkFailure extends Failure {
  const NetworkFailure({
    String? message,
    super.stackTrace,
    super.originalError,
  }) : super(
          message: message ?? 'No internet connection. Please check your network.',
        );
}

/// Server error (5xx errors)
class ServerFailure extends Failure {
  final int? statusCode;

  const ServerFailure({
    this.statusCode,
    String? message,
    super.stackTrace,
    super.originalError,
  }) : super(
          message: message ?? 'Server error. Please try again later.',
        );
}

/// Request timeout
class TimeoutFailure extends Failure {
  const TimeoutFailure({
    String? message,
    super.stackTrace,
    super.originalError,
  }) : super(
          message: message ?? 'Request timed out. Please try again.',
        );
}

/// Data persistence failure
class DatabaseFailure extends Failure {
  const DatabaseFailure({
    String? message,
    super.stackTrace,
    super.originalError,
  }) : super(
          message: message ?? 'Failed to save data. Please try again.',
        );
}

// ============================================================
// CLIENT FAILURES
// ============================================================

/// Validation failure (business rule violation)
class ValidationFailure extends Failure {
  final Map<String, String>? fieldErrors;

  const ValidationFailure(
    String message, {
    this.fieldErrors,
    super.stackTrace,
    super.originalError,
  }) : super(message: message);

  /// Check if specific field has error
  bool hasFieldError(String field) => fieldErrors?.containsKey(field) ?? false;

  /// Get error for specific field
  String? getFieldError(String field) => fieldErrors?[field];
}

/// Resource not found (404)
class NotFoundFailure extends Failure {
  final String? resourceType;
  final String? resourceId;

  const NotFoundFailure({
    this.resourceType,
    this.resourceId,
    String? message,
    super.stackTrace,
    super.originalError,
  }) : super(
          message: message ??
              (resourceType != null
                  ? '$resourceType not found'
                  : 'Resource not found'),
        );
}

/// Unauthorized access (401)
class UnauthorizedFailure extends Failure {
  const UnauthorizedFailure({
    String? message,
    super.stackTrace,
    super.originalError,
  }) : super(
          message: message ?? 'Unauthorized. Please log in again.',
        );
}

/// Forbidden access (403)
class ForbiddenFailure extends Failure {
  const ForbiddenFailure({
    String? message,
    super.stackTrace,
    super.originalError,
  }) : super(
          message: message ?? 'Access denied. You do not have permission.',
        );
}

/// Conflict (409) - e.g., duplicate resource
class ConflictFailure extends Failure {
  const ConflictFailure({
    String? message,
    super.stackTrace,
    super.originalError,
  }) : super(
          message: message ?? 'Resource already exists.',
        );
}

// ============================================================
// BUSINESS LOGIC FAILURES
// ============================================================

/// Operation not allowed due to business rules
class BusinessRuleFailure extends Failure {
  final String rule;

  const BusinessRuleFailure({
    required this.rule,
    String? message,
    super.stackTrace,
    super.originalError,
  }) : super(
          message: message ?? 'Operation not allowed: $rule',
        );
}

/// Concurrent modification detected
class ConcurrentModificationFailure extends Failure {
  const ConcurrentModificationFailure({
    String? message,
    super.stackTrace,
    super.originalError,
  }) : super(
          message: message ??
              'Data was modified by another process. Please refresh and try again.',
        );
}

// ============================================================
// PARSING/SERIALIZATION FAILURES
// ============================================================

/// JSON parsing failure
class ParsingFailure extends Failure {
  const ParsingFailure({
    String? message,
    super.stackTrace,
    super.originalError,
  }) : super(
          message: message ?? 'Failed to parse data. Please contact support.',
        );
}

/// Cache failure
class CacheFailure extends Failure {
  const CacheFailure({
    String? message,
    super.stackTrace,
    super.originalError,
  }) : super(
          message: message ?? 'Cache error occurred.',
        );
}

// ============================================================
// UNKNOWN/UNEXPECTED FAILURES
// ============================================================

/// Unknown error (catch-all)
class UnknownFailure extends Failure {
  const UnknownFailure({
    String? message,
    super.stackTrace,
    super.originalError,
  }) : super(
          message: message ?? 'An unexpected error occurred. Please try again.',
        );
}

// ============================================================
// HELPER EXTENSIONS
// ============================================================

extension FailureExtension on Failure {
  /// Check if failure is network-related
  bool get isNetworkFailure => this is NetworkFailure || this is TimeoutFailure;

  /// Check if failure is server-related
  bool get isServerFailure => this is ServerFailure;

  /// Check if failure is client-related (user error)
  bool get isClientFailure =>
      this is ValidationFailure ||
      this is NotFoundFailure ||
      this is UnauthorizedFailure ||
      this is ForbiddenFailure;

  /// Check if user should retry
  bool get isRetryable =>
      this is NetworkFailure ||
      this is TimeoutFailure ||
      this is ServerFailure;

  /// Get user-friendly message
  String get userMessage => message;

  /// Get technical details for logging
  String get technicalDetails {
    final buffer = StringBuffer();
    buffer.writeln('Failure: $runtimeType');
    buffer.writeln('Message: $message');
    if (originalError != null) {
      buffer.writeln('Original Error: $originalError');
    }
    if (stackTrace != null) {
      buffer.writeln('Stack Trace: $stackTrace');
    }
    return buffer.toString();
  }
}
