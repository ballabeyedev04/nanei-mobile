import 'package:dio/dio.dart';
import 'package:nanei/core/utils/media_type.dart';
import 'package:nanei/core/config/env.dart';
import 'package:nanei/core/utils/pagination.dart';

import '../models/reclamation_model.dart';

abstract class ReclamationRemoteDataSource {
  /// Sans [page] ni [limit] : liste complète.
  Future<PageResultat<ReclamationModel>> getReclamations(
      {int? page, int? limit});
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
  Future<PageResultat<ReclamationModel>> getReclamations(
      {int? page, int? limit}) async {
    final response = await dio.get(
      Env.reclamations,
      queryParameters: parametresPagination(page: page, limit: limit),
    );
    return PageResultat.depuisReponse<ReclamationModel>(
        response.data, const ['reclamations'], ReclamationModel.fromJson);
  }

  @override
  Future<ReclamationModel> creerReclamation({
    required String colisId,
    required String type,
    required String description,
    required List<String> photos,
  }) async {
    // Type MIME explicite : sans lui, Dio envoie application/octet-stream et
    // le back refuse la photo.
    final photoFiles = <MapEntry<String, MultipartFile>>[
      for (final p in photos) MapEntry('photos', await multipartImage(p)),
    ];

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
