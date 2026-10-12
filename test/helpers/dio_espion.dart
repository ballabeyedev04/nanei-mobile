import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';

/// Adaptateur HTTP qui n'atteint JAMAIS le réseau : il ENREGISTRE ce que le
/// mobile a réellement envoyé, et rend la réponse qu'on lui a préparée.
///
/// ## Pourquoi les tests d'appels API passent par là
///
/// Un datasource (ou une page qui appelle `sl<Dio>()` directement) fait deux
/// choses que ni l'analyse ni la compilation ne vérifient :
///
///  1. il compose une requête — un verbe, un chemin, des paramètres, un
///     corps. Dart accepte n'importe quelle chaîne comme chemin ou comme clé
///     de corps : une faute (`colisId` au lieu de `colis_id`) ne se voit
///     qu'en production, sous la forme d'un 400 ou d'un écran vide ;
///
///  2. il relit une réponse JSON. Une clé mal orthographiée traverse le
///     `as String?` sans bruit et ressort en `null` — un champ vide à l'écran
///     qu'on prend pour une donnée absente côté serveur. Un DECIMAL Postgres
///     renvoyé en CHAÎNE (`"12.50"`) fait au contraire planter un `as num`.
///
/// L'espion rend les deux observables : [requetes] conserve ce qui est parti,
/// et les réponses sont écrites à la main, TELLES QUE LE BACK LES FORME
/// (enveloppe, clés snake_case, nombres en chaîne compris).
///
/// Contrairement à un `Mock` de `Dio`, l'espion laisse tourner le vrai Dio :
/// sérialisation du corps, `FormData` multipart, en-têtes, `validateStatus`
/// et `DioException` sont ceux de l'application.
class DioEspion implements HttpClientAdapter {
  /// Ce que le mobile a envoyé, dans l'ordre.
  final List<RequestOptions> requetes = [];

  /// Réponses servies dans l'ordre des appels. Une fois toutes servies, la
  /// DERNIÈRE est réutilisée (cas courant : une réponse pour un test à un
  /// seul appel, ou une réponse répétée). Une réponse préparée après coup
  /// sera servie à l'appel suivant.
  final List<_Reponse> _reponses = [];
  int _servies = 0;
  final Map<String, int> _serviesParChemin = {};

  /// Réponses réservées à un chemin précis (`/client/colis-envoyes`) ou à un
  /// appel précis (`GET /client/colis-envoyes`) — pour les appels parallèles
  /// dont l'ordre d'arrivée n'est pas garanti.
  final Map<String, List<_Reponse>> _parChemin = {};

  /// Prépare une réponse JSON de succès. [corps] est écrit ENVELOPPE COMPRISE
  /// (`{ success, data… }`) : c'est elle que le mobile doit savoir défaire.
  void repond(Object? corps,
      {int statut = 200, String? pour, Future<void>? apres}) {
    _ajouter(
        _Reponse.json(jsonEncode(corps), statut, apres: apres), pour);
  }

  /// Prépare une réponse d'ERREUR du serveur, avec son corps : c'est lui qui
  /// porte le `message` (ou les `details` de validation Joi) que l'écran
  /// doit afficher.
  void repondErreur(int statut, {Object? corps, String? pour}) {
    _ajouter(_Reponse.json(jsonEncode(corps ?? const {}), statut), pour);
  }

  /// Réponse binaire (PDF de facture, étiquette).
  void repondOctets(List<int> octets,
      {int statut = 200,
      String contentType = 'application/pdf',
      String? pour}) {
    _ajouter(_Reponse(Uint8List.fromList(octets), statut, contentType), pour);
  }

  /// Réponse texte NON JSON — typiquement la page HTML d'un proxy (nginx
  /// 502) : le corps arrive alors en `String`, pas en `Map`.
  void repondTexte(String texte,
      {int statut = 200,
      String contentType = 'text/html; charset=utf-8',
      String? pour}) {
    _ajouter(
        _Reponse(Uint8List.fromList(utf8.encode(texte)), statut, contentType),
        pour);
  }

  /// Panne réseau (aucune réponse du serveur).
  void coupeReseau({String? pour}) {
    _ajouter(_Reponse.panne(), pour);
  }

