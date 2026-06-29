import 'package:dartz/dartz.dart';
import 'package:nanei/core/errors/failure.dart';
import '../entities/paiement.dart';

abstract class PaiementRepository {
  Future<Either<Failure, List<Paiement>>> mesPaiements();
  Future<Either<Failure, String>> initierPaiement({
    required String colisId,
    required String moyenPaiement,
  });
}
