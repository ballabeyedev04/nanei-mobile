import 'dart:async';
import 'dart:io';

import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:nanei/core/errors/failure.dart';
import 'package:nanei/core/utils/pagination.dart';
import 'package:nanei/features/avis/domain/entities/avis_entity.dart';
import 'package:nanei/features/avis/domain/usecases/donner_avis.dart';
import 'package:nanei/features/avis/domain/usecases/get_mes_avis.dart';
import 'package:nanei/features/avis/presentation/cubit/avis_cubit.dart';
import 'package:nanei/features/home/domain/entities/colis.dart';
import 'package:nanei/features/home/domain/entities/personne.dart';
import 'package:nanei/features/home/presentation/pages/client/colis_detail_page.dart';
import 'package:nanei/features/reclamations/domain/repositories/reclamation_repository.dart';
import 'package:nanei/features/reclamations/presentation/cubit/reclamations_cubit.dart';
import 'package:nanei/injection_container.dart';

import '../../../../../helpers/dio_espion.dart';
import '../../../../../helpers/environnement.dart';
import '../../../../../helpers/pompe_page.dart';

class _GetMesAvis extends Mock implements GetMesAvis {}

class _DonnerAvis extends Mock implements DonnerAvis {}

class _DepotReclamations extends Mock implements ReclamationRepository {}

