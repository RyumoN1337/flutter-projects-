import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../error/app_exception.dart';

class ApiInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    options.headers['X-Client'] = 'PostExplorer/1.0';
    options.headers['X-Request-Id'] = DateTime.now().microsecondsSinceEpoch
        .toString();
    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    handler.next(err.copyWith(error: AppException.from(err)));
  }
}

class DioClient {
  static Dio create() =>
      Dio(
          BaseOptions(
            baseUrl: 'https://jsonplaceholder.typicode.com',
            connectTimeout: const Duration(seconds: 12),
            receiveTimeout: const Duration(seconds: 15),
            sendTimeout: const Duration(seconds: 15),
          ),
        )
        ..interceptors.addAll([
          ApiInterceptor(),
          if (kDebugMode) LogInterceptor(responseBody: false),
        ]);
}