  void _ajouter(_Reponse r, String? pour) {
    if (pour == null) {
      _reponses.add(r);
    } else {
      _parChemin.putIfAbsent(pour, () => []).add(r);
    }
  }

  /// La requête envoyée — pour un test à un seul appel.
  RequestOptions get requete {
    if (requetes.isEmpty) {
      throw StateError("aucune requête n'a été envoyée");
    }
    return requetes.single;
  }

  /// « VERBE /chemin », la forme comparée dans les assertions.
  String get appel => '${requete.method} ${requete.path}';

  /// Tous les appels, dans l'ordre, sous la forme « VERBE /chemin ».
  List<String> get appels =>
      requetes.map((r) => '${r.method} ${r.path}').toList();

  /// La (dernière) requête envoyée vers [chemin].
  RequestOptions requetePour(String chemin) =>
      requetes.lastWhere((r) => r.path == chemin,
          orElse: () => throw StateError('aucune requête vers $chemin '
              '(envoyées : $appels)'));

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    // Copie : l'intercepteur d'authentification MODIFIE les en-têtes de la
    // même `RequestOptions` avant de la rejouer — sans copie, la première
    // requête enregistrée afficherait le jeton de la seconde.
    requetes.add(options.copyWith());

    // Consommer le corps, comme le ferait un vrai adaptateur : un envoi
    // multipart tient des fichiers OUVERTS tant que son flux n'a pas été lu
    // (sous Windows, le fichier temporaire ne pourrait plus être supprimé).
    if (requestStream != null) {
      await requestStream.drain<void>();
    }

    final cle = '${options.method} ${options.path}';
    final cleChemin = _parChemin.containsKey(cle) ? cle : options.path;
    final file = _parChemin[cleChemin];
    final _Reponse reponse;
    if (file != null && file.isNotEmpty) {
      final i = _serviesParChemin[cleChemin] ?? 0;
      reponse = file[i < file.length ? i : file.length - 1];
      _serviesParChemin[cleChemin] = i + 1;
    } else if (_reponses.isNotEmpty) {
      reponse = _reponses[
          _servies < _reponses.length ? _servies : _reponses.length - 1];
      _servies++;
    } else {
      throw StateError('aucune réponse préparée pour $cle');
    }

    if (reponse.apres != null) await reponse.apres;

    if (reponse.panne) {
      throw DioException.connectionError(
        requestOptions: options,
        reason: 'réseau coupé (test)',
      );
    }

    return ResponseBody.fromBytes(
      reponse.octets,
      reponse.statut,
      headers: {
        Headers.contentTypeHeader: [reponse.contentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

class _Reponse {
  final Uint8List octets;
  final int statut;
  final String contentType;
  final bool panne;
  final Future<void>? apres;

  _Reponse(this.octets, this.statut, this.contentType,
      {this.panne = false, this.apres});

  factory _Reponse.json(String corps, int statut, {Future<void>? apres}) =>
      _Reponse(Uint8List.fromList(utf8.encode(corps)), statut,
          Headers.jsonContentType,
          apres: apres);

  factory _Reponse.panne() =>
      _Reponse(Uint8List(0), 0, Headers.jsonContentType, panne: true);
}

/// URL de base des tests (équivalent de `API_BASE_URL`, préfixe `/nanei`
/// compris — comme en production).
const String baseUrlDeTest = 'https://api.test/nanei';

/// Un `Dio` branché sur [espion], configuré comme celui de l'application
/// (`injection_container.dart`) : JSON par défaut, `Accept: application/json`
/// et `validateStatus` PAR DÉFAUT de Dio — tout code hors 2xx lève une
/// `DioException`, que les datasources ou les écrans traduisent.
Dio dioDeTest(DioEspion espion, {String baseUrl = baseUrlDeTest}) {
  final dio = Dio(BaseOptions(
    baseUrl: baseUrl,
    contentType: 'application/json',
    headers: {'Accept': 'application/json'},
  ));
  dio.httpClientAdapter = espion;
  return dio;
}

/// Lit le corps JSON envoyé (Map) — échoue clairement s'il n'en est pas un.
Map<String, dynamic> corpsEnvoye(RequestOptions r) {
  final d = r.data;
  if (d is Map<String, dynamic>) return d;
  if (d is String) return jsonDecode(d) as Map<String, dynamic>;
  throw StateError('corps non JSON : ${d.runtimeType}');
}
