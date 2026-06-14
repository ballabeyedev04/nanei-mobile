import '../entities/client_recherche.dart';
import '../repositories/colis_repository.dart';

class RechercherClient {
  final ColisRepository repository;
  const RechercherClient(this.repository);
  Future<List<ClientRecherche>> call(String query) =>
      repository.rechercherClient(query);
}
