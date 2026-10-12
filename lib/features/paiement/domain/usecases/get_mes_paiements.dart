import 'package:dartz/dartz.dart';
import 'package:nanei/core/errors/failure.dart';
import 'package:nanei/core/utils/pagination.dart';
import '../entities/paiement.dart';
import '../repositories/paiement_repository.dart';

class GetMesPaiements {
  final PaiementRepository repository;
  const GetMesPaiements(this.repository);
  /// [statut] : en_attente | en_cours | paye | echoue | rembourse (null ou
  /// 'tous' = tous), filtré côté serveur.
  Future<Either<Failure, PageResultat<Paiement>>> call(
          {int? page, int? limit, String? statut}) =>
      repository.mesPaiements(page: page, limit: limit, statut: statut);
}
