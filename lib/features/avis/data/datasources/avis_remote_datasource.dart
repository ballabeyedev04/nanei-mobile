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
    await dio.post(Env.avis, data: {
      'colisId': colisId,
      'note': note,
      if (commentaire != null && commentaire.isNotEmpty)
        'commentaire': commentaire,
    });
  }

  @override
  Future<List<AvisModel>> mesAvis() async {
    final response = await dio.get(Env.avis);
    final List data = response.data['data'] ?? [];
    return data
        .map((e) => AvisModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
