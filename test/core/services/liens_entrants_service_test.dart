import 'package:flutter_test/flutter_test.dart';
import 'package:nanei/core/services/liens_entrants_service.dart';

/// Retour de paiement par lien profond.
///
/// ## Ce que ce fichier rend impossible
///
/// Après Wave / Orange Money, la page `GET /paiements/retour` du back
/// (`ClientPaiementService.traiterRetour`) redirige vers
/// `nanei://paiement/<succes|verification|echec>?colisId=…`. Un lien mal
/// reconnu laisse « Mes paiements » sur l'ancien statut, et l'utilisateur
/// repaie un colis déjà payé. Un lien étranger (autre chemin, état inventé)
/// ne doit RIEN déclencher.
void main() {
  RetourPaiement? analyser(String lien) =>
      LiensEntrantsService.analyserRetourPaiement(Uri.parse(lien));

  test('les trois états du back (schéma nanei://)', () {
    expect(analyser('nanei://paiement/succes?colisId=c-1'), RetourPaiement.succes);
    expect(analyser('nanei://paiement/verification?colisId=c-1'),
        RetourPaiement.verification);
    expect(analyser('nanei://paiement/echec?colisId='), RetourPaiement.echec);
  });

  test('variante App Link https://hôte/paiement/<état>', () {
    expect(analyser('https://api.app-nanei.com/paiement/succes?colisId=c-1'),
        RetourPaiement.succes);
    expect(analyser('https://api.app-nanei.com/nanei/paiement/echec'),
        RetourPaiement.echec);
  });

  test('liens étrangers : ignorés', () {
    expect(analyser('nanei://paiement'), isNull);
    expect(analyser('nanei://paiement/rembourse'), isNull);
    expect(analyser('nanei://colis/succes'), isNull);
    expect(analyser('https://exemple.com/autre/chemin'), isNull);
    // Sur https, l'hôte « paiement » n'est pas un segment de chemin.
    expect(analyser('https://paiement/succes'), isNull);
  });
}
