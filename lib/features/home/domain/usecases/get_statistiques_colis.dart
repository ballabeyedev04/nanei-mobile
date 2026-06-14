import '../repositories/colis_repository.dart';

class GetStatistiquesColis {
  final ColisRepository repository;
  const GetStatistiquesColis(this.repository);
  Future<Map<String, int>> call() => repository.getStatistiques();
}
