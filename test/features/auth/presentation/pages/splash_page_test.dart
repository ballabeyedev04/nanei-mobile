import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nanei/core/constants/storage_keys.dart';
import 'package:nanei/core/routes/app_router.dart';
import 'package:nanei/core/services/token_service.dart';
import 'package:nanei/features/auth/domain/entities/user.dart';
import 'package:nanei/features/auth/presentation/pages/splash_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../helpers/dio_espion.dart';
import '../../../../helpers/environnement.dart';
import '../../../../helpers/jetons.dart';
import '../../../../helpers/pompe_page.dart';

/// Écran de démarrage — `GET /account/me` en appel `sl<Dio>()` direct.
///
/// ## Ce que ce fichier rend impossible
///
///  - un utilisateur relu ailleurs que sous `utilisateur` (`formatUser`) :
///    l'accueil s'ouvrirait sans identité ;
///  - une session REFUSÉE par le serveur (403 compte désactivé, 404 compte
///    supprimé, 401) qui ouvrirait quand même l'accueil, jetons conservés ;
///  - une simple panne réseau qui DÉCONNECTERAIT l'utilisateur ;
///  - un appel à `/account/me` sans aucune session locale.
void main() {
  late DioEspion espion;
  late FlutterSecureStorage stockage;

  setUpAll(initialiserEnvironnementDeTest);

  Future<void> preparer({Map<String, String>? jetons}) async {
    await viderSl();
    SharedPreferences.setMockInitialValues({StorageKeys.onboardingDone: true});
    FlutterSecureStorage.setMockInitialValues(jetons ??
        {StorageKeys.jwtToken: jwtDeTest(), StorageKeys.refreshToken: 'rt-1'});
    stockage = const FlutterSecureStorage();
    espion = DioEspion();
    enregistrerDio(dioDeTest(espion));
    remplacerDansSl<TokenService>(TokenService(secureStorage: stockage));
  }

  tearDown(viderSl);

  Future<List<RouteSettings>> demarrer(WidgetTester tester) async {
    final routes = <RouteSettings>[];
    await pomperPage(
      tester,
      const SplashPage(),
      onGenerateRoute: (s) {
        routes.add(s);
        return MaterialPageRoute(builder: (_) => const Scaffold(body: Text('suite')));
      },
    );
    await tester.pump(const Duration(milliseconds: 1700));
    await laisserRepondre(tester);
    return routes;
  }

  testWidgets('session valide : GET /account/me, accueil avec l’utilisateur relu',
      (tester) async {
    await preparer();
    espion.repond({
      'utilisateur': {
        'id': 'u-1',
        'nom': 'Beye',
        'prenom': 'Balla',
        'email': 'balla@exemple.fr',
        'adresse': 'Paris',
        'telephone': '+33600000000',
        'role': 'Particulier',
        'statut': 'actif',
        'photoProfil': null,
      },
    });

    final routes = await demarrer(tester);

    expect(espion.appel, 'GET /account/me');
    expect(routes.single.name, AppRouter.clientRoute);
    final user = routes.single.arguments as User;
    expect(user.id, 'u-1');
    expect(user.prenom, 'Balla');
    expect(user.telephone, '+33600000000');
  });

  for (final cas in {
    403: 'Compte désactivé. Contactez le support.',
    404: 'Utilisateur introuvable',
    401: 'Token invalide',
  }.entries) {
    testWidgets('${cas.key} : session effacée, retour à la connexion', (tester) async {
      await preparer();
      espion.repondErreur(cas.key, corps: {'message': cas.value});
      // 401 : l'appli ne passe pas par l'intercepteur ici (Dio de test nu).

      final routes = await demarrer(tester);

      expect(routes.single.name, AppRouter.loginRoute);
      expect(await stockage.read(key: StorageKeys.jwtToken), isNull);
      expect(await stockage.read(key: StorageKeys.refreshToken), isNull);
    });
  }

  testWidgets('panne réseau : session gardée, accueil ouvert', (tester) async {
    await preparer();
    espion.coupeReseau();

    final routes = await demarrer(tester);

    expect(routes.single.name, AppRouter.clientRoute);
    expect(routes.single.arguments, isNull);
    expect(await stockage.read(key: StorageKeys.refreshToken), 'rt-1');
  });

  testWidgets('aucune session : connexion, sans appel réseau', (tester) async {
    await preparer(jetons: {});

    final routes = await demarrer(tester);

    expect(espion.requetes, isEmpty);
    expect(routes.single.name, AppRouter.loginRoute);
  });
}
