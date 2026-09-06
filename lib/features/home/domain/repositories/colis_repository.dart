import '../entities/colis.dart';
import '../entities/client_recherche.dart';
import '../entities/notification_model.dart';
import '../entities/country_pricing.dart';
import '../entities/prix_calcule.dart';
import '../entities/suivi_public.dart';

abstract class ColisRepository {
  Future<List<Colis>> getColisEnvoyes();
  Future<List<Colis>> getColisRecus();
  Future<Colis> rechercherColisParReference(String reference);
  Future<Map<String, int>> getStatistiques();
  Future<String?> envoyerColis({
    String? recepteurId,
    Map<String, dynamic>? destinataireManuel,
    required double poids,
    required double prix,
    required String destination,
    required String typeColis,
    String? description,
  });
  Future<List<Colis>> envoyerColisLot(List<Map<String, dynamic>> items);
  Future<List<ClientRecherche>> rechercherClient(String query);
  Future<List<NotificationModel>> getNotifications();
  Future<void> marquerNotificationLue(String id);
  Future<List<CountryItem>> getCountries();
  Future<CountryPricing> getPricingByCountry(String countryId);
  Future<PrixCalcule> calculerPrix({
    required String countryId,
    required double weight,
    required String shippingType,
    bool needsPickup,
    bool needsDelivery,
  });
  Future<SuiviPublic> suiviPublicParReference(String reference);
}
