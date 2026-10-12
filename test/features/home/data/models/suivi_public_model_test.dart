import 'package:flutter_test/flutter_test.dart';
import 'package:nanei/features/home/data/models/notification_model.dart';
import 'package:nanei/features/home/data/models/prix_calcule_model.dart';
import 'package:nanei/features/home/data/models/suivi_public_model.dart';

/// Modèles « suivi public », notifications et prix calculé.
///
/// ## Ce que ce fichier rend impossible
///
///  - le suivi public (`tracking.controller.js`) relu avec des clés
///    camelCase alors qu'il écrit `type_colis`, `type_transport`,
///    `created_at`, et un historique en `ancien_statut` / `nouveau_statut` ;
///  - un expéditeur ou un historique ABSENT (colis sans compte, colis
///    jamais déplacé) qui ferait planter la feuille de suivi ;
///  - un poids en chaîne qui planterait le suivi ;
///  - une notification lue comme « non lue » (seul `statut: 'lu'` compte)
///    ou sans date ;
///  - un prix calculé relu de travers quand un montant arrive en chaîne.
void main() {
  group('SuiviPublicModel', () {
    test('forme complète du back', () {
      final s = SuiviPublicModel.fromJson({
        'reference': 'COL-1',
        'statut': 'livre',
        'destination': 'Mali',
        'poids': '3.5',
        'type_colis': 'Document',
        'type_transport': 'maritime',
        'created_at': '2026-10-01T10:00:00.000Z',
        'expediteur': {'nom': 'Beye', 'prenom': 'Balla', 'telephone': '06****78'},
        'recepteur': null,
        'historique': [
          {'ancien_statut': null, 'nouveau_statut': 'en_attente', 'created_at': '2026-10-01T10:00:00.000Z'},
          {'ancien_statut': 'en_attente', 'nouveau_statut': 'livre', 'commentaire': 'Remis en main propre', 'created_at': '2026-10-04T10:00:00.000Z'},
        ],
      });

      expect(s.poids, 3.5);
      expect(s.typeColis, 'Document');
      expect(s.typeTransport, 'maritime');
      expect(s.expediteurTelephone, '06****78');
      expect(s.recepteurNom, isNull);
      expect(s.historique.map((h) => h.nouveauStatut), ['en_attente', 'livre']);
      expect(s.historique.first.ancienStatut, isNull);
      expect(s.historique.last.commentaire, 'Remis en main propre');
    });

    test('champs absents : valeurs neutres, aucun plantage', () {
      final s = SuiviPublicModel.fromJson({'reference': 'COL-2'});
      expect(s.statut, 'inconnu');
      expect(s.poids, 0);
      expect(s.createdAt, isNull);
      expect(s.historique, isEmpty);
    });
  });

  group('NotificationDataModel', () {
    test('seul statut « lu » est lu ; date camelCase ou snake_case', () {
      final lue = NotificationDataModel.fromJson({
        'id': 'n1',
        'statut': 'lu',
        'created_at': '2026-10-01T10:00:00.000Z',
      });
      final nonLue = NotificationDataModel.fromJson({'id': 'n2', 'statut': 'non_lu'});
      expect(lue.lue, isTrue);
      expect(lue.date, DateTime.utc(2026, 10, 1, 10));
      expect(nonLue.lue, isFalse);
      expect(nonLue.referenceColis, '');
      expect(nonLue.copyWith(lu: true).lue, isTrue);
    });
  });

  group('PrixCalculeModel', () {
    test('nombres ou chaînes', () {
      final p = PrixCalculeModel.fromJson({
        'shippingPrice': '118.75',
        'pickupPrice': 15,
        'deliveryPrice': null,
        'total': 133.75,
      });
      expect(p.shippingPrice, 118.75);
      expect(p.pickupPrice, 15);
      expect(p.deliveryPrice, 0);
      expect(p.total, 133.75);
    });
  });
}
