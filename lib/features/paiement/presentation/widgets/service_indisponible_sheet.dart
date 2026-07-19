import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:nanei/core/theme/app_color.dart';

/// Modal temporaire affichée tant que le paiement en ligne (Wave/Orange
/// Money) n'est pas activé côté backend. À retirer et remplacer par
/// ChoixPaiementSheet une fois le paiement géré côté serveur — voir
/// paiements_page.dart::_afficherChoixPaiement.
class ServiceIndisponibleSheet extends StatelessWidget {
  const ServiceIndisponibleSheet({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      padding: EdgeInsets.fromLTRB(
        24, 28, 24,
        MediaQuery.of(context).viewInsets.bottom + 32,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(width: 40, height: 4,
            decoration: BoxDecoration(color: const Color(0xFFE5E7EB), borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 24),
          Container(
            width: 64, height: 64,
            decoration: BoxDecoration(
              color: AppColor.kPrimary.withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.hourglass_empty_rounded, color: AppColor.kPrimary, size: 32),
          ),
          const SizedBox(height: 20),
          Text('Service indisponible',
            style: GoogleFonts.plusJakartaSans(fontSize: 18, fontWeight: FontWeight.w800, color: const Color(0xFF111827))),
          const SizedBox(height: 8),
          Text(
            "Le service de paiement n'est pas disponible pour le moment. Réessayez plus tard.",
            textAlign: TextAlign.center,
            style: GoogleFonts.plusJakartaSans(fontSize: 14, color: const Color(0xFF6B7280), height: 1.4),
          ),
          const SizedBox(height: 28),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColor.kPrimary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 0,
              ),
              child: Text("J'ai compris",
                style: GoogleFonts.plusJakartaSans(fontSize: 15, fontWeight: FontWeight.w800)),
            ),
          ),
        ],
      ),
    );
  }
}
