import 'package:dartz/dartz.dart';
import 'package:nanei/core/errors/failure.dart';
import 'package:nanei/core/utils/pagination.dart';
import '../entities/avis_entity.dart';
import '../repositories/avis_repository.dart';

class GetMesAvis {
  final AvisRepository repository;
  const GetMesAvis(this.repository);

  /// Sans [page] ni [limit] : liste complète (ex. vérifier si un colis est
  /// déjà noté).
  Future<Either<Failure, PageResultat<AvisEntity>>> call(
          {int? page, int? limit}) =>
      repository.mesAvis(page: page, limit: limit);
}
