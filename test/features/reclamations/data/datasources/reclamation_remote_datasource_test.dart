import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nanei/core/utils/api_error.dart';
import 'package:nanei/features/reclamations/data/datasources/reclamation_remote_datasource.dart';

import '../../../../helpers/dio_espion.dart';
import '../../../../helpers/environnement.dart';

/// L'API Réclamations (`/reclamations`, multipart + liste + détail).
///
/// ## Ce que ce fichier rend impossible
///
///  - une photo envoyée en `application/octet-stream` : multer
///    (`createUploader`, types `image/png|jpeg|webp`) la refuse avec
///    « Type de fichier non autorisé » — le client croit à une panne ;
///  - un champ mal nommé : le back lit `colis_id` (pas `colisId`), `type`,
///    `description` et les fichiers sous `photos` (`upload.array('photos', 5)`) ;
///  - le type `endommagé` perdu en route : c'est la valeur EXACTE de l'ENUM
///    Postgres, avec accent ;
///  - une réclamation relue de travers (`colis_id`, `commentaire_admin`,
///    `photos` JSON, `createdAt`).
void main() {
  setUpAll(initialiserEnvironnementDeTest);

  late DioEspion espion;
  late ReclamationRemoteDataSourceImpl source;
  late Directory dossier;

  setUp(() {
    espion = DioEspion();
    source = ReclamationRemoteDataSourceImpl(dio: dioDeTest(espion));
    dossier = Directory.systemTemp.createTempSync('reclamation_test');
  });

  tearDown(() {
    if (dossier.existsSync()) dossier.deleteSync(recursive: true);
  });

  /// Réclamation telle que Sequelize la sérialise (`underscored: true`).
  Map<String, dynamic> reclamationBack({
    String type = 'endommagé',
    String statut = 'ouverte',
    String? commentaireAdmin,
  }) =>
      {
        'id': 'r-1',
        'colis_id': 'c-1',
        'utilisateur_id': 'u-1',
        'type': type,
        'description': 'Carton écrasé',
        'photos': ['https://cdn.test/nanei/reclamations/a.jpg'],
        'statut': statut,
        'commentaire_admin': commentaireAdmin,
        'createdAt': '2026-10-03T12:00:00.000Z',
        'updatedAt': '2026-10-03T12:00:00.000Z',
        'colis': {
          'reference': 'COL-2026-A1B2C3-4567',
          'statut': 'livre',
          'destination': 'Mali',
        },
      };

  group('POST /reclamations (multipart)', () {
    test('champs exacts, type avec accent, photos typées image/*', () async {
      final jpg = File('${dossier.path}/preuve.jpg')..writeAsBytesSync([1, 2, 3]);
      final png = File('${dossier.path}/zoom.PNG')..writeAsBytesSync([4, 5]);
      espion.repond({
        'success': true,
        'message': 'Réclamation créée',
        'reclamation': reclamationBack(),
      }, statut: 201);

      final r = await source.creerReclamation(
        colisId: 'c-1',
        type: 'endommagé',
        description: 'Carton écrasé',
        photos: [jpg.path, png.path],
      );

      expect(espion.appel, 'POST /reclamations');
      final requete = espion.requete;
      // Le Content-Type porte la frontière multipart : sans elle, multer ne
      // découpe pas le corps et ne voit ni champ ni fichier.
      expect(requete.headers[Headers.contentTypeHeader],
          startsWith('multipart/form-data; boundary='));

      final fd = requete.data as FormData;
      expect(Map.fromEntries(fd.fields), {
        'colis_id': 'c-1',
        'type': 'endommagé',
        'description': 'Carton écrasé',
      });
      expect(fd.files.map((f) => f.key), ['photos', 'photos']);
      expect(fd.files.map((f) => f.value.contentType.toString()),
          ['image/jpeg', 'image/png']);
      expect(fd.files.first.value.filename, 'preuve.jpg');

      expect(r.id, 'r-1');
      expect(r.colisId, 'c-1');
      expect(r.type, 'endommagé');
      expect(r.photos, ['https://cdn.test/nanei/reclamations/a.jpg']);
    });

    test('sans photo : aucun fichier, corps multipart malgré tout', () async {
      espion.repond({'success': true, 'reclamation': reclamationBack(type: 'retard')},
          statut: 201);

      await source.creerReclamation(
          colisId: 'c-1', type: 'retard', description: 'Toujours pas là', photos: const []);

      final fd = espion.requete.data as FormData;
      expect(fd.files, isEmpty);
      expect(Map.fromEntries(fd.fields)['type'], 'retard');
    });

    test('refus du back (400 type invalide, 403 colis d’un autre) : message conservé',
        () async {
      espion.repondErreur(400, corps: {
        'success': false,
        'message': 'Type de réclamation invalide (perdu, endommagé, retard ou autre)',
      });
      espion.repondErreur(403,
          corps: {'success': false, 'message': 'Ce colis ne vous appartient pas'});

      for (final attendu in [
        'Type de réclamation invalide (perdu, endommagé, retard ou autre)',
        'Ce colis ne vous appartient pas',
      ]) {
        try {
          await source.creerReclamation(
              colisId: 'c-1', type: 'x', description: 'y', photos: const []);
          fail('DioException attendue');
        } on DioException catch (e) {
          expect(messageErreurApi(e), attendu);
        }
      }
    });
  });

  test('GET /reclamations : liste paginée sous `reclamations`', () async {
    espion.repond({
      'success': true,
      'reclamations': [
        reclamationBack(statut: 'resolue', commentaireAdmin: 'Remboursé'),
      ],
      'pagination': {'page': 1, 'limit': 20, 'total': 1, 'pages': 1},
    });

    final r = await source.getReclamations(page: 1, limit: 20);

    expect(espion.appel, 'GET /reclamations');
    expect(espion.requete.queryParameters, {'page': 1, 'limit': 20});
    final rec = r.elements.single;
    expect(rec.statut, 'resolue');
    expect(rec.commentaireAdmin, 'Remboursé');
    expect(rec.description, 'Carton écrasé');
    expect(rec.createdAt, DateTime.utc(2026, 10, 3, 12));
    expect(r.pagination.total, 1);
  });

  group('GET /reclamations/:id', () {
    test('relit la réclamation sous `reclamation`', () async {
      espion.repond({'success': true, 'reclamation': reclamationBack()});
      final r = await source.getReclamation('r-1');
      expect(espion.appel, 'GET /reclamations/r-1');
      expect(r.commentaireAdmin, isNull);
    });

    test('404 « Réclamation introuvable »', () async {
      espion.repondErreur(404,
          corps: {'success': false, 'message': 'Réclamation introuvable'});
      try {
        await source.getReclamation('autre');
        fail('DioException attendue');
      } on DioException catch (e) {
        expect(e.response?.statusCode, 404);
        expect(messageErreurApi(e), 'Réclamation introuvable');
      }
    });
  });
}
