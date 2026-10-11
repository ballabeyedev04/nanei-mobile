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
    super.lotId,
    super.typeTransport,
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
      statut: normaliserStatut(json['statut']?.toString()),
      type: json['type'] ?? json['type_colis'] ?? '',
      description: json['description'],
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'])
          : null,
      lotId: json['lot_id']?.toString(),
      typeTransport: normaliserTypeTransport(json['type_transport']?.toString()),
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
        'lot_id': lotId,
        'type_transport': typeTransport,
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

/// Ramène le mode de transport à 'aerien' | 'maritime' (null si inconnu).
String? normaliserTypeTransport(String? raw) {
  final s = (raw ?? '').trim().toLowerCase().replaceAll('é', 'e');
  if (s == 'aerien') return 'aerien';
  if (s == 'maritime') return 'maritime';
  return null;
}

/// Ramène le statut renvoyé par l'API au code canonique du back
/// (`en_attente` | `recupere` | `livre`), quelles que soient casse et accents.
String normaliserStatut(String? raw) {
  final s = (raw ?? '').trim().toLowerCase();
  switch (s) {
    case 'livre':
    case 'livré':
    case 'livrée':
    case 'livree':
      return 'livre';
    case 'recupere':
    case 'récupéré':
    case 'recuperé':
      return 'recupere';
    case 'en_attente':
    case 'en attente':
      return 'en_attente';
    default:
      return s.isEmpty ? 'inconnu' : s;
  }
}
