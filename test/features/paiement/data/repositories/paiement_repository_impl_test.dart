import 'package:flutter_test/flutter_test.dart';
import 'package:nanei/core/errors/failure.dart';
import 'package:nanei/features/paiement/data/datasources/paiement_remote_datasource.dart';
import 'package:nanei/features/paiement/data/repositories/paiement_repository_impl.dart';

import '../../../../helpers/dio_espion.dart';
import '../../../../helpers/environnement.dart';

/// Dépôt Paiements : succès / échecs métier.
///
/// ## Ce que ce fichier rend impossible
///
///  - perdre le message d'un refus (« Ce colis est déjà payé », « Moyen de
///    paiement invalide ») derrière un texte générique ;
///  - exposer un détail technique sur un 500 ;
///  - un plantage du dépôt sur une réponse d'erreur NON JSON (HTML d'un
///    proxy) : la liste des paiements restait bloquée en chargement.
void main() {
  setUpAll(initialiserEnvironnementDeTest);

  late DioEspion espion;
  late PaiementRepositoryImpl depot;

  setUp(() {
    espion = DioEspion();
    depot = PaiementRepositoryImpl(
        remoteDataSource: PaiementRemoteDataSourceImpl(dio: dioDeTest(espion)));
  });

  Future<Failure> echec(Future<dynamic> r) async =>
      (await r).fold((f) => f, (_) => fail('échec attendu'));

  test('initier : URL de paiement en succès', () async {
    espion.repond({
      'success': true,
      'data': {'checkoutUrl': 'https://pay.wave.com/c/x'},
    });
    final r = await depot.initierPaiement(colisId: 'c-1', moyenPaiement: 'wave');
    expect(r.getOrElse(() => ''), 'https://pay.wave.com/c/x');
  });

  test('initier : 400 « Moyen de paiement invalide » conservé', () async {
    espion.repondErreur(400,
        corps: {'success': false, 'message': 'Moyen de paiement invalide'});
    final f = await echec(depot.initierPaiement(colisId: 'c-1', moyenPaiement: 'cb'));
    expect(f.errorMessage, 'Moyen de paiement invalide');
  });

  test('initier : réponse sans URL → échec explicite', () async {
    espion.repond({'success': true, 'data': {}});
    final f = await echec(depot.initierPaiement(colisId: 'c-1', moyenPaiement: 'wave'));
    expect(f.errorMessage, contains('URL de paiement invalide'));
  });

  test('liste : 500 → message générique, sans détail technique', () async {
    espion.repondErreur(500, corps: {'success': false, 'message': 'Erreur serveur'});
    final f = await echec(depot.mesPaiements());
    expect(f.errorMessage, 'Erreur serveur. Réessayez plus tard.');
  });

  test('liste : 404 HTML (proxy mal routé) → échec propre', () async {
    espion.repondTexte('<html><body>Not Found</body></html>', statut: 404);
    final f = await echec(depot.mesPaiements(page: 1, limit: 20));
    expect(f, isA<ServerFailure>());
    expect(f.errorMessage, 'Erreur de paiement.');
  });

  test('liste : coupure réseau → message de connexion', () async {
    espion.coupeReseau();
    final f = await echec(depot.mesPaiements());
    expect(f.errorMessage, 'Impossible de joindre le serveur.');
  });

  test('liste : par_statut transmis jusqu’au bloc', () async {
    espion.repond({
      'success': true,
      'data': [],
      'par_statut': {'paye': 3, 'total': 3},
    });
    final r = await depot.mesPaiements(statut: 'paye');
    expect(r.getOrElse(() => fail('succès attendu')).compte('paye'), 3);
  });
}
