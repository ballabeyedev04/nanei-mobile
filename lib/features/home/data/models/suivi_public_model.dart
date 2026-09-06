import '../../domain/entities/suivi_public.dart';

class SuiviPublicModel extends SuiviPublic {
  const SuiviPublicModel({
    required super.reference,
    required super.statut,
    required super.destination,
    required super.poids,
    required super.typeColis,
    super.createdAt,
    super.expediteurNom,
    super.expediteurPrenom,
    super.expediteurTelephone,
    super.recepteurNom,
    super.recepteurPrenom,
    super.recepteurTelephone,
    super.historique,
  });

  static double _d(dynamic v) {
    if (v == null) return 0;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString()) ?? 0;
  }

  static DateTime? _dt(dynamic v) {
    if (v == null) return null;
    return DateTime.tryParse(v.toString());
  }

  factory SuiviPublicModel.fromJson(Map<String, dynamic> json) {
    final exp = json['expediteur'] as Map<String, dynamic>?;
    final rec = json['recepteur'] as Map<String, dynamic>?;
    final histoRaw = (json['historique'] as List?) ?? const [];

    return SuiviPublicModel(
      reference: json['reference']?.toString() ?? '',
      statut: json['statut']?.toString() ?? 'inconnu',
      destination: json['destination']?.toString() ?? '',
      poids: _d(json['poids']),
      typeColis: json['type_colis']?.toString() ?? '',
      createdAt: _dt(json['created_at']),
      expediteurNom: exp?['nom']?.toString(),
      expediteurPrenom: exp?['prenom']?.toString(),
      expediteurTelephone: exp?['telephone']?.toString(),
      recepteurNom: rec?['nom']?.toString(),
      recepteurPrenom: rec?['prenom']?.toString(),
      recepteurTelephone: rec?['telephone']?.toString(),
      historique: histoRaw
          .whereType<Map<String, dynamic>>()
          .map((e) => SuiviEvenement(
                ancienStatut: e['ancien_statut']?.toString(),
                nouveauStatut: e['nouveau_statut']?.toString() ?? '',
                commentaire: e['commentaire']?.toString(),
                date: _dt(e['created_at']),
              ))
          .toList(),
    );
  }
}
