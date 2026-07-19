import 'package:dio/dio.dart';
import 'package:nanei/core/config/env.dart';

import '../models/reclamation_model.dart';

abstract class ReclamationRemoteDataSource {
  Future<List<ReclamationModel>> getReclamations();
  Future<ReclamationModel> creerReclamation({
    required String colisId,
    required String type,
    required String description,
    required List<String> photos,
  });
  Future<ReclamationModel> getReclamation(String id);
}

class ReclamationRemoteDataSourceImpl implements ReclamationRemoteDataSource {
  final Dio dio;
  const ReclamationRemoteDataSourceImpl({required this.dio});

  @override
  Future<List<ReclamationModel>> getReclamations() async {
    final response = await dio.get(Env.reclamations);
    final List data = response.data['reclamations'] ?? [];
    return data
        .map((e) => ReclamationModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<ReclamationModel> creerReclamation({
    required String colisId,
    required String type,
    required String description,
    required List<String> photos,
  }) async {
    final photoFiles = photos
        .map((p) => MapEntry('photos', MultipartFile.fromFileSync(p)))
        .toList();

    final fd = FormData.fromMap({
      'colis_id': colisId,
      'type': type,
      'description': description,
    });
    fd.files.addAll(photoFiles);

    final response = await dio.post(
      Env.reclamations,
      data: fd,
      options: Options(contentType: 'multipart/form-data'),
    );
    return ReclamationModel.fromJson(
        response.data['reclamation'] as Map<String, dynamic>);
  }

  @override
  Future<ReclamationModel> getReclamation(String id) async {
    final response = await dio.get(Env.reclamationById(id));
    return ReclamationModel.fromJson(
        response.data['reclamation'] as Map<String, dynamic>);
  }
}
