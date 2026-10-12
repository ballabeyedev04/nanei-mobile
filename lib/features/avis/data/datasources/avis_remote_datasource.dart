import 'package:dio/dio.dart';
import 'package:nanei/core/config/env.dart';
import 'package:nanei/core/utils/pagination.dart';
import '../models/avis_model.dart';

abstract class AvisRemoteDataSource {
  Future<void> donnerAvis(
      {required String colisId, required int note, String? commentaire});
  /// Sans [page] ni [limit] : liste complète (sert à savoir si un colis est
  /// déjà noté).
  Future<PageResultat<AvisModel>> mesAvis({int? page, int? limit});
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
  Future<PageResultat<AvisModel>> mesAvis({int? page, int? limit}) async {
    final response = await dio.get(
      Env.avis,
      queryParameters: parametresPagination(page: page, limit: limit),
    );
    // Le backend renvoie { success, avis: [...] } ; on tolère aussi 'data'
    // au cas où l'enveloppe serait un jour normalisée.
    return PageResultat.depuisReponse<AvisModel>(
        response.data, const ['avis', 'data'], AvisModel.fromJson);
  }
}
