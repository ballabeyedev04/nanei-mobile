/// Suivi public d'un colis par référence (`GET /suivi/:reference?format=json`).
/// Données volontairement partielles côté backend : pas d'adresse, téléphones
/// masqués. Aucune authentification requise.
class SuiviEvenement {
  final String? ancienStatut;
  final String nouveauStatut;
  final String? commentaire;
  final DateTime? date;

  const SuiviEvenement({
    this.ancienStatut,
    required this.nouveauStatut,
    this.commentaire,
    this.date,
  });
}

class SuiviPublic {
  final String reference;
  final String statut;
  final String destination;
  final double poids;
  final String typeColis;
  final DateTime? createdAt;

  final String? expediteurNom;
  final String? expediteurPrenom;
  final String? expediteurTelephone;

  final String? recepteurNom;
  final String? recepteurPrenom;
  final String? recepteurTelephone;

  final List<SuiviEvenement> historique;

  const SuiviPublic({
    required this.reference,
    required this.statut,
    required this.destination,
    required this.poids,
    required this.typeColis,
    this.createdAt,
    this.expediteurNom,
    this.expediteurPrenom,
    this.expediteurTelephone,
    this.recepteurNom,
    this.recepteurPrenom,
    this.recepteurTelephone,
    this.historique = const [],
  });
}
