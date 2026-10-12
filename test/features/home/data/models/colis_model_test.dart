import 'package:flutter_test/flutter_test.dart';
import 'package:nanei/features/home/data/models/colis_model.dart';

/// Modèle Colis.
///
/// ## Ce que ce fichier rend impossible
///
///  - un statut non reconnu parce qu'il arrive sous une autre forme : le back
///    renvoie des codes SANS accent (`en_attente` | `recupere` | `livre`),
///    d'anciennes données ou l'admin des libellés accentués ;
///  - un mode de transport accentué (`aérien`) qui ne serait pas ramené à
///    `aerien` (filtres et libellés le comparent tel quel) ;
///  - un poids / prix renvoyé en CHAÎNE (colonne NUMERIC : « 12.50 ») qui
///    faisait planter toute la liste sur `as num` ;
///  - un `type_colis` (nom de colonne du back) perdu faute de clé `type`.
void main() {
  group('normaliserStatut', () {
    test('codes canoniques du back', () {
      expect(normaliserStatut('en_attente'), 'en_attente');
      expect(normaliserStatut('recupere'), 'recupere');
      expect(normaliserStatut('livre'), 'livre');
    });

    test('variantes accentuées et casse', () {
      expect(normaliserStatut('Livré'), 'livre');
      expect(normaliserStatut('LIVRÉE'), 'livre');
      expect(normaliserStatut('Récupéré'), 'recupere');
      expect(normaliserStatut('En attente'), 'en_attente');
      expect(normaliserStatut('  livre '), 'livre');
    });

    test('valeur absente ou inconnue', () {
      expect(normaliserStatut(null), 'inconnu');
      expect(normaliserStatut(''), 'inconnu');
      expect(normaliserStatut('perdu'), 'perdu');
    });
  });

  group('normaliserTypeTransport', () {
    test('avec ou sans accent, toute casse', () {
      expect(normaliserTypeTransport('aérien'), 'aerien');
      expect(normaliserTypeTransport('AERIEN'), 'aerien');
      expect(normaliserTypeTransport(' Maritime '), 'maritime');
      expect(normaliserTypeTransport('Vêtement'), isNull);
      expect(normaliserTypeTransport(null), isNull);
    });
  });

  group('ColisModel.fromJson', () {
    Map<String, dynamic> base() => {
          'id': 'c-1',
          'reference': 'COL-2026-A1B2C3-4567',
          'poids': 12.5,
          'prix': 87.5,
          'destination': 'Mali',
          'statut': 'Livré',
          'type_colis': 'Vêtement',
          'type_transport': 'aérien',
          'lot_id': null,
          'createdAt': '2026-10-01T10:00:00.000Z',
        };

    test('statut et transport normalisés, type lu sous type_colis', () {
      final c = ColisModel.fromJson(base());
      expect(c.statut, 'livre');
      expect(c.typeTransport, 'aerien');
      expect(c.typeTransportLabel, 'Aérien');
      expect(c.type, 'Vêtement');
      expect(c.expediteur, isNull);
      expect(c.updatedAt, isNull);
    });

    test('poids et prix en chaîne (NUMERIC) : relus en nombres', () {
      final c = ColisModel.fromJson(base()
        ..['poids'] = '12.50'
        ..['prix'] = '87.5');
      expect(c.poids, 12.5);
      expect(c.prix, 87.5);
    });

    test('poids / prix absents ou illisibles : 0, sans planter', () {
      final c = ColisModel.fromJson(base()
        ..remove('poids')
        ..['prix'] = 'n/a');
      expect(c.poids, 0);
      expect(c.prix, 0);
    });

    test('id numérique et lot_id : convertis en chaîne', () {
      final c = ColisModel.fromJson(base()
        ..['id'] = 42
        ..['lot_id'] = 'lot-1');
      expect(c.id, '42');
      expect(c.lotId, 'lot-1');
    });

    test('toJson conserve les clés snake_case du back', () {
      final json = ColisModel.fromJson(base()..['lot_id'] = 'lot-1').toJson();
      expect(json['lot_id'], 'lot-1');
      expect(json['type_transport'], 'aerien');
      expect(json['statut'], 'livre');
    });
  });
}
