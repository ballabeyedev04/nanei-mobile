import 'package:dartz/dartz.dart';
import 'package:nanei/core/errors/failure.dart';
import '../entities/avis_entity.dart';
import '../repositories/avis_repository.dart';

class GetMesAvis {
  final AvisRepository repository;
  const GetMesAvis(this.repository);

  Future<Either<Failure, List<AvisEntity>>> call() => repository.mesAvis();
}
