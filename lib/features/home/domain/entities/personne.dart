class Personne {
  final String id;
  final String nom;
  final String prenom;
  final String email;
  final String telephone;

  const Personne({
    required this.id,
    required this.nom,
    required this.prenom,
    required this.email,
    this.telephone = '',
  });

  String get nomComplet => '$prenom $nom'.trim();
}
