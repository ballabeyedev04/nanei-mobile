import 'package:dio/dio.dart';
import 'package:francomalishipp/injection_container.dart';
import '../../domain/entities/client_recherche.dart';

class ColisApi {
  static Future<List<ClientRecherche>> rechercherClient(String query) async {
    if (query.isEmpty) return [];
    try {
      final dio = sl<Dio>();
      final response = await dio.get(
        '/client/rechercher-client',
        queryParameters: {'q': query},
      );
      if (response.statusCode == 200) {
        final List data = response.data['data'] ?? [];
        return data.map((e) => ClientRecherche.fromJson(e)).toList();
      }
      return [];
    } catch (e) {
      throw Exception("Erreur recherche client");
    }
  }

  static Future<void> envoyerColis({
    required String recepteurId,
    required double poids,
    required double prix,
    required String destination,
  }) async {
    final dio = sl<Dio>();
    final response = await dio.post(
      '/client/envoie-colis',
      data: {
        'recepteurId': recepteurId,
        'poids': poids,
        'prix': prix,
        'destination': destination,
      },
    );
    if (response.statusCode != 201) {
      throw Exception("Erreur envoi colis");
    }
  }

  static Future<int> getNombreColisEnvoyes() async {
    try {
      final dio = sl<Dio>();
      final response = await dio.get('/client/nombre-coli-envoyer');
      if (response.statusCode == 200) {
        return response.data['data'] ?? 0;
      }
      return 0;
    } catch (e) {
      return 0;
    }
  }

  static Future<int> getNombreColisRecus() async {
    try {
      final dio = sl<Dio>();
      final response = await dio.get('/client/nombre-coli-recu');
      if (response.statusCode == 200) {
        return response.data['data'] ?? 0;
      }
      return 0;
    } catch (e) {
      return 0;
    }
  }
}