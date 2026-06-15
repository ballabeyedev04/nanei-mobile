import '../entities/colis.dart';
import '../entities/client_recherche.dart';
import '../entities/notification_model.dart';
import '../entities/country_pricing.dart';

abstract class ColisRepository {
  Future<List<Colis>> getColisEnvoyes();
  Future<List<Colis>> getColisRecus();
  Future<Map<String, int>> getStatistiques();
  Future<String?> envoyerColis({
    required String recepteurId,
    required double poids,
    required double prix,
    required String destination,
    required String typeColis,
    String? description,
  });
  Future<List<ClientRecherche>> rechercherClient(String query);
  Future<List<NotificationModel>> getNotifications();
  Future<void> marquerNotificationLue(String id);
  Future<List<CountryItem>> getCountries();
  Future<CountryPricing> getPricingByCountry(String countryId);
}
