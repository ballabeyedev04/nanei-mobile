import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:nanei/core/theme/app_color.dart';
import 'package:nanei/core/utils/pagination.dart';

/// Barre de pagination commune à tous les écrans de liste :
/// « Précédent » · « Page X sur Y » · « Suivant ».
///
/// Les boutons sont désactivés aux extrémités et pendant un chargement.
class BarrePagination extends StatelessWidget {
  final InfoPagination pagination;

  /// Appelé avec le numéro de la page demandée.
  final ValueChanged<int> onPage;

  /// Désactive les boutons (chargement en cours).
  final bool chargement;

  /// Libellé du total, ex. « colis », « notifications » (affiché sous la page).
  final String? libelleTotal;

  final EdgeInsetsGeometry padding;

  const BarrePagination({
    super.key,
    required this.pagination,
    required this.onPage,
    this.chargement = false,
    this.libelleTotal,
    this.padding = const EdgeInsets.symmetric(vertical: 12),
  });

  @override
  Widget build(BuildContext context) {
    final p = pagination;
    final precedente = p.aPrecedente && !chargement;
    final suivante = p.aSuivante && !chargement;

    return Padding(
      padding: padding,
      child: Row(
        children: [
          _Bouton(
            key: const Key('pagination_precedent'),
            libelle: 'Précédent',
            icone: Icons.chevron_left_rounded,
            iconeAvant: true,
            actif: precedente,
            onTap: () => onPage(p.page - 1),
          ),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Page ${p.page} sur ${p.pages}',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColor.kGrayscaleDark100,
                  ),
                ),
                if (libelleTotal != null)
                  Text(
                    '${p.total} $libelleTotal',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      color: AppColor.kGrayscale40,
                    ),
                  ),
              ],
            ),
          ),
          _Bouton(
            key: const Key('pagination_suivant'),
            libelle: 'Suivant',
            icone: Icons.chevron_right_rounded,
            iconeAvant: false,
            actif: suivante,
            onTap: () => onPage(p.page + 1),
          ),
        ],
      ),
    );
  }
}

class _Bouton extends StatelessWidget {
  final String libelle;
  final IconData icone;
  final bool iconeAvant;
  final bool actif;
  final VoidCallback onTap;

  const _Bouton({
    super.key,
    required this.libelle,
    required this.icone,
    required this.iconeAvant,
    required this.actif,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final couleur = actif ? AppColor.kPrimary : AppColor.kGrayscale20;
    final icon = Icon(icone, size: 18, color: couleur);
    final texte = Text(
      libelle,
      style: GoogleFonts.plusJakartaSans(
        fontSize: 12.5,
        fontWeight: FontWeight.w700,
        color: couleur,
      ),
    );

    return Semantics(
      button: true,
      enabled: actif,
      label: libelle,
      child: Material(
        color: actif ? AppColor.kAccentSoft : AppColor.kBackground2,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: actif ? onTap : null,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: EdgeInsets.fromLTRB(
                iconeAvant ? 8 : 14, 10, iconeAvant ? 14 : 8, 10),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: iconeAvant
                  ? [icon, const SizedBox(width: 2), texte]
                  : [texte, const SizedBox(width: 2), icon],
            ),
          ),
        ),
      ),
    );
  }
}

/// Ramène une liste en haut (changement de page).
void remonterEnHaut(ScrollController controller) {
  if (!controller.hasClients) return;
  controller.animateTo(
    0,
    duration: const Duration(milliseconds: 250),
    curve: Curves.easeOut,
  );
}
