import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nanei/core/constants/storage_keys.dart';
import 'package:nanei/core/network/auth_interceptor.dart';
import 'package:nanei/core/services/token_service.dart';

import '../../helpers/dio_espion.dart';
import '../../helpers/environnement.dart';
import '../../helpers/jetons.dart';

/// L'intercepteur d'authentification du Dio partagé, branché exactement
/// comme dans `injection_container.dart` (client de refresh SANS
/// intercepteurs, `AuthInterceptor.refreshVia`).
///
/// ## Ce que ce fichier rend impossible
///
///  - une requête protégée partie SANS `Authorization` (→ 401 « Token
///    manquant ») ou une route `/auth/…` partie AVEC (le login d'un autre
///    compte porterait le jeton du précédent) ;
///  - un 401 qui ne relance pas la requête après renouvellement : l'écran
///    afficherait une erreur alors que la session est encore valide ;
///  - une BOUCLE : requête rejouée, nouveau 401, nouveau refresh… jusqu'au
///    429. Une requête n'est rejouée qu'une fois ;
///  - plusieurs 401 simultanés qui déclencheraient plusieurs refresh (le
///    second, avec un refresh token déjà révoqué par la rotation, déconnecte) ;
///  - un refresh sur un 403 (compte désactivé) — ce n'est pas un jeton expiré.
void main() {
  setUpAll(initialiserEnvironnementDeTest);

  late DioEspion api;
  late DioEspion auth;
  late Dio dio;
  late TokenService jetons;
  late FlutterSecureStorage stockage;

  setUp(() {
    FlutterSecureStorage.setMockInitialValues({});
    stockage = const FlutterSecureStorage();
    jetons = TokenService(secureStorage: stockage);
    api = DioEspion();
    auth = DioEspion();
    dio = dioDeTest(api);
    dio.interceptors.add(AuthInterceptor(
      dio: dio,
      tokenService: jetons,
      refreshCall: AuthInterceptor.refreshVia(dioDeTest(auth)),
    ));
  });

  tearDown(() => jetons.dispose());

  Future<void> session(String jwt, {String rt = 'rt-1'}) async {
    await stockage.write(key: StorageKeys.jwtToken, value: jwt);
    await stockage.write(key: StorageKeys.refreshToken, value: rt);
  }

  String? bearer(RequestOptions r) => r.headers['Authorization'] as String?;

  test('requête protégée : Bearer du jeton courant, aucun refresh', () async {
    final jwt = jwtDeTest();
    await session(jwt);
    api.repond({'data': []});

    await dio.get('/client/colis-envoyes');

    expect(bearer(api.requete), 'Bearer $jwt');
    expect(auth.requetes, isEmpty);
  });

  test('route /auth/ : jamais de jeton', () async {
    await session(jwtDeTest());
    api.repond({'token': 't'});

    await dio.post('/auth/login', data: {'identifiant': 'a', 'mot_de_passe': 'b'});

    expect(bearer(api.requete), isNull);
  });

  test('jeton expiré : renouvelé AVANT l’appel (POST /auth/refresh { refreshToken })',
      () async {
    await session(jwtDeTest(expireDans: const Duration(minutes: -2)));
    final neuf = jwtDeTest();
    auth.repond({'token': neuf, 'refreshToken': 'rt-2'});
    api.repond({'utilisateur': {}});

    await dio.get('/account/me');

    expect(auth.appel, 'POST /auth/refresh');
    expect(corpsEnvoye(auth.requete), {'refreshToken': 'rt-1'});
    expect(bearer(auth.requete), isNull);
    expect(bearer(api.requete), 'Bearer $neuf');
    expect(await jetons.getRefreshToken(), 'rt-2');
  });

  test('401 : refresh puis requête REJOUÉE une fois avec le nouveau jeton',
      () async {
    final ancien = jwtDeTest();
    final neuf = jwtDeTest(id: 'u-1-neuf');
    await session(ancien);
    api.repondErreur(401, corps: {'message': 'Token invalide'});
    api.repond({'data': ['ok']});
    auth.repond({'token': neuf, 'refreshToken': 'rt-2'});

    final r = await dio.get('/client/colis-recus');

    expect(r.data, {'data': ['ok']});
    expect(api.appels, ['GET /client/colis-recus', 'GET /client/colis-recus']);
    expect(bearer(api.requetes.first), 'Bearer $ancien');
    expect(bearer(api.requetes.last), 'Bearer $neuf');
    expect(auth.requetes, hasLength(1));
  });

  test('401 encore après le rejeu : erreur remontée, AUCUNE boucle', () async {
    await session(jwtDeTest());
    api.repondErreur(401, corps: {'message': 'Token invalide'});
    auth.repond({'token': jwtDeTest(id: 'autre'), 'refreshToken': 'rt-2'});

    await expectLater(
      dio.get('/client/colis-recus'),
      throwsA(isA<DioException>()
          .having((e) => e.response?.statusCode, 'statut', 401)),
    );
    expect(api.requetes, hasLength(2));
    expect(auth.requetes, hasLength(1));
  });

  test('refresh refusé (401) : le 401 d’origine remonte, session effacée',
      () async {
    await session(jwtDeTest());
    api.repondErreur(401, corps: {'message': 'Token invalide'});
    auth.repondErreur(401, corps: {'message': 'Refresh token invalide ou révoqué'});

    await expectLater(
      dio.get('/account/me'),
      throwsA(isA<DioException>()
          .having((e) => e.response?.statusCode, 'statut', 401)),
    );
    expect(api.requetes, hasLength(1));
    expect(await jetons.getToken(), isNull);
    expect(await jetons.getRefreshToken(), isNull);
  });

  test('deux 401 simultanés : UN seul refresh, deux rejeux', () async {
    await session(jwtDeTest());
    final neuf = jwtDeTest(id: 'neuf');
    final feuVert = Completer<void>();
    api.repondErreur(401, pour: '/a');
    api.repond({'r': 'a'}, pour: '/a');
    api.repondErreur(401, pour: '/b');
    api.repond({'r': 'b'}, pour: '/b');
    auth.repond({'token': neuf, 'refreshToken': 'rt-2'}, apres: feuVert.future);

    final reponses = Future.wait([dio.get('/a'), dio.get('/b')]);
    await Future<void>.delayed(const Duration(milliseconds: 50));
    feuVert.complete();
    final r = await reponses;

    expect(r.map((x) => x.data), [
      {'r': 'a'},
      {'r': 'b'},
    ]);
    expect(auth.requetes, hasLength(1));
    expect(api.requetes.where((x) => bearer(x) == 'Bearer $neuf'), hasLength(2));
  });

  test('403 (compte désactivé) : pas de refresh, erreur telle quelle', () async {
    await session(jwtDeTest());
    api.repondErreur(403, corps: {'message': 'Compte désactivé. Contactez le support.'});

    await expectLater(
      dio.get('/account/me'),
      throwsA(isA<DioException>()
          .having((e) => e.response?.statusCode, 'statut', 403)),
    );
    expect(auth.requetes, isEmpty);
  });

  test('401 sur /auth/login (mauvais identifiants) : pas de refresh', () async {
    await session(jwtDeTest());
    api.repondErreur(401, corps: {'message': 'Identifiants incorrects'});

    await expectLater(dio.post('/auth/login'), throwsA(isA<DioException>()));
    expect(auth.requetes, isEmpty);
  });

  test('estRouteAuth ignore la query string', () {
    expect(AuthInterceptor.estRouteAuth('/auth/refresh'), isTrue);
    expect(AuthInterceptor.estRouteAuth('https://h/nanei/auth/oublier-password'), isTrue);
    expect(AuthInterceptor.estRouteAuth('/client/colis?x=/auth/'), isFalse);
  });
}
