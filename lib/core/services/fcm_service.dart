import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:nanei/core/config/env.dart';
import 'package:nanei/core/constants/storage_keys.dart';
import 'package:nanei/core/services/token_service.dart';
import 'package:nanei/core/utils/app_logger.dart';
import 'package:nanei/injection_container.dart';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FcmService {
  FcmService._();

  static Future<void> init() async {
    final messaging = FirebaseMessaging.instance;

    final settings = await messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    AppLogger.debug('[FCM] Permission: ${settings.authorizationStatus}');

    // Retenter l'envoi d'un token pending du démarrage précédent
    await _retrySendPendingToken();

    final token = await messaging.getToken();
    if (token != null) {
      await _envoyerTokenAuBackend(token);
    }

    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      AppLogger.info('Notification FCM reçue', {'titre': message.notification?.title});
    });

    messaging.onTokenRefresh.listen(_envoyerTokenAuBackend);
  }

  static Future<void> _retrySendPendingToken() async {
    final prefs = await SharedPreferences.getInstance();
    final pending = prefs.getString(StorageKeys.fcmTokenPending);
    if (pending != null) {
      final success = await _envoyerTokenAuBackend(pending);
      if (success) await prefs.remove(StorageKeys.fcmTokenPending);
    }
  }

  static Future<bool> _envoyerTokenAuBackend(String token) async {
    try {
      final tokenService = sl<TokenService>();
      final jwt = await tokenService.getToken();
      if (jwt == null || jwt.isEmpty) return false;

      await sl<Dio>().post(
        Env.accountFcmToken,
        data: {'fcm_token': token},
        options: Options(headers: {'Authorization': 'Bearer $jwt'}),
      );

      AppLogger.debug('[FCM] Token envoyé au backend.');
      return true;
    } catch (e) {
      AppLogger.error('[FCM] Erreur envoi token — sera réessayé au prochain démarrage', e);
      // Sauvegarder pour retry au prochain démarrage
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(StorageKeys.fcmTokenPending, token);
      return false;
    }
  }
}
