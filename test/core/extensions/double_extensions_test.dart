import 'package:flutter_test/flutter_test.dart';
import 'package:nanei/core/extensions/double_extensions.dart';

import '../../helpers/dio_espion.dart';
import '../../helpers/environnement.dart';

/// Affichage des montants (€ + équivalent FCFA).
///
/// ## Ce que ce fichier rend impossible
///
///  - un prix au kg ARRONDI à l'unité : une grille à 9,50 €/kg s'affichait
///    « 10 €/kg » alors que le total était calculé sur 9,50 ;
///  - une conversion FCFA qui ne suit pas le taux du `TauxChangeService`
///    (655,957 par défaut) ou un séparateur de milliers manquant.
void main() {
  setUpAll(() async {
    await initialiserEnvironnementDeTest();
    enregistrerDio(dioDeTest(DioEspion()));
  });

  test('montant : 2 décimales + FCFA au taux officiel', () {
    expect(87.5.toEurFcfa(), '87.50 € (≈ 57 396 FCFA)');
  });

  test('prix au kg : décimales seulement si nécessaires', () {
    expect(5.0.toEurFcfaPerKg(), '5 €/kg (≈ 3 280 FCFA/kg)');
    expect(9.5.toEurFcfaPerKg(), '9.50 €/kg (≈ 6 232 FCFA/kg)');
    expect(9.5.toEurFcfaPerKg(decimals: 1), '9.5 €/kg (≈ 6 232 FCFA/kg)');
  });

  test('FCFA seul', () {
    expect(1234567.0.toXof(), '1 234 567 FCFA');
    expect((null as double?).toXofOrDash(), '—');
  });
}
