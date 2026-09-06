import 'package:dio/dio.dart';
import 'package:nanei/core/config/env.dart';
import '../models/avis_model.dart';

abstract class AvisRemoteDataSource {
  Future<void> donnerAvis(
      {required String colisId, required int note, String? commentaire});
  Future<List<AvisModel>> mesAvis();
}

class AvisRemoteDataSourceImpl implements AvisRemoteDataSource {
  final Dio dio;
  const AvisRemoteDataSourceImpl({required this.dio});

  @override
  Future<void> donnerAvis(
      {required String colisId,
      required int note,
      String? commentaire}) async {
    // Le backend lit `colis_id` (snake_case). On envoie la clé attendue ;
    // `colisId` est conservé par tolérance pour un éventuel autre consommateur.
    await dio.post(Env.avis, data: {
      'colis_id': colisId,
      'colisId': colisId,
      'note': note,
      if (commentaire != null && commentaire.isNotEmpty)
        'commentaire': commentaire,
    });
  }

  @override
  Future<List<AvisModel>> mesAvis() async {
    final response = await dio.get(Env.avis);
    // Le backend renvoie { success, avis: [...] } ; on tolère aussi 'data'
    // au cas où l'enveloppe serait un jour normalisée.
    final body = response.data as Map<String, dynamic>? ?? const {};
    final List data = (body['avis'] ?? body['data'] ?? const []) as List;
    return data
        .map((e) => AvisModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
