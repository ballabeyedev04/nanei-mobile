import '../../domain/entities/colis.dart';
import '../../domain/entities/client_recherche.dart';
import '../../domain/entities/notification_model.dart';
import '../../domain/repositories/colis_repository.dart';
import '../datasources/colis_remote_datasource.dart';

class ColisRepositoryImpl implements ColisRepository {
  final ColisRemoteDataSource remoteDataSource;
  const ColisRepositoryImpl({required this.remoteDataSource});

  @override
  Future<List<Colis>> getColisEnvoyes() =>
      remoteDataSource.getColisEnvoyes();

  @override
  Future<List<Colis>> getColisRecus() =>
      remoteDataSource.getColisRecus();

  @override
  Future<Map<String, int>> getStatistiques() =>
      remoteDataSource.getStatistiques();

  @override
  Future<String?> envoyerColis({
    required String recepteurId,
    required double poids,
    required double prix,
    required String destination,
    required String typeColis,
    String? description,
  }) =>
      remoteDataSource.envoyerColis(
        recepteurId: recepteurId,
        poids: poids,
        prix: prix,
        destination: destination,
        typeColis: typeColis,
        description: description,
      );

  @override
  Future<List<ClientRecherche>> rechercherClient(String query) =>
      remoteDataSource.rechercherClient(query);

  @override
  Future<List<NotificationModel>> getNotifications() =>
      remoteDataSource.getNotifications();

  @override
  Future<void> marquerNotificationLue(String id) =>
      remoteDataSource.marquerNotificationLue(id);
}
