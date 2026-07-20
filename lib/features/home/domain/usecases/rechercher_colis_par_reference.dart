import '../entities/colis.dart';
import '../repositories/colis_repository.dart';

class RechercherColisParReference {
  final ColisRepository repository;
  const RechercherColisParReference(this.repository);
  Future<Colis> call(String reference) => repository.rechercherColisParReference(reference);
}
