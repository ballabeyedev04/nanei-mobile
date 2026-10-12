import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nanei/core/constants/storage_keys.dart';
import 'package:nanei/core/services/token_service.dart';
import 'package:nanei/features/auth/data/datasources/auth_remote_datasource.dart';
import 'package:nanei/features/auth/data/repositories/auth_repository_impl.dart';

import '../../../../helpers/dio_espion.dart';
import '../../../../helpers/environnement.dart';

/// Dépôt d'authentification : ce que la connexion ÉCRIT sur le téléphone.
///
/// ## Ce que ce fichier rend impossible
///
///  - une connexion réussie qui n'enregistre pas le REFRESH token : la
///    session meurt au bout d'une heure, l'utilisateur doit se reconnecter ;
///  - l'identifiant utilisateur non mémorisé (`user_id`) : l'écran de suivi
///    ne sait plus distinguer colis envoyés et reçus ;
///  - une inscription qui écrase la session courante avec un jeton vide ;
///  - un refus de connexion affiché « Erreur serveur (400) » au lieu du
///    message du back, ou les `details` Joi ignorés.
void main() {
  setUpAll(initialiserEnvironnementDeTest);

  late DioEspion espion;
  late AuthRepositoryImpl depot;
  late FlutterSecureStorage stockage;
  late TokenService jetons;

  setUp(() async {
    await viderSl();
    FlutterSecureStorage.setMockInitialValues({});
    stockage = const FlutterSecureStorage();
    jetons = TokenService(secureStorage: stockage);
    remplacerDansSl<FlutterSecureStorage>(stockage);
    remplacerDansSl<TokenService>(jetons);
    espion = DioEspion();
    depot = AuthRepositoryImpl(
        remoteDataSource: AuthRemoteDataSourceImpl(dio: dioDeTest(espion)));
  });

  tearDown(viderSl);

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

  test('connexion : jeton, refresh token et user_id enregistrés', () async {
    espion.repond({
      'token': 'jwt-acces',
      'refreshToken': 'jwt-refresh',
      'utilisateur': utilisateur,
    });

    final r = await depot.login('balla@exemple.fr', 'Secret123');

    expect(r.isRight(), isTrue);
    expect(await stockage.read(key: StorageKeys.jwtToken), 'jwt-acces');
    expect(await stockage.read(key: StorageKeys.refreshToken), 'jwt-refresh');
    expect(await stockage.read(key: StorageKeys.userId), 'u-1');
  });

  test('connexion refusée : message du back, rien n’est écrit', () async {
    espion.repondErreur(400, corps: {'message': 'Identifiants incorrects'});

    final r = await depot.login('x', 'y');

    expect(r.fold((f) => f.errorMessage, (_) => ''), 'Identifiants incorrects');
    expect(await stockage.read(key: StorageKeys.jwtToken), isNull);
  });

  test('400 Joi : les details plutôt que « Données invalides »', () async {
    espion.repondErreur(400, corps: {
      'message': 'Données invalides',
      'details': ['"identifiant" is not allowed to be empty', '"mot_de_passe" is required'],
    });
    final r = await depot.login('', '');
    expect(r.fold((f) => f.errorMessage, (_) => ''),
        '"identifiant" is not allowed to be empty\n"mot_de_passe" is required');
  });

  test('429 : message de la limite de débit', () async {
    espion.repondErreur(429, corps: {
      'message': 'Trop de tentatives. Veuillez réessayer dans 15 minutes.',
    });
    final r = await depot.login('x', 'y');
    expect(r.fold((f) => f.errorMessage, (_) => ''),
        'Trop de tentatives. Veuillez réessayer dans 15 minutes.');
  });

  test('coupure réseau : message de connexion', () async {
    espion.coupeReseau();
    final r = await depot.login('x', 'y');
    expect(r.fold((f) => f.errorMessage, (_) => ''),
        contains('Impossible de joindre le serveur'));
  });

  test('inscription (201 sans jeton) : la session existante n’est pas touchée',
      () async {
    await stockage.write(key: StorageKeys.jwtToken, value: 'session-existante');
    espion.repond({'message': 'Inscription réussie', 'utilisateur': utilisateur},
        statut: 201);

    final r = await depot.register(
      nom: 'Beye',
      prenom: 'Balla',
      email: 'balla@exemple.fr',
      mot_de_passe: 'Secret123',
      adresse: '',
      telephone: '',
    );

    expect(r.fold((_) => null, (u) => u.email), 'balla@exemple.fr');
    expect(await stockage.read(key: StorageKeys.jwtToken), 'session-existante');
  });
}
