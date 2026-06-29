import 'package:dio/dio.dart';
import 'package:nanei/core/config/env.dart';
import '../../domain/entities/paiement.dart';
import '../models/paiement_model.dart';

abstract class PaiementRemoteDataSource {
  Future<List<Paiement>> mesPaiements();
  Future<String> initierPaiement({required String colisId, required String moyenPaiement});
}

class PaiementRemoteDataSourceImpl implements PaiementRemoteDataSource {
  final Dio dio;
  const PaiementRemoteDataSourceImpl({required this.dio});

  @override
  Future<List<Paiement>> mesPaiements() async {
    final response = await dio.get(Env.paiements);
    final List data = response.data['data'] ?? [];
    return data.map((e) => PaiementModel.fromJson(e as Map<String, dynamic>)).toList();
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
