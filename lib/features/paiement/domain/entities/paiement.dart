class Paiement {
  final String id;
  final String colisId;
  final String reference;
  final double prixTotal;
  final double montantPaye;
  final String? moyenPaiement;
  final String statut; // en_attente | en_cours | paye | echoue | rembourse
  final String? checkoutUrl;
  final String destination;
  final double poids;
  final DateTime createdAt;

  const Paiement({
    required this.id,
    required this.colisId,
    required this.reference,
    required this.prixTotal,
    required this.montantPaye,
    this.moyenPaiement,
    required this.statut,
    this.checkoutUrl,
    required this.destination,
    required this.poids,
    required this.createdAt,
  });

  bool get estPaye       => statut == 'paye';
  bool get estEnAttente  => statut == 'en_attente';
  bool get estEnCours    => statut == 'en_cours';
  bool get estEchoue     => statut == 'echoue';
  bool get peutPayer     => statut == 'en_attente' || statut == 'echoue';
}
