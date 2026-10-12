import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nanei/core/widgets/support_sheet.dart';

import '../../helpers/dio_espion.dart';
import '../../helpers/environnement.dart';
import '../../helpers/pompe_page.dart';

/// Feuille « Contacter le support » — appel `sl<Dio>()` direct.
///
/// ## Ce que ce fichier rend impossible
///
///  - un message parti vers une autre route que `POST /messages`, ou avec
///    d'autres noms de champs que ceux lus par `messageClient.controller.js`
///    (`email`, `objet`, `description`) : le back répond « Les champs email,
///    objet et description sont obligatoires » ;
///  - un formulaire invalide envoyé quand même ;
///  - un refus du back (e-mail invalide, objet trop long) remplacé par un
///    message générique, ou un écran « Message envoyé ! » affiché malgré
///    l'échec.
void main() {
  late DioEspion espion;

  setUpAll(initialiserEnvironnementDeTest);

  setUp(() async {
    await viderSl();
    espion = DioEspion();
    remplacerDansSl<Dio>(dioDeTest(espion));
  });

  tearDown(viderSl);

  Future<void> ouvrir(WidgetTester tester) async {
    await pomperPage(
      tester,
      Builder(
        builder: (context) => Scaffold(
          body: Center(
            child: ElevatedButton(
              onPressed: () => showSupportSheet(context),
              child: const Text('Aide'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Aide'));
    await tester.pumpAndSettle();
  }

  Future<void> remplir(WidgetTester tester) async {
    await tester.enterText(
        find.widgetWithText(TextFormField, 'Votre email'), ' awa@exemple.ml ');
    await tester.enterText(find.widgetWithText(TextFormField, 'Objet'), 'Colis bloqué');
    await tester.enterText(
        find.widgetWithText(TextFormField, 'Description'), 'Toujours en attente.');
  }

  testWidgets('POST /messages { email, objet, description } puis confirmation',
      (tester) async {
    espion.repond({
      'success': true,
      'message': 'Message envoyé avec succès. Nous vous répondrons via email.',
      'data': {'id': 'm-1'},
    }, statut: 201);
    await ouvrir(tester);
    await remplir(tester);

    await tester.tap(find.text('Envoyer le message'));
    await tester.pumpAndSettle();

    expect(espion.appel, 'POST /messages');
    expect(corpsEnvoye(espion.requete), {
      'email': 'awa@exemple.ml',
      'objet': 'Colis bloqué',
      'description': 'Toujours en attente.',
    });
    expect(find.text('Message envoyé !'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('formulaire invalide : aucun envoi', (tester) async {
    await ouvrir(tester);
    await tester.enterText(find.widgetWithText(TextFormField, 'Votre email'), 'a@b');

    await tester.tap(find.text('Envoyer le message'));
    await tester.pumpAndSettle();

    expect(espion.requetes, isEmpty);
    expect(find.text('Objet requis'), findsOneWidget);
    expect(find.text('Description requise'), findsOneWidget);
  });

  testWidgets('400 du back : son message s’affiche, pas de confirmation',
      (tester) async {
    espion.repondErreur(400,
        corps: {'success': false, 'message': 'Adresse email invalide.'});
    await ouvrir(tester);
    await remplir(tester);

    await tester.tap(find.text('Envoyer le message'));
    await laisserRepondre(tester);

    expect(find.text('Adresse email invalide.'), findsOneWidget);
    expect(find.text('Message envoyé !'), findsNothing);
    await laisserToastSeFermer(tester);
  });
}
