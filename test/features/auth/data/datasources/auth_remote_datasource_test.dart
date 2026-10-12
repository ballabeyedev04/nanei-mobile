import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nanei/core/utils/api_error.dart';
import 'package:nanei/features/auth/data/datasources/auth_remote_datasource.dart';

import '../../../../helpers/dio_espion.dart';
import '../../../../helpers/environnement.dart';

/// L'API d'authentification (`POST /auth/login`, `POST /auth/register`).
///
/// ## Ce que ce fichier rend impossible
///
///  - un champ que `validate(loginSchema)` ne connaît pas : Joi applique
///    `stripUnknown`, un `password` au lieu de `mot_de_passe` serait
///    silencieusement RETIRÉ et le back répondrait « Données invalides » ;
///  - un refresh token non relu : sans lui, la session meurt au bout d'1 h ;
///  - l'utilisateur relu ailleurs que sous `utilisateur` (`formatUser`) ;
///  - un refus (400 identifiants, 400 Joi avec `details`, 429) dont le
///    message n'arriverait pas à l'écran de connexion.
void main() {
  setUpAll(initialiserEnvironnementDeTest);

  late DioEspion espion;
  late AuthRemoteDataSourceImpl source;

  setUp(() {
    espion = DioEspion();
    source = AuthRemoteDataSourceImpl(dio: dioDeTest(espion));
  });

  /// `formatUser()` du back.
  const utilisateur = {
    'id': 'u-1',
    'nom': 'Beye',
    'prenom': 'Balla',
    'email': 'balla@exemple.fr',
    'adresse': 'Paris',
    'telephone': '+33600000000',
    'role': 'Particulier',
    'statut': 'actif',
    'photoProfil': null,
  };

  group('POST /auth/login', () {
    test('identifiant + mot_de_passe ; relit jeton, refresh token et profil',
        () async {
      espion.repond({
        'token': 'jwt-acces',
        'refreshToken': 'jwt-refresh',
        'utilisateur': utilisateur,
      });

      final r = await source.login('balla@exemple.fr', 'Secret123');

      expect(espion.appel, 'POST /auth/login');
      expect(corpsEnvoye(espion.requete),
          {'identifiant': 'balla@exemple.fr', 'mot_de_passe': 'Secret123'});
      expect(r.token, 'jwt-acces');
      expect(r.refreshToken, 'jwt-refresh');
      expect(r.user.id, 'u-1');
      expect(r.user.prenom, 'Balla');
      expect(r.user.telephone, '+33600000000');
      // Le mot de passe ne revient jamais du back : chaîne vide.
      expect(r.user.mot_de_passe, '');
      // Aucune route /auth/ ne porte de jeton.
      expect(espion.requete.headers.containsKey('Authorization'), isFalse);
    });

    test('400 identifiants incorrects : message du back', () async {
      espion.repondErreur(400, corps: {'message': 'Identifiants incorrects'});
      try {
        await source.login('x', 'y');
        fail('DioException attendue');
      } on DioException catch (e) {
        expect(messageErreurApi(e), 'Identifiants incorrects');
      }
    });

    test('400 Joi : les `details` sont préférés au « Données invalides »',
        () async {
      espion.repondErreur(400, corps: {
        'message': 'Données invalides',
        'details': ['"identifiant" is not allowed to be empty'],
      });
      try {
        await source.login('', 'y');
        fail('DioException attendue');
      } on DioException catch (e) {
        expect(messageErreurApi(e), '"identifiant" is not allowed to be empty');
      }
    });

    test('429 de authRateLimit : message du back', () async {
      espion.repondErreur(429, corps: {
        'message': 'Trop de tentatives. Veuillez réessayer dans 15 minutes.',
      });
      try {
        await source.login('x', 'y');
        fail('DioException attendue');
      } on DioException catch (e) {
        expect(e.response?.statusCode, 429);
        expect(messageErreurApi(e),
            'Trop de tentatives. Veuillez réessayer dans 15 minutes.');
      }
    });
  });

  group('POST /auth/register', () {
    test('noms de champs du registerSchema ; 201 sans jeton', () async {
      espion.repond({
        'message': 'Inscription réussie',
        'utilisateur': utilisateur,
      }, statut: 201);

      final r = await source.register(
        nom: 'Beye',
        prenom: 'Balla',
        email: 'balla@exemple.fr',
        mot_de_passe: 'Secret123',
        adresse: '',
        telephone: '+33600000000',
      );

      expect(espion.appel, 'POST /auth/register');
      expect(corpsEnvoye(espion.requete), {
        'nom': 'Beye',
        'prenom': 'Balla',
        'email': 'balla@exemple.fr',
        'mot_de_passe': 'Secret123',
        'adresse': '',
        'telephone': '+33600000000',
      });
      // Par conception, l'inscription ne connecte pas.
      expect(r.token, isEmpty);
      expect(r.refreshToken, isEmpty);
      expect(r.user.email, 'balla@exemple.fr');
    });

    test('400 « Cet email est déjà utilisé » : message conservé', () async {
      espion.repondErreur(400, corps: {'message': 'Cet email est déjà utilisé'});
      try {
        await source.register(
          nom: 'B',
          prenom: 'B',
          email: 'pris@exemple.fr',
          mot_de_passe: 'Secret123',
          adresse: '',
          telephone: '',
        );
        fail('DioException attendue');
      } on DioException catch (e) {
        expect(messageErreurApi(e), 'Cet email est déjà utilisé');
      }
    });
  });
}
