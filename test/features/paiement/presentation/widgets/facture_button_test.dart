import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nanei/features/paiement/presentation/widgets/facture_button.dart';

import '../../../../helpers/dio_espion.dart';
import '../../../../helpers/environnement.dart';
import '../../../../helpers/pompe_page.dart';

/// Bouton « Facture » — appel `sl<Dio>()` direct, réponse BINAIRE.
///
/// ## Ce que ce fichier rend impossible
///
///  - l'aperçu demandé ailleurs que `GET /factures/:id` et le téléchargement
///    ailleurs que `GET /factures/:id/download` (`facture.route.js`) ;
///  - un PDF lu en JSON/texte (octets corrompus) : `ResponseType.bytes` et
///    `Accept: application/pdf` sont exigés ;
///  - un refus du back (400 « Facture disponible uniquement après paiement
///    validé », 403) affiché en charabia : en mode octets, le JSON d'erreur
///    arrive LUI AUSSI en octets et doit être décodé ;
///  - un 401 sans corps exploitable sans message de session expirée.
void main() {
  late DioEspion espion;
  late Directory dossier;
  late List<String> ouverts;

  setUpAll(initialiserEnvironnementDeTest);

  setUp(() async {
    await viderSl();
    espion = DioEspion();
    enregistrerDio(dioDeTest(espion));
    dossier = Directory.systemTemp.createTempSync('facture_test');
  });

  tearDown(() async {
    await viderSl();
    if (dossier.existsSync()) dossier.deleteSync(recursive: true);
  });

  const pdf = [0x25, 0x50, 0x44, 0x46, 0x2D, 0x31, 0x2E, 0x37];

  Future<void> choisir(WidgetTester tester, String option) async {
    ouverts = simulerGreffonsFichiers(dossier);
    await pomperPage(
      tester,
      const Scaffold(
        body: Center(
            child: FactureButton(paiementId: 'p-1', reference: 'COL-2026-A1B2C3-4567')),
      ),
    );
    await tester.tap(find.text('Facture'));
    await tester.pumpAndSettle();
    await tester.tap(find.text(option));
    // Alterne images (code de l'écran, zone de test) et vraies E/S (écriture
    // du PDF) : on attend l'ouverture, ou ~3 s quand le serveur refuse.
    for (var i = 0; i < 60 && ouverts.isEmpty; i++) {
      await tester.pump(const Duration(milliseconds: 20));
      await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 30)));
    }
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
  }

  testWidgets('aperçu : GET /factures/:id en octets, PDF écrit puis ouvert',
      (tester) async {
    espion.repondOctets(pdf);
    await choisir(tester, 'Aperçu de la facture');

    final r = espion.requete;
    expect('${r.method} ${r.path}', 'GET /factures/p-1');
    expect(r.responseType, ResponseType.bytes);
    expect(r.headers['Accept'], 'application/pdf');
    expect(ouverts.single, endsWith('facture-COL-2026-A1B2C3-4567.pdf'));
    expect(File(ouverts.single).readAsBytesSync(), pdf);
  });

  testWidgets('téléchargement : GET /factures/:id/download', (tester) async {
    espion.repondOctets(pdf);
    await choisir(tester, 'Télécharger le PDF');

    expect(espion.appel, 'GET /factures/p-1/download');
    expect(espion.requete.responseType, ResponseType.bytes);
    expect(ouverts.single, endsWith('Facture-COL-2026-A1B2C3-4567.pdf'));
    await tester.pumpAndSettle(const Duration(seconds: 5));
  });

  testWidgets('400 du back (JSON en octets) : message décodé et affiché',
      (tester) async {
    espion.repondOctets(
      utf8.encode(jsonEncode({
        'success': false,
        'message': 'Facture disponible uniquement après paiement validé',
      })),
      statut: 400,
      contentType: 'application/json; charset=utf-8',
    );
    await choisir(tester, 'Aperçu de la facture');

    expect(find.text('Facture disponible uniquement après paiement validé'),
        findsOneWidget);
    expect(ouverts, isEmpty);
    await tester.pumpAndSettle(const Duration(seconds: 5));
  });

  testWidgets('401 sans message : « Session expirée »', (tester) async {
    espion.repondOctets(const [], statut: 401, contentType: 'application/json');
    await choisir(tester, 'Aperçu de la facture');

    expect(find.text('Session expirée, veuillez vous reconnecter'), findsOneWidget);
    await tester.pumpAndSettle(const Duration(seconds: 5));
  });
}
