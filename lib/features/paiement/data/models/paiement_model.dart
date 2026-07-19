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

  // Certains champs monétaires (DECIMAL Postgres) peuvent revenir en String
  // selon le point d'API — parsing tolérant pour éviter un crash "type
  // 'String' is not a subtype of type 'num'" si un endpoint les sérialise
  // différemment.
  static double _toDouble(dynamic v) {
    if (v == null) return 0;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString()) ?? 0;
  }

  factory PaiementModel.fromJson(Map<String, dynamic> json) {
    final colis = json['colis'] as Map<String, dynamic>? ?? {};
    return PaiementModel(
      id:             json['id'] as String,
      colisId:        json['colisId'] as String? ?? colis['id'] as String? ?? '',
      reference:      colis['reference'] as String? ?? '',
      prixTotal:      _toDouble(json['prixTotal']),
      montantPaye:    _toDouble(json['montantPaye']),
      moyenPaiement:  json['moyenPaiement'] as String?,
      statut:         json['statut'] as String? ?? 'en_attente',
      checkoutUrl:    json['checkoutUrl'] as String?,
      destination:    colis['destination'] as String? ?? '',
      poids:          _toDouble(colis['poids']),
      createdAt:      DateTime.tryParse(json['createdAt'] as String? ?? '') ?? DateTime.now(),
    );
  }
}
