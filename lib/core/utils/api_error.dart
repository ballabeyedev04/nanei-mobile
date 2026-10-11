import 'package:dio/dio.dart';

/// Message lisible pour l'utilisateur à partir d'une erreur d'appel API.
///
/// Le back n'a pas d'enveloppe d'erreur unique : selon la route, le texte est
/// dans `message` (cas général), dans `details` (validation Joi : liste de
/// messages précis) ou dans `error` (gestionnaire d'erreurs global).
String messageErreurApi(
  Object erreur, {
  String fallback = 'Une erreur est survenue. Veuillez réessayer.',
}) {
  if (erreur is DioException) {
    final data = erreur.response?.data;
    if (data is Map) {
      final details = data['details'];
      if (details is List && details.isNotEmpty) {
        return details.map((d) => d.toString()).join('\n');
      }
      final message = data['message'] ?? data['error'];
      if (message is String && message.trim().isNotEmpty) return message;
    }
    switch (erreur.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
        return 'Connexion trop lente. Vérifiez votre réseau.';
      case DioExceptionType.receiveTimeout:
        return 'Le serveur met du temps à répondre. Réessayez dans quelques secondes.';
      case DioExceptionType.connectionError:
        return 'Impossible de joindre le serveur. Vérifiez votre connexion internet.';
      default:
        break;
    }
    final status = erreur.response?.statusCode;
    if (status == 429) return 'Trop de tentatives. Réessayez dans quelques minutes.';
  }
  return fallback;
}
