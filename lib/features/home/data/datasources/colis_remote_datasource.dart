import 'package:dio/dio.dart';
import 'package:nanei/core/config/env.dart';
import 'package:nanei/core/utils/pagination.dart';
import '../../domain/entities/page_notifications.dart';
import '../../domain/entities/colis.dart';
import '../../domain/entities/client_recherche.dart';
import '../../domain/entities/notification_model.dart';
import '../../domain/entities/country_pricing.dart';
import '../models/colis_model.dart';
import '../models/client_recherche_model.dart';
import '../models/notification_model.dart' as nm;
import '../models/country_pricing_model.dart';
import '../models/prix_calcule_model.dart';
import '../../domain/entities/prix_calcule.dart';
import '../../domain/entities/suivi_public.dart';
import '../models/suivi_public_model.dart';

// ── Interface ─────────────────────────────────────────────────────────────────

abstract class ColisRemoteDataSource {
  /// Sans [page] ni [limit] : liste complète (une seule page).
  /// [statut] : en_attente | recupere | livre (null ou 'tous' = tous), filtré
  /// côté serveur avant la pagination. `parStatut` du résultat = compteurs sur
  /// toutes les pages, indépendants du filtre.
  Future<PageResultat<Colis>> getColisEnvoyes(
      {int? page, int? limit, String? statut});
  Future<PageResultat<Colis>> getColisRecus(
      {int? page, int? limit, String? statut});
  Future<Colis> rechercherColisParReference(String reference);
  Future<Map<String, int>> getStatistiques();
  Future<String?> envoyerColis({
    String? recepteurId,
    Map<String, dynamic>? destinataireManuel,
    required double poids,
    required double prix,
    required String destination,
    required String typeColis,
    String? description,
    Map<String, dynamic>? tarif,
  });
  Future<List<Colis>> envoyerColisLot(List<Map<String, dynamic>> items);
  Future<List<ClientRecherche>> rechercherClient(String query);
  Future<PageNotifications> getNotifications({int? page, int? limit});
  Future<void> marquerNotificationLue(String id);
  Future<void> marquerToutesNotificationsLues();
  Future<List<CountryItem>> getCountries();
  Future<CountryPricing> getPricingByCountry(String countryId);

  /// Calcul de prix côté serveur — POST /pricing/calculate
  Future<PrixCalcule> calculerPrix({
    required String countryId,
    required double weight,
    required String shippingType,
    bool needsPickup,
    bool needsDelivery,
  });

  /// Suivi public d'un colis par référence — GET /suivi/:reference?format=json
  Future<SuiviPublic> suiviPublicParReference(String reference);
}

// ── Implémentation ────────────────────────────────────────────────────────────

class ColisRemoteDataSourceImpl implements ColisRemoteDataSource {
  final Dio dio;
  const ColisRemoteDataSourceImpl({required this.dio});

  @override
  Future<PageResultat<Colis>> getColisEnvoyes(
      {int? page, int? limit, String? statut}) async {
    final response = await dio.get(
      Env.colisEnvoyes,
      queryParameters: {
        ...parametresPagination(page: page, limit: limit),
        ...parametreStatut(statut),
      },
    );
    return PageResultat.depuisReponse<Colis>(
        response.data, const ['data'], ColisModel.fromJson);
  }

  @override
  Future<PageResultat<Colis>> getColisRecus(
      {int? page, int? limit, String? statut}) async {
    final response = await dio.get(
      Env.colisRecus,
      queryParameters: {
        ...parametresPagination(page: page, limit: limit),
        ...parametreStatut(statut),
      },
    );
    return PageResultat.depuisReponse<Colis>(
        response.data, const ['data'], ColisModel.fromJson);
  }

  @override
  Future<Colis> rechercherColisParReference(String reference) async {
    final response = await dio.get(Env.colisRecherche(reference));
    return ColisModel.fromJson(response.data['data']);
  }

  @override
  Future<Map<String, int>> getStatistiques() async {
    final response = await dio.get(Env.colisStatistiques);
    final data = response.data['data'];
    return {
      'envoyes': (data?['colisEnvoyes'] as num?)?.toInt() ?? 0,
      'recus':   (data?['colisRecus']   as num?)?.toInt() ?? 0,
      'total':   (data?['total']        as num?)?.toInt() ?? 0,
    };
  }

