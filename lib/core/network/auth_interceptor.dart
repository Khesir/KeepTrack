import 'package:dio/dio.dart';
import '../auth/auth_tokens.dart';
import '../auth/token_storage.dart';

/// Injects Bearer token on every request.
/// On 401: tries one token refresh, then retries. On failure: clears tokens.
class AuthInterceptor extends Interceptor {
  final Dio _dio;
  final TokenStorage _storage = TokenStorage.instance;

  bool _isRefreshing = false;

  AuthInterceptor(this._dio);

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final token = await _storage.getAccessToken();
    if (token != null) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    if (err.response?.statusCode == 401 && !_isRefreshing) {
      _isRefreshing = true;
      try {
        final refreshed = await _tryRefresh();
        if (refreshed) {
          // Retry the original request with the new token
          final token = await _storage.getAccessToken();
          final opts = err.requestOptions
            ..headers['Authorization'] = 'Bearer $token';
          final response = await _dio.fetch(opts);
          handler.resolve(response);
          return;
        }
      } catch (_) {
        // Refresh failed
      } finally {
        _isRefreshing = false;
      }
      // Refresh failed — clear tokens (app will redirect to login)
      await _storage.clear();
    }
    handler.next(err);
  }

  Future<bool> _tryRefresh() async {
    final refreshToken = await _storage.getRefreshToken();
    if (refreshToken == null) return false;

    final response = await _dio.post(
      '/auth/refresh',
      data: {'refreshToken': refreshToken},
      options: Options(headers: {'Authorization': null}),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      final data = response.data as Map<String, dynamic>;
      await _storage.save(
        AuthTokens(
          accessToken: data['accessToken'] as String,
          refreshToken: data['refreshToken'] as String,
        ),
      );
      return true;
    }
    return false;
  }
}
