import 'package:flutter_test/flutter_test.dart';
import 'package:nanei/features/reclamations/data/datasources/reclamation_remote_datasource.dart';
import 'package:nanei/features/reclamations/data/repositories/reclamation_repository_impl.dart';

import '../../../../helpers/dio_espion.dart';
import '../../../../helpers/environnement.dart';

/// Dépôt Réclamations.
///
/// ## Ce que ce fichier rend impossible
///
///  - perdre la pagination en convertissant les modèles en entités ;
///  - avaler un refus du serveur : le cubit en a besoin pour afficher le
///    message (« Ce colis ne vous appartient pas »).
void main() {
  setUpAll(initialiserEnvironnementDeTest);

  late DioEspion espion;
  late ReclamationRepositoryImpl depot;

  setUp(() {
    espion = DioEspion();
    depot = ReclamationRepositoryImpl(
        remoteDataSource: ReclamationRemoteDataSourceImpl(dio: dioDeTest(espion)));
  });

  test('page et pagination transmises', () async {
    espion.repond({
      'success': true,
      'reclamations': [
        {'id': 'r1', 'colis_id': 'c1', 'type': 'perdu', 'statut': 'en_cours', 'photos': []},
      ],
      'pagination': {'page': 2, 'limit': 20, 'total': 21, 'pages': 2},
    });

    final r = await depot.getReclamations(page: 2, limit: 20);

    expect(r.elements.single.statut, 'en_cours');
    expect(r.pagination.page, 2);
    expect(r.pagination.total, 21);
  });

  test('détail et refus', () async {
    espion.repond({
      'success': true,
      'reclamation': {'id': 'r1', 'colis_id': 'c1', 'type': 'retard', 'photos': null},
    });
    final r = await depot.getReclamation('r1');
    expect(r.type, 'retard');
    // `photos` NULL côté back : liste vide, pas de plantage.
    expect(r.photos, isEmpty);

    espion.repondErreur(403, corps: {'success': false, 'message': 'Ce colis ne vous appartient pas'});
    expect(
        () => depot.creerReclamation(
            colisId: 'c', type: 'perdu', description: 'd', photos: const []),
        throwsA(anything));
  });
}
