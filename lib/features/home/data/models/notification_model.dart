import '../../domain/entities/notification_model.dart';

class NotificationDataModel extends NotificationModel {
  NotificationDataModel({
    required super.id,
    required super.referenceColis,
    required super.typeColis,
    required super.descriptionColis,
    required super.expediteurNom,
    required super.expediteurPrenom,
    required super.expediteurEmail,
    required super.date,
    required super.lue,
  });

  factory NotificationDataModel.fromJson(Map<String, dynamic> json) {
    return NotificationDataModel(
      id: json['id']?.toString() ?? '',
      referenceColis: json['colis']?['reference'] ?? '',
      typeColis: json['colis']?['type_colis'] ?? '',
      descriptionColis: json['colis']?['description'] ?? '',
      expediteurNom: json['expediteur']?['nom'] ?? '',
      expediteurPrenom: json['expediteur']?['prenom'] ?? '',
      expediteurEmail: json['expediteur']?['email'] ?? '',
      // Backend Sequelize : attribut `createdAt` (camel). On tolère `created_at`.
      date: DateTime.tryParse(
              (json['createdAt'] ?? json['created_at'] ?? '').toString()) ??
          DateTime.now(),
      lue: (json['statut'] ?? 'non_lu') == 'lu',
    );
  }
}
