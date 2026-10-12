import 'package:flutter_test/flutter_test.dart';
import 'package:nanei/core/utils/pagination.dart';

void main() {
  group('InfoPagination.depuisJson', () {
    test('lit le bloc pagination du back', () {
      final p = InfoPagination.depuisJson(
        {'page': 2, 'limit': 20, 'total': 137, 'pages': 7},
        nbElements: 20,
      );
      expect(p, const InfoPagination(page: 2, limit: 20, total: 137, pages: 7));
      expect(p.aPrecedente, isTrue);
      expect(p.aSuivante, isTrue);
    });

    test('pagination absente → une seule page avec tous les éléments', () {
      final p = InfoPagination.depuisJson(null, nbElements: 5);
      expect(p.page, 1);
      expect(p.pages, 1);
      expect(p.total, 5);
      expect(p.aPrecedente, isFalse);
      expect(p.aSuivante, isFalse);
    });

    test('dernière page : pas de suivante', () {
      final p = InfoPagination.depuisJson(
          {'page': 7, 'limit': 20, 'total': 137, 'pages': 7},
          nbElements: 17);
      expect(p.aSuivante, isFalse);
      expect(p.aPrecedente, isTrue);
    });
  });

  group('PageResultat.depuisReponse', () {
    test('liste + pagination', () {
      final r = PageResultat.depuisReponse<String>(
        {
          'contacts': [
            {'n': 'a'},
            {'n': 'b'},
          ],
          'pagination': {'page': 1, 'limit': 2, 'total': 3, 'pages': 2},
        },
        const ['contacts', 'data'],
        (j) => j['n'] as String,
      );
      expect(r.elements, ['a', 'b']);
      expect(r.pagination.pages, 2);
      expect(r.pagination.total, 3);
    });

    test('clé alternative et réponse non paginée', () {
      final r = PageResultat.depuisReponse<String>(
        {
          'data': [
            {'n': 'x'},
          ],
        },
        const ['contacts', 'data'],
        (j) => j['n'] as String,
      );
      expect(r.elements, ['x']);
      expect(r.pagination.pages, 1);
      expect(r.pagination.total, 1);
    });

    test('corps vide', () {
      final r = PageResultat.depuisReponse<String>(
          null, const ['data'], (j) => j['n'] as String);
      expect(r.elements, isEmpty);
      expect(r.pagination.pages, 1);
    });
  });

  test('parametresPagination', () {
    expect(parametresPagination(), isEmpty);
    expect(parametresPagination(page: 3), {'page': 3, 'limit': kTaillePage});
    expect(parametresPagination(page: 2, limit: 10), {'page': 2, 'limit': 10});
  });

  group('chargerPageNonVide', () {
    PageResultat<int> page(int n, List<int> elements, {int pages = 3}) =>
        PageResultat(
          elements: elements,
          pagination: InfoPagination(
              page: n, limit: 20, total: 41, pages: pages),
        );

    test('page non vide : un seul appel', () async {
      final appels = <int>[];
      final r = await chargerPageNonVide<int>(2, (p) async {
        appels.add(p);
        return page(p, [1, 2]);
      });
      expect(appels, [2]);
      expect(r.pagination.page, 2);
    });

    test('page devenue vide → repli sur la dernière page existante', () async {
      final appels = <int>[];
      final r = await chargerPageNonVide<int>(3, (p) async {
        appels.add(p);
        return p == 3 ? page(3, [], pages: 2) : page(p, [9], pages: 2);
      });
      expect(appels, [3, 2]);
      expect(r.elements, [9]);
    });

    test('page 1 vide : pas de repli', () async {
      final appels = <int>[];
      await chargerPageNonVide<int>(1, (p) async {
        appels.add(p);
        return page(1, [], pages: 1);
      });
      expect(appels, [1]);
    });
  });
  group('par_statut', () {
    test('lu depuis la réponse (toutes pages, indépendant du filtre)', () {
      final r = PageResultat.depuisReponse<String>(
        {
          'data': [
            {'n': 'a'},
          ],
          'par_statut': {'en_attente': 3, 'recupere': 1, 'livre': '5', 'total': 9},
          'pagination': {'page': 1, 'limit': 20, 'total': 3, 'pages': 1},
        },
        const ['data'],
        (j) => j['n'] as String,
      );
      expect(r.parStatut,
          {'en_attente': 3, 'recupere': 1, 'livre': 5, 'total': 9});
      expect(r.compte('livre'), 5);
      expect(r.compte('inconnu'), 0);
    });

    test('absent → vide', () {
      final r = PageResultat.depuisReponse<String>(
          {'data': []}, const ['data'], (j) => j['n'] as String);
      expect(r.parStatut, isEmpty);
    });

    test('additionnerParStatut (envoyés + reçus)', () {
      expect(
        additionnerParStatut(
          {'en_attente': 1, 'livre': 2, 'total': 3},
          {'en_attente': 4, 'recupere': 1, 'total': 5},
        ),
        {'en_attente': 5, 'livre': 2, 'recupere': 1, 'total': 8},
      );
    });
  });

  test('parametreStatut : rien pour « tous »', () {
    expect(parametreStatut(null), isEmpty);
    expect(parametreStatut('tous'), isEmpty);
    expect(parametreStatut('livre'), {'statut': 'livre'});
  });
}
