import 'package:dartz/dartz.dart';
import 'package:nanei/core/errors/failure.dart';
import '../entities/paiement.dart';
import '../repositories/paiement_repository.dart';

class GetMesPaiements {
  final PaiementRepository repository;
  const GetMesPaiements(this.repository);
  Future<Either<Failure, List<Paiement>>> call() => repository.mesPaiements();
}
