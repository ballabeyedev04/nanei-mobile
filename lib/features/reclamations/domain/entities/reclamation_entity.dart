class ReclamationEntity {
  final String id;
  final String colisId;
  final String type;
  final String description;
  final String statut;
  final List<String> photos;
  final String? commentaireAdmin;
  final DateTime createdAt;

  const ReclamationEntity({
    required this.id,
    required this.colisId,
    required this.type,
    required this.description,
    required this.statut,
    required this.photos,
    this.commentaireAdmin,
    required this.createdAt,
  });
}
