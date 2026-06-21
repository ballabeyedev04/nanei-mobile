import 'package:flutter/foundation.dart';
import 'package:talker_flutter/talker_flutter.dart';

/// Champs à masquer dans les logs
const _sensitiveKeys = ['password', 'token', 'access_token', 'refresh_token',
  'fcm_token', 'authorization', 'secret', 'otp', 'pin', 'card_number'];

/// Masque les données sensibles dans un Map
Map<String, dynamic> sanitize(Map<String, dynamic> data) {
  return data.map((key, value) {
    final k = key.toLowerCase();
    if (_sensitiveKeys.any((s) => k.contains(s))) {
      return MapEntry(key, '[REDACTED]');
    }
    if (value is Map<String, dynamic>) return MapEntry(key, sanitize(value));
    return MapEntry(key, value);
  });
}

/// Masque un email : ba***@gmail.com
String maskEmail(String email) {
  final parts = email.split('@');
  if (parts.length != 2) return email;
  final local = parts[0];
  final visible = local.length > 3 ? local.substring(0, 3) : local.substring(0, 1);
  return '$visible***@${parts[1]}';
}

/// Masque un téléphone : +221 7****89
String maskPhone(String phone) {
  if (phone.length < 4) return '****';
  return '${phone.substring(0, 4)}****${phone.substring(phone.length - 2)}';
}

class AppLogger {
  static late Talker _talker;
  static bool _initialized = false;

  static Talker get instance {
    assert(_initialized, 'AppLogger.init() must be called first');
    return _talker;
  }

  static Future<void> init() async {
    _talker = TalkerFlutter.init(
      settings: TalkerSettings(
        // En release : on désactive les logs console, mais on garde l'historique pour erreurs
        enabled: true,
        useConsoleLogs: kDebugMode,
      ),
      logger: TalkerLogger(
        settings: TalkerLoggerSettings(
          enableColors: kDebugMode,
        ),
      ),
    );
    _initialized = true;

    if (kDebugMode) {
      _talker.info('AppLogger initialisé [DEBUG mode]');
    }
  }

  // ── Raccourcis ────────────────────────────────────────────────────

  static void debug(String msg, [Object? meta]) {
    if (kReleaseMode) return; // Jamais en production
    _talker.debug('$msg${meta != null ? ' | $meta' : ''}');
  }

  static void info(String msg, [Object? meta]) {
    _talker.info('$msg${meta != null ? ' | ${_safeMeta(meta)}' : ''}');
  }

  static void warning(String msg, [Object? meta]) {
    _talker.warning('$msg${meta != null ? ' | ${_safeMeta(meta)}' : ''}');
  }

  static void error(String msg, [Object? error, StackTrace? stackTrace]) {
    _talker.error(msg, error, stackTrace);
  }

  static void critical(String msg, [Object? error, StackTrace? stackTrace]) {
    _talker.critical(msg, error, stackTrace);
  }

  // ── Logs métier spécifiques ────────────────────────────────────────

  static void authEvent(String event, {String? userId, String? email}) {
    info('Auth: $event', {
      if (userId != null) 'user_id': userId,
      if (email != null) 'email': maskEmail(email),
    });
  }

  static void colisEvent(String event, {String? colisId, String? statut, String? reference}) {
    info('Colis: $event', {
      if (colisId != null) 'colis_id': colisId,
      if (statut != null) 'statut': statut,
      if (reference != null) 'reference': reference,
    });
  }

  static void paiementEvent(String event, {String? paiementId, String? type, double? montant}) {
    info('Paiement: $event', {
      if (paiementId != null) 'paiement_id': paiementId,
      if (type != null) 'type': type,
      if (montant != null) 'montant': montant,
    });
  }

  static void apiError(String endpoint, int? statusCode, String message) {
    warning('API Error: $endpoint', {
      'status': statusCode,
      'message': message,
    });
  }

  static void navigationEvent(String route) {
    debug('Navigation → $route');
  }

  // ── Interne ────────────────────────────────────────────────────────

  static String _safeMeta(Object? meta) {
    if (meta is Map<String, dynamic>) return sanitize(meta).toString();
    return meta.toString();
  }
}
