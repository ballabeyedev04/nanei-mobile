import 'package:flutter_test/flutter_test.dart';
import 'package:nanei/features/home/data/datasources/colis_remote_datasource.dart';
import 'package:nanei/features/home/data/repositories/colis_repository_impl.dart';
import 'package:nanei/features/home/domain/usecases/envoyer_colis.dart';
import 'package:nanei/features/home/domain/usecases/envoyer_colis_lot.dart';
import 'package:nanei/features/home/domain/usecases/rechercher_client.dart';

import '../../../../helpers/dio_espion.dart';
import '../../../../helpers/environnement.dart';

/// Dépôt Colis + cas d'usage d'envoi, de bout en bout jusqu'au corps HTTP.
///
/// ## Ce que ce fichier rend impossible
///
///  - un paramètre perdu entre l'écran et le datasource (filtre `statut`,
///    pagination, champs tarifaires) : le dépôt est un simple relais, mais
///    un relais qui oublie un argument passe toutes les analyses ;
///  - un `DestinataireManuel` sérialisé avec des clés vides (le back crée
///    alors un compte « léger » avec un e-mail "" au lieu de null) ;
///  - un lot dont un élément porterait À LA FOIS `recepteurId` et
///    `destinataireManuel` ;
///  - une recherche de destinataire par NOM qui partirait au serveur (le
///    back n'accepte plus qu'un e-mail ou un téléphone exact).
void main() {
  setUpAll(initialiserEnvironnementDeTest);

  late DioEspion espion;
  late ColisRepositoryImpl depot;

  setUp(() {
    espion = DioEspion();
    depot = ColisRepositoryImpl(
        remoteDataSource: ColisRemoteDataSourceImpl(dio: dioDeTest(espion)));
  });

  test('filtre et pagination relayés', () async {
    espion.repond({'data': [], 'par_statut': {'livre': 2}});
    final r = await depot.getColisRecus(page: 3, limit: 10, statut: 'livre');
    expect(espion.requete.queryParameters, {'page': 3, 'limit': 10, 'statut': 'livre'});
    expect(r.compte('livre'), 2);
  });

  test('EnvoyerColis : destinataire manuel sans clé vide, tarif complet', () async {
    espion.repond({'message': 'ok', 'colis': {'reference': 'COL-1'}}, statut: 201);

    final ref = await EnvoyerColis(depot)(const EnvoyerColisParams(
      destinataireManuel: DestinataireManuel(
        prenom: 'Awa',
        nom: 'Diallo',
        telephone: '+22376001234',
        email: '  ',
        ville: 'Bamako',
        paysId: 'pays-ml',
      ),
      poids: 3,
      prix: 30,
      destination: 'Mali',
      typeColis: 'Document',
      countryId: 'pays-ml',
      shippingType: 'aérien',
      needsDelivery: true,
    ));

    expect(ref, 'COL-1');
    expect(corpsEnvoye(espion.requete), {
      'destinataireManuel': {
        'prenom': 'Awa',
        'nom': 'Diallo',
        'telephone': '+22376001234',
        'ville': 'Bamako',
        'paysId': 'pays-ml',
      },
      'poids': 3.0,
      'prix': 30.0,
      'destination': 'Mali',
      'type_colis': 'Document',
      'description': null,
      'countryId': 'pays-ml',
      'shippingType': 'aérien',
      'needsPickup': false,
      'needsDelivery': true,
    });
  });

  test('EnvoyerColisLot : chaque élément a UN destinataire', () async {
    espion.repond({'message': 'ok', 'lotId': 'l', 'colis': []}, statut: 201);

    await EnvoyerColisLot(depot)(const [
      EnvoyerColisParams(
          recepteurId: 'u-1', poids: 1, prix: 1, destination: 'Mali', typeColis: 'a'),
      EnvoyerColisParams(
          destinataireManuel:
              DestinataireManuel(prenom: 'A', nom: 'B', telephone: '+2237000000'),
          poids: 2,
          prix: 2,
          destination: 'Mali',
          typeColis: 'b'),
    ]);

    final items = (corpsEnvoye(espion.requete)['colis'] as List).cast<Map>();
    expect(items[0]['recepteurId'], 'u-1');
    expect(items[0].containsKey('destinataireManuel'), isFalse);
    expect(items[1].containsKey('recepteurId'), isFalse);
    expect(items[1]['destinataireManuel'], {'prenom': 'A', 'nom': 'B', 'telephone': '+2237000000'});
    expect(items.every((i) => i['type_colis'] != null), isTrue);
  });

  test('RechercherClient : téléphone exact envoyé, nom jamais', () async {
    espion.repond({'data': []});
    await RechercherClient(depot)('Amadou');
    expect(espion.requetes, isEmpty);

    await RechercherClient(depot)(' +223 76 00 12 34 ');
    expect(espion.requete.queryParameters, {'q': '+223 76 00 12 34'});
  });
}
