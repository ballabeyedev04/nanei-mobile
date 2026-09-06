import 'package:flutter/foundation.dart';
import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Déverrouillage de l'ouverture de l'application par empreinte, visage ou
/// code de l'appareil.
///
/// Ce verrou protège l'ACCÈS À L'APPLICATION, pas la session : le jeton reste
/// en stockage sécurisé et sa validité n'en dépend pas. Quelqu'un qui
/// extrairait le stockage de l'appareil ne serait pas arrêté par ce réglage —
/// il n'y prétend pas. Il empêche un proche d'ouvrir l'application sur un
/// téléphone laissé déverrouillé.
///
/// Il ne remplace pas non plus la connexion : celle-ci reste nécessaire une
/// fois par appareil pour obtenir le jeton. Le verrou évite seulement d'avoir
/// à ressaisir email et mot de passe à chaque ouverture.
class VerrouBiometrique extends ChangeNotifier {
  final SharedPreferences _prefs;
  final LocalAuthentication _auth;

  VerrouBiometrique({
    required SharedPreferences prefs,
    LocalAuthentication? auth,
  })  : _prefs = prefs,
        _auth = auth ?? LocalAuthentication();

  static const _kActif = 'verrou_biometrique_actif';
  static const _kPropose = 'verrou_biometrique_propose';

  /// Désactivé par défaut : un verrou qu'on n'a pas demandé et qu'on ne sait
  /// pas retirer transformerait l'application en piège.
  bool get actif => _prefs.getBool(_kActif) ?? false;

  /// L'offre d'activation a-t-elle déjà été présentée ?
  ///
  /// Le réglage vit dans le profil, où personne ne va le chercher : on le
  /// propose donc une fois, à l'arrivée dans l'application. UNE fois — reposer
  /// la question à chaque ouverture à quelqu'un qui a répondu « plus tard »
  /// transformerait une commodité en harcèlement, et le refus deviendrait un
  /// réflexe.
  bool get propositionFaite => _prefs.getBool(_kPropose) ?? false;

  Future<void> marquerPropositionFaite() async {
    await _prefs.setBool(_kPropose, true);
  }

  /// L'appareil propose-t-il une authentification UTILISABLE ?
  ///
  /// `isDeviceSupported()` couvre aussi le code de déverrouillage, pas
  /// seulement la biométrie : un téléphone sans empreinte enregistrée mais
  /// avec un code PIN peut parfaitement honorer le réglage, puisque
  /// `authentifier` accepte ce repli.
  Future<bool> get disponible async {
    try {
      return await _auth.isDeviceSupported();
    } catch (_) {
      // Plateforme sans plugin (tests, bureau) : annoncer l'indisponibilité
      // plutôt que de laisser remonter l'exception.
      return false;
    }
  }

  /// Active ou désactive le verrou.
  ///
  /// L'ACTIVATION exige une authentification réussie : sans cela, quelqu'un
  /// qui trouve le téléphone déverrouillé pourrait poser un verrou que le
  /// propriétaire ne saurait pas franchir. La DÉSACTIVATION l'exige aussi,
  /// pour la raison inverse — sinon le verrou se contourne en deux touchers.
  ///
  /// Retourne `false` si l'authentification a échoué : le réglage n'a alors
  /// PAS changé.
  Future<bool> definirActif(bool valeur, {required String motif}) async {
    if (valeur == actif) return true;
    if (!await authentifier(motif: motif)) return false;

    await _prefs.setBool(_kActif, valeur);
    notifyListeners();
    return true;
  }

  /// Demande l'authentification à l'appareil.
  ///
  /// Renvoie `false` sur refus, échec ou absence de capteur — jamais
  /// d'exception : l'appelant n'a qu'un cas d'échec à traiter.
  Future<bool> authentifier({required String motif}) async {
    try {
      return await _auth.authenticate(
        localizedReason: motif,
        options: const AuthenticationOptions(
          // `biometricOnly: false` : le code de déverrouillage de l'appareil
          // reste accepté en repli. L'exiger biométrique enfermerait dehors
          // quiconque a un doigt blessé, mouillé, ou pas de capteur du tout.
          biometricOnly: false,
          stickyAuth: true,
          useErrorDialogs: true,
        ),
      );
    } catch (_) {
      return false;
    }
  }
}
