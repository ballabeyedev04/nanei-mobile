import '../../domain/entities/reclamation_entity.dart';
import '../../domain/repositories/reclamation_repository.dart';
import '../datasources/reclamation_remote_datasource.dart';

class ReclamationRepositoryImpl implements ReclamationRepository {
  final ReclamationRemoteDataSource remoteDataSource;
  const ReclamationRepositoryImpl({required this.remoteDataSource});

  @override
  Future<List<ReclamationEntity>> getReclamations() =>
      remoteDataSource.getReclamations();

  @override
  Future<ReclamationEntity> creerReclamation({
    required String colisId,
    required String type,
    required String description,
    required List<String> photos,
  }) =>
      remoteDataSource.creerReclamation(
        colisId: colisId,
        type: type,
        description: description,
        photos: photos,
      );

  @override
  Future<ReclamationEntity> getReclamation(String id) =>
      remoteDataSource.getReclamation(id);
}
