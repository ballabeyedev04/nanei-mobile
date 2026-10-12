import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nanei/core/utils/api_error.dart';
import 'package:nanei/core/utils/media_type.dart';

/// Traduction d'une erreur d'appel API en message lisible.
///
/// ## Ce que ce fichier rend impossible
///
/// Le back n'a pas d'enveloppe d'erreur unique : `message` (cas général),
/// `details` (validation Joi : `{ message: 'Données invalides', details: [...] }`),
/// `error` (gestionnaire global). Sans cette traduction, l'utilisateur lit
/// « Données invalides » sans savoir QUEL champ corriger, ou pire un
/// `DioException [bad response]: …` brut.
void main() {
  DioException reponse(int statut, Object? corps,
          {DioExceptionType type = DioExceptionType.badResponse}) =>
      DioException(
        requestOptions: RequestOptions(path: '/x'),
        response: Response(
            requestOptions: RequestOptions(path: '/x'),
            statusCode: statut,
            data: corps),
        type: type,
      );

  test('400 Joi : chaque détail, une ligne chacun', () {
    expect(
      messageErreurApi(reponse(400, {
        'message': 'Données invalides',
        'details': [
          '"email" doit être un email valide',
          '"mot_de_passe" doit contenir au moins 8 caractères',
        ],
      })),
      '"email" doit être un email valide\n'
      '"mot_de_passe" doit contenir au moins 8 caractères',
    );
  });

  test('message du back pour 400 / 401 / 403 / 404 / 409 / 429', () {
    final cas = {
      400: 'Recepteur non trouvé',
      401: 'Session expirée suite à un changement de mot de passe. Veuillez vous reconnecter.',
      403: 'Compte désactivé. Contactez le support.',
      404: 'Colis introuvable',
      409: 'Un avis existe déjà pour ce colis',
      429: 'Trop de requêtes. Veuillez réessayer dans quelques minutes.',
    };
    cas.forEach((statut, message) {
      expect(messageErreurApi(reponse(statut, {'success': false, 'message': message})),
          message,
          reason: '$statut');
    });
  });

  test('`error` à défaut de `message`', () {
    expect(messageErreurApi(reponse(400, {'error': 'Type de fichier non autorisé'})),
        'Type de fichier non autorisé');
  });

  test('429 sans corps : message dédié', () {
    expect(messageErreurApi(reponse(429, null)),
        'Trop de tentatives. Réessayez dans quelques minutes.');
  });

  test('page HTML d’un proxy (502) : repli, sans planter', () {
    expect(
        messageErreurApi(reponse(502, '<html><body>Bad Gateway</body></html>'),
            fallback: 'Réessayez.'),
        'Réessayez.');
  });

  test('pannes réseau : messages distincts', () {
    DioException panne(DioExceptionType t) =>
        DioException(requestOptions: RequestOptions(path: '/x'), type: t);
    expect(messageErreurApi(panne(DioExceptionType.connectionError)),
        contains('Impossible de joindre le serveur'));
    expect(messageErreurApi(panne(DioExceptionType.connectionTimeout)),
        contains('Connexion trop lente'));
    expect(messageErreurApi(panne(DioExceptionType.receiveTimeout)),
        contains('met du temps à répondre'));
  });

  test('erreur non Dio : repli', () {
    expect(messageErreurApi(StateError('x'), fallback: 'Oups'), 'Oups');
  });

  group('mediaTypeImage (photos multipart)', () {
    test('type MIME déduit de l’extension, JPEG par défaut', () {
      expect(mediaTypeImage('/tmp/a.png').toString(), 'image/png');
      expect(mediaTypeImage('/tmp/a.WEBP').toString(), 'image/webp');
      expect(mediaTypeImage('/tmp/a.jpg').toString(), 'image/jpeg');
      expect(mediaTypeImage('/tmp/sans_extension').toString(), 'image/jpeg');
    });
  });
}
