/// Pure Dart stream-based state management
/// No external dependencies, fully portable
library;

import 'dart:async';

import 'package:keep_track/core/error/failure.dart';

/// Base class for state containers using streams
/// Implements disposable pattern for cleanup
abstract class StreamState<T> {
  final _controller = StreamController<T>.broadcast();
  T _state;

  StreamState(this._state);

  /// Current state value
  T get state => _state;

  /// Stream of state changes
  Stream<T> get stream => _controller.stream;

  /// Emit new state to all listeners
  void emit(T newState) {
    _state = newState;
    if (!_controller.isClosed) {
      _controller.add(newState);
    }
  }

  /// Update state using current value
  void update(T Function(T current) updater) {
    emit(updater(_state));
  }

  /// Cleanup resources
  void dispose() {
    _controller.close();
  }
}

/// Async state wrapper for handling loading/success/error states
sealed class AsyncState<T> {
  const AsyncState();
}

class AsyncLoading<T> extends AsyncState<T> {
  const AsyncLoading();
}

class AsyncData<T> extends AsyncState<T> {
  final T data;
  const AsyncData(this.data);
}

class AsyncError<T> extends AsyncState<T> {
  final String message;
  final Object? error;
  const AsyncError(this.message, [this.error]);
}

/// Extension for easier async state management
extension AsyncStateExtension<T> on StreamState<AsyncState<T>> {
  bool get isLoading => state is AsyncLoading;
  bool get hasData => state is AsyncData;
  bool get hasError => state is AsyncError;

  T? get data => state is AsyncData<T> ? (state as AsyncData<T>).data : null;
  String? get errorMessage =>
      state is AsyncError<T> ? (state as AsyncError<T>).message : null;

  /// Execute async operation with automatic loading/error states
  Future<void> execute(Future<T> Function() operation) async {
    emit(const AsyncLoading());
    try {
      final result = await operation();
      emit(AsyncData(result));
    } on Failure catch (failure) {
      emit(AsyncError(failure.message, failure));
    } catch (e, stackTrace) {
      // Log unexpected errors for debugging
      print('StreamState unexpected error: $e');
      print('Stack trace: $stackTrace');

      // fallback for truly unknown errors
      emit(
        AsyncError(
          'Unexpected error: ${e.toString()}',
          UnknownFailure(
            message: e.toString(),
            originalError: e,
            stackTrace: stackTrace,
          ),
        ),
      );
    }
  }
}
