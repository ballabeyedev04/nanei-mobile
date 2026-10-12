import 'package:dio/dio.dart';
import 'package:nanei/core/config/env.dart';
import 'package:nanei/core/utils/pagination.dart';
import '../../domain/entities/paiement.dart';
import '../models/paiement_model.dart';

abstract class PaiementRemoteDataSource {
  /// Sans [page] ni [limit] : liste complète. [statut] : en_attente |
  /// en_cours | paye | echoue | rembourse (null ou 'tous' = tous).
  /// `parStatut` du résultat = compteurs sur toutes les pages.
  Future<PageResultat<Paiement>> mesPaiements(
      {int? page, int? limit, String? statut});
  Future<String> initierPaiement({required String colisId, required String moyenPaiement});
}

class PaiementRemoteDataSourceImpl implements PaiementRemoteDataSource {
  final Dio dio;
  const PaiementRemoteDataSourceImpl({required this.dio});

  @override
  Future<PageResultat<Paiement>> mesPaiements(
      {int? page, int? limit, String? statut}) async {
    final response = await dio.get(
      Env.paiements,
      queryParameters: {
        ...parametresPagination(page: page, limit: limit),
        ...parametreStatut(statut),
      },
    );
    return PageResultat.depuisReponse<Paiement>(
        response.data, const ['data'], PaiementModel.fromJson);
  }

  @override
  Future<String> initierPaiement({
    required String colisId,
    required String moyenPaiement,
  }) async {
    final response = await dio.post(
      Env.paiementInitier(colisId),
      data: {'moyenPaiement': moyenPaiement},
    );
    final url = response.data['data']?['checkoutUrl'] as String?;
    if (url == null || url.isEmpty) {
      throw DioException(
        requestOptions: response.requestOptions,
        response: response,
        error: 'URL de paiement invalide retournée par le serveur.',
      );
    }
    return url;
  }
}
