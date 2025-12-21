/// Result type for functional error handling
/// Alternative to throwing exceptions - returns either Success or Failure
library;

import 'failure.dart';

/// Result type - either Success with data or Error with failure
/// Use this for operations that can fail
sealed class Result<T> {
  const Result();

  /// Create a success result
  factory Result.success(T data) = Success<T>;

  /// Create an error result
  factory Result.error(Failure failure) = Error<T>;

  /// Check if result is success
  bool get isSuccess => this is Success<T>;

  /// Check if result is error
  bool get isError => this is Error<T>;

  /// Get data if success, null otherwise
  T? get dataOrNull => switch (this) {
    Success(data: final data) => data,
    Error() => null,
  };

  /// Get failure if error, null otherwise
  Failure? get failureOrNull => switch (this) {
    Success() => null,
    Error(failure: final failure) => failure,
  };

  /// Get data or throw if error
  T get data => switch (this) {
    Success(data: final data) => data,
    Error(failure: final failure) => throw Exception(
      'Tried to get data from error result: $failure',
    ),
  };

  /// Get failure or throw if success
  Failure get failure => switch (this) {
    Success() => throw Exception('Tried to get failure from success result'),
    Error(failure: final failure) => failure,
  };

  /// Transform success value
  Result<R> map<R>(R Function(T data) transform) {
    return switch (this) {
      Success(data: final data) => Result.success(transform(data)),
      Error(failure: final failure) => Result.error(failure),
    };
  }

  /// Transform success value asynchronously
  Future<Result<R>> mapAsync<R>(Future<R> Function(T data) transform) async {
    return switch (this) {
      Success(data: final data) => Result.success(await transform(data)),
      Error(failure: final failure) => Result.error(failure),
    };
  }

  /// Transform failure
  Result<T> mapError(Failure Function(Failure failure) transform) {
    return switch (this) {
      Success(data: final data) => Result.success(data),
      Error(failure: final failure) => Result.error(transform(failure)),
    };
  }

  /// Chain operations (flatMap/bind)
  Result<R> flatMap<R>(Result<R> Function(T data) transform) {
    return switch (this) {
      Success(data: final data) => transform(data),
      Error(failure: final failure) => Result.error(failure),
    };
  }

  /// Chain async operations
  Future<Result<R>> flatMapAsync<R>(
    Future<Result<R>> Function(T data) transform,
  ) async {
    return switch (this) {
      Success(data: final data) => await transform(data),
      Error(failure: final failure) => Result.error(failure),
    };
  }

  /// Get data or return default value
  T getOrElse(T defaultValue) {
    return switch (this) {
      Success(data: final data) => data,
      Error() => defaultValue,
    };
  }

  /// Get data or compute default value
  T getOrElseCompute(T Function(Failure failure) defaultValue) {
    return switch (this) {
      Success(data: final data) => data,
      Error(failure: final failure) => defaultValue(failure),
    };
  }

  /// Execute function on success
  Result<T> onSuccess(void Function(T data) action) {
    if (this is Success<T>) {
      action((this as Success<T>).data);
    }
    return this;
  }

  /// Execute function on error
  Result<T> onError(void Function(Failure failure) action) {
    if (this is Error<T>) {
      action((this as Error<T>).failure);
    }
    return this;
  }

  /// Fold result into single value
  R fold<R>({
    required R Function(T data) onSuccess,
    required R Function(Failure failure) onError,
  }) {
    return switch (this) {
      Success(data: final data) => onSuccess(data),
      Error(failure: final failure) => onError(failure),
    };
  }

  /// Convert to nullable value (null on error)
  T? toNullable() => dataOrNull;

  @override
  String toString() {
    return switch (this) {
      Success(data: final data) => 'Success($data)',
      Error(failure: final failure) => 'Error($failure)',
    };
  }
}

/// Success result containing data
class Success<T> extends Result<T> {
  final T data;

  const Success(this.data);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Success<T> &&
          runtimeType == other.runtimeType &&
          data == other.data;

  @override
  int get hashCode => data.hashCode;
}

/// Error result containing failure
class Error<T> extends Result<T> {
  final Failure failure;

  const Error(this.failure);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Error<T> &&
          runtimeType == other.runtimeType &&
          failure == other.failure;

  @override
  int get hashCode => failure.hashCode;
}

// ============================================================
// HELPER EXTENSIONS
// ============================================================
// ============================================================
// RESULT UNWRAP EXTENSION (for UI / State layers)
// ============================================================

extension ResultUnwrap<T> on Result<T> {
  /// Returns data if success, throws Failure if error
  T unwrap() {
    return switch (this) {
      Success(data: final data) => data,
      Error(failure: final failure) => throw failure,
    };
  }
}

/// Extension for Future<Result<T>>
extension FutureResultExtension<T> on Future<Result<T>> {
  /// Map success value
  Future<Result<R>> map<R>(R Function(T data) transform) async {
    final result = await this;
    return result.map(transform);
  }

  /// FlatMap for chaining
  Future<Result<R>> flatMap<R>(
    Future<Result<R>> Function(T data) transform,
  ) async {
    final result = await this;
    return result.flatMapAsync(transform);
  }

  /// Get data or default
  Future<T> getOrElse(T defaultValue) async {
    final result = await this;
    return result.getOrElse(defaultValue);
  }

  /// Execute on success
  Future<Result<T>> onSuccess(void Function(T data) action) async {
    final result = await this;
    return result.onSuccess(action);
  }

  /// Execute on error
  Future<Result<T>> onError(void Function(Failure failure) action) async {
    final result = await this;
    return result.onError(action);
  }
}

/// Helper to wrap a function that might throw
Result<T> resultOf<T>(T Function() fn) {
  try {
    return Result.success(fn());
  } on Failure catch (e) {
    return Result.error(e);
  } catch (e, stackTrace) {
    return Result.error(
      UnknownFailure(
        message: e.toString(),
        stackTrace: stackTrace,
        originalError: e,
      ),
    );
  }
}

/// Helper to wrap an async function that might throw
Future<Result<T>> resultOfAsync<T>(Future<T> Function() fn) async {
  try {
    return Result.success(await fn());
  } on Failure catch (e) {
    return Result.error(e);
  } catch (e, stackTrace) {
    return Result.error(
      UnknownFailure(
        message: e.toString(),
        stackTrace: stackTrace,
        originalError: e,
      ),
    );
  }
}
