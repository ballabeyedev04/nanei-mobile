import '../../domain/entities/client_recherche.dart';

class ClientRechercheModel extends ClientRecherche {
  const ClientRechercheModel({
    required super.id,
    required super.nom,
    required super.prenom,
    required super.email,
    required super.telephone,
  });

  factory ClientRechercheModel.fromJson(Map<String, dynamic> json) {
    return ClientRechercheModel(
      id: json['id']?.toString() ?? '',
      nom: json['nom'] ?? '',
      prenom: json['prenom'] ?? '',
      email: json['email'] ?? '',
      telephone: json['telephone'] ?? '',
    );
  }
}
