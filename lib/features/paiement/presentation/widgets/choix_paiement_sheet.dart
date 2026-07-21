import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:nanei/core/theme/app_color.dart';
import 'package:nanei/core/extensions/double_extensions.dart';

class ChoixPaiementSheet extends StatefulWidget {
  final String reference;
  final double montant;
  final void Function(String moyen) onChoix;

  const ChoixPaiementSheet({
    super.key,
    required this.reference,
    required this.montant,
    required this.onChoix,
  });

  @override
  State<ChoixPaiementSheet> createState() => _ChoixPaiementSheetState();
}

class _ChoixPaiementSheetState extends State<ChoixPaiementSheet>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scale;
  String? _selected;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 400));
    _scale = CurvedAnimation(parent: _ctrl, curve: Curves.easeOutBack);
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scale,
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        ),
        padding: EdgeInsets.fromLTRB(
          24, 16, 24,
          MediaQuery.of(context).viewInsets.bottom + 32,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle
            Container(width: 40, height: 4,
              decoration: BoxDecoration(color: const Color(0xFFE5E7EB), borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 24),

            // Titre
            Text('Choisir un mode de paiement',
              style: GoogleFonts.plusJakartaSans(fontSize: 18, fontWeight: FontWeight.w800, color: const Color(0xFF111827))),
            const SizedBox(height: 6),
            RichText(text: TextSpan(
              style: GoogleFonts.plusJakartaSans(fontSize: 14, color: const Color(0xFF6B7280)),
              children: [
                const TextSpan(text: 'Référence '),
                TextSpan(text: widget.reference,
                  style: const TextStyle(fontWeight: FontWeight.w700, color: Color(0xFF111827))),
                const TextSpan(text: ' · '),
                TextSpan(text: widget.montant.toEurFcfa(),
                  style: const TextStyle(fontWeight: FontWeight.w800, color: AppColor.kPrimary)),
              ],
            )),
            const SizedBox(height: 28),

            // Options
            _PaymentOption(
              selected: _selected == 'wave',
              onTap: () => setState(() => _selected = 'wave'),
              bgColor: const Color(0xFF1463F3),
              logo: _WaveLogo(),
              name: 'Wave',
              description: 'Paiement instantané via Wave',
            ),
            const SizedBox(height: 12),
            _PaymentOption(
              selected: _selected == 'orange_money',
              onTap: () => setState(() => _selected = 'orange_money'),
              bgColor: Colors.white,
              logo: _OMLogo(),
              name: 'Orange Money',
              description: 'Paiement via Orange Money',
            ),
            const SizedBox(height: 28),

            // Bouton confirmer
            SizedBox(
              width: double.infinity,
              child: AnimatedOpacity(
                opacity: _selected != null ? 1.0 : 0.4,
                duration: const Duration(milliseconds: 200),
                child: ElevatedButton(
                  onPressed: _selected != null
                    ? () { Navigator.pop(context); widget.onChoix(_selected!); }
                    : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColor.kPrimary,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: AppColor.kPrimary,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: 0,
                  ),
                  child: Text('Payer maintenant',
                    style: GoogleFonts.plusJakartaSans(fontSize: 15, fontWeight: FontWeight.w800)),
                ),
              ),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Annuler',
                style: GoogleFonts.plusJakartaSans(fontSize: 14, color: const Color(0xFF9CA3AF), fontWeight: FontWeight.w600)),
            ),
          ],
        ),
      ),
    );
  }
}

class _PaymentOption extends StatelessWidget {
  final bool selected;
  final VoidCallback onTap;
  final Color bgColor;
  final Widget logo;
  final String name;
  final String description;

  const _PaymentOption({
    required this.selected,
    required this.onTap,
    required this.bgColor,
    required this.logo,
    required this.name,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? AppColor.kPrimary : const Color(0xFFE5E7EB),
            width: selected ? 2 : 1.5,
          ),
          color: selected ? AppColor.kPrimary.withValues(alpha: 0.04) : Colors.white,
        ),
        child: Row(
          children: [
            // Logo container
            Container(
              width: 56, height: 56,
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.circular(16),
                border: bgColor == Colors.white
                    ? Border.all(color: const Color(0xFFE5E7EB), width: 1)
                    : null,
                boxShadow: [BoxShadow(
                  color: bgColor.withValues(alpha: 0.3),
                  blurRadius: 10, offset: const Offset(0, 4),
                )],
              ),
              child: Center(child: logo),
            ),
            const SizedBox(width: 16),
            Expanded(child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: GoogleFonts.plusJakartaSans(
                  fontSize: 16, fontWeight: FontWeight.w800, color: const Color(0xFF111827))),
                const SizedBox(height: 2),
                Text(description, style: GoogleFonts.plusJakartaSans(
                  fontSize: 12, color: const Color(0xFF6B7280), fontWeight: FontWeight.w500)),
              ],
            )),
            // Radio
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 22, height: 22,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: selected ? AppColor.kPrimary : const Color(0xFFD1D5DB),
                  width: 2,
                ),
                color: selected ? AppColor.kPrimary : Colors.transparent,
              ),
              child: selected
                ? const Icon(Icons.check, size: 13, color: Colors.white)
                : null,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Logos ──────────────────────────────────────────────────────────────────────

class _WaveLogo extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'assets/images/wave_logo.png',
      width: 38,
      height: 38,
      fit: BoxFit.contain,
    );
  }
}

class _OMLogo extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SvgPicture.asset(
      'assets/images/orange_money_logo.svg',
      width: 38,
      height: 38,
      fit: BoxFit.contain,
    );
  }
}
