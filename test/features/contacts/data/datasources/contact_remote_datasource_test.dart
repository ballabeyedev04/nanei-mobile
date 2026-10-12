import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nanei/core/utils/api_error.dart';
import 'package:nanei/features/contacts/data/datasources/contact_remote_datasource.dart';

import '../../../../helpers/dio_espion.dart';
import '../../../../helpers/environnement.dart';

/// L'API Contacts favoris (`/contacts`, `/contacts/:id`).
///
/// ## Ce que ce fichier rend impossible
///
///  - la liste relue sous une mauvaise clé : le back renvoie `contacts`
///    (liste) et `contact` (création / modification), pas `data` ;
///  - le pays relu sous `pays` alors que la colonne est `pays_id` ;
///  - un `prenom` / `telephone` NULL côté back qui s'afficherait « null » ;
///  - une suppression envoyée sur le mauvais verbe ou le mauvais chemin, ou
///    un 404 (contact d'un autre) avalé en silence.
void main() {
  setUpAll(initialiserEnvironnementDeTest);

  late DioEspion espion;
  late ContactRemoteDataSourceImpl source;

  setUp(() {
    espion = DioEspion();
    source = ContactRemoteDataSourceImpl(dio: dioDeTest(espion));
  });

  Map<String, dynamic> contactBack({Object? prenom = 'Awa', Object? tel = '+22376001234'}) =>
      {
        'id': 'k-1',
        'utilisateur_id': 'u-1',
        'nom': 'Diallo',
        'prenom': prenom,
        'email': null,
        'telephone': tel,
        'ville': 'Bamako',
        'pays_id': 'pays-ml',
        'createdAt': '2026-10-01T10:00:00.000Z',
        'updatedAt': '2026-10-01T10:00:00.000Z',
      };

  test('GET /contacts : page/limit envoyés, relus sous `contacts`', () async {
    espion.repond({
      'success': true,
      'contacts': [contactBack(), contactBack(prenom: null, tel: null)],
      'pagination': {'page': 1, 'limit': 20, 'total': 2, 'pages': 1},
    });

    final r = await source.getContacts(page: 1, limit: 20);

    expect(espion.appel, 'GET /contacts');
    expect(espion.requete.queryParameters, {'page': 1, 'limit': 20});
    final k = r.elements.first;
    expect(k.nomComplet, 'Awa Diallo');
    expect(k.ville, 'Bamako');
    expect(k.pays, 'pays-ml');
    expect(k.email, isNull);
    // Valeurs NULL du back : chaînes vides, jamais « null ».
    expect(r.elements.last.prenom, '');
    expect(r.elements.last.telephone, '');
    expect(r.elements.last.initiales, 'D');
  });

  test('GET /contacts sans page : aucun paramètre (sélecteur de destinataire)',
      () async {
    espion.repond({'success': true, 'contacts': []});
    final r = await source.getContacts();
    expect(espion.requete.queryParameters, isEmpty);
    expect(r.elements, isEmpty);
  });

  test('POST /contacts : corps transmis tel quel, relu sous `contact`', () async {
    espion.repond({'success': true, 'message': 'Contact créé', 'contact': contactBack()},
        statut: 201);

    final donnees = {
      'nom': 'Diallo',
      'prenom': 'Awa',
      'email': null,
      'telephone': '+22376001234',
      'ville': 'Bamako',
    };
    final k = await source.createContact(donnees);

    expect(espion.appel, 'POST /contacts');
    expect(corpsEnvoye(espion.requete), donnees);
    expect(k.id, 'k-1');
  });

  test('POST /contacts sans nom : 400 « Le nom est obligatoire »', () async {
    espion.repondErreur(400,
        corps: {'success': false, 'message': 'Le nom est obligatoire'});
    try {
      await source.createContact({'nom': ''});
      fail('DioException attendue');
    } on DioException catch (e) {
      expect(messageErreurApi(e), 'Le nom est obligatoire');
    }
  });

  test('PUT /contacts/:id', () async {
    espion.repond({'success': true, 'message': 'Contact mis à jour', 'contact': contactBack()});
    await source.updateContact('k-1', {'ville': 'Kayes'});
    expect(espion.appel, 'PUT /contacts/k-1');
    expect(corpsEnvoye(espion.requete), {'ville': 'Kayes'});
  });

  test('DELETE /contacts/:id ; 404 d’un contact étranger remonte', () async {
    espion.repond({'success': true, 'message': 'Contact supprimé'});
    espion.repondErreur(404, corps: {'success': false, 'message': 'Contact introuvable'});

    await source.deleteContact('k-1');
    expect(espion.appel, 'DELETE /contacts/k-1');

    try {
      await source.deleteContact('k-autre');
      fail('DioException attendue');
    } on DioException catch (e) {
      expect(e.response?.statusCode, 404);
    }
  });
}
