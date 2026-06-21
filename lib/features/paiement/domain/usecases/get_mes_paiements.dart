import '../entities/paiement.dart';
import '../repositories/paiement_repository.dart';

class GetMesPaiements {
  final PaiementRepository repository;
  const GetMesPaiements(this.repository);
  Future<List<Paiement>> call() => repository.mesPaiements();
}
