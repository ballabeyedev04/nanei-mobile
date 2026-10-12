import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:nanei/core/config/env.dart';
import 'package:nanei/core/utils/api_error.dart';
import 'package:nanei/features/paiement/data/datasources/paiement_remote_datasource.dart';

import '../../../../helpers/dio_espion.dart';
import '../../../../helpers/environnement.dart';

class MockDio extends Mock implements Dio {}

/// L'API Paiements (`/paiements`, `/paiements/:colisId/initier`).
///
/// ## Ce que ce fichier rend impossible
///
///  - un montant DECIMAL renvoyé en CHAÎNE (`"87.50"`, forme native de
///    Sequelize/pg pour `prixTotal` / `montantPaye`) qui ferait planter la
///    liste sur un `as num` ;
///  - un filtre `statut` ou une pagination qui n'arriverait pas au serveur
///    (les compteurs `par_statut` sont, eux, calculés sur TOUTES les pages) ;
///  - l'oubli de `moyenPaiement` (nom exact lu par
///    `controllers/client/paiement.controller.js`), ou l'envoi d'un montant
///    que le serveur doit calculer lui-même ;
///  - une URL de paiement absente acceptée en silence (bouton « Payer » qui
///    n'ouvre rien).
void main() {
  setUpAll(initialiserEnvironnementDeTest);

  test('paiements : envoie statut + page, lit par_statut', () async {
    final dio = MockDio();
    when(() => dio.get(Env.paiements,
            queryParameters: any(named: 'queryParameters')))
        .thenAnswer((_) async => Response(
              requestOptions: RequestOptions(path: Env.paiements),
              statusCode: 200,
              data: {
                'data': [],
                'par_statut': {
                  'en_attente': 4,
                  'en_cours': 1,
                  'paye': 10,
                  'echoue': 2,
                  'rembourse': 0,
                  'total': 17,
                },
                'pagination': {'page': 1, 'limit': 20, 'total': 10, 'pages': 1},
              },
            ));

    final r = await PaiementRemoteDataSourceImpl(dio: dio)
        .mesPaiements(page: 1, limit: 20, statut: 'paye');

    verify(() => dio.get(Env.paiements,
        queryParameters: {'page': 1, 'limit': 20, 'statut': 'paye'})).called(1);
    expect(r.compte('paye'), 10);
    expect(r.compte('total'), 17);
  });

  group('avec le vrai Dio (espion)', () {
    late DioEspion espion;
    late PaiementRemoteDataSourceImpl source;

    setUp(() {
      espion = DioEspion();
      source = PaiementRemoteDataSourceImpl(dio: dioDeTest(espion));
    });

    /// Un paiement tel que `ClientPaiementService.mesPaiements` le renvoie.
    Map<String, dynamic> paiementBack({
      Object? prixTotal = 87.5,
      Object? montantPaye = 0,
      String statut = 'en_attente',
      Object? poids = 12.5,
    }) =>
        {
          'id': 'p-1',
          'colisId': 'c-1',
          'payeurId': 'u-1',
          'prixTotal': prixTotal,
          'montantPaye': montantPaye,
          'moyenPaiement': null,
          'statut': statut,
          'referenceTransaction': null,
          'checkoutUrl': null,
          'createdAt': '2026-10-01T10:00:00.000Z',
          'updatedAt': '2026-10-01T10:00:00.000Z',
          'colis': {
            'id': 'c-1',
            'reference': 'COL-2026-A1B2C3-4567',
            'prix': 87.5,
            'poids': poids,
            'destination': 'Mali',
            'type_colis': 'Vêtement',
            'statut': 'recupere',
          },
        };

    test('GET /paiements : relit chaque champ, référence du colis comprise',
        () async {
      espion.repond({
        'success': true,
        'data': [paiementBack(statut: 'paye', montantPaye: 87.5)],
        'par_statut': {
          'en_attente': 0,
          'en_cours': 0,
          'paye': 1,
          'echoue': 0,
          'rembourse': 0,
          'total': 1,
        },
        'pagination': {'page': 1, 'limit': 20, 'total': 1, 'pages': 1},
      });

      final r = await source.mesPaiements(page: 1, limit: 20);

      expect(espion.appel, 'GET /paiements');
      expect(espion.requete.queryParameters, {'page': 1, 'limit': 20});
      final p = r.elements.single;
      expect(p.id, 'p-1');
      expect(p.colisId, 'c-1');
      expect(p.reference, 'COL-2026-A1B2C3-4567');
      expect(p.prixTotal, 87.5);
      expect(p.montantPaye, 87.5);
      expect(p.estPaye, isTrue);
      expect(p.destination, 'Mali');
      expect(p.poids, 12.5);
      expect(p.createdAt, DateTime.utc(2026, 10, 1, 10));
    });

    test('DECIMAL en chaîne (« 87.50 ») : relu en nombre, sans planter',
        () async {
      espion.repond({
        'success': true,
        'data': [
          paiementBack(prixTotal: '87.50', montantPaye: null, poids: '12.50'),
        ],
        'par_statut': {'total': '1', 'en_attente': '1'},
      });

      final r = await source.mesPaiements();

      expect(espion.requete.queryParameters, isEmpty);
      expect(r.elements.single.prixTotal, 87.5);
      expect(r.elements.single.montantPaye, 0);
      expect(r.elements.single.poids, 12.5);
      expect(r.elements.single.peutPayer, isTrue);
      // COUNT() Postgres arrive lui aussi en chaîne.
      expect(r.compte('en_attente'), 1);
    });

    test('400 « Statut invalide » : message du back conservé', () async {
      espion.repondErreur(400, corps: {
        'success': false,
        'message':
            'Statut invalide (en_attente, en_cours, paye, echoue, rembourse)',
      });
      try {
        await source.mesPaiements(statut: 'inconnu');
        fail('DioException attendue');
      } on DioException catch (e) {
        expect(espion.requete.queryParameters, {'statut': 'inconnu'});
        expect(messageErreurApi(e), startsWith('Statut invalide'));
      }
    });

    test('POST /paiements/:colisId/initier : seul moyenPaiement est envoyé',
        () async {
      espion.repond({
        'success': true,
        'data': {
          'checkoutUrl': 'https://pay.wave.com/c/cos-18qq4',
          'paiementId': 'p-1',
          'montant': 57396,
          'devise': 'XOF',
          'prixEur': 87.5,
          'tauxChange': 655.957,
        },
      });

      final url =
          await source.initierPaiement(colisId: 'c-1', moyenPaiement: 'wave');

      expect(espion.appel, 'POST /paiements/c-1/initier');
      // Le montant est calculé par le serveur : le mobile ne l'envoie pas.
      expect(corpsEnvoye(espion.requete), {'moyenPaiement': 'wave'});
      expect(url, 'https://pay.wave.com/c/cos-18qq4');
    });

    test('réponse sans checkoutUrl : erreur explicite, pas une URL vide',
        () async {
      espion.repond({
        'success': true,
        'data': {'paiementId': 'p-1'},
      });
      await expectLater(
        source.initierPaiement(colisId: 'c-1', moyenPaiement: 'orange_money'),
        throwsA(isA<DioException>().having(
            (e) => '${e.error}', 'error', contains('URL de paiement invalide'))),
      );
    });

    test('colis déjà payé : 400 avec le message du service', () async {
      espion.repondErreur(400,
          corps: {'success': false, 'message': 'Ce colis est déjà payé'});
      try {
        await source.initierPaiement(colisId: 'c-1', moyenPaiement: 'wave');
        fail('DioException attendue');
      } on DioException catch (e) {
        expect(messageErreurApi(e), 'Ce colis est déjà payé');
      }
    });
  });
}
