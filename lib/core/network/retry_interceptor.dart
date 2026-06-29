import 'dart:io';
import 'package:dio/dio.dart';

class RetryInterceptor extends Interceptor {
  final Dio dio;
  final int maxRetries;

  RetryInterceptor({required this.dio, this.maxRetries = 3});

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    final retriable = _isRetriable(err);
    final attempt = (err.requestOptions.extra['_retry'] as int?) ?? 0;

    if (retriable && attempt < maxRetries) {
      final delaySeconds = 1 << attempt; // 1s, 2s, 4s
      await Future.delayed(Duration(seconds: delaySeconds));

      final opts = err.requestOptions;
      opts.extra['_retry'] = attempt + 1;

      try {
        final response = await dio.fetch(opts);
        return handler.resolve(response);
      } on DioException catch (e) {
        return handler.next(e);
      }
    }

    return handler.next(err);
  }

  bool _isRetriable(DioException e) {
    if (e.response?.statusCode == 401) return false; // géré par le token interceptor
    return e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.sendTimeout ||
        e.type == DioExceptionType.receiveTimeout ||
        e.type == DioExceptionType.connectionError ||
        e.error is SocketException;
  }
}
