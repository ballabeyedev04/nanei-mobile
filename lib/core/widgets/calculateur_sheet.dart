import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_color.dart';
import '../../injection_container.dart';
import '../../features/home/domain/entities/country_pricing.dart';
import '../../features/home/domain/usecases/get_countries.dart';
import '../../features/home/domain/usecases/get_pricing_by_country.dart';

Future<void> showCalculateurSheet(BuildContext context) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => const _CalculateurSheet(),
  );
}

class _CalculateurSheet extends StatefulWidget {
  const _CalculateurSheet();

  @override
  State<_CalculateurSheet> createState() => _CalculateurSheetState();
}

class _CalculateurSheetState extends State<_CalculateurSheet> {
  // ── Pays ──────────────────────────────────────────────────────────────────
  List<CountryItem> _countries = [];
  bool _loadingCountries = true;
  CountryItem? _selectedCountry;

  // ── Pricing ───────────────────────────────────────────────────────────────
  CountryPricing? _pricing;
  bool _loadingPricing = false;
  String? _selectedType; // 'aérien' | 'maritime'

  // ── Saisie ────────────────────────────────────────────────────────────────
  final _poidsCtrl = TextEditingController();
  double? _prixEstime;
  double? _pricePerKg;

  @override
  void initState() {
    super.initState();
    _poidsCtrl.addListener(_calculer);
    _loadCountries();
  }

