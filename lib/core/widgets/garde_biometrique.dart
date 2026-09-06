import 'package:flutter/material.dart';

import '../services/verrou_biometrique.dart';
import '../theme/app_color.dart';

/// Voile de verrouillage posé au-dessus de l'application.
///
/// Placé dans le `builder` de `MaterialApp`, il couvre donc TOUS les écrans,
/// y compris ceux ouverts depuis une notification : un lien profond ne doit
/// pas être un chemin de contournement du verrou.
///
/// Le contenu reste MONTÉ derrière le voile plutôt que d'être remplacé : le
/// démonter viderait chaque bloc et forcerait un rechargement complet à
/// chaque retour d'arrière-plan.
class GardeBiometrique extends StatefulWidget {
  final VerrouBiometrique verrou;
  final Widget child;

  const GardeBiometrique({super.key, required this.verrou, required this.child});

  @override
  State<GardeBiometrique> createState() => _GardeBiometriqueState();
}

class _GardeBiometriqueState extends State<GardeBiometrique> with WidgetsBindingObserver {
  bool _verrouille = false;
  bool _demandeEnCours = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    if (widget.verrou.actif) {
      _verrouille = true;
      // Après la première image : `authenticate` ouvre une boîte système,
      // impossible pendant la construction de l'arbre.
      WidgetsBinding.instance.addPostFrameCallback((_) => _demander());
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState etat) {
    // Reverrouiller au retour d'arrière-plan : un verrou qui ne joue qu'au
    // tout premier lancement ne protège rien, l'application restant ouverte
    // des journées entières.
    //
    // `paused` et non `inactive` : `inactive` se déclenche aussi pour un
    // appel entrant ou le centre de contrôle, ce qui redemanderait
    // l'empreinte en permanence.
    if (etat == AppLifecycleState.paused && widget.verrou.actif && !_verrouille) {
      setState(() => _verrouille = true);
    }
    if (etat == AppLifecycleState.resumed && _verrouille && !_demandeEnCours) {
      _demander();
    }
  }

  Future<void> _demander() async {
    if (_demandeEnCours) return;
    _demandeEnCours = true;
    final ok = await widget.verrou.authentifier(
      motif: 'Déverrouillez Nanei pour continuer',
    );
    _demandeEnCours = false;
    if (!mounted) return;
    if (ok) setState(() => _verrouille = false);
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,
        if (_verrouille)
          // Opaque : le voile doit masquer le contenu, pas seulement le
          // rendre inactif — c'est tout l'objet du verrou.
          Positioned.fill(
            child: ColoredBox(
              color: AppColor.kWhite,
              child: SafeArea(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 88,
                          height: 88,
                          decoration: const BoxDecoration(
                            color: AppColor.kAccentSoft,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.lock_rounded, size: 40, color: AppColor.kPrimary),
                        ),
                        const SizedBox(height: 22),
                        const Text(
                          'Application verrouillée',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 19,
                            fontWeight: FontWeight.w800,
                            color: AppColor.kBlack,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Authentifiez-vous pour accéder à vos colis.',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 14, color: AppColor.kGrayscale40),
                        ),
                        const SizedBox(height: 24),
                        FilledButton.icon(
                          onPressed: _demander,
                          style: FilledButton.styleFrom(
                            backgroundColor: AppColor.kPrimary,
                            padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                          icon: const Icon(Icons.fingerprint_rounded, size: 20),
                          label: const Text(
                            'Déverrouiller',
                            style: TextStyle(fontWeight: FontWeight.w700),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
