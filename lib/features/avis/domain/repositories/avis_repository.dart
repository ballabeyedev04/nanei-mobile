import 'package:dartz/dartz.dart';
import 'package:nanei/core/errors/failure.dart';
import '../entities/avis_entity.dart';

abstract class AvisRepository {
  Future<Either<Failure, void>> donnerAvis({
    required String colisId,
    required int note,
    String? commentaire,
  });

  Future<Either<Failure, List<AvisEntity>>> mesAvis();
}
