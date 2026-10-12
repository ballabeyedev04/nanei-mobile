import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nanei/core/utils/api_error.dart';
import 'package:nanei/features/avis/data/datasources/avis_remote_datasource.dart';

import '../../../../helpers/dio_espion.dart';
import '../../../../helpers/environnement.dart';

/// L'API Avis (`POST /avis`, `GET /avis`).
///
/// ## Ce que ce fichier rend impossible
///
///  - un avis envoyé sans `colis_id` (nom canonique lu par
///    `avis.controller.js`) : le back répond « colis_id et note sont
///    obligatoires » et l'étoile cliquée est perdue ;
///  - un commentaire VIDE envoyé tel quel (le back l'enregistre en "" au
///    lieu de null) ;
///  - la liste relue sous une mauvaise clé : le back renvoie `avis`, pas
///    `data`. Lue de travers, elle serait vide — et le bandeau « Donnez
///    votre avis » réapparaîtrait sur un colis déjà noté (→ 409) ;
///  - un 409 (avis déjà donné) indiscernable d'une panne.
void main() {
  setUpAll(initialiserEnvironnementDeTest);

  late DioEspion espion;
  late AvisRemoteDataSourceImpl source;

  setUp(() {
    espion = DioEspion();
    source = AvisRemoteDataSourceImpl(dio: dioDeTest(espion));
  });

  group('POST /avis', () {
    test('colis_id + note + commentaire', () async {
      espion.repond({'success': true, 'message': 'Avis enregistré', 'avis': {}},
          statut: 201);

      await source.donnerAvis(colisId: 'c-1', note: 4, commentaire: 'Rapide');

      expect(espion.appel, 'POST /avis');
      final corps = corpsEnvoye(espion.requete);
      expect(corps['colis_id'], 'c-1');
      expect(corps['note'], 4);
      expect(corps['commentaire'], 'Rapide');
    });

    test('commentaire vide : clé absente', () async {
      espion.repond({'success': true}, statut: 201);
      await source.donnerAvis(colisId: 'c-1', note: 5, commentaire: '');
      expect(corpsEnvoye(espion.requete).containsKey('commentaire'), isFalse);
    });

    test('409 « Un avis existe déjà » et 400 « après livraison » remontent',
        () async {
      espion.repondErreur(409,
          corps: {'success': false, 'message': 'Un avis existe déjà pour ce colis'});
      espion.repondErreur(400, corps: {
        'success': false,
        'message': 'Vous pouvez donner un avis uniquement après livraison',
      });

      DioException? e409;
      DioException? e400;
      try {
        await source.donnerAvis(colisId: 'c-1', note: 3);
      } on DioException catch (e) {
        e409 = e;
      }
      try {
        await source.donnerAvis(colisId: 'c-2', note: 3);
      } on DioException catch (e) {
        e400 = e;
      }
      expect(e409!.response?.statusCode, 409);
      expect(e400!.response?.statusCode, 400);
      expect(messageErreurApi(e400),
          'Vous pouvez donner un avis uniquement après livraison');
    });
  });

  group('GET /avis', () {
    test('liste complète (aucun paramètre) relue sous `avis`', () async {
      espion.repond({
        'success': true,
        'avis': [
          {
            'id': 'a-1',
            'colis_id': 'c-1',
            'utilisateur_id': 'u-1',
            'note': 5,
            'commentaire': null,
            'createdAt': '2026-10-01T10:00:00.000Z',
            'colis': {'reference': 'COL-2026-A1B2C3-4567', 'destination': 'Mali'},
          },
        ],
      });

      final r = await source.mesAvis();

      expect(espion.appel, 'GET /avis');
      expect(espion.requete.queryParameters, isEmpty);
      expect(r.elements.single.colisId, 'c-1');
      expect(r.elements.single.note, 5);
      expect(r.elements.single.commentaire, isNull);
      expect(r.pagination.pages, 1);
    });

    test('page demandée : page/limit envoyés, pagination relue', () async {
      espion.repond({
        'success': true,
        'avis': [],
        'pagination': {'page': 2, 'limit': 20, 'total': 21, 'pages': 2},
      });
      final r = await source.mesAvis(page: 2, limit: 20);
      expect(espion.requete.queryParameters, {'page': 2, 'limit': 20});
      expect(r.pagination.page, 2);
      expect(r.pagination.total, 21);
    });
  });
}
