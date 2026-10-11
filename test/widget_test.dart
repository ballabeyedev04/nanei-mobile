import 'package:flutter_test/flutter_test.dart';
import 'package:nanei/features/home/data/models/colis_model.dart';

// Le back renvoie des codes de statut sans accent (en_attente | recupere |
// livre) : l'app doit les reconnaître quelle que soit leur forme.
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
    });

    test('valeur absente ou inconnue', () {
      expect(normaliserStatut(null), 'inconnu');
      expect(normaliserStatut(''), 'inconnu');
      expect(normaliserStatut('perdu'), 'perdu');
    });
  });
}
