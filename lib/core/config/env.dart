import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Résolution 3-niveaux : dart-define → .env → fallback
class Env {
  Env._();

  static String _get(String key, String fallback) {
    // 1. Compile-time dart-define (production)
    final defined = const String.fromEnvironment('');
    if (defined.isNotEmpty) return defined;

    // 2. .env fichier (développement)
    final fromEnv = dotenv.maybeGet(key)?.trim();
    if (fromEnv != null && fromEnv.isNotEmpty) return fromEnv;

    // 3. Fallback codé en dur
    if (kDebugMode) {
      debugPrint('[Env] $key non défini → fallback utilisé');
    }
    return fallback;
  }

  // ── Base ──────────────────────────────────────────────────────────────────
  static String get baseUrl =>
      _get('API_BASE_URL', 'http://10.0.2.2:3000');

  // ── Auth ──────────────────────────────────────────────────────────────────
  static String get authLogin    => _get('AUTH_LOGIN_PATH',    '/auth/login');
  static String get authRegister => _get('AUTH_REGISTER_PATH', '/auth/register');
  static String get authRefresh  => _get('AUTH_REFRESH_PATH',  '/auth/refresh');
  static String get authLogout   => _get('AUTH_LOGOUT_PATH',   '/auth/logout');

  // ── Colis ─────────────────────────────────────────────────────────────────
  static String get colisEnvoyer        => '/client/envoie-colis';
  static String get colisEnvoyes        => '/client/colis-envoyes';
  static String get colisRecus          => '/client/colis-recus';
  static String get colisStatistiques   => '/client/statistiques-colis';
  static String get colisNbEnvoyes      => '/client/nombre-coli-envoyer';
  static String get colisNbRecus        => '/client/nombre-coli-recu';

  // ── Client ────────────────────────────────────────────────────────────────
  static String get clientRechercher => '/client/rechercher-client';

  // ── Notifications ─────────────────────────────────────────────────────────
  static String get notificationsMes  => '/client/mes-notifications';
  static String notificationLire(String id) => '/client/lire-notifications/$id';

  // ── Account ───────────────────────────────────────────────────────────────
  static String get accountMe            => '/account/me';
  static String get accountModifierProfil => '/account/modifier-profil';
  static String get accountChangePassword => '/account/change-password';

  // ── Support ───────────────────────────────────────────────────────────────
  static String get messagesEnvoyer => '/messages';
}
