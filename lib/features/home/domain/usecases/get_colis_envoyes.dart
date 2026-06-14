import '../entities/colis.dart';
import '../repositories/colis_repository.dart';

class GetColisEnvoyes {
  final ColisRepository repository;
  const GetColisEnvoyes(this.repository);
  Future<List<Colis>> call() => repository.getColisEnvoyes();
}
