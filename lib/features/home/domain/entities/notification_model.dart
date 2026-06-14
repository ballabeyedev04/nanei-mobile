class NotificationModel {
  final String id;
  final String referenceColis;
  final String typeColis;
  final String descriptionColis;
  final String expediteurNom;
  final String expediteurPrenom;
  final String expediteurEmail;
  final DateTime date;
  final bool lue;

  NotificationModel({
    required this.id,
    required this.referenceColis,
    required this.typeColis,
    required this.descriptionColis,
    required this.expediteurNom,
    required this.expediteurPrenom,
    required this.expediteurEmail,
    required this.date,
    required this.lue,
  });

  NotificationModel copyWith({bool? lu}) => NotificationModel(
        id: id,
        referenceColis: referenceColis,
        typeColis: typeColis,
        descriptionColis: descriptionColis,
        expediteurNom: expediteurNom,
        expediteurPrenom: expediteurPrenom,
        expediteurEmail: expediteurEmail,
        date: date,
        lue: lu ?? this.lue,
      );

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id']?.toString() ?? '',
      referenceColis: json['colis']?['reference'] ?? '',
      typeColis: json['colis']?['type_colis'] ?? '',
      descriptionColis: json['colis']?['description'] ?? '',
      expediteurNom: json['expediteur']?['nom'] ?? '',
      expediteurPrenom: json['expediteur']?['prenom'] ?? '',
      expediteurEmail: json['expediteur']?['email'] ?? '',
      date: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
      lue: (json['statut'] ?? 'non_lu') == 'lu',
    );
  }
}