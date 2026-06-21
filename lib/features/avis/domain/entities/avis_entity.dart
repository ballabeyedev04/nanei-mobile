class AvisEntity {
  final String id;
  final String colisId;
  final int note;
  final String? commentaire;

  const AvisEntity({
    required this.id,
    required this.colisId,
    required this.note,
    this.commentaire,
  });
}