/// Détail d'un colis : deux appels `sl<Dio>()` directs (preuve de livraison,
/// étiquette PDF).
///
/// ## Ce que ce fichier rend impossible
///
///  - la preuve demandée ailleurs que `GET /colis/:id/preuve` (route montée
///    sous `/nanei`, `preuve.route.js`) ou relue ailleurs que sous
///    `preuve.photo_url` : la photo n'apparaîtrait jamais ;
///  - une preuve demandée pour un colis NON livré (403/404 inutiles) ;
///  - « Aucune preuve disponible » (404) qui casserait l'écran ;
///  - l'étiquette demandée en JSON au lieu d'octets (`ResponseType.bytes`) :
///    le PDF serait corrompu ;
///  - un `setState()` après fermeture de l'écran quand la preuve arrive en
///    retard (exception « setState() called after dispose() »).
void main() {
  late DioEspion espion;
  late _GetMesAvis getMesAvis;

  setUpAll(initialiserEnvironnementDeTest);

  setUp(() async {
    await viderSl();
    espion = DioEspion();
    getMesAvis = _GetMesAvis();
    when(() => getMesAvis(page: any(named: 'page'), limit: any(named: 'limit')))
        .thenAnswer((_) async => Right<Failure, PageResultat<AvisEntity>>(
            PageResultat<AvisEntity>.vide()));
    enregistrerDio(dioDeTest(espion));
    remplacerDansSl<GetMesAvis>(getMesAvis);
    sl.registerFactory<AvisCubit>(
        () => AvisCubit(donnerAvis: _DonnerAvis(), getMesAvis: getMesAvis));
    sl.registerFactory<ReclamationsCubit>(
        () => ReclamationsCubit(repository: _DepotReclamations()));
  });

  tearDown(viderSl);

  Colis colis({String statut = 'livre'}) => Colis(
        id: 'c-1',
        reference: 'COL-2026-A1B2C3-4567',
        recepteur: const Personne(
            id: 'u-2', nom: 'Diallo', prenom: 'Awa', email: 'awa@exemple.ml'),
        poids: 12.5,
        prix: 87.5,
        destination: 'Mali',
        statut: statut,
        type: 'Vêtement',
        createdAt: DateTime(2026, 10, 1),
      );

  Image? imagePreuve(WidgetTester tester) {
    final images = tester.widgetList<Image>(find.byType(Image)).where(
        (i) => i.image is NetworkImage);
    return images.isEmpty ? null : images.first;
  }

  testWidgets('colis livré : GET /colis/:id/preuve, photo relue sous preuve.photo_url',
      (tester) async {
    espion.repond({
      'success': true,
      'preuve': {
        'id': 'p-1',
        'colis_id': 'c-1',
        'photo_url': 'https://cdn.test/nanei/preuves/p-1.jpg',
        'commentaire': null,
        'gps_lat': null,
        'gps_lng': null,
      },
    });

    await pomperPage(tester, ColisDetailPage(colis: colis(), isReception: false));
    await laisserRepondre(tester);

    expect(espion.appel, 'GET /colis/c-1/preuve');
    expect((imagePreuve(tester)!.image as NetworkImage).url,
        'https://cdn.test/nanei/preuves/p-1.jpg');
    expect(tester.takeException(), isNull);
  });

  testWidgets('404 « Aucune preuve disponible » : écran intact', (tester) async {
    espion.repondErreur(404,
        corps: {'success': false, 'message': 'Aucune preuve disponible'});

    await pomperPage(tester, ColisDetailPage(colis: colis(), isReception: true));
    await laisserRepondre(tester);

    expect(imagePreuve(tester), isNull);
    expect(find.text('Preuve non disponible'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('colis non livré : aucune demande de preuve', (tester) async {
    await pomperPage(
        tester, ColisDetailPage(colis: colis(statut: 'recupere'), isReception: false));
    await laisserRepondre(tester);

    expect(espion.requetes, isEmpty);
    expect(find.text('Preuve de livraison'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('écran quitté avant la réponse : aucune exception', (tester) async {
    final feuVert = Completer<void>();
    espion.repond({
      'success': true,
      'preuve': {'photo_url': 'https://cdn.test/p.jpg'},
    }, apres: feuVert.future);

    await pomperPage(
      tester,
      Builder(
        builder: (context) => Scaffold(
          body: ElevatedButton(
            onPressed: () => Navigator.of(context).push(MaterialPageRoute(
                builder: (_) => ColisDetailPage(colis: colis(), isReception: false))),
            child: const Text('ouvrir'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('ouvrir'));
    // La preuve est en attente : l'indicateur tourne, pas de pumpAndSettle.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(espion.requetes, hasLength(1));
    Navigator.of(tester.element(find.byType(ColisDetailPage))).pop();
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    expect(find.byType(ColisDetailPage, skipOffstage: false), findsNothing);

    feuVert.complete();
    await laisserRepondre(tester);
    expect(tester.takeException(), isNull);
  });

  testWidgets('étiquette : GET /etiquettes/:id en OCTETS, PDF écrit puis ouvert',
      (tester) async {
    final dossier = Directory.systemTemp.createTempSync('etiquette_test');
    addTearDown(() => dossier.deleteSync(recursive: true));
    final ouverts = simulerGreffonsFichiers(dossier);
    final pdf = [0x25, 0x50, 0x44, 0x46, 0x2D, 0x31, 0x2E, 0x34]; // %PDF-1.4
    espion.repond({'success': true, 'preuve': null}, pour: '/colis/c-1/preuve');
    espion.repondOctets(pdf, pour: '/etiquettes/c-1');

    await pomperPage(tester, ColisDetailPage(colis: colis(), isReception: false));
    await laisserRepondre(tester);

    await tester.ensureVisible(find.text('Étiquette'));
    await tester.runAsync(() async {
      await tester.tap(find.text('Étiquette'));
      for (var i = 0; i < 20 && ouverts.isEmpty; i++) {
        await Future<void>.delayed(const Duration(milliseconds: 50));
      }
    });
    await tester.pump();

    final requete = espion.requetePour('/etiquettes/c-1');
    expect(requete.method, 'GET');
    expect(requete.responseType, ResponseType.bytes);
    // Nom lisible (référence), pas l'UUID interne.
    expect(ouverts.single, endsWith('Etiquette-COL-2026-A1B2C3-4567.pdf'));
    expect(File(ouverts.single).readAsBytesSync(), pdf);
  });
}
