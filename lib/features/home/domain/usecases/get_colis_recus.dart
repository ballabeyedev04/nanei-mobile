import '../entities/colis.dart';
import '../repositories/colis_repository.dart';

class GetColisRecus {
  final ColisRepository repository;
  const GetColisRecus(this.repository);
  Future<List<Colis>> call() => repository.getColisRecus();
}
