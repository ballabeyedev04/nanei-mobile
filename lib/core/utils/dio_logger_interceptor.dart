import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'app_logger.dart';

class AppDioInterceptor extends Interceptor {
  // Tronque le path pour éviter la divulgation d'endpoints en logs
  static String _safePath(String path) {
    if (kReleaseMode) return '[redacted]';
    final parts = path.split('/');
    return parts.length > 2 ? '/${parts[1]}/***' : path;
  }

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    AppLogger.debug('→ ${options.method} ${_safePath(options.path)}');
    super.onRequest(options, handler);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    AppLogger.debug('← ${response.statusCode} ${_safePath(response.requestOptions.path)}');
    super.onResponse(response, handler);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    final status = err.response?.statusCode;
    final path = _safePath(err.requestOptions.path);
    final message = err.response?.data?['message'] ?? err.message ?? 'Erreur inconnue';

    if (status == null || status >= 500) {
      AppLogger.error('API erreur serveur: $path', err, err.stackTrace);
    } else if (status == 401) {
      AppLogger.warning('API non autorisé: $path', {'status': status});
    } else if (status == 404) {
      AppLogger.warning('API non trouvé: $path', {'status': status});
    } else {
      AppLogger.warning('API erreur: $path', {'status': status, 'message': message});
    }
    super.onError(err, handler);
  }
}
