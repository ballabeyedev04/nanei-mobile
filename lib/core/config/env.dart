import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:nanei/core/utils/app_logger.dart';

/// Résolution 3-niveaux : dart-define → .env → fallback
class Env {
  Env._();

  static String _get(String key, String fallback) {
    // 1. Compile-time dart-define (production)
    final defined = String.fromEnvironment(key);
    if (defined.isNotEmpty) return defined;

    // 2. .env fichier (développement)
    final fromEnv = dotenv.maybeGet(key)?.trim();
    if (fromEnv != null && fromEnv.isNotEmpty) return fromEnv;

    // 3. Fallback codé en dur
    AppLogger.debug('[Env] $key non défini → fallback utilisé');
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
  static String get colisEnvoyerLot     => '/client/envoie-colis-lot';
  static String get colisEnvoyes        => '/client/colis-envoyes';
  static String get colisRecus          => '/client/colis-recus';
  static String colisRecherche(String reference) => '/client/colis-recherche/$reference';
  static String get colisStatistiques   => '/client/statistiques-colis';
  static String get colisNbEnvoyes      => '/client/nombre-coli-envoyer';
  static String get colisNbRecus        => '/client/nombre-coli-recu';

  // ── Client ────────────────────────────────────────────────────────────────
  static String get clientRechercher => '/client/rechercher-client';
  static String get clientCountries  => '/client/countries';
  static String clientPricing(String countryId) => '/client/pricing/$countryId';

  // ── Notifications ─────────────────────────────────────────────────────────
  static String get notificationsMes  => '/client/mes-notifications';
  static String notificationLire(String id) => '/client/lire-notifications/$id';

  // ── Account ───────────────────────────────────────────────────────────────
  static String get accountMe            => '/account/me';
  static String get accountModifierProfil => '/account/modifier-profil';
  static String get accountChangePassword => '/account/change-password';

  // ── Support ───────────────────────────────────────────────────────────────
  static String get messagesEnvoyer => '/messages';

  // ── FCM ───────────────────────────────────────────────────────────────────
  // NB : baseUrl (API_BASE_URL) inclut déjà le préfixe /nanei en production
  // (ex: https://api.app-nanei.com/nanei) — ne jamais le répéter ici, sinon
  // les requêtes partent en /nanei/nanei/... et le backend renvoie 404.
  static String get accountFcmToken => '/account/fcm-token';

  // ── Contacts ─────────────────────────────────────────────────────────────
  static String get contacts                    => '/contacts';
  static String contactById(String id)          => '/contacts/$id';

  // ── Réclamations ─────────────────────────────────────────────────────────
  static String get reclamations                => '/reclamations';
  static String reclamationById(String id)      => '/reclamations/$id';

  // ── Avis ──────────────────────────────────────────────────────────────────
  static String get avis                        => '/avis';

  // ── Preuve de livraison ───────────────────────────────────────────────────
  static String preuveLivraison(String colisId) => '/colis/$colisId/preuve';

  // ── Étiquette colis ───────────────────────────────────────────────────────
  static String etiquetteColis(String colisId) => '/etiquettes/$colisId';

  // ── Compte ───────────────────────────────────────────────────────────────
  static String get accountDelete               => '/account';

  // ── Reset Password ────────────────────────────────────────────────────────
  static String resetPassword(String token)     => '/auth/reset-password/$token';

  // ── Suivi public ─────────────────────────────────────────────────────────
  static String suiviPublic(String reference)   => '$baseUrl/suivi/$reference';

  // ── Paiements ─────────────────────────────────────────────────────────────
  static String get paiements                       => '/paiements';
  static String paiementInitier(String colisId)     => '/paiements/$colisId/initier';
}
