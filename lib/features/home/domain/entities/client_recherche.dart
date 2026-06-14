class ClientRecherche {
  final String id;
  final String nom;
  final String prenom;
  final String email;
  final String telephone;

  const ClientRecherche({
    required this.id,
    required this.nom,
    required this.prenom,
    required this.email,
    this.telephone = '',
  });
}
