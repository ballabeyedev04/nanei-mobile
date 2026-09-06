import '../../domain/entities/colis.dart';
import '../../domain/entities/client_recherche.dart';
import '../../domain/entities/notification_model.dart';
import '../../domain/entities/country_pricing.dart';
import '../../domain/entities/prix_calcule.dart';
import '../../domain/entities/suivi_public.dart';
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
  Future<Colis> rechercherColisParReference(String reference) =>
      remoteDataSource.rechercherColisParReference(reference);

  @override
  Future<Map<String, int>> getStatistiques() =>
      remoteDataSource.getStatistiques();

  @override
  Future<String?> envoyerColis({
    String? recepteurId,
    Map<String, dynamic>? destinataireManuel,
    required double poids,
    required double prix,
    required String destination,
    required String typeColis,
    String? description,
  }) =>
      remoteDataSource.envoyerColis(
        recepteurId: recepteurId,
        destinataireManuel: destinataireManuel,
        poids: poids,
        prix: prix,
        destination: destination,
        typeColis: typeColis,
        description: description,
      );

  @override
  Future<List<Colis>> envoyerColisLot(List<Map<String, dynamic>> items) =>
      remoteDataSource.envoyerColisLot(items);

  @override
  Future<List<ClientRecherche>> rechercherClient(String query) =>
      remoteDataSource.rechercherClient(query);

  @override
  Future<List<NotificationModel>> getNotifications() =>
      remoteDataSource.getNotifications();

  @override
  Future<void> marquerNotificationLue(String id) =>
      remoteDataSource.marquerNotificationLue(id);

  @override
  Future<List<CountryItem>> getCountries() =>
      remoteDataSource.getCountries();

  @override
  Future<CountryPricing> getPricingByCountry(String countryId) =>
      remoteDataSource.getPricingByCountry(countryId);

  @override
  Future<PrixCalcule> calculerPrix({
    required String countryId,
    required double weight,
    required String shippingType,
    bool needsPickup = false,
    bool needsDelivery = false,
  }) =>
      remoteDataSource.calculerPrix(
        countryId: countryId,
        weight: weight,
        shippingType: shippingType,
        needsPickup: needsPickup,
        needsDelivery: needsDelivery,
      );

  @override
  Future<SuiviPublic> suiviPublicParReference(String reference) =>
      remoteDataSource.suiviPublicParReference(reference);
}
