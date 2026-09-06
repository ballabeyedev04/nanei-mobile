import '../entities/prix_calcule.dart';
import '../repositories/colis_repository.dart';

/// Calcul de prix côté serveur (`POST /pricing/calculate`).
/// Utilisé comme source de vérité avant l'envoi d'un colis ; le calcul
/// local dans EnvoiColisPage reste le repli si l'appel échoue.
class CalculerPrix {
  final ColisRepository repository;
  const CalculerPrix(this.repository);

  Future<PrixCalcule> call({
    required String countryId,
    required double weight,
    required String shippingType,
    bool needsPickup = false,
    bool needsDelivery = false,
  }) =>
      repository.calculerPrix(
        countryId: countryId,
        weight: weight,
        shippingType: shippingType,
        needsPickup: needsPickup,
        needsDelivery: needsDelivery,
      );
}
