import '../entities/colis.dart';
import '../repositories/colis_repository.dart';
import 'envoyer_colis.dart';

class EnvoyerColisLot {
  final ColisRepository repository;
  const EnvoyerColisLot(this.repository);

  Future<List<Colis>> call(List<EnvoyerColisParams> items) {
    final payload = items.map((p) => {
          if (p.destinataireManuel != null)
            'destinataireManuel': p.destinataireManuel!.toJson()
          else
            'recepteurId': p.recepteurId,
          'poids': p.poids,
          'prix': p.prix,
          'destination': p.destination,
          'type_colis': p.typeColis,
          'description': p.description,
        }).toList();
    return repository.envoyerColisLot(payload);
  }
}
