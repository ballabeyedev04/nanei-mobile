import '../entities/reclamation_entity.dart';

abstract class ReclamationRepository {
  Future<List<ReclamationEntity>> getReclamations();
  Future<ReclamationEntity> creerReclamation({
    required String colisId,
    required String type,
    required String description,
    required List<String> photos,
  });
  Future<ReclamationEntity> getReclamation(String id);
}
