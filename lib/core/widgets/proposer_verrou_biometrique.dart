import 'package:flutter/material.dart';

import '../services/verrou_biometrique.dart';
import '../theme/app_color.dart';

/// Propose UNE fois le déverrouillage rapide, à l'arrivée dans l'application.
///
/// Le réglage existe dans le profil, mais personne ne va l'y chercher : sans
/// cette invitation au bon moment, la fonctionnalité n'est jamais activée. Le
/// dialogue ne fait que rendre découvrable un interrupteur déjà en place.
///
/// À appeler depuis l'écran d'accueil qui suit la connexion, après la
/// première image.
Future<void> proposerVerrouBiometrique(
  BuildContext context,
  VerrouBiometrique verrou,
) async {
  if (verrou.actif || verrou.propositionFaite) return;
  // Un appareil sans authentification utilisable ne peut pas honorer le
  // réglage : proposer serait promettre ce qu'on ne peut pas tenir.
  if (!await verrou.disponible) return;
  if (!context.mounted) return;

  final accepte = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      icon: Container(
        width: 62,
        height: 62,
        decoration: const BoxDecoration(color: AppColor.kAccentSoft, shape: BoxShape.circle),
        child: const Icon(Icons.fingerprint_rounded, size: 32, color: AppColor.kPrimary),
      ),
      title: const Text(
        'Se connecter plus vite ?',
        textAlign: TextAlign.center,
        style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800, color: AppColor.kBlack),
      ),
      content: const Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Ouvrez l’application avec votre empreinte, votre visage ou le code '
            'de votre téléphone, sans ressaisir vos identifiants.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14.5, height: 1.45, color: AppColor.kGrayscale60),
          ),
          SizedBox(height: 10),
          Text(
            'Vous pourrez le modifier dans Paramètres.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12.5, color: AppColor.kGrayscale40),
          ),
        ],
      ),
      actionsAlignment: MainAxisAlignment.spaceBetween,
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext, false),
          style: TextButton.styleFrom(foregroundColor: AppColor.kGrayscale40),
          child: const Text('Plus tard', style: TextStyle(fontWeight: FontWeight.w600)),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(dialogContext, true),
          style: FilledButton.styleFrom(
            backgroundColor: AppColor.kPrimary,
            padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          child: const Text('Activer', style: TextStyle(fontWeight: FontWeight.w700)),
        ),
      ],
    ),
  );

  if (accepte != true) {
    // Refus explicite (ou dialogue fermé) : on ne repose plus la question.
    await verrou.marquerPropositionFaite();
    return;
  }

  // `definirActif` redemande l'authentification pour confirmer : c'est elle
  // qui fait apparaître la boîte du système (empreinte, visage, ou code de
  // l'appareil en repli).
  final active = await verrou.definirActif(
    true,
    motif: 'Confirmez pour activer le déverrouillage rapide',
  );

  // Marqué SEULEMENT si l'activation a abouti : un capteur qui n'a pas lu le
  // doigt du premier coup ne doit pas coûter l'offre définitivement.
  if (active) {
    await verrou.marquerPropositionFaite();
    return;
  }

  if (!context.mounted) return;
  ScaffoldMessenger.maybeOf(context)?.showSnackBar(
    const SnackBar(content: Text('Activation annulée. Réglage disponible dans votre profil.')),
  );
}
