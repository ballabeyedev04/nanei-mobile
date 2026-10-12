import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nanei/features/reclamations/data/datasources/reclamation_remote_datasource.dart';
import 'package:nanei/features/reclamations/data/repositories/reclamation_repository_impl.dart';
import 'package:nanei/features/reclamations/presentation/cubit/reclamations_cubit.dart';
import 'package:nanei/features/reclamations/presentation/pages/nouvelle_reclamation_page.dart';

import '../../../../helpers/dio_espion.dart';
import '../../../../helpers/environnement.dart';
import '../../../../helpers/pompe_page.dart';

/// Écran « Nouvelle réclamation », de la liste des colis jusqu'au multipart.
///
/// ## Ce que ce fichier rend impossible
///
///  - une liste de colis limitée aux colis ENVOYÉS : le back accepte aussi
///    la réclamation du DESTINATAIRE (c'est souvent lui qui constate un
///    colis endommagé). L'écran lit `/client/colis-envoyes` ET
///    `/client/colis-recus`, sans pagination (liste complète), sans doublon ;
///  - le libellé « Colis endommagé » envoyé avec une autre valeur que
///    `endommagé` (ENUM du back, avec accent) ;
///  - un refus du back (403, colis d'un autre) qui fermerait l'écran comme
///    si la réclamation était partie.
void main() {
  late DioEspion espion;

  setUpAll(initialiserEnvironnementDeTest);

  setUp(() async {
    await viderSl();
    espion = DioEspion();
    remplacerDansSl<Dio>(dioDeTest(espion));
    espion.repond({
      'data': [
        {'id': 'c-1', 'reference': 'COL-A', 'statut': 'livre'},
        {'id': 'c-2', 'reference': 'COL-B', 'statut': 'livre'},
      ],
      'par_statut': {},
    }, pour: 'GET /client/colis-envoyes');
    espion.repond({
      'data': [
        // Colis envoyé à soi-même : présent dans les deux listes.
        {'id': 'c-2', 'reference': 'COL-B', 'statut': 'livre'},
        {'id': 'c-3', 'reference': 'COL-C', 'statut': 'recupere'},
      ],
      'par_statut': {},
    }, pour: 'GET /client/colis-recus');
  });

  tearDown(viderSl);

  Future<void> monter(WidgetTester tester, {String? colisId}) async {
    final cubit = ReclamationsCubit(
      repository: ReclamationRepositoryImpl(
        remoteDataSource: ReclamationRemoteDataSourceImpl(dio: dioDeTest(espion)),
      ),
    );
    addTearDown(cubit.close);
    await pomperPage(
      tester,
      Builder(
        builder: (context) => Scaffold(
          body: ElevatedButton(
            onPressed: () => Navigator.of(context).push(MaterialPageRoute(
                builder: (_) => NouvelleReclamationPage(colisIdPreRempli: colisId))),
            child: const Text('ouvrir'),
          ),
        ),
      ),
      enveloppe: (app) =>
          BlocProvider<ReclamationsCubit>.value(value: cubit, child: app),
    );
    await tester.tap(find.text('ouvrir'));
    await laisserRepondre(tester);
  }

  testWidgets('colis envoyés ET reçus, complets et sans doublon', (tester) async {
    await monter(tester, colisId: 'c-3');

    expect(espion.appels.toSet(),
        {'GET /client/colis-envoyes', 'GET /client/colis-recus'});
    for (final r in espion.requetes) {
      expect(r.queryParameters, isEmpty, reason: r.path);
    }
    // Présélection d'un colis REÇU.
    expect(find.text('#COL-C'), findsOneWidget);

    await tester.tap(find.text('#COL-C'));
    await tester.pumpAndSettle();
    expect(find.text('#COL-A'), findsWidgets);
    expect(find.text('#COL-B'), findsNWidgets(1));
    expect(tester.takeException(), isNull);
  });

  testWidgets('envoi : multipart colis_id / type « endommagé » / description',
      (tester) async {
    espion.repond({
      'success': true,
      'message': 'Réclamation créée',
      'reclamation': {'id': 'r-1', 'colis_id': 'c-2', 'type': 'endommagé', 'photos': []},
    }, statut: 201, pour: 'POST /reclamations');
    await monter(tester, colisId: 'c-2');

    await tester.tap(find.text('Colis perdu'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Colis endommagé').last);
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField), 'Carton écrasé');
    await tester.ensureVisible(find.text('Envoyer la réclamation'));
    await tester.tap(find.text('Envoyer la réclamation'));
    await laisserRepondre(tester);

    final requete = espion.requetePour('/reclamations');
    expect(requete.method, 'POST');
    final fd = requete.data as FormData;
    expect(Map.fromEntries(fd.fields), {
      'colis_id': 'c-2',
      'type': 'endommagé',
      'description': 'Carton écrasé',
    });
    // Écran refermé, confirmation affichée.
    expect(find.text('ouvrir'), findsOneWidget);
    expect(find.text('Réclamation envoyée avec succès !'), findsOneWidget);
    await tester.pumpAndSettle(const Duration(seconds: 5));
  });

  testWidgets('refus 403 : message du back, l’écran reste ouvert', (tester) async {
    espion.repondErreur(403,
        corps: {'success': false, 'message': 'Ce colis ne vous appartient pas'},
        pour: 'POST /reclamations');
    await monter(tester, colisId: 'c-1');

    await tester.enterText(find.byType(TextFormField), 'Perdu depuis 3 semaines');
    await tester.ensureVisible(find.text('Envoyer la réclamation'));
    await tester.tap(find.text('Envoyer la réclamation'));
    await laisserRepondre(tester);

    expect(find.text('Ce colis ne vous appartient pas'), findsOneWidget);
    expect(find.text('Envoyer la réclamation'), findsOneWidget);
    await tester.pumpAndSettle(const Duration(seconds: 5));
  });
}
