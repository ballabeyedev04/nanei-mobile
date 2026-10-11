import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:toastification/toastification.dart';

import '../routes/navigation.dart';
import '../utils/app_logger.dart';
import '../widgets/toastNotif.dart';

/// Résultat d'un retour de paiement reçu par lien profond.
enum RetourPaiement { succes, verification, echec }

/// Liens profonds entrants.
///
/// Après un paiement Wave / Orange Money, la page de retour du back
/// (`GET /paiements/retour`) redirige vers :
///   - `nanei://paiement/succes?colisId=…`
///   - `nanei://paiement/verification?colisId=…` (en attente de confirmation
///     de l'opérateur)
///   - `nanei://paiement/echec?colisId=…`
/// La variante App Link `https://<hôte>/paiement/<etat>` est aussi acceptée.
class LiensEntrantsService {
  LiensEntrantsService._();

  static final _appLinks = AppLinks();
  static StreamSubscription<Uri>? _abonnement;

  static final StreamController<RetourPaiement> _retoursPaiement =
      StreamController<RetourPaiement>.broadcast();

  /// Émis à chaque retour de paiement : la page « Mes paiements » s'y abonne
  /// pour recharger la liste.
  static Stream<RetourPaiement> get retoursPaiement => _retoursPaiement.stream;

  static Future<void> init() async {
    if (_abonnement != null) return;
    // uriLinkStream émet aussi le lien qui a lancé l'app (démarrage à froid).
    _abonnement = _appLinks.uriLinkStream.listen(
      _traiter,
      onError: (Object e) => AppLogger.warning('Lien entrant invalide', e.toString()),
    );
  }

  static void _traiter(Uri uri) {
    AppLogger.debug('Lien entrant reçu', {'uri': uri.toString()});
    final retour = analyserRetourPaiement(uri);
    if (retour == null) return;

    _retoursPaiement.add(retour);

    final (titre, texte, type) = switch (retour) {
      RetourPaiement.succes => (
          'Paiement réussi',
          'Votre paiement a bien été enregistré.',
          ToastificationType.success,
        ),
      RetourPaiement.verification => (
          'Paiement en cours de vérification',
          "L'opérateur confirme votre paiement. Le statut sera mis à jour dans quelques instants.",
          ToastificationType.info,
        ),
      RetourPaiement.echec => (
          'Paiement échoué',
          'Le paiement a échoué ou a été annulé.',
          ToastificationType.error,
        ),
    };
    // Laisse l'app reprendre le premier plan avant d'afficher le toast.
    Future.delayed(const Duration(milliseconds: 400), () {
      final ctx = contexteGlobal;
      if (ctx != null && ctx.mounted) showToast(ctx, titre, texte, type);
    });
  }

  /// `nanei://paiement/<etat>` → host = paiement, chemin = /<etat> ;
  /// `https://hote/paiement/<etat>` → chemin = /paiement/<etat>.
  static RetourPaiement? analyserRetourPaiement(Uri uri) {
    final segments = [
      if (uri.scheme != 'http' && uri.scheme != 'https') uri.host,
      ...uri.pathSegments,
    ].where((s) => s.isNotEmpty).toList();
    final i = segments.indexOf('paiement');
    if (i < 0 || i + 1 >= segments.length) return null;
    return switch (segments[i + 1]) {
      'succes' => RetourPaiement.succes,
      'verification' => RetourPaiement.verification,
      'echec' => RetourPaiement.echec,
      _ => null,
    };
  }
}
