/// Résultat du calcul de prix côté serveur (`POST /pricing/calculate`).
/// Source de vérité pour le montant facturé — le calcul local dans
/// EnvoiColisPage ne sert que d'estimation d'affichage / de repli.
class PrixCalcule {
  final double shippingPrice;
  final double pickupPrice;
  final double deliveryPrice;
  final double total;

  const PrixCalcule({
    required this.shippingPrice,
    required this.pickupPrice,
    required this.deliveryPrice,
    required this.total,
  });
}
