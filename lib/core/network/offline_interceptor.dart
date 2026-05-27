import 'package:dio/dio.dart';
import 'package:keep_track/core/connectivity/connectivity_service.dart';

class OfflineModeInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    if (!ConnectivityService.instance.isForceOffline) {
      handler.next(options);
      return;
    }

    final method = options.method.toUpperCase();
    dynamic data;

    if (method == 'GET') {
      // Return empty list for list endpoints, empty map for single-item
      final path = options.path;
      final isListEndpoint = !RegExp(r'/[^/]+$').hasMatch(path) ||
          path.endsWith('s') ||
          (options.queryParameters.isNotEmpty);
      data = isListEndpoint ? [] : <String, dynamic>{};
    } else {
      // For mutations (POST/PATCH/DELETE), echo back the request body or empty map
      data = options.data ?? <String, dynamic>{};
    }

    handler.resolve(
      Response(
        requestOptions: options,
        data: data,
        statusCode: 200,
      ),
      true,
    );
  }
}
