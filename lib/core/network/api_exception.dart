import 'package:dio/dio.dart';
import '../error/failure.dart';

/// Maps DioException → app Failure types
Failure mapDioError(DioException e) {
  if (e.type == DioExceptionType.connectionTimeout ||
      e.type == DioExceptionType.sendTimeout ||
      e.type == DioExceptionType.receiveTimeout ||
      e.type == DioExceptionType.connectionError) {
    return NetworkFailure(
      message: 'No internet connection or server unreachable',
      originalError: e,
    );
  }

  final status = e.response?.statusCode;
  final body = e.response?.data;
  final serverMsg =
      (body is Map ? body['message']?.toString() : null) ?? e.message ?? '';

  return switch (status) {
    400 => ValidationFailure(serverMsg),
    401 => const UnauthorizedFailure(message: 'Unauthorized'),
    403 => const UnauthorizedFailure(message: 'Forbidden'),
    404 => NotFoundFailure(message: serverMsg.isNotEmpty ? serverMsg : 'Not found'),
    409 => ValidationFailure(serverMsg.isNotEmpty ? serverMsg : 'Conflict'),
    _ => ServerFailure(message: serverMsg.isNotEmpty ? serverMsg : 'Server error'),
  };
}
