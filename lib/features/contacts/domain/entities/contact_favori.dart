class ContactFavori {
  final String id;
  final String nom;
  final String prenom;
  final String? email;
  final String telephone;
  final String? ville;
  final String? pays;

  const ContactFavori({
    required this.id,
    required this.nom,
    required this.prenom,
    this.email,
    required this.telephone,
    this.ville,
    this.pays,
  });

  String get nomComplet => '$prenom $nom'.trim();
  String get initiales {
    final p = prenom.isNotEmpty ? prenom[0] : '';
    final n = nom.isNotEmpty ? nom[0] : '';
    return '$p$n'.toUpperCase();
  }
}
