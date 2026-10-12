import 'package:flutter_test/flutter_test.dart';
import 'package:nanei/core/services/taux_change_service.dart';

import '../../helpers/dio_espion.dart';
import '../../helpers/environnement.dart';

/// Taux EUR → FCFA pour l'affichage double devise.
///
/// ## Ce que ce fichier rend impossible
///
///  - lire le taux ailleurs que sous `data.valeur` (`pricing.controller.js`,
///    `getTauxChange`) : tous les montants FCFA seraient faux ;
///  - remplacer le taux officiel (655,957) par 0 ou par rien quand l'appel
///    échoue : les prix afficheraient « 0 FCFA ».
void main() {
  setUpAll(initialiserEnvironnementDeTest);

  late DioEspion espion;
  late TauxChangeService service;

  setUp(() {
    espion = DioEspion();
    service = TauxChangeService(dioDeTest(espion));
  });

  test('GET /pricing/taux-change : relit data.valeur', () async {
    espion.repond({
      'success': true,
      'data': {'deviseSource': 'EUR', 'deviseCible': 'FCFA', 'valeur': 656.5},
    });

    await service.charger();

    expect(espion.appel, 'GET /pricing/taux-change');
    expect(service.taux, 656.5);
  });

  test('panne réseau, 500 ou valeur absurde : taux officiel conservé', () async {
    espion.coupeReseau();
    await service.charger();
    expect(service.taux, 655.957);

    final s2 = TauxChangeService(dioDeTest(DioEspion()
      ..repondErreur(500, corps: {'success': false, 'message': 'Erreur serveur'})));
    await s2.charger();
    expect(s2.taux, 655.957);

    final s3 = TauxChangeService(dioDeTest(DioEspion()
      ..repond({'success': true, 'data': {'valeur': 0}})));
    await s3.charger();
    expect(s3.taux, 655.957);
  });
}
