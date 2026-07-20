import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:nanei/core/theme/app_color.dart';
import '../../../domain/entities/colis.dart';
import '../../widgets/colis_card.dart';

/// Liste tous les colis d'un même lot (envoi groupé) — réutilise exactement
/// la même carte que la liste "Mes colis" (buildColisCard), sans variante.
class LotColisPage extends StatelessWidget {
  final List<Colis> colisDuLot;
  final bool isReception;

  const LotColisPage({
    super.key,
    required this.colisDuLot,
    required this.isReception,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F4F8),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 8, 20, 12),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
                    color: AppColor.kGrayscaleDark100,
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  Expanded(
                    child: Text(
                      'Colis du lot',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: AppColor.kGrayscaleDark100,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                '${colisDuLot.length} colis dans cet envoi',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColor.kGrayscale40,
                ),
              ),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                itemCount: colisDuLot.length,
                itemBuilder: (_, i) => buildColisCard(
                  colis: colisDuLot[i],
                  isReception: isReception,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
