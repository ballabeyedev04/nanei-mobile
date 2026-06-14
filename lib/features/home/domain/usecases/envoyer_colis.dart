import '../repositories/colis_repository.dart';

class EnvoyerColisParams {
  final String recepteurId;
  final double poids;
  final double prix;
  final String destination;
  final String typeColis;
  final String? description;

  const EnvoyerColisParams({
    required this.recepteurId,
    required this.poids,
    required this.prix,
    required this.destination,
    required this.typeColis,
    this.description,
  });
}

class EnvoyerColis {
  final ColisRepository repository;
  const EnvoyerColis(this.repository);

  Future<String?> call(EnvoyerColisParams params) => repository.envoyerColis(
        recepteurId: params.recepteurId,
        poids: params.poids,
        prix: params.prix,
        destination: params.destination,
        typeColis: params.typeColis,
        description: params.description,
      );
}
