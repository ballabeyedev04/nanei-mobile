import 'package:nanei/core/utils/pagination.dart';
import '../entities/colis.dart';
import '../entities/page_notifications.dart';
import '../entities/client_recherche.dart';
import '../entities/country_pricing.dart';
import '../entities/prix_calcule.dart';
import '../entities/suivi_public.dart';

abstract class ColisRepository {
  /// Sans [page] ni [limit] : liste complète (une seule page).
  /// [statut] : en_attente | recupere | livre (null ou 'tous' = tous).
  Future<PageResultat<Colis>> getColisEnvoyes(
      {int? page, int? limit, String? statut});
  Future<PageResultat<Colis>> getColisRecus(
      {int? page, int? limit, String? statut});
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
    Map<String, dynamic>? tarif,
  });
  Future<List<Colis>> envoyerColisLot(List<Map<String, dynamic>> items);
  Future<List<ClientRecherche>> rechercherClient(String query);
  Future<PageNotifications> getNotifications({int? page, int? limit});
  Future<void> marquerNotificationLue(String id);
  Future<void> marquerToutesNotificationsLues();
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
