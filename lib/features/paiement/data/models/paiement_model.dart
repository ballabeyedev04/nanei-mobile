import '../../domain/entities/paiement.dart';

class PaiementModel extends Paiement {
  const PaiementModel({
    required super.id,
    required super.colisId,
    required super.reference,
    required super.prixTotal,
    required super.montantPaye,
    super.moyenPaiement,
    required super.statut,
    super.checkoutUrl,
    required super.destination,
    required super.poids,
    required super.createdAt,
  });

  factory PaiementModel.fromJson(Map<String, dynamic> json) {
    final colis = json['colis'] as Map<String, dynamic>? ?? {};
    return PaiementModel(
      id:             json['id'] as String,
      colisId:        json['colisId'] as String? ?? colis['id'] as String? ?? '',
      reference:      colis['reference'] as String? ?? '',
      prixTotal:      (json['prixTotal'] as num?)?.toDouble() ?? 0,
      montantPaye:    (json['montantPaye'] as num?)?.toDouble() ?? 0,
      moyenPaiement:  json['moyenPaiement'] as String?,
      statut:         json['statut'] as String? ?? 'en_attente',
      checkoutUrl:    json['checkoutUrl'] as String?,
      destination:    colis['destination'] as String? ?? '',
      poids:          (colis['poids'] as num?)?.toDouble() ?? 0,
      createdAt:      DateTime.tryParse(json['createdAt'] as String? ?? '') ?? DateTime.now(),
    );
  }
}
