import 'personne.dart';

class Colis {
  final String id;
  final String reference;
  final Personne? expediteur;
  final Personne? recepteur;
  final double poids;
  final double prix;
  final String destination;
  final String statut;
  final String type;
  final String? description;
  final DateTime createdAt;
  final DateTime? updatedAt;
  /// Regroupement de colis — non null si ce colis a été envoyé avec d'autres
  /// dans une même commande groupée (voir EnvoyerColisLot).
  final String? lotId;

  /// Mode de transport : 'aerien' | 'maritime' (sans accent), null pour les
  /// anciens colis créés avant que le back ne l'enregistre.
  final String? typeTransport;

  /// Libellé affichable du mode de transport ('' si inconnu).
  String get typeTransportLabel => switch (typeTransport) {
        'aerien' => 'Aérien',
        'maritime' => 'Maritime',
        _ => '',
      };

  const Colis({
    required this.id,
    required this.reference,
    this.expediteur,
    this.recepteur,
    required this.poids,
    required this.prix,
    required this.destination,
    required this.statut,
    required this.type,
    this.description,
    required this.createdAt,
    this.updatedAt,
    this.lotId,
    this.typeTransport,
  });
}
