import '../../domain/entities/avis_entity.dart';

class AvisModel extends AvisEntity {
  const AvisModel({
    required super.id,
    required super.colisId,
    required super.note,
    super.commentaire,
  });

  factory AvisModel.fromJson(Map<String, dynamic> json) {
    return AvisModel(
      id: json['id']?.toString() ?? '',
      colisId: json['colisId']?.toString() ?? '',
      note: (json['note'] as num?)?.toInt() ?? 0,
      commentaire: json['commentaire']?.toString(),
    );
  }
}
