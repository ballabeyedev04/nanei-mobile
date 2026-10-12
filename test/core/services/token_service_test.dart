import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nanei/core/constants/storage_keys.dart';
import 'package:nanei/core/services/token_service.dart';

import '../../helpers/jetons.dart';

/// Le gardien des jetons : JWT d'accès (1 h) et refresh token (7 j, ROTATIF).
///
/// ## Ce que ce fichier rend impossible
///
///  - deux `POST /auth/refresh` simultanés : le back révoque l'ancien refresh
///    token dès le premier ; le second, rejouant le même, est refusé
///    (« révoqué ») et DÉCONNECTE l'utilisateur. Le refresh doit être
///    mutualisé ;
///  - garder l'ancien refresh token après une rotation (même effet, au
///    renouvellement suivant) ;
///  - effacer la session sur une simple coupure réseau ou un 500 : seuls un
///    400 ou un 401 du serveur prouvent que le refresh token est mort ;
///  - croire valide un jeton expiré (ou illisible).
void main() {
  late FlutterSecureStorage stockage;
  late TokenService service;

  setUp(() {
    FlutterSecureStorage.setMockInitialValues({});
    stockage = const FlutterSecureStorage();
    service = TokenService(secureStorage: stockage);
  });

  tearDown(() => service.dispose());

  Future<void> session({required String jwt, String? rt = 'rt-ancien'}) async {
    await stockage.write(key: StorageKeys.jwtToken, value: jwt);
    if (rt != null) await stockage.write(key: StorageKeys.refreshToken, value: rt);
  }

  DioException refus(int statut) => DioException(
        requestOptions: RequestOptions(path: '/auth/refresh'),
        response: Response(
          requestOptions: RequestOptions(path: '/auth/refresh'),
          statusCode: statut,
          data: {'message': 'Refresh token invalide ou révoqué'},
        ),
        type: DioExceptionType.badResponse,
      );

  group('validité du jeton', () {
    test('aucun jeton : non authentifié', () async {
      expect(await service.isAuthenticated, isFalse);
      expect(await service.getValidToken(), isNull);
    });

    test('jeton valide : authentifié', () async {
      final jwt = jwtDeTest();
      await session(jwt: jwt);
      expect(await service.isAuthenticated, isTrue);
      expect(await service.getValidToken(), jwt);
    });

    test('jeton expiré (ou à moins de 30 s de l’être) : non authentifié', () async {
      await session(jwt: jwtDeTest(expireDans: const Duration(seconds: 10)));
      expect(await service.isAuthenticated, isFalse);
    });

    test('getValidToken sur jeton expiré : efface la session', () async {
      await session(jwt: jwtDeTest(expireDans: const Duration(minutes: -5)));
      expect(await service.getValidToken(), isNull);
      expect(await stockage.read(key: StorageKeys.jwtToken), isNull);
      expect(await stockage.read(key: StorageKeys.refreshToken), isNull);
    });

    test('jeton illisible : considéré expiré', () async {
      await session(jwt: 'pas-un-jwt');
      expect(await service.isAuthenticated, isFalse);
    });

    test('setToken publie l’état sur authChanges', () async {
      final etats = <bool>[];
      final abo = service.authChanges.listen(etats.add);
      await service.setToken(jwtDeTest());
      await service.setToken(null);
      await Future<void>.delayed(Duration.zero);
      expect(etats, [true, false]);
      await abo.cancel();
    });
  });

  group('tryRefresh', () {
    test('rotation : le NOUVEAU refresh token remplace l’ancien', () async {
      await session(jwt: jwtDeTest(expireDans: const Duration(minutes: -1)));
      final nouveau = jwtDeTest();
      String? envoye;

      final ok = await service.tryRefresh((rt) async {
        envoye = rt;
        return {'token': nouveau, 'refreshToken': 'rt-nouveau'};
      });

      expect(ok, isTrue);
      expect(envoye, 'rt-ancien');
      expect(await service.getToken(), nouveau);
      expect(await service.getRefreshToken(), 'rt-nouveau');
      expect(await service.isAuthenticated, isTrue);
    });

    test('MUTUALISÉ : trois 401 simultanés → un seul POST /auth/refresh',
        () async {
      await session(jwt: jwtDeTest(expireDans: const Duration(minutes: -1)));
      final reponse = Completer<Map<String, dynamic>?>();
      var appels = 0;
      Future<Map<String, dynamic>?> refresh(String rt) {
        appels++;
        return reponse.future;
      }

      final resultats = Future.wait([
        service.tryRefresh(refresh),
        service.tryRefresh(refresh),
        service.tryRefresh(refresh),
      ]);
      await Future<void>.delayed(Duration.zero);
      reponse.complete({'token': jwtDeTest(), 'refreshToken': 'rt-nouveau'});

      expect(await resultats, [true, true, true]);
      expect(appels, 1);

      // Une fois terminé, un refresh ULTÉRIEUR repart bien (pas de verrou
      // resté coincé).
      await service.tryRefresh((rt) async {
        appels++;
        expect(rt, 'rt-nouveau');
        return {'token': jwtDeTest(), 'refreshToken': 'rt-3'};
      });
      expect(appels, 2);
    });

    for (final statut in [400, 401]) {
      test('$statut du serveur : session effacée et sessionExpiree émis',
          () async {
        await session(jwt: jwtDeTest(expireDans: const Duration(minutes: -1)));
        var expiree = false;
        final abo = service.sessionExpiree.listen((_) => expiree = true);

        final ok = await service.tryRefresh((_) async => throw refus(statut));
        await Future<void>.delayed(Duration.zero);

        expect(ok, isFalse);
        expect(expiree, isTrue);
        expect(await service.getToken(), isNull);
        expect(await service.getRefreshToken(), isNull);
        await abo.cancel();
      });
    }

    for (final cas in <String, Object Function()>{
      'coupure réseau': () => DioException.connectionError(
          requestOptions: RequestOptions(path: '/auth/refresh'), reason: 'off'),
      '500': () => refus(500),
      '429': () => refus(429),
      'erreur inattendue': () => StateError('boom'),
    }.entries) {
      test('${cas.key} : la session est CONSERVÉE', () async {
        await session(jwt: 'jwt-courant');
        final ok = await service.tryRefresh((_) async => throw cas.value());
        expect(ok, isFalse);
        expect(await service.getToken(), 'jwt-courant');
        expect(await service.getRefreshToken(), 'rt-ancien');
      });
    }

    test('sans refresh token : aucun appel', () async {
      await session(jwt: jwtDeTest(), rt: null);
      var appele = false;
      final ok = await service.tryRefresh((_) async {
        appele = true;
        return null;
      });
      expect(ok, isFalse);
      expect(appele, isFalse);
      expect(await service.aUnRefreshToken, isFalse);
    });

    test('réponse sans `token` : échec, rien n’est écrasé', () async {
      await session(jwt: 'jwt-courant');
      final ok = await service.tryRefresh((_) async => {'refreshToken': 'rt-x'});
      expect(ok, isFalse);
      expect(await service.getToken(), 'jwt-courant');
      expect(await service.getRefreshToken(), 'rt-ancien');
    });
  });
}
