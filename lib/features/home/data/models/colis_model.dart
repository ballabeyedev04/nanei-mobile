import '../../domain/entities/colis.dart';
import '../../domain/entities/personne.dart';

class ColisModel extends Colis {
  const ColisModel({
    required super.id,
    required super.reference,
    super.expediteur,
    super.recepteur,
    required super.poids,
    required super.prix,
    required super.destination,
    required super.statut,
    required super.type,
    super.description,
    required super.createdAt,
    super.updatedAt,
  });

  factory ColisModel.fromJson(Map<String, dynamic> json) {
    return ColisModel(
      id: json['id']?.toString() ?? '',
      reference: json['reference'] ?? '',
      expediteur: json['expediteur'] != null
          ? PersonneModel.fromJson(json['expediteur'])
          : null,
      recepteur: json['recepteur'] != null
          ? PersonneModel.fromJson(json['recepteur'])
          : null,
      poids: (json['poids'] as num?)?.toDouble() ?? 0.0,
      prix: (json['prix'] as num?)?.toDouble() ?? 0.0,
      destination: json['destination'] ?? '',
      statut: json['statut'] ?? 'inconnu',
      type: json['type'] ?? json['type_colis'] ?? '',
      description: json['description'],
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'])
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'reference': reference,
        'poids': poids,
        'prix': prix,
        'destination': destination,
        'statut': statut,
        'type': type,
        'description': description,
        'createdAt': createdAt.toIso8601String(),
      };
}

class PersonneModel extends Personne {
  const PersonneModel({
    required super.id,
    required super.nom,
    required super.prenom,
    required super.email,
    required super.telephone,
  });

  factory PersonneModel.fromJson(Map<String, dynamic> json) {
    return PersonneModel(
      id: json['id']?.toString() ?? '',
      nom: json['nom'] ?? '',
      prenom: json['prenom'] ?? '',
      email: json['email'] ?? '',
      telephone: json['telephone'] ?? '',
    );
  }
}
