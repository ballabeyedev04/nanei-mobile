import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nanei/features/home/data/datasources/colis_remote_datasource.dart';
import 'package:nanei/features/home/data/repositories/colis_repository_impl.dart';
import 'package:nanei/features/home/domain/repositories/colis_repository.dart';
import 'package:nanei/features/home/domain/usecases/calculer_prix.dart';
import 'package:nanei/features/home/domain/usecases/envoyer_colis.dart';
import 'package:nanei/features/home/domain/usecases/envoyer_colis_lot.dart';
import 'package:nanei/features/home/domain/usecases/get_countries.dart';
import 'package:nanei/features/home/domain/usecases/get_pricing_by_country.dart';
import 'package:nanei/features/home/domain/usecases/rechercher_client.dart';
import 'package:nanei/features/home/presentation/pages/client/envoi_colis_page.dart';

import '../../../../../helpers/dio_espion.dart';
import '../../../../../helpers/environnement.dart';
import '../../../../../helpers/pompe_page.dart';

/// Formulaire d'envoi : recherche du destinataire, de l'écran jusqu'à
/// `GET /client/rechercher-client`.
///
/// ## Ce que ce fichier rend impossible
///
///  - une recherche par NOM ou par début d'e-mail envoyée au serveur : le back
///    ne répond plus qu'à un e-mail COMPLET ou un téléphone exact (anti
///    parcours de l'annuaire) ; l'écran n'appelle pas l'API pour rien ;
///  - une requête par frappe : la saisie est temporisée (500 ms) ;
///  - le résultat unique (e-mail et téléphone MASQUÉS par le back) non
///    affiché, ou une absence de résultat sans proposition de saisie
///    manuelle du destinataire.
void main() {
  late DioEspion espion;

  setUpAll(initialiserEnvironnementDeTest);

  setUp(() async {
    await viderSl();
    espion = DioEspion();
    final dio = dioDeTest(espion);
    enregistrerDio(dio);
    final ColisRepository depot =
        ColisRepositoryImpl(remoteDataSource: ColisRemoteDataSourceImpl(dio: dio));
    remplacerDansSl<GetCountries>(GetCountries(depot));
    remplacerDansSl<GetPricingByCountry>(GetPricingByCountry(depot));
    remplacerDansSl<RechercherClient>(RechercherClient(depot));
    remplacerDansSl<CalculerPrix>(CalculerPrix(depot));
    remplacerDansSl<EnvoyerColis>(EnvoyerColis(depot));
    remplacerDansSl<EnvoyerColisLot>(EnvoyerColisLot(depot));

    espion.repond({
      'success': true,
      'data': [
        {'id': 'pays-ml', 'name': 'Mali', 'code': 'ML'},
      ],
    }, pour: 'GET /client/countries');
    espion.repond({
      'success': true,
      'data': {
        'country': {'id': 'pays-ml', 'name': 'Mali', 'code': 'ML'},
        'shippingPrices': [
          {'type': 'aérien', 'minWeight': 0, 'maxWeight': 30, 'pricePerKg': 9.5},
        ],
        'servicePrices': [
          {'serviceType': 'récupération', 'price': 15},
          {'serviceType': 'livraison', 'price': 10},
        ],
      },
    }, pour: 'GET /client/pricing/pays-ml');
  });

  tearDown(viderSl);

  /// Remplit l'étape 1 (pays, transport, type, poids) et passe à l'étape 2.
  Future<void> allerEtape2(WidgetTester tester) async {
    await pomperPage(tester, const EnvoiColisPage());
    await laisserRepondre(tester);

    await tester.tap(find.text('Sélectionnez un pays'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Mali').last);
    await tester.pumpAndSettle();
    await laisserRepondre(tester);
    await tester.tap(find.text('Aérien'));
    await tester.pump();
    await tester.enterText(
        find.widgetWithText(TextFormField, 'Ex: Document, Vêtement, Électronique...'),
        'Vêtement');
    await tester.enterText(find.widgetWithText(TextFormField, 'Ex: 2.5'), '2');
    await tester.pump();
    // Le bandeau « Prix transport estimé » (€ + FCFA) doit tenir sur un
    // téléphone de 390 px : il débordait de ~90 px.
    expect(tester.takeException(), isNull);
    await tester.tap(find.byIcon(Icons.arrow_forward_rounded));
    await tester.pumpAndSettle();
  }

  Finder champRecherche() => find.widgetWithText(
      TextFormField, 'E-mail ou numéro de téléphone du destinataire');

  int rechercheEnvoyees() =>
      espion.appels.where((a) => a == 'GET /client/rechercher-client').length;

  testWidgets('e-mail complet : UNE requête après la saisie, résultat masqué affiché',
      (tester) async {
    espion.repond({
      'data': [
        {
          'id': 'u-42',
          'nom': 'Diallo',
          'prenom': 'Amadou',
          'email': 'am***@gmail.com',
          'telephone': '+223 ** ** 12 34',
        },
      ],
    }, pour: 'GET /client/rechercher-client');
    await allerEtape2(tester);

    await tester.enterText(champRecherche(), 'amadou@gmail');
    await tester.pump(const Duration(milliseconds: 100));
    await tester.enterText(champRecherche(), 'amadou@gmail.com');
    await tester.pump(const Duration(milliseconds: 600));
    await laisserRepondre(tester);

    expect(rechercheEnvoyees(), 1);
    expect(espion.requetePour('/client/rechercher-client').queryParameters,
        {'q': 'amadou@gmail.com'});
    expect(find.text('Diallo Amadou'), findsOneWidget);
    expect(find.text('am***@gmail.com · +223 ** ** 12 34'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('nom ou e-mail incomplet : aucun appel au serveur', (tester) async {
    await allerEtape2(tester);

    for (final saisie in ['Amadou', 'amadou@', 'am']) {
      await tester.enterText(champRecherche(), saisie);
      await tester.pump(const Duration(milliseconds: 600));
    }
    await laisserRepondre(tester);

    expect(rechercheEnvoyees(), 0);
  });

  testWidgets('téléphone sans résultat : proposition de saisie manuelle',
      (tester) async {
    espion.repond({'data': []}, pour: 'GET /client/rechercher-client');
    await allerEtape2(tester);

    await tester.enterText(champRecherche(), '+223 76 00 12 34');
    await tester.pump(const Duration(milliseconds: 600));
    await laisserRepondre(tester);

    expect(espion.requetePour('/client/rechercher-client').queryParameters,
        {'q': '+223 76 00 12 34'});
    expect(find.text('Saisir le destinataire manuellement'), findsOneWidget);
  });
}
