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
  });
}
