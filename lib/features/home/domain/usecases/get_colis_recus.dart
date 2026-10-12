import 'package:nanei/core/utils/pagination.dart';
import '../entities/colis.dart';
import '../repositories/colis_repository.dart';

class GetColisRecus {
  final ColisRepository repository;
  const GetColisRecus(this.repository);

  /// Sans [page] ni [limit] : liste complète. [statut] : en_attente |
  /// recupere | livre (null ou 'tous' = tous), filtré côté serveur.
  Future<PageResultat<Colis>> call({int? page, int? limit, String? statut}) =>
      repository.getColisRecus(page: page, limit: limit, statut: statut);
}
