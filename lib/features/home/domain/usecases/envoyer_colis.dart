import '../repositories/colis_repository.dart';

/// Destinataire saisi manuellement par l'expéditeur lorsque la personne n'a
/// pas encore de compte. Le back réutilise un compte existant (dédup par
/// email/téléphone) ou en crée un « léger » automatiquement.
class DestinataireManuel {
  final String prenom;
  final String nom;
  final String telephone;
  final String? email;
  final String? ville;
  final String? paysId;

  const DestinataireManuel({
    required this.prenom,
    required this.nom,
    required this.telephone,
    this.email,
    this.ville,
    this.paysId,
  });

  String get nomComplet => '$nom $prenom'.trim();

  Map<String, dynamic> toJson() => {
        'prenom': prenom,
        'nom': nom,
        'telephone': telephone,
        if (email != null && email!.trim().isNotEmpty) 'email': email!.trim(),
        if (ville != null && ville!.trim().isNotEmpty) 'ville': ville!.trim(),
        if (paysId != null && paysId!.trim().isNotEmpty) 'paysId': paysId,
      };
}

class EnvoyerColisParams {
  /// Identifiant d'un destinataire existant (résultat de recherche). Null si
  /// [destinataireManuel] est fourni à la place.
  final String? recepteurId;

  /// Destinataire saisi manuellement. Null si [recepteurId] est fourni.
  final DestinataireManuel? destinataireManuel;

  final double poids;
  final double prix;
  final String destination;
  final String typeColis;
  final String? description;

  const EnvoyerColisParams({
    this.recepteurId,
    this.destinataireManuel,
    required this.poids,
    required this.prix,
    required this.destination,
    required this.typeColis,
    this.description,
  }) : assert(recepteurId != null || destinataireManuel != null,
            'recepteurId ou destinataireManuel doit être fourni');

  /// Libellé affichable du destinataire (pour les toasts / le récap du lot).
  String get destinataireLabel =>
      destinataireManuel?.nomComplet ?? '';
}

class EnvoyerColis {
  final ColisRepository repository;
  const EnvoyerColis(this.repository);

  Future<String?> call(EnvoyerColisParams params) => repository.envoyerColis(
        recepteurId: params.recepteurId,
        destinataireManuel: params.destinataireManuel?.toJson(),
        poids: params.poids,
        prix: params.prix,
        destination: params.destination,
        typeColis: params.typeColis,
        description: params.description,
      );
}
