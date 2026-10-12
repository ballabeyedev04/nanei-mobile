import 'package:nanei/core/utils/pagination.dart';
import '../entities/reclamation_entity.dart';

abstract class ReclamationRepository {
  /// Sans [page] ni [limit] : liste complète.
  Future<PageResultat<ReclamationEntity>> getReclamations(
      {int? page, int? limit});
  Future<ReclamationEntity> creerReclamation({
    required String colisId,
    required String type,
    required String description,
    required List<String> photos,
  });
  Future<ReclamationEntity> getReclamation(String id);
}
