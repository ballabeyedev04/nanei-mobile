import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:nanei/core/theme/app_color.dart';
import '../../domain/entities/colis.dart';
import '../../domain/entities/personne.dart';

// ── Statut ─────────────────────────────────────────────────────────────────

class _Status {
  final String label;
  final Color color;
  final Color bg;
  final IconData icon;
  const _Status({
    required this.label,
    required this.color,
    required this.bg,
    required this.icon,
  });
}

_Status _getStatus(String raw) {
  switch (raw.toLowerCase()) {
    case 'livré':
    case 'livrée':
      return const _Status(
        label: 'Livré',
        color: Color(0xFF059669),
        bg: Color(0xFFD1FAE5),
        icon: Icons.check_circle_rounded,
      );
    case 'recupere':
      return const _Status(
        label: 'Récupéré',
        color: Color(0xFF2563EB),
        bg: Color(0xFFDBEAFE),
        icon: Icons.inventory_2_rounded,
      );
    case 'en_attente':
      return const _Status(
        label: 'En attente',
        color: Color(0xFFB45309),
        bg: Color(0xFFFEF3C7),
        icon: Icons.schedule_rounded,
      );
    default:
      return _Status(
        label: raw,
        color: AppColor.kGrayscale60,
        bg: AppColor.kBackground2,
        icon: Icons.help_outline_rounded,
      );
  }
}

// ── Date ───────────────────────────────────────────────────────────────────

String formatDate(DateTime d) {
  const m = [
    'jan', 'fév', 'mar', 'avr', 'mai', 'juin',
    'juil', 'août', 'sep', 'oct', 'nov', 'déc'
  ];
  return '${d.day} ${m[d.month - 1]}. ${d.year}';
}

// ── Card ───────────────────────────────────────────────────────────────────

Widget buildColisCard({required Colis colis, required bool isReception}) {
  final Personne? personne = isReception ? colis.expediteur : colis.recepteur;
  final String personneNom = personne?.nomComplet ?? 'Inconnu';
  final String initiale =
      personneNom.isNotEmpty ? personneNom[0].toUpperCase() : '?';
  final String personneLabel = isReception ? 'Expéditeur' : 'Destinataire';

  final status = _getStatus(colis.statut);

  // Couleur de l'accent gauche (= couleur statut)
  final accentColor = status.color;

  return Container(
    margin: const EdgeInsets.only(bottom: 16),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.06),
          blurRadius: 20,
          offset: const Offset(0, 6),
        ),
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.03),
          blurRadius: 6,
          offset: const Offset(0, 2),
        ),
      ],
    ),
    child: ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Barre accent gauche colorée selon statut ─────────────────
            Container(width: 5, color: accentColor),

            // ── Contenu ──────────────────────────────────────────────────
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Ligne 1 : référence + badge statut
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                isReception ? 'Colis reçu' : 'Colis envoyé',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: AppColor.kGrayscale40,
                                  letterSpacing: 0.4,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '#${colis.reference}',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w800,
                                  color: AppColor.kGrayscaleDark100,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        // Badge statut
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: status.bg,
                            borderRadius: BorderRadius.circular(30),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 6,
                                height: 6,
                                decoration: BoxDecoration(
                                  color: accentColor,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 5),
                              Text(
                                status.label,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: accentColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 14),

                    // Ligne 2 : destination
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.flight_takeoff_rounded,
                            size: 14,
                            color: AppColor.kGrayscale40,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Vers ',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12,
                              color: AppColor.kGrayscale40,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Expanded(
                            child: Text(
                              colis.destination,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: AppColor.kGrayscaleDark100,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 14),

                    // Ligne 3 : personne
                    Row(
                      children: [
                        // Avatar
                        Container(
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: isReception
                                  ? [
                                      const Color(0xFF2563EB),
                                      const Color(0xFF60A5FA),
                                    ]
                                  : [
                                      AppColor.kPrimary,
                                      AppColor.kPrimaryLight,
                                    ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Center(
                            child: Text(
                              initiale,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 14,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                personneLabel,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 10,
                                  color: AppColor.kGrayscale40,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              Text(
                                personneNom,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: AppColor.kGrayscaleDark100,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                              if (personne?.email != null &&
                                  personne!.email.isNotEmpty)
                                Text(
                                  personne.email,
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 10,
                                    color: AppColor.kGrayscale40,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 14),
                    Divider(height: 1, color: Colors.grey.shade100),
                    const SizedBox(height: 12),

                    // Ligne 4 : méta + date
                    Row(
                      children: [
                        _meta(
                          icon: Icons.category_outlined,
                          label: colis.type.isNotEmpty ? colis.type : 'Colis',
                          color: const Color(0xFF7C3AED),
                        ),
                        const SizedBox(width: 14),
                        _meta(
                          icon: Icons.scale_outlined,
                          label: '${colis.poids.toStringAsFixed(1)} kg',
                          color: AppColor.kGrayscale60,
                        ),
                        const SizedBox(width: 14),
                        _meta(
                          icon: Icons.euro_rounded,
                          label: '${colis.prix.toStringAsFixed(0)} €',
                          color: const Color(0xFF059669),
                        ),
                        const Spacer(),
                        Row(
                          children: [
                            Icon(
                              Icons.calendar_today_outlined,
                              size: 10,
                              color: AppColor.kGrayscale20,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              formatDate(colis.createdAt),
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 10,
                                color: AppColor.kGrayscale40,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

Widget _meta({
  required IconData icon,
  required String label,
  required Color color,
}) {
  return Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(icon, size: 13, color: color),
      const SizedBox(width: 4),
      Text(
        label,
        style: GoogleFonts.plusJakartaSans(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: AppColor.kGrayscale60,
        ),
      ),
    ],
  );
}
