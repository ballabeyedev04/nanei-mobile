import 'package:flutter_test/flutter_test.dart';
import 'package:nanei/features/reclamations/data/models/reclamation_model.dart';

/// Modèle Réclamation.
///
/// ## Ce que ce fichier rend impossible
///
///  - le type `endommagé` (ENUM Postgres, AVEC accent) altéré à la lecture ;
///  - le commentaire de l'admin perdu : il est écrit sous `commentaire_admin`
///    (`adminUpdate`), c'est la réponse que le client attend ;
///  - des photos NULL (colonne JSON vide) qui feraient planter la liste.
void main() {
  test('forme du back (snake_case)', () {
    final r = ReclamationModel.fromJson({
      'id': 'r-1',
      'colis_id': 'c-1',
      'type': 'endommagé',
      'description': 'Carton écrasé',
      'statut': 'rejetee',
      'photos': ['https://cdn/a.jpg', 'https://cdn/b.jpg'],
      'commentaire_admin': 'Photos insuffisantes',
      'createdAt': '2026-10-03T12:00:00.000Z',
    });
    expect(r.colisId, 'c-1');
    expect(r.type, 'endommagé');
    expect(r.statut, 'rejetee');
    expect(r.photos, hasLength(2));
    expect(r.commentaireAdmin, 'Photos insuffisantes');
    expect(r.createdAt, DateTime.utc(2026, 10, 3, 12));
  });

  test('variantes camelCase tolérées, valeurs absentes neutres', () {
    final r = ReclamationModel.fromJson({
      'id': 7,
      'colisId': 'c-2',
      'commentaireAdmin': 'ok',
      'photos': null,
    });
    expect(r.id, '7');
    expect(r.colisId, 'c-2');
    expect(r.commentaireAdmin, 'ok');
    expect(r.photos, isEmpty);
    expect(r.statut, 'ouverte');
  });
}
