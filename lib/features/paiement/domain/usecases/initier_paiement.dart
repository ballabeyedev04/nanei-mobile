import 'package:dartz/dartz.dart';
import 'package:nanei/core/errors/failure.dart';
import '../repositories/paiement_repository.dart';

class InitierPaiement {
  final PaiementRepository repository;
  const InitierPaiement(this.repository);

  Future<Either<Failure, String>> call({
    required String colisId,
    required String moyenPaiement,
  }) =>
      repository.initierPaiement(
        colisId: colisId,
        moyenPaiement: moyenPaiement,
      );
}