  @override
  void dispose() {
    _poidsCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadCountries() async {
    try {
      final countries = await sl<GetCountries>()();
      if (mounted) setState(() { _countries = countries; _loadingCountries = false; });
    } catch (_) {
      if (mounted) setState(() => _loadingCountries = false);
    }
  }

  Future<void> _onCountrySelected(CountryItem country) async {
    setState(() {
      _selectedCountry = country;
      _pricing = null;
      _selectedType = null;
      _prixEstime = null;
      _pricePerKg = null;
      _loadingPricing = true;
    });
    try {
      final pricing = await sl<GetPricingByCountry>()(country.id);
      if (!mounted) return;
      // Pré-sélectionner le premier type disponible
      final types = pricing.shippingPrices.map((p) => p.type).toSet().toList();
      setState(() {
        _pricing = pricing;
        _loadingPricing = false;
        _selectedType = types.isNotEmpty ? types.first : null;
      });
      _calculer();
    } catch (_) {
      if (mounted) setState(() => _loadingPricing = false);
    }
  }

  void _onTypeSelected(String type) {
    setState(() {
      _selectedType = type;
      _prixEstime = null;
      _pricePerKg = null;
    });
    _calculer();
  }

  void _calculer() {
    if (_pricing == null || _selectedType == null) return;
    final poids = double.tryParse(_poidsCtrl.text.replaceAll(',', '.'));
    if (poids == null || poids <= 0) {
      setState(() { _prixEstime = null; _pricePerKg = null; });
      return;
    }
    final prices = _pricing!.shippingPrices
        .where((p) => p.type == _selectedType)
        .toList();
    ShippingPriceItem? applicable;
    for (final p in prices) {
      if (poids >= p.minWeight && poids <= p.maxWeight) {
        applicable = p;
        break;
      }
    }
    // Fallback : dernier palier (poids > max)
    if (applicable == null && prices.isNotEmpty) {
      applicable = prices.last;
    }
    if (applicable == null) return;
    setState(() {
      _pricePerKg = applicable!.pricePerKg;
      _prixEstime = poids * applicable.pricePerKg;
    });
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).viewInsets.bottom;
    final types = _pricing?.shippingPrices.map((p) => p.type).toSet().toList() ?? [];

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.fromLTRB(24, 0, 24, 24 + bottomPadding),
      child: SingleChildScrollView(
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

            // ── Pays ────────────────────────────────────────────────────────
            Text(
              'Pays de destination',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColor.kGrayscaleDark100,
              ),
            ),
            const SizedBox(height: 10),
            if (_loadingCountries)
              const Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
              )
            else if (_countries.isEmpty)
              Text(
                'Aucun pays disponible.',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  color: AppColor.kGrayscale40,
                ),
              )
            else
              SizedBox(
                height: 44,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: _countries.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (_, i) {
                    final c = _countries[i];
                    final selected = _selectedCountry?.id == c.id;
                    return GestureDetector(
                      onTap: () => _onCountrySelected(c),
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
                        child: Text(
                          c.name,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: selected
                                ? Colors.white
                                : AppColor.kGrayscale60,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),

            // ── Type transport ───────────────────────────────────────────────
            if (_selectedCountry != null) ...[
              const SizedBox(height: 20),
              Text(
                'Type de transport',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColor.kGrayscaleDark100,
                ),
              ),
              const SizedBox(height: 10),
              if (_loadingPricing)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
                )
              else if (types.isEmpty)
                Text(
                  'Aucun tarif disponible pour ce pays.',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    color: AppColor.kGrayscale40,
                  ),
                )
              else
                Row(
                  children: types.map((type) {
                    final selected = _selectedType == type;
                    final icon = type == 'aérien'
                        ? Icons.flight_rounded
                        : Icons.directions_boat_rounded;
                    final pkgPrice = _pricing!.shippingPrices
                        .firstWhere((p) => p.type == type)
                        .pricePerKg;
                    return Expanded(
                      child: GestureDetector(
                        onTap: () => _onTypeSelected(type),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          margin: EdgeInsets.only(
                              right: type != types.last ? 8 : 0),
                          padding: const EdgeInsets.symmetric(
                              vertical: 12, horizontal: 12),
                          decoration: BoxDecoration(
                            color: selected
                                ? AppColor.kAccentSoft
                                : const Color(0xFFF2F4F8),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: selected
                                  ? AppColor.kPrimary
                                  : const Color(0xFFE5E7EB),
                              width: selected ? 2 : 1,
                            ),
                          ),
                          child: Column(
                            children: [
                              Icon(icon,
                                  size: 22,
                                  color: selected
                                      ? AppColor.kPrimary
                                      : AppColor.kGrayscale40),
                              const SizedBox(height: 4),
                              Text(
                                type[0].toUpperCase() + type.substring(1),
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: selected
                                      ? AppColor.kPrimary
                                      : AppColor.kGrayscaleDark100,
                                ),
                              ),
                              Text(
                                '${pkgPrice.toStringAsFixed(0)} €/kg',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 11,
                                  color: selected
                                      ? AppColor.kPrimary
                                      : AppColor.kGrayscale40,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
            ],

            // ── Poids ────────────────────────────────────────────────────────
            const SizedBox(height: 20),
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
              style: GoogleFonts.plusJakartaSans(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColor.kGrayscaleDark100,
              ),
              decoration: InputDecoration(
                hintText: 'Ex : 2.5',
                hintStyle: GoogleFonts.plusJakartaSans(
                    fontSize: 14, color: AppColor.kGrayscale20),
                prefixIcon: const Icon(Icons.scale_outlined, size: 20),
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
                    borderSide:
                        BorderSide(color: AppColor.kPrimary, width: 1.5)),
              ),
            ),

            const SizedBox(height: 20),

            // ── Résultat ─────────────────────────────────────────────────────
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
      ),
    );
  }

  Widget _buildResult() {
    final poids =
        double.tryParse(_poidsCtrl.text.replaceAll(',', '.')) ?? 0;

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
                  '${_selectedCountry!.name}  ·  ${poids.toStringAsFixed(1)} kg'
                  '  ·  ${_pricePerKg?.toStringAsFixed(2) ?? '—'} €/kg'
                  '  ·  ${_selectedType ?? ''}',
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
              'Choisissez un pays, un type de transport\net entrez le poids pour voir l\'estimation.',
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
