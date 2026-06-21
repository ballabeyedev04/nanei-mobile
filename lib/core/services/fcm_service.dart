import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:nanei/core/config/env.dart';
import 'package:nanei/core/services/token_service.dart';
import 'package:nanei/core/utils/app_logger.dart';
import 'package:nanei/injection_container.dart';
import 'package:dio/dio.dart';

/// Service Firebase Cloud Messaging.
/// Nécessite google-services.json (Android) et GoogleService-Info.plist (iOS)
/// disponibles sur Firebase Console.
class FcmService {
  FcmService._();

  static Future<void> init() async {
    final messaging = FirebaseMessaging.instance;

    // Demander les permissions (iOS + Android 13+)
    final settings = await messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    AppLogger.debug('[FCM] Permission: ${settings.authorizationStatus}');

    // Récupérer le token FCM et l'envoyer au backend
    final token = await messaging.getToken();
    if (token != null) {
      await _envoyerTokenAuBackend(token);
    }

    // Écouter les messages en foreground
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      AppLogger.info('Notification FCM reçue', {'titre': message.notification?.title});
      // La notification in-app est gérée via toastification si besoin
    });

    // Écouter le refresh du token
    messaging.onTokenRefresh.listen(_envoyerTokenAuBackend);
  }

  static Future<void> _envoyerTokenAuBackend(String token) async {
    try {
      final tokenService = sl<TokenService>();
      final jwt = await tokenService.getToken();
      if (jwt == null || jwt.isEmpty) return;

      await sl<Dio>().post(
        Env.accountFcmToken,
        data: {'fcm_token': token},
        options: Options(headers: {'Authorization': 'Bearer $jwt'}),
      );

      AppLogger.debug('[FCM] Token envoyé au backend.');
    } catch (e) {
      AppLogger.error('[FCM] Erreur envoi token au backend', e);
    }
  }
}
