import 'package:nanei/core/utils/pagination.dart';
import '../entities/colis.dart';
import '../repositories/colis_repository.dart';

class GetColisEnvoyes {
  final ColisRepository repository;
  const GetColisEnvoyes(this.repository);

  /// Sans [page] ni [limit] : liste complète. [statut] : en_attente |
  /// recupere | livre (null ou 'tous' = tous), filtré côté serveur.
  Future<PageResultat<Colis>> call({int? page, int? limit, String? statut}) =>
      repository.getColisEnvoyes(page: page, limit: limit, statut: statut);
}
