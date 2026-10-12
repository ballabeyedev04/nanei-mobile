import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nanei/core/config/env.dart';
import 'package:nanei/core/utils/api_error.dart';
import 'package:nanei/features/home/data/datasources/colis_remote_datasource.dart';

import '../../../../helpers/dio_espion.dart';
import '../../../../helpers/environnement.dart';

/// L'API Colis (`/client/*`, `/pricing/calculate`, `/suivi/:ref`), du chemin
/// envoyé jusqu'au champ affiché.
///
/// ## Ce que ce fichier rend impossible
///
///  1. un CHEMIN, un VERBE ou un NOM DE CHAMP qui ne correspond pas au back
///     (`routes/client/envoieColis.route.js`, `envoieColis.controller.js`) :
///     `type_colis` et non `typeColis`, `recepteurId` OU `destinataireManuel`
///     (jamais les deux), `colis` pour un lot, `q` pour la recherche ;
///  2. une RELECTURE fausse du JSON tel que le back le forme réellement :
///     statuts sans accent (`recupere`), `type_transport`, `lot_id`,
///     `par_statut`, `pagination`, `non_lues`, enveloppes différentes selon
///     la route (`data`, `colis`, `success`) ;
///  3. un refus du serveur (400, 403, 404) qui perdrait son message : il doit
///     arriver jusqu'à l'écran tel que le back l'a écrit.
///
/// Les réponses sont recopiées des contrôleurs du back ; aucun appel réseau
/// réel n'est fait (voir `DioEspion`).
void main() {
  setUpAll(initialiserEnvironnementDeTest);

  late DioEspion espion;
  late ColisRemoteDataSourceImpl source;

  setUp(() {
    espion = DioEspion();
    source = ColisRemoteDataSourceImpl(dio: dioDeTest(espion));
  });

  /// Un colis tel que Sequelize le sérialise (`underscored: true` : colonnes
  /// snake_case, mais attributs `createdAt` / `expediteurId` en camelCase).
  Map<String, dynamic> colisBack({
    String id = 'c-1',
    String statut = 'recupere',
    String? lotId,
    String? typeTransport = 'maritime',
  }) =>
      {
        'id': id,
        'reference': 'COL-2026-A1B2C3-4567',
        'expediteurId': 'u-exp',
        'recepteurId': 'u-rec',
        'poids': 12.5,
        'prix': 87.5,
        'destination': 'Mali',
        'description': 'Vêtements',
        'type_colis': 'Vêtement',
        'type_transport': typeTransport,
        'statut': statut,
        'lot_id': lotId,
        'createdAt': '2026-10-01T10:00:00.000Z',
        'updatedAt': '2026-10-02T08:30:00.000Z',
        'deletedAt': null,
        'recepteur': {
          'id': 'u-rec',
          'nom': 'Diallo',
          'prenom': 'Awa',
          'email': 'awa@exemple.ml',
          'telephone': '+22376001234',
        },
        'expediteur': {
          'id': 'u-exp',
          'nom': 'Beye',
          'prenom': 'Balla',
          'email': 'balla@exemple.fr',
          'telephone': null,
        },
      };

  group('GET /client/colis-envoyes', () {
    test('envoie page, limit et statut ; relit colis, par_statut et pagination',
        () async {
      espion.repond({
        'data': [colisBack()],
        'par_statut': {'en_attente': 2, 'recupere': 1, 'livre': 4, 'total': 7},
        'pagination': {'page': 2, 'limit': 20, 'total': 21, 'pages': 2},
      });

      final r =
          await source.getColisEnvoyes(page: 2, limit: 20, statut: 'recupere');

      expect(espion.appel, 'GET /client/colis-envoyes');
      expect(espion.requete.queryParameters,
          {'page': 2, 'limit': 20, 'statut': 'recupere'});

      final c = r.elements.single;
      expect(c.id, 'c-1');
      expect(c.reference, 'COL-2026-A1B2C3-4567');
      expect(c.statut, 'recupere');
      // `type_colis` (nom de colonne du back), pas `type`.
      expect(c.type, 'Vêtement');
      expect(c.typeTransport, 'maritime');
      expect(c.poids, 12.5);
      expect(c.prix, 87.5);
      expect(c.recepteur!.nomComplet, 'Awa Diallo');
      // Un téléphone NULL côté back ne doit pas devenir « null » à l'écran.
      expect(c.expediteur!.telephone, '');
      expect(c.createdAt, DateTime.utc(2026, 10, 1, 10));
      expect(c.updatedAt, isNotNull);
      expect(c.lotId, isNull);

      expect(r.pagination.page, 2);
      expect(r.pagination.total, 21);
      expect(r.compte('recupere'), 1);
      expect(r.compte('total'), 7);
    });

    test('statut « tous » : aucun filtre envoyé (le back refuse une valeur inconnue)',
        () async {
      espion.repond({'data': [], 'par_statut': {}});
      await source.getColisEnvoyes(page: 1, limit: 20, statut: 'tous');
      expect(espion.requete.queryParameters, {'page': 1, 'limit': 20});
    });

    test('400 « Statut invalide » : le message du back remonte tel quel',
        () async {
      espion.repondErreur(400, corps: {
        'message': 'Statut invalide (en_attente, recupere, livre)',
      });
      final e = await _erreur(() => source.getColisEnvoyes(statut: 'perdu'));
      expect(e.response?.statusCode, 400);
      expect(messageErreurApi(e),
          'Statut invalide (en_attente, recupere, livre)');
    });
  });

  group('GET /client/colis-recus', () {
    test('lit un colis livré d’un lot (lot_id) avec son expéditeur', () async {
      espion.repond({
        'data': [colisBack(statut: 'livre', lotId: 'lot-9')],
        'par_statut': {'en_attente': 0, 'recupere': 0, 'livre': 1, 'total': 1},
      });

      final r = await source.getColisRecus();

      expect(espion.appel, 'GET /client/colis-recus');
      // Sans page ni limite : AUCUN paramètre → liste complète côté back.
      expect(espion.requete.queryParameters, isEmpty);
      expect(r.elements.single.statut, 'livre');
      expect(r.elements.single.lotId, 'lot-9');
      expect(r.elements.single.expediteur!.nom, 'Beye');
      expect(r.pagination.pages, 1);
    });

    test('ancien colis sans type_transport : null, pas une chaîne vide',
        () async {
      espion.repond({
        'data': [colisBack(typeTransport: null)],
        'par_statut': {},
      });
      final r = await source.getColisRecus();
      expect(r.elements.single.typeTransport, isNull);
      expect(r.elements.single.typeTransportLabel, '');
    });
  });

  group('GET /client/colis-recherche/:reference (scan QR)', () {
    test('relit le colis sous `data`', () async {
      espion.repond({'data': colisBack(statut: 'en_attente')});

      final c = await source.rechercherColisParReference('COL-2026-A1B2C3-4567');

      expect(espion.appel, 'GET /client/colis-recherche/COL-2026-A1B2C3-4567');
      expect(c.statut, 'en_attente');
    });

    test('404 « Colis introuvable » et 403 « ne vous appartient pas »',
        () async {
      espion.repondErreur(404, corps: {'message': 'Colis introuvable'});
      espion.repondErreur(403, corps: {'message': 'Ce colis ne vous appartient pas'});

      final e404 = await _erreur(() => source.rechercherColisParReference('X'));
      final e403 = await _erreur(() => source.rechercherColisParReference('Y'));

      expect(e404.response?.statusCode, 404);
      expect(messageErreurApi(e404), 'Colis introuvable');
      expect(e403.response?.statusCode, 403);
      expect(messageErreurApi(e403), 'Ce colis ne vous appartient pas');
    });
  });

  test('GET /client/statistiques-colis : relit colisEnvoyes / colisRecus / total',
      () async {
    espion.repond({
      'success': true,
      'data': {'colisEnvoyes': 3, 'colisRecus': 2, 'total': 5},
    });

    final s = await source.getStatistiques();

    expect(espion.appel, 'GET /client/statistiques-colis');
    expect(s, {'envoyes': 3, 'recus': 2, 'total': 5});
  });

  group('POST /client/envoie-colis', () {
    test('destinataire inscrit : recepteurId + champs tarifaires, référence relue',
        () async {
      espion.repond({
        'message': 'Colis créé avec succès',
        'colis': colisBack(statut: 'en_attente'),
      }, statut: 201);

      final ref = await source.envoyerColis(
        recepteurId: 'u-rec',
        poids: 12.5,
        prix: 87.5,
        destination: 'Mali',
        typeColis: 'Vêtement',
        description: 'Vêtements',
        tarif: const {
          'countryId': 'pays-ml',
          'shippingType': 'maritime',
          'needsPickup': true,
          'needsDelivery': false,
        },
      );

      expect(espion.appel, 'POST /client/envoie-colis');
      expect(corpsEnvoye(espion.requete), {
        'recepteurId': 'u-rec',
        'poids': 12.5,
        'prix': 87.5,
        'destination': 'Mali',
        'type_colis': 'Vêtement',
        'description': 'Vêtements',
        'countryId': 'pays-ml',
        'shippingType': 'maritime',
        'needsPickup': true,
        'needsDelivery': false,
      });
      expect(ref, 'COL-2026-A1B2C3-4567');
    });

    test('destinataire manuel : destinataireManuel SANS recepteurId', () async {
      espion.repond({'message': 'ok', 'colis': colisBack()}, statut: 201);

      await source.envoyerColis(
        destinataireManuel: const {
          'prenom': 'Awa',
          'nom': 'Diallo',
          'telephone': '+22376001234',
          'ville': 'Bamako',
        },
        poids: 2,
        prix: 10,
        destination: 'Mali',
        typeColis: 'Document',
      );

      final corps = corpsEnvoye(espion.requete);
      expect(corps.containsKey('recepteurId'), isFalse);
      expect(corps['destinataireManuel'], {
        'prenom': 'Awa',
        'nom': 'Diallo',
        'telephone': '+22376001234',
        'ville': 'Bamako',
      });
    });

    test('400 « Recepteur non trouvé » : message du back conservé', () async {
      espion.repondErreur(400, corps: {'message': 'Recepteur non trouvé'});
      final e = await _erreur(() => source.envoyerColis(
            recepteurId: 'inconnu',
            poids: 1,
            prix: 1,
            destination: 'Mali',
            typeColis: 'x',
          ));
      expect(messageErreurApi(e), 'Recepteur non trouvé');
    });
  });

  test('POST /client/envoie-colis-lot : { colis: [...] } → colis créés avec lot_id',
      () async {
    espion.repond({
      'message': '2 colis créés avec succès',
      'lotId': 'lot-1',
      'colis': [
        colisBack(id: 'a', statut: 'en_attente', lotId: 'lot-1'),
        colisBack(id: 'b', statut: 'en_attente', lotId: 'lot-1'),
      ],
    }, statut: 201);

    final items = [
      {'recepteurId': 'u1', 'poids': 1.0, 'type_colis': 'x'},
      {'recepteurId': 'u2', 'poids': 2.0, 'type_colis': 'y'},
    ];
    final crees = await source.envoyerColisLot(items);

    expect(espion.appel, 'POST /client/envoie-colis-lot');
    expect(corpsEnvoye(espion.requete), {'colis': items});
    expect(crees.map((c) => c.id), ['a', 'b']);
    expect(crees.every((c) => c.lotId == 'lot-1'), isTrue);
  });

  group('GET /client/rechercher-client', () {
    test('paramètre `q` ; relit l’unique résultat MASQUÉ', () async {
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
      });

      final r = await source.rechercherClient('amadou@gmail.com');

      expect(espion.appel, 'GET /client/rechercher-client');
      expect(espion.requete.queryParameters, {'q': 'amadou@gmail.com'});
      expect(r.single.id, 'u-42');
      expect(r.single.email, 'am***@gmail.com');
      expect(r.single.telephone, '+223 ** ** 12 34');
    });

    test('saisie vide : aucun appel', () async {
      expect(await source.rechercherClient(''), isEmpty);
      expect(espion.requetes, isEmpty);
    });
  });

  group('notifications', () {
    Map<String, dynamic> notif(String id, String statut) => {
          'id': id,
          'expediteurId': 'u-exp',
          'recepteurId': 'u-moi',
          'colisId': 'c-1',
          'statut': statut,
          'createdAt': '2026-10-01T10:00:00.000Z',
          'colis': {
            'id': 'c-1',
            'reference': 'COL-2026-A1B2C3-4567',
            'type_colis': 'Vêtement',
            'description': 'Pagnes',
            'statut': 'en_attente',
            'created_at': '2026-10-01T10:00:00.000Z',
          },
          'expediteur': {
            'id': 'u-exp',
            'nom': 'Beye',
            'prenom': 'Balla',
            'email': 'balla@exemple.fr',
            'telephone': '+33600000000',
          },
        };

    test('GET /client/mes-notifications : page + non_lues (toutes pages)',
        () async {
      espion.repond({
        'data': [notif('n1', 'non_lu'), notif('n2', 'lu')],
        'non_lues': 12,
        'pagination': {'page': 1, 'limit': 20, 'total': 30, 'pages': 2},
      });

      final r = await source.getNotifications(page: 1, limit: 20);

      expect(espion.appel, 'GET /client/mes-notifications');
      expect(espion.requete.queryParameters, {'page': 1, 'limit': 20});
      expect(r.elements.map((n) => n.lue), [false, true]);
      expect(r.elements.first.referenceColis, 'COL-2026-A1B2C3-4567');
      expect(r.elements.first.typeColis, 'Vêtement');
      expect(r.elements.first.expediteurPrenom, 'Balla');
      expect(r.elements.first.date, DateTime.utc(2026, 10, 1, 10));
      // Le badge montre le total du serveur, pas le décompte de la page.
      expect(r.nonLues, 12);
      expect(r.pagination.pages, 2);
    });

    test('non_lues absent (ancien back) : décompte sur la page reçue',
        () async {
      espion.repond({
        'data': [notif('n1', 'non_lu'), notif('n2', 'non_lu'), notif('n3', 'lu')],
      });
      final r = await source.getNotifications();
      expect(espion.requete.queryParameters, isEmpty);
      expect(r.nonLues, 2);
    });

    test('PATCH /client/lire-notifications/:id', () async {
      espion.repond({'message': 'Notification marquée comme lue', 'data': notif('n1', 'lu')});
      await source.marquerNotificationLue('n1');
      expect(espion.appel, 'PATCH /client/lire-notifications/n1');
    });

    test('PATCH sur la notification d’un autre : 404 remonte', () async {
      espion.repondErreur(404, corps: {'message': 'Notification introuvable'});
      final e = await _erreur(() => source.marquerNotificationLue('autre'));
      expect(e.response?.statusCode, 404);
      expect(messageErreurApi(e), 'Notification introuvable');
    });

    test('POST /client/notifications/mark-all-read', () async {
      espion.repond({
        'message': 'Notifications marquées comme lues',
        'data': {'nombre': 4},
      });
      await source.marquerToutesNotificationsLues();
      expect(espion.appel, 'POST /client/notifications/mark-all-read');
    });
  });

  group('tarifs', () {
    test('GET /client/countries : { success, data: [{ id, name, code }] }',
        () async {
      espion.repond({
        'success': true,
        'data': [
          {'id': 'pays-ml', 'name': 'Mali', 'code': 'ML'},
          {'id': 'pays-sn', 'name': 'Sénégal', 'code': 'SN'},
        ],
      });

      final pays = await source.getCountries();

      expect(espion.appel, 'GET /client/countries');
      expect(pays.map((p) => p.name), ['Mali', 'Sénégal']);
      expect(pays.first.code, 'ML');
    });

    test('GET /client/pricing/:countryId : grilles aérien/maritime et services',
        () async {
      // Forme de `ShippingRateService.getPricingForCountry` +
      // `ServiceRateService.getServicesForCountry` : types AVEC accent.
      espion.repond({
        'success': true,
        'data': {
          'country': {'id': 'pays-ml', 'name': 'Mali', 'code': 'ML'},
          'shippingPrices': [
            {'type': 'aérien', 'minWeight': 0, 'maxWeight': 30, 'pricePerKg': 9.5},
            {'type': 'maritime', 'minWeight': 0, 'maxWeight': 500, 'pricePerKg': 3},
          ],
          'servicePrices': [
            {'serviceType': 'récupération', 'price': 15},
            {'serviceType': 'livraison', 'price': 10.5},
          ],
        },
      });

      final p = await source.getPricingByCountry('pays-ml');

      expect(espion.appel, 'GET /client/pricing/pays-ml');
      expect(p.country.name, 'Mali');
      expect(p.shippingPrices.map((s) => s.type), ['aérien', 'maritime']);
      expect(p.shippingPrices.first.pricePerKg, 9.5);
      expect(p.shippingPrices.last.maxWeight, 500);
      expect(p.servicePrices.map((s) => s.serviceType),
          ['récupération', 'livraison']);
      expect(p.servicePrices.last.price, 10.5);
    });

    test('pays inactif : 404 « Pays non trouvé »', () async {
      espion.repondErreur(404, corps: {'success': false, 'message': 'Pays non trouvé'});
      final e = await _erreur(() => source.getPricingByCountry('pays-off'));
      expect(messageErreurApi(e), 'Pays non trouvé');
    });

    test('POST /pricing/calculate : noms anglais attendus par le contrôleur',
        () async {
      espion.repond({
        'success': true,
        'message': 'Prix calculé avec succès',
        'data': {
          'shippingPrice': 118.75,
          'pickupPrice': 15,
          'deliveryPrice': 0,
          'total': 133.75,
          'pricePerKg': 9.5,
          'breakdown': {'weight': 12.5, 'type': 'aérien', 'country': 'Mali'},
        },
      });

      final prix = await source.calculerPrix(
        countryId: 'pays-ml',
        weight: 12.5,
        shippingType: 'aérien',
        needsPickup: true,
      );

      expect(espion.appel, 'POST /pricing/calculate');
      expect(corpsEnvoye(espion.requete), {
        'countryId': 'pays-ml',
        'weight': 12.5,
        'shippingType': 'aérien',
        'needsPickup': true,
        'needsDelivery': false,
      });
      expect(prix.total, 133.75);
      expect(prix.pickupPrice, 15);
      expect(prix.deliveryPrice, 0);
    });

    test('poids hors grille : 400 avec le message du calculateur', () async {
      espion.repondErreur(400, corps: {
        'success': false,
        'message': 'Aucune plage de poids ne correspond au poids de 999kg',
      });
      final e = await _erreur(() => source.calculerPrix(
          countryId: 'pays-ml', weight: 999, shippingType: 'aérien'));
      expect(messageErreurApi(e),
          'Aucune plage de poids ne correspond au poids de 999kg');
    });
  });

  group('GET /suivi/:reference?format=json (public)', () {
    test('URL publique + format=json ; relit colis, masques et historique',
        () async {
      espion.repond({
        'success': true,
        'colis': {
          'reference': 'COL-2026-A1B2C3-4567',
          'statut': 'recupere',
          'destination': 'Mali',
          'poids': 12.5,
          'type_colis': 'Vêtement',
          'type_transport': 'aerien',
          'created_at': '2026-10-01T10:00:00.000Z',
          'expediteur': {'nom': 'Beye', 'prenom': 'Balla', 'telephone': '06****78'},
          'recepteur': {'nom': 'Diallo', 'prenom': 'Awa', 'telephone': '+2****34'},
          'historique': [
            {
              'ancien_statut': 'en_attente',
              'nouveau_statut': 'recupere',
              'commentaire': null,
              'created_at': '2026-10-02T09:00:00.000Z',
            },
          ],
        },
      });

      final s = await source.suiviPublicParReference('COL-2026-A1B2C3-4567');

      final uri = espion.requete.uri;
      expect(espion.requete.method, 'GET');
      expect(uri.path, endsWith('/suivi/COL-2026-A1B2C3-4567'));
      expect(uri.queryParameters, {'format': 'json'});
      expect(uri.toString(), startsWith(Env.baseUrl));

      expect(s.reference, 'COL-2026-A1B2C3-4567');
      expect(s.statut, 'recupere');
      expect(s.typeTransport, 'aerien');
      expect(s.createdAt, DateTime.utc(2026, 10, 1, 10));
      expect(s.recepteurTelephone, '+2****34');
      expect(s.historique.single.ancienStatut, 'en_attente');
      expect(s.historique.single.nouveauStatut, 'recupere');
      expect(s.historique.single.date, DateTime.utc(2026, 10, 2, 9));
    });

    test('référence inconnue : 404 JSON « Colis introuvable »', () async {
      espion.repondErreur(404,
          corps: {'success': false, 'message': 'Colis introuvable'});
      final e = await _erreur(() => source.suiviPublicParReference('NOPE'));
      expect(messageErreurApi(e), 'Colis introuvable');
    });
  });

  test('429 de la limite de débit : message du back affiché', () async {
    espion.repondErreur(429, corps: {
      'message': 'Trop de requêtes. Veuillez réessayer dans quelques minutes.',
    });
    final e = await _erreur(() => source.getColisEnvoyes());
    expect(e.response?.statusCode, 429);
    expect(messageErreurApi(e),
        'Trop de requêtes. Veuillez réessayer dans quelques minutes.');
  });

  test('401 sans corps : DioException badResponse (traitée par l’intercepteur)',
      () async {
    espion.repondErreur(401, corps: {'message': 'Token invalide'});
    final e = await _erreur(() => source.getColisRecus());
    expect(e.type, DioExceptionType.badResponse);
    expect(e.response?.statusCode, 401);
  });
}

Future<DioException> _erreur(Future<Object?> Function() appel) async {
  try {
    await appel();
  } on DioException catch (e) {
    return e;
  }
  fail('une DioException était attendue');
}
