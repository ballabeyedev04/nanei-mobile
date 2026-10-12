import 'package:flutter_test/flutter_test.dart';
import 'package:nanei/features/contacts/data/datasources/contact_remote_datasource.dart';
import 'package:nanei/features/contacts/data/repositories/contact_repository_impl.dart';

import '../../../../helpers/dio_espion.dart';
import '../../../../helpers/environnement.dart';

/// Dépôt Contacts : transmission fidèle de la page et des erreurs.
///
/// ## Ce que ce fichier rend impossible
///
///  - perdre la PAGINATION en convertissant les modèles en entités (la barre
///    afficherait « Page 1 sur 1 » quel que soit le nombre de contacts) ;
///  - avaler une erreur du serveur : le cubit doit la recevoir pour
///    afficher l'écran d'erreur.
void main() {
  setUpAll(initialiserEnvironnementDeTest);

  late DioEspion espion;
  late ContactRepositoryImpl depot;

  setUp(() {
    espion = DioEspion();
    depot = ContactRepositoryImpl(
        remoteDataSource: ContactRemoteDataSourceImpl(dio: dioDeTest(espion)));
  });

  test('page et pagination transmises', () async {
    espion.repond({
      'success': true,
      'contacts': [
        {'id': 'k1', 'nom': 'Diallo', 'prenom': 'Awa', 'telephone': '70'},
      ],
      'pagination': {'page': 3, 'limit': 20, 'total': 41, 'pages': 3},
    });

    final r = await depot.getContacts(page: 3, limit: 20);

    expect(r.elements.single.id, 'k1');
    expect(r.pagination.page, 3);
    expect(r.pagination.pages, 3);
  });

  test('création, modification, suppression : délégués au bon appel', () async {
    espion.repond({'success': true, 'contact': {'id': 'k1', 'nom': 'D'}});
    await depot.createContact({'nom': 'D'});
    await depot.updateContact('k1', {'nom': 'E'});
    await depot.deleteContact('k1');
    expect(espion.appels, ['POST /contacts', 'PUT /contacts/k1', 'DELETE /contacts/k1']);
  });

  test('erreur du serveur : propagée (pas avalée)', () async {
    espion.repondErreur(500, corps: {'success': false, 'message': 'Erreur serveur'});
    expect(() => depot.getContacts(), throwsA(anything));
  });
}
