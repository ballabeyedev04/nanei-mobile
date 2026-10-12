import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nanei/core/utils/pagination.dart';
import 'package:nanei/core/widgets/barre_pagination.dart';

import '../../helpers/pompe_page.dart';

/// La barre « Précédent · Page X sur Y · Suivant » commune aux listes.
///
/// ## Ce que ce fichier rend impossible
///
///  - un bouton ACTIF aux extrémités : « Précédent » sur la page 1 demandait
///    la page 0, que le back ramène à 1 — un rechargement inutile qui fait
///    clignoter la liste ; « Suivant » sur la dernière page demandait une
///    page vide ;
///  - un double chargement : pendant qu'une page charge, les deux boutons
///    doivent être inertes, sinon deux taps rapides envoient deux requêtes
///    dont la plus lente écrase l'autre ;
///  - un mauvais numéro demandé : le rappel reçoit page ± 1, pas un index.
void main() {
  Future<List<int>> monter(WidgetTester tester, InfoPagination p,
      {bool chargement = false, String? libelleTotal}) async {
    final demandees = <int>[];
    await pomperPage(
      tester,
      Scaffold(
        body: BarrePagination(
          pagination: p,
          chargement: chargement,
          libelleTotal: libelleTotal,
          onPage: demandees.add,
        ),
      ),
    );
    return demandees;
  }

  testWidgets('page du milieu : les deux sens demandent page ± 1',
      (tester) async {
    final demandees = await monter(
      tester,
      const InfoPagination(page: 3, limit: 20, total: 137, pages: 7),
      libelleTotal: 'colis',
    );

    expect(find.text('Page 3 sur 7'), findsOneWidget);
    expect(find.text('137 colis'), findsOneWidget);

    await tester.tap(find.byKey(const Key('pagination_precedent')));
    await tester.tap(find.byKey(const Key('pagination_suivant')));
    expect(demandees, [2, 4]);
    expect(tester.takeException(), isNull);
  });

  testWidgets('première page : « Précédent » est inerte', (tester) async {
    final demandees = await monter(
        tester, const InfoPagination(page: 1, limit: 20, total: 41, pages: 3));

    await tester.tap(find.byKey(const Key('pagination_precedent')));
    await tester.tap(find.byKey(const Key('pagination_suivant')));
    expect(demandees, [2]);
  });

  testWidgets('dernière page : « Suivant » est inerte', (tester) async {
    final demandees = await monter(
        tester, const InfoPagination(page: 3, limit: 20, total: 41, pages: 3));

    await tester.tap(find.byKey(const Key('pagination_suivant')));
    await tester.tap(find.byKey(const Key('pagination_precedent')));
    expect(demandees, [2]);
  });

  testWidgets('pendant un chargement, aucun bouton ne répond', (tester) async {
    final demandees = await monter(
      tester,
      const InfoPagination(page: 2, limit: 20, total: 60, pages: 3),
      chargement: true,
    );

    await tester.tap(find.byKey(const Key('pagination_precedent')));
    await tester.tap(find.byKey(const Key('pagination_suivant')));
    expect(demandees, isEmpty);
  });

  testWidgets('sans libellé de total, le total n’est pas affiché',
      (tester) async {
    await monter(
        tester, const InfoPagination(page: 1, limit: 20, total: 5, pages: 1));
    expect(find.text('Page 1 sur 1'), findsOneWidget);
    expect(find.textContaining('5 '), findsNothing);
  });
}
