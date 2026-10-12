import 'package:equatable/equatable.dart';

/// Taille de page utilisée par tous les écrans de liste de l'app.
const int kTaillePage = 20;

/// Bloc `pagination` renvoyé par le back quand `page` / `limit` sont passés :
/// `{ "page": 2, "limit": 20, "total": 137, "pages": 7 }`.
class InfoPagination extends Equatable {
  final int page;
  final int limit;
  final int total;
  final int pages;

  const InfoPagination({
    required this.page,
    required this.limit,
    required this.total,
    required this.pages,
  });

  /// État initial d'une liste pas encore chargée.
  static const InfoPagination initiale =
      InfoPagination(page: 1, limit: kTaillePage, total: 0, pages: 1);

  /// Réponse sans bloc `pagination` (ancien back, liste complète) : une seule
  /// page qui contient tous les éléments.
  factory InfoPagination.unePage(int nbElements) => InfoPagination(
        page: 1,
        limit: nbElements < 1 ? kTaillePage : nbElements,
        total: nbElements,
        pages: 1,
      );

  /// Lit `pagination` ; s'il est absent ou invalide → une seule page.
  factory InfoPagination.depuisJson(dynamic json, {required int nbElements}) {
    if (json is! Map) return InfoPagination.unePage(nbElements);
    int lire(String cle, int defaut) {
      final v = json[cle];
      if (v is num) return v.toInt();
      return int.tryParse('$v') ?? defaut;
    }

    final page = lire('page', 1);
    final limit = lire('limit', kTaillePage);
    final total = lire('total', nbElements);
    final pages = lire('pages', 1);
    return InfoPagination(
      page: page < 1 ? 1 : page,
      limit: limit < 1 ? kTaillePage : limit,
      total: total < 0 ? 0 : total,
      pages: pages < 1 ? 1 : pages,
    );
  }

  bool get aPrecedente => page > 1;
  bool get aSuivante => page < pages;

  @override
  List<Object?> get props => [page, limit, total, pages];
}

/// Une page de résultats d'une liste de l'API.
class PageResultat<T> {
  final List<T> elements;
  final InfoPagination pagination;

  /// Compteurs par statut sur TOUTES les pages (`par_statut` du back, ex.
  /// `{ en_attente, recupere, livre, total }`), indépendants du filtre.
  /// Vide si le back ne les renvoie pas.
  final Map<String, int> parStatut;

  const PageResultat({
    required this.elements,
    required this.pagination,
    this.parStatut = const {},
  });

  /// Compteur `par_statut[cle]` (0 si absent).
  int compte(String cle) => parStatut[cle] ?? 0;

  /// Résultat vide (une page, aucun élément).
  PageResultat.vide()
      : elements = const [],
        pagination = InfoPagination.unePage(0),
        parStatut = const {};

  /// Toute la liste en une seule page (réponse non paginée).
  PageResultat.unePage(List<T> elements)
      : this(elements: elements, pagination: InfoPagination.unePage(elements.length));

  /// Construit le résultat depuis le corps JSON d'une réponse de liste.
  /// [cles] : clé(s) possibles de la liste, la première présente est utilisée.
  static PageResultat<E> depuisReponse<E>(
    dynamic corps,
    List<String> cles,
    E Function(Map<String, dynamic> json) depuisJson,
  ) {
    final map = corps is Map ? corps : const {};
    List brut = const [];
    for (final cle in cles) {
      final v = map[cle];
      if (v is List) {
        brut = v;
        break;
      }
    }
    final elements =
        brut.map((e) => depuisJson(Map<String, dynamic>.from(e as Map))).toList();
    return PageResultat<E>(
      elements: elements,
      pagination:
          InfoPagination.depuisJson(map['pagination'], nbElements: elements.length),
      parStatut: lireParStatut(map['par_statut']),
    );
  }
}

/// Lit un objet `par_statut` (valeurs numériques) ; vide s'il est absent.
Map<String, int> lireParStatut(dynamic json) {
  if (json is! Map) return const {};
  final resultat = <String, int>{};
  json.forEach((cle, valeur) {
    final n = valeur is num ? valeur.toInt() : int.tryParse('$valeur');
    if (n != null) resultat['$cle'] = n;
  });
  return resultat;
}

/// Additionne des compteurs `par_statut` (ex. envoyés + reçus).
Map<String, int> additionnerParStatut(Map<String, int> a, Map<String, int> b) {
  final resultat = Map<String, int>.from(a);
  b.forEach((cle, n) => resultat[cle] = (resultat[cle] ?? 0) + n);
  return resultat;
}

/// Paramètre de filtre `statut` : absent pour « tous ».
Map<String, dynamic> parametreStatut(String? statut) =>
    statut == null || statut.isEmpty || statut == 'tous'
        ? const {}
        : {'statut': statut};

/// Paramètres de requête `page` / `limit`. Sans page ni limite → aucun
/// paramètre : le back renvoie la liste complète (usages non paginés).
Map<String, dynamic> parametresPagination({int? page, int? limit}) {
  if (page == null && limit == null) return const {};
  return {'page': page ?? 1, 'limit': limit ?? kTaillePage};
}

/// Charge la page [page] ; si elle est vide alors qu'elle n'est pas la
/// première (ex. dernier élément de la dernière page supprimé), recharge la
/// dernière page existante.
Future<PageResultat<T>> chargerPageNonVide<T>(
  int page,
  Future<PageResultat<T>> Function(int page) charger,
) async {
  final cible = page < 1 ? 1 : page;
  final resultat = await charger(cible);
  if (resultat.elements.isEmpty && cible > 1) {
    final derniere = resultat.pagination.pages;
    final repli = derniere < cible ? derniere : cible - 1;
    return charger(repli < 1 ? 1 : repli);
  }
  return resultat;
}
