import 'package:dartz/dartz.dart';
import 'package:nanei/core/errors/failure.dart';
import 'package:nanei/core/utils/pagination.dart';
import '../entities/avis_entity.dart';

abstract class AvisRepository {
  Future<Either<Failure, void>> donnerAvis({
    required String colisId,
    required int note,
    String? commentaire,
  });

  /// Sans [page] ni [limit] : liste complète.
  Future<Either<Failure, PageResultat<AvisEntity>>> mesAvis(
      {int? page, int? limit});
}
