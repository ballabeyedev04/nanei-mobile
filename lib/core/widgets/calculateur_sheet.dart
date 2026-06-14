import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_color.dart';

Future<void> showCalculateurSheet(BuildContext context) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => const _CalculateurSheet(),
  );
}

class _Pays {
  final String nom;
  final String drapeau;
  final double prixParKg;
  const _Pays(this.nom, this.drapeau, this.prixParKg);
}

const _paysList = [
  _Pays('Sénégal',      '🇸🇳', 4.5),
  _Pays('Mali',         '🇲🇱', 5.0),
  _Pays('Côte d\'Ivoire','🇨🇮', 5.5),
  _Pays('France',       '🇫🇷', 8.0),
  _Pays('Guinée',       '🇬🇳', 5.0),
  _Pays('Burkina Faso', '🇧🇫', 5.2),
];

class _CalculateurSheet extends StatefulWidget {
  const _CalculateurSheet();

  @override
  State<_CalculateurSheet> createState() => _CalculateurSheetState();
}

class _CalculateurSheetState extends State<_CalculateurSheet> {
  _Pays? _selectedPays;
  final _poidsCtrl = TextEditingController();
  double? _prixEstime;

  @override
  void dispose() {
    _poidsCtrl.dispose();
    super.dispose();
  }

  void _calculer() {
    final poids = double.tryParse(_poidsCtrl.text.replaceAll(',', '.'));
    if (poids == null || poids <= 0 || _selectedPays == null) return;
    setState(() => _prixEstime = poids * _selectedPays!.prixParKg);
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.fromLTRB(24, 0, 24, 24 + bottomPadding),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 12, bottom: 20),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFE5E7EB),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // Titre
          Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF7C3AED), Color(0xFF9F67F5)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF7C3AED).withValues(alpha: 0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Icon(Icons.calculate_rounded,
                    color: Colors.white, size: 24),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Calculer le tarif',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: AppColor.kGrayscaleDark100,
                      ),
                    ),
                    Text(
                      'Estimez le coût de votre envoi',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        color: AppColor.kGrayscale40,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Sélecteur pays
          Text(
            'Pays de destination',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColor.kGrayscaleDark100,
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 44,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _paysList.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (_, i) {
                final pays = _paysList[i];
                final selected = _selectedPays == pays;
                return GestureDetector(
                  onTap: () {
                    setState(() => _selectedPays = pays);
                    _calculer();
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: selected
                          ? AppColor.kPrimary
                          : const Color(0xFFF2F4F8),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: selected
                            ? AppColor.kPrimary
                            : const Color(0xFFE5E7EB),
                      ),
                    ),
                    child: Row(
                      children: [
                        Text(pays.drapeau,
                            style: const TextStyle(fontSize: 16)),
                        const SizedBox(width: 6),
                        Text(
                          pays.nom,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: selected
                                ? Colors.white
                                : AppColor.kGrayscale60,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: 20),

          // Champ poids
          Text(
            'Poids du colis (kg)',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColor.kGrayscaleDark100,
            ),
          ),
          const SizedBox(height: 10),
          TextFormField(
            controller: _poidsCtrl,
            keyboardType:
                const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
            ],
            onChanged: (_) => _calculer(),
            style: GoogleFonts.plusJakartaSans(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColor.kGrayscaleDark100,
            ),
            decoration: InputDecoration(
              hintText: 'Ex : 2.5',
              hintStyle: GoogleFonts.plusJakartaSans(
                  fontSize: 14, color: AppColor.kGrayscale20),
              prefixIcon:
                  const Icon(Icons.scale_outlined, size: 20),
              prefixIconColor: AppColor.kGrayscale40,
              suffixText: 'kg',
              suffixStyle: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColor.kGrayscale40),
              filled: true,
              fillColor: const Color(0xFFF8FAFC),
              contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 14),
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide:
                      const BorderSide(color: Color(0xFFE5E9F2))),
              enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide:
                      const BorderSide(color: Color(0xFFE5E9F2))),
              focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(
                      color: AppColor.kPrimary, width: 1.5)),
            ),
          ),

          const SizedBox(height: 20),

          // Résultat
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            transitionBuilder: (child, anim) => SlideTransition(
              position: Tween<Offset>(
                      begin: const Offset(0, 0.3), end: Offset.zero)
                  .animate(CurvedAnimation(
                      parent: anim, curve: Curves.easeOutCubic)),
              child: FadeTransition(opacity: anim, child: child),
            ),
            child: _prixEstime != null
                ? _buildResult()
                : _buildPlaceholder(),
          ),

          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildResult() {
    final pays = _selectedPays!;
    final poids = double.tryParse(_poidsCtrl.text.replaceAll(',', '.')) ?? 0;

    return Container(
      key: const ValueKey('result'),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFF7A00), Color(0xFFE06A00)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: AppColor.kPrimary.withValues(alpha: 0.30),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Estimation du tarif',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    color: Colors.white.withValues(alpha: 0.75),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${_prixEstime!.toStringAsFixed(2)} €',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 32,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    height: 1,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '${pays.drapeau} ${pays.nom}  ·  ${poids.toStringAsFixed(1)} kg  ·  ${pays.prixParKg} €/kg',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    color: Colors.white.withValues(alpha: 0.75),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.euro_rounded,
                color: Colors.white, size: 28),
          ),
        ],
      ),
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      key: const ValueKey('placeholder'),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE5E9F2)),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline_rounded,
              size: 20, color: AppColor.kGrayscale20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Choisissez un pays et entrez le poids\npour voir l\'estimation.',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                color: AppColor.kGrayscale40,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