  @override
  Future<String?> envoyerColis({
    String? recepteurId,
    Map<String, dynamic>? destinataireManuel,
    required double poids,
    required double prix,
    required String destination,
    required String typeColis,
    String? description,
    Map<String, dynamic>? tarif,
  }) async {
    final response = await dio.post(
      Env.colisEnvoyer,
      data: {
        if (destinataireManuel != null)
          'destinataireManuel': destinataireManuel
        else
          'recepteurId': recepteurId,
        'poids': poids,
        'prix': prix,
        'destination': destination,
        'type_colis': typeColis,
        'description': description,
        ...?tarif,
      },
    );
    if (response.statusCode != 201) {
      throw Exception('Erreur envoi colis');
    }
    // Backend : { message, colis: { reference, ... } }. On tolère aussi 'data'.
    final body = response.data as Map<String, dynamic>? ?? const {};
    final colis =
        (body['colis'] ?? body['data']) as Map<String, dynamic>?;
    return colis?['reference'] as String?;
  }

  @override
  Future<List<Colis>> envoyerColisLot(List<Map<String, dynamic>> items) async {
    final response = await dio.post(
      Env.colisEnvoyerLot,
      data: {'colis': items},
    );
    if (response.statusCode != 201) {
      throw Exception('Erreur envoi du lot de colis');
    }
    final List data = response.data?['colis'] ?? [];
    return data.map((e) => ColisModel.fromJson(e)).toList();
  }

  @override
  Future<List<ClientRecherche>> rechercherClient(String query) async {
    if (query.isEmpty) return [];
    final response = await dio.get(
      Env.clientRechercher,
      queryParameters: {'q': query},
    );
    final List data = response.data['data'] ?? [];
    return data.map((e) => ClientRechercheModel.fromJson(e)).toList();
  }

  @override
  Future<PageNotifications> getNotifications({int? page, int? limit}) async {
    final response = await dio.get(
      Env.notificationsMes,
      queryParameters: parametresPagination(page: page, limit: limit),
    );
    final resultat = PageResultat.depuisReponse<NotificationModel>(
        response.data, const ['data'], nm.NotificationDataModel.fromJson);
    final body = response.data is Map ? response.data as Map : const {};
    final nonLues = body['non_lues'];
    return PageNotifications(
      elements: resultat.elements,
      pagination: resultat.pagination,
      // `non_lues` = total des non lues toutes pages ; à défaut (ancien
      // back), calcul sur la page reçue.
      nonLues: nonLues is num
          ? nonLues.toInt()
          : int.tryParse('$nonLues') ??
              resultat.elements.where((n) => !n.lue).length,
    );
  }

  @override
  Future<void> marquerNotificationLue(String id) async {
    await dio.patch(Env.notificationLire(id));
  }

  @override
  Future<void> marquerToutesNotificationsLues() async {
    await dio.post(Env.notificationsToutesLues);
  }

  @override
  Future<List<CountryItem>> getCountries() async {
    final response = await dio.get(Env.clientCountries);
    final List data = response.data['data'] ?? [];
    return data.map((e) => CountryItemModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  @override
  Future<CountryPricing> getPricingByCountry(String countryId) async {
    final response = await dio.get(Env.clientPricing(countryId));
    return CountryPricingModel.fromJson(response.data['data'] as Map<String, dynamic>);
  }

  @override
  Future<PrixCalcule> calculerPrix({
    required String countryId,
    required double weight,
    required String shippingType,
    bool needsPickup = false,
    bool needsDelivery = false,
  }) async {
    final response = await dio.post(
      Env.pricingCalculate,
      data: {
        'countryId': countryId,
        'weight': weight,
        'shippingType': shippingType,
        'needsPickup': needsPickup,
        'needsDelivery': needsDelivery,
      },
    );
    final data = response.data['data'] as Map<String, dynamic>?;
    if (data == null) {
      throw Exception('Réponse de calcul de prix invalide');
    }
    return PrixCalculeModel.fromJson(data);
  }

  @override
  Future<SuiviPublic> suiviPublicParReference(String reference) async {
    // Endpoint public (pas d'auth). baseUrl est déjà inclus dans le helper.
    final response = await dio.get(Env.suiviPublicJson(reference));
    final data = response.data as Map<String, dynamic>;
    final colis = data['colis'] as Map<String, dynamic>?;
    if (colis == null) {
      throw Exception('Colis introuvable');
    }
    return SuiviPublicModel.fromJson(colis);
  }
}
