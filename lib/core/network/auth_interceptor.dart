import 'package:dio/dio.dart';

import '../config/env.dart';
import '../services/token_service.dart';

/// Intercepteur d'authentification du client Dio PARTAGÉ.
///
///  - ajoute `Authorization: Bearer <jwt>` à toute requête hors `/auth/…` ;
///  - renouvelle le jeton AVANT l'appel s'il est expiré côté client et qu'un
///    refresh token existe ;
///  - sur un 401, renouvelle le jeton (une seule fois, mutualisé par
///    [TokenService.tryRefresh]) puis REJOUE la requête une seule fois.
///
/// Extrait de `injection_container.dart` pour pouvoir être testé sans
/// GetIt : le comportement est strictement celui d'avant.
class AuthInterceptor extends Interceptor {
  /// Client sur lequel la requête est rejouée après renouvellement.
  final Dio dio;
  final TokenService tokenService;

  /// Appel `POST /auth/refresh` — sur un client SANS intercepteurs, sinon un
  /// 401 du refresh relancerait un refresh (boucle jusqu'au 429).
  final Future<Map<String, dynamic>?> Function(String refreshToken) refreshCall;

  AuthInterceptor({
    required this.dio,
    required this.tokenService,
    required this.refreshCall,
  });

  /// `POST /auth/refresh { refreshToken }` sur [refreshDio] (client SANS
  /// intercepteurs). Le back répond `{ token, refreshToken }` (rotation).
  static Future<Map<String, dynamic>?> Function(String) refreshVia(
          Dio refreshDio) =>
      (rt) async {
        final response = await refreshDio.post(
          Env.authRefresh,
          data: {'refreshToken': rt},
        );
        return response.data as Map<String, dynamic>?;
      };

  Future<bool> _rafraichir() => tokenService.tryRefresh(refreshCall);

  /// Routes d'authentification : jamais de jeton ni de rafraîchissement
  /// (login, register, refresh, logout, mot de passe oublié…).
  static bool estRouteAuth(String path) {
    final p = path.split('?')[0].trim();
    return p.contains('/auth/');
  }

  @override
  Future<void> onRequest(
      RequestOptions options, RequestInterceptorHandler handler) async {
    if (!estRouteAuth(options.path) &&
        !options.headers.containsKey('Authorization')) {
      // Jeton expiré côté client (1 h) : on le renouvelle AVANT l'appel
      // plutôt que d'attendre un 401.
      if (!await tokenService.isAuthenticated &&
          await tokenService.aUnRefreshToken) {
        await _rafraichir();
      }
      final token = await tokenService.getToken();
      if (token != null && token.isNotEmpty) {
        options.headers['Authorization'] = 'Bearer $token';
      }
    }
    return handler.next(options);
  }

  @override
  Future<void> onError(DioException e, ErrorInterceptorHandler handler) async {
    final opts = e.requestOptions;
    final dejaRejouee = opts.extra['_rejoueApresRefresh'] == true;
    if (e.response?.statusCode != 401 ||
        estRouteAuth(opts.path) ||
        dejaRejouee) {
      return handler.next(e);
    }

    final jetonUtilise = (opts.headers['Authorization'] as String?)
        ?.replaceFirst('Bearer ', '');
    final jetonActuel = await tokenService.getToken();

    // Un autre appel a déjà renouvelé le jeton pendant que celui-ci était en
    // vol : on rejoue simplement avec le nouveau jeton.
    final dejaRenouvele = jetonActuel != null &&
        jetonActuel.isNotEmpty &&
        jetonActuel != jetonUtilise;
    final ok = dejaRenouvele || await _rafraichir();
    if (!ok) return handler.next(e);

    final nouveauJeton = await tokenService.getToken();
    opts.headers['Authorization'] = 'Bearer $nouveauJeton';
    opts.extra['_rejoueApresRefresh'] = true;
    try {
      final response = await dio.fetch(opts);
      return handler.resolve(response);
    } on DioException catch (retryError) {
      return handler.next(retryError);
    }
  }
}
