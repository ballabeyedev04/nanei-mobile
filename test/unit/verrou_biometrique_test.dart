import 'package:flutter_test/flutter_test.dart';
import 'package:nanei/core/services/verrou_biometrique.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// État persistant du déverrouillage rapide.
///
/// Deux clés distinctes cohabitent ici, et les confondre est le piège
/// classique : « la proposition a été faite » n'est PAS « le verrou est
/// actif ». Les mélanger activerait le verrou chez quelqu'un ayant répondu
/// « Plus tard », ou reposerait la question à chaque ouverture.
void main() {
  late VerrouBiometrique verrou;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    verrou = VerrouBiometrique(prefs: await SharedPreferences.getInstance());
  });

  test('installation neuve : ni verrou actif, ni proposition faite', () {
    expect(verrou.actif, isFalse);
    expect(verrou.propositionFaite, isFalse);
  });

  test('marquerPropositionFaite n’active PAS le verrou', () async {
    await verrou.marquerPropositionFaite();

    expect(verrou.propositionFaite, isTrue);
    expect(verrou.actif, isFalse);
  });

  test('la proposition survit au redémarrage de l’application', () async {
    await verrou.marquerPropositionFaite();

    // Relu depuis le stockage, pas depuis l'instance : c'est ce qui compte au
    // lancement suivant.
    final apresRedemarrage = VerrouBiometrique(prefs: await SharedPreferences.getInstance());
    expect(apresRedemarrage.propositionFaite, isTrue);
  });

  test('disponible répond false hors appareil, sans lever d’exception', () async {
    // Le plugin local_auth n'existe pas dans l'environnement de test : le
    // service doit annoncer l'indisponibilité plutôt que de laisser remonter
    // une MissingPluginException jusqu'à l'écran.
    await expectLater(verrou.disponible, completion(isFalse));
  });

  test('authentifier renvoie false hors appareil, sans lever d’exception', () async {
    await expectLater(
      verrou.authentifier(motif: 'test'),
      completion(isFalse),
    );
  });

  test('definirActif sans authentification possible laisse le réglage inchangé', () async {
    // Aucun capteur en test : `authentifier` échoue, donc le réglage ne doit
    // PAS être écrit — sinon on poserait un verrou infranchissable.
    final ok = await verrou.definirActif(true, motif: 'test');

    expect(ok, isFalse);
    expect(verrou.actif, isFalse);
  });
}
