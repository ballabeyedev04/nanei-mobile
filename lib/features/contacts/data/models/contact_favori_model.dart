import '../../domain/entities/contact_favori.dart';

class ContactFavoriModel extends ContactFavori {
  const ContactFavoriModel({
    required super.id,
    required super.nom,
    required super.prenom,
    super.email,
    required super.telephone,
    super.ville,
    super.pays,
  });

  factory ContactFavoriModel.fromJson(Map<String, dynamic> json) {
    return ContactFavoriModel(
      id: json['id']?.toString() ?? '',
      nom: json['nom']?.toString() ?? '',
      prenom: json['prenom']?.toString() ?? '',
      email: json['email']?.toString(),
      telephone: json['telephone']?.toString() ?? '',
      ville: json['ville']?.toString(),
      pays: json['pays']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'nom': nom,
        'prenom': prenom,
        'email': email,
        'telephone': telephone,
        'ville': ville,
        'pays': pays,
      };
}
