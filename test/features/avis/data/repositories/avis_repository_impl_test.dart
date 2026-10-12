import 'package:flutter_test/flutter_test.dart';
import 'package:nanei/core/errors/failure.dart';
import 'package:nanei/features/avis/data/datasources/avis_remote_datasource.dart';
import 'package:nanei/features/avis/data/repositories/avis_repository_impl.dart';

import '../../../../helpers/dio_espion.dart';
import '../../../../helpers/environnement.dart';

/// Dépôt Avis : traduction des réponses du back en succès / échecs métier.
///
/// ## Ce que ce fichier rend impossible
///
///  - un 409 (« Un avis existe déjà ») présenté comme une ERREUR : l'écran
///    doit le traiter comme « déjà noté » ([AvisDejaDonneFailure]) ;
///  - un message du back (400, 403) remplacé par un texte générique ;
///  - un plantage du dépôt quand la réponse d'erreur n'est PAS du JSON (page
///    HTML d'un proxy nginx en 502) : l'exception s'échappait du `catch` et
///    l'écran restait bloqué sur son indicateur de chargement.
void main() {
  setUpAll(initialiserEnvironnementDeTest);

  late DioEspion espion;
  late AvisRepositoryImpl depot;

  setUp(() {
    espion = DioEspion();
    depot = AvisRepositoryImpl(
        remoteDataSource: AvisRemoteDataSourceImpl(dio: dioDeTest(espion)));
  });

  Future<Failure> echec(Future<dynamic> resultat) async =>
      (await resultat).fold((f) => f, (_) => fail('échec attendu'));

  test('201 : succès', () async {
    espion.repond({'success': true, 'message': 'Avis enregistré'}, statut: 201);
    final r = await depot.donnerAvis(colisId: 'c-1', note: 5);
    expect(r.isRight(), isTrue);
  });

  test('409 : AvisDejaDonneFailure (traité comme « déjà noté »)', () async {
    espion.repondErreur(409,
        corps: {'success': false, 'message': 'Un avis existe déjà pour ce colis'});
    final f = await echec(depot.donnerAvis(colisId: 'c-1', note: 5));
    expect(f, isA<AvisDejaDonneFailure>());
  });

  test('400 / 403 : message du back', () async {
    espion.repondErreur(400, corps: {
      'success': false,
      'message': 'Vous pouvez donner un avis uniquement après livraison',
    });
    espion.repondErreur(403,
        corps: {'success': false, 'message': 'Ce colis ne vous appartient pas'});

    final f400 = await echec(depot.donnerAvis(colisId: 'c-1', note: 5));
    final f403 = await echec(depot.donnerAvis(colisId: 'c-2', note: 5));
    expect(f400, isA<ServerFailure>());
    expect(f400.errorMessage, 'Vous pouvez donner un avis uniquement après livraison');
    expect(f403.errorMessage, 'Ce colis ne vous appartient pas');
  });

  test('500 : message générique (aucun détail technique)', () async {
    espion.repondErreur(500, corps: {'success': false, 'message': 'Erreur serveur'});
    final f = await echec(depot.mesAvis());
    expect(f.errorMessage, 'Erreur serveur. Réessayez plus tard.');
  });

  test('502 en HTML (proxy) : un échec propre, pas une exception', () async {
    espion.repondTexte('<html><body>502 Bad Gateway</body></html>', statut: 502);
    final f = await echec(depot.donnerAvis(colisId: 'c-1', note: 5));
    expect(f, isA<ServerFailure>());
  });

  test('403 en HTML (WAF) : un échec propre, pas une exception', () async {
    espion.repondTexte('<html>Forbidden</html>', statut: 403);
    final f = await echec(depot.mesAvis(page: 1, limit: 20));
    expect(f, isA<ServerFailure>());
    expect(f.errorMessage, isNotEmpty);
  });

  test('coupure réseau : message de connexion', () async {
    espion.coupeReseau();
    final f = await echec(depot.mesAvis());
    expect(f.errorMessage, 'Impossible de joindre le serveur.');
  });

  test('mesAvis : éléments et pagination transmis', () async {
    espion.repond({
      'success': true,
      'avis': [
        {'id': 'a1', 'colis_id': 'c1', 'note': 4},
      ],
      'pagination': {'page': 1, 'limit': 20, 'total': 1, 'pages': 1},
    });
    final r = await depot.mesAvis(page: 1, limit: 20);
    final page = r.getOrElse(() => fail('succès attendu'));
    expect(page.elements.single.colisId, 'c1');
    expect(page.pagination.total, 1);
  });
}
