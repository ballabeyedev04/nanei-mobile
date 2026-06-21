import 'package:dio/dio.dart';
import 'app_logger.dart';

class AppDioInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    AppLogger.debug('→ ${options.method} ${options.path}');
    super.onRequest(options, handler);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    AppLogger.debug('← ${response.statusCode} ${response.requestOptions.path}');
    super.onResponse(response, handler);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    final status = err.response?.statusCode;
    final path = err.requestOptions.path;
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
