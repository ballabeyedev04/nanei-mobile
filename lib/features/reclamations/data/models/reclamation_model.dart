import '../../domain/entities/reclamation_entity.dart';

class ReclamationModel extends ReclamationEntity {
  const ReclamationModel({
    required super.id,
    required super.colisId,
    required super.type,
    required super.description,
    required super.statut,
    required super.photos,
    super.commentaireAdmin,
    required super.createdAt,
  });

  factory ReclamationModel.fromJson(Map<String, dynamic> json) {
    final List rawPhotos = json['photos'] as List? ?? [];
    return ReclamationModel(
      id: json['id']?.toString() ?? '',
      colisId: json['colisId']?.toString() ?? '',
      type: json['type']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      statut: json['statut']?.toString() ?? 'en_attente',
      photos: rawPhotos.map((e) => e.toString()).toList(),
      commentaireAdmin: json['commentaireAdmin']?.toString(),
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}
