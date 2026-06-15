import 'package:dio/dio.dart';
import 'package:nanei/core/config/env.dart';
import '../../domain/entities/colis.dart';
import '../../domain/entities/client_recherche.dart';
import '../../domain/entities/notification_model.dart';
import '../../domain/entities/country_pricing.dart';
import '../models/colis_model.dart';
import '../models/client_recherche_model.dart';
import '../models/notification_model.dart' as nm;
import '../models/country_pricing_model.dart';

// ── Interface ─────────────────────────────────────────────────────────────────

abstract class ColisRemoteDataSource {
  Future<List<Colis>> getColisEnvoyes();
  Future<List<Colis>> getColisRecus();
  Future<Map<String, int>> getStatistiques();
  Future<String?> envoyerColis({
    required String recepteurId,
    required double poids,
    required double prix,
    required String destination,
    required String typeColis,
    String? description,
  });
  Future<List<ClientRecherche>> rechercherClient(String query);
  Future<List<NotificationModel>> getNotifications();
  Future<void> marquerNotificationLue(String id);
  Future<List<CountryItem>> getCountries();
  Future<CountryPricing> getPricingByCountry(String countryId);
}

// ── Implémentation ────────────────────────────────────────────────────────────

class ColisRemoteDataSourceImpl implements ColisRemoteDataSource {
  final Dio dio;
  const ColisRemoteDataSourceImpl({required this.dio});

  @override
  Future<List<Colis>> getColisEnvoyes() async {
    final response = await dio.get(Env.colisEnvoyes);
    final List data = response.data['data'] ?? [];
    return data.map((e) => ColisModel.fromJson(e)).toList();
  }

  @override
  Future<List<Colis>> getColisRecus() async {
    final response = await dio.get(Env.colisRecus);
    final List data = response.data['data'] ?? [];
    return data.map((e) => ColisModel.fromJson(e)).toList();
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
    required String recepteurId,
    required double poids,
    required double prix,
    required String destination,
    required String typeColis,
    String? description,
  }) async {
    final response = await dio.post(
      Env.colisEnvoyer,
      data: {
        'recepteurId': recepteurId,
        'poids': poids,
        'prix': prix,
        'destination': destination,
        'type_colis': typeColis,
        'description': description,
      },
    );
    if (response.statusCode != 201) {
      throw Exception('Erreur envoi colis');
    }
    return response.data?['data']?['reference'] as String?;
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
  Future<List<NotificationModel>> getNotifications() async {
    final response = await dio.get(Env.notificationsMes);
    final List data = response.data['data'] ?? [];
    return data.map((e) => nm.NotificationDataModel.fromJson(e)).toList();
  }

  @override
  Future<void> marquerNotificationLue(String id) async {
    await dio.patch(Env.notificationLire(id));
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
}
