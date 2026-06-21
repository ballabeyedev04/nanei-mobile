import 'package:dio/dio.dart';
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
    final response = await dio.get('/paiements');
    final List data = response.data['data'] ?? [];
    return data.map((e) => PaiementModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  @override
  Future<String> initierPaiement({
    required String colisId,
    required String moyenPaiement,
  }) async {
    final response = await dio.post(
      '/paiements/$colisId/initier',
      data: {'moyenPaiement': moyenPaiement},
    );
    final url = response.data['data']?['checkoutUrl'] as String?;
    if (url == null || url.isEmpty) throw Exception('URL de paiement invalide');
    return url;
  }
}
