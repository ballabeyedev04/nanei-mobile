import 'package:dartz/dartz.dart';
import 'package:nanei/core/errors/failure.dart';
import 'package:nanei/core/utils/pagination.dart';
import '../entities/paiement.dart';

abstract class PaiementRepository {
  /// Sans [page] ni [limit] : liste complète.
  Future<Either<Failure, PageResultat<Paiement>>> mesPaiements(
      {int? page, int? limit, String? statut});
  Future<Either<Failure, String>> initierPaiement({
    required String colisId,
    required String moyenPaiement,
  });
}
