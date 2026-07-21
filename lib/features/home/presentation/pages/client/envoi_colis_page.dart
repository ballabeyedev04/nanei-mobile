import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:toastification/toastification.dart';
import 'dart:async';
import 'package:nanei/core/theme/app_color.dart';
import 'package:nanei/core/extensions/double_extensions.dart';
import 'package:nanei/core/widgets/app_toast.dart';
import 'package:nanei/core/widgets/toastNotif.dart';
import '../../bloc/colis_bloc.dart';
import '../../bloc/colis_event.dart';
import '../../../domain/entities/client_recherche.dart';
import '../../../domain/entities/country_pricing.dart';
import '../../../domain/usecases/envoyer_colis.dart';
import '../../../domain/usecases/envoyer_colis_lot.dart';
import '../../../domain/usecases/rechercher_client.dart';
import '../../../domain/usecases/get_countries.dart';
import '../../../domain/usecases/get_pricing_by_country.dart';
import 'package:nanei/injection_container.dart';

class EnvoiColisPage extends StatefulWidget {
  const EnvoiColisPage({super.key});

  @override
  State<EnvoiColisPage> createState() => _EnvoiColisPageState();
}

/// Un colis déjà validé et mis de côté dans le lot en cours de constitution
/// (regroupement — plusieurs colis envoyés en une seule commande).
class _PanierItem {
  final EnvoyerColisParams params;
  final String destinataireNom;
  final String paysNom;

  const _PanierItem({
    required this.params,
    required this.destinataireNom,
    required this.paysNom,
  });
}

class _EnvoiColisPageState extends State<EnvoiColisPage> {
  int _currentStep = 1;

  // ── Regroupement de colis ────────────────────────────────────────────────
  // Colis déjà "ajoutés au lot" en attente d'être envoyés ensemble en une
  // seule commande. Vide = comportement inchangé (envoi simple d'un colis).
  final List<_PanierItem> _panier = [];

  // ── Pays / Pricing ───────────────────────────────────────────────────────
  List<CountryItem> _countries = [];
  bool _isLoadingCountries = false;
  CountryItem? _selectedCountry;
  CountryPricing? _countryPricing;
  bool _isLoadingPricing = false;
  String? _selectedShippingType; // 'aérien' | 'maritime'

  // ── Services optionnels ──────────────────────────────────────────────────
  bool _needsPickup = false;
  bool _needsDelivery = false;

  // ── Champs formulaire ────────────────────────────────────────────────────
  final _poidsController = TextEditingController();
  final _typeController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _rechercheController = TextEditingController();
  final _rechercheFocus = FocusNode();
  final _formKeyStep1 = GlobalKey<FormState>();
  final _formKeyStep2 = GlobalKey<FormState>();

  final _poidsFocus = FocusNode();
  final _typeFocus = FocusNode();
  final _descFocus = FocusNode();
  bool _poidsFocused = false;
  bool _typeFocused = false;
  bool _descFocused = false;
  bool _rechercheFocused = false;

  // ── Destinataire ─────────────────────────────────────────────────────────
  List<ClientRecherche> _resultatsRecherche = [];
  ClientRecherche? _selectedDestinataire;
  bool _isLoadingRecherche = false;
  Timer? _debounceTimer;

  // ── Calcul prix ──────────────────────────────────────────────────────────
  double get _pricePerKg {
    if (_countryPricing == null || _selectedShippingType == null) return 0;
    final poids = double.tryParse(_poidsController.text) ?? 0;
    final prices = _countryPricing!.shippingPrices
        .where((p) => p.type == _selectedShippingType)
        .toList();
    for (final p in prices) {
      if (poids >= p.minWeight && poids <= p.maxWeight) return p.pricePerKg;
    }
    return prices.isNotEmpty ? prices.first.pricePerKg : 0;
  }

  double get _pickupPrice {
    if (!_needsPickup || _countryPricing == null) return 0;
    try {
      return _countryPricing!.servicePrices
          .firstWhere((p) => p.serviceType == 'récupération')
          .price;
    } catch (_) {
      return 0;
    }
  }

  double get _deliveryPrice {
    if (!_needsDelivery || _countryPricing == null) return 0;
    try {
      return _countryPricing!.servicePrices
          .firstWhere((p) => p.serviceType == 'livraison')
          .price;
    } catch (_) {
      return 0;
    }
  }

  double get _pickupPriceDisplay {
    if (_countryPricing == null) return 0;
    try {
      return _countryPricing!.servicePrices
          .firstWhere((p) => p.serviceType == 'récupération')
          .price;
    } catch (_) {
      return 0;
    }
  }

  double get _deliveryPriceDisplay {
    if (_countryPricing == null) return 0;
    try {
      return _countryPricing!.servicePrices
          .firstWhere((p) => p.serviceType == 'livraison')
          .price;
    } catch (_) {
      return 0;
    }
  }

  double get _totalEstime {
    final poids = double.tryParse(_poidsController.text) ?? 0;
    return poids * _pricePerKg + _pickupPrice + _deliveryPrice;
  }

  @override
  void initState() {
    super.initState();
    _loadCountries();
    _rechercheController.addListener(_onSearchChanged);
    _poidsController.addListener(() => setState(() {}));
    _poidsFocus.addListener(() =>
        setState(() => _poidsFocused = _poidsFocus.hasFocus));
    _typeFocus.addListener(() =>
        setState(() => _typeFocused = _typeFocus.hasFocus));
    _descFocus.addListener(() =>
        setState(() => _descFocused = _descFocus.hasFocus));
    _rechercheFocus.addListener(() =>
        setState(() => _rechercheFocused = _rechercheFocus.hasFocus));
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _rechercheController.removeListener(_onSearchChanged);
    _poidsController.dispose();
    _typeController.dispose();
    _descriptionController.dispose();
    _rechercheController.dispose();
    _poidsFocus.dispose();
    _typeFocus.dispose();
    _descFocus.dispose();
    _rechercheFocus.dispose();
    super.dispose();
  }

  Future<void> _loadCountries() async {
    setState(() => _isLoadingCountries = true);
    try {
      final countries = await sl<GetCountries>()();
      setState(() {
        _countries = countries;
        _isLoadingCountries = false;
      });
    } catch (_) {
      setState(() => _isLoadingCountries = false);
    }
  }

  Future<void> _loadPricing(String countryId) async {
    setState(() {
      _isLoadingPricing = true;
      _countryPricing = null;
      _selectedShippingType = null;
      _needsPickup = false;
      _needsDelivery = false;
    });
    try {
      final pricing = await sl<GetPricingByCountry>()(countryId);
      setState(() {
        _countryPricing = pricing;
        _isLoadingPricing = false;
      });
    } catch (_) {
      setState(() => _isLoadingPricing = false);
    }
  }

  void _ouvrirSelecteurPays() {
    if (_isLoadingCountries) return;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _PaysBottomSheet(
        countries: _countries,
        selected: _selectedCountry,
        onSelect: (c) {
          setState(() {
            _selectedCountry = c;
            _selectedShippingType = null;
            _countryPricing = null;
            _needsPickup = false;
            _needsDelivery = false;
          });
          Navigator.of(context).pop();
          _loadPricing(c.id);
        },
      ),
    );
  }

  void _onSearchChanged() {
    if (_debounceTimer?.isActive ?? false) _debounceTimer!.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 500), () async {
      final query = _rechercheController.text.trim();
      if (query.isEmpty) {
        setState(() => _resultatsRecherche = []);
        return;
      }
      setState(() => _isLoadingRecherche = true);
      try {
        final results = await sl<RechercherClient>()(query);
        setState(() {
          _resultatsRecherche = results;
          _isLoadingRecherche = false;
        });
      } catch (e) {
        setState(() => _isLoadingRecherche = false);
      }
    });
  }

  void _suivant() {
    if (_selectedCountry == null) {
      showErrorToast(context, 'Veuillez sélectionner un pays.');
      return;
    }
    if (_selectedShippingType == null) {
      showErrorToast(context, 'Veuillez choisir un type de transport.');
      return;
    }
    if (_formKeyStep1.currentState!.validate()) {
      setState(() => _currentStep = 2);
    }
  }

  void _retour() {
    setState(() {
      _currentStep = 1;
      _selectedDestinataire = null;
      _rechercheController.clear();
      _resultatsRecherche = [];
    });
  }

  /// Construit les paramètres du colis actuellement affiché à l'écran, si le
  /// formulaire est valide — null sinon (ex: pas de destinataire sélectionné).
  EnvoyerColisParams? _buildCurrentParams() {
    if (_selectedDestinataire == null) return null;
    if (_selectedCountry == null) return null;
    if (!(_formKeyStep2.currentState?.validate() ?? false)) return null;

    final double poids = double.tryParse(_poidsController.text) ?? 0.0;
    return EnvoyerColisParams(
      recepteurId: _selectedDestinataire!.id,
      poids: poids,
      prix: _totalEstime,
      destination: _selectedCountry!.name,
      typeColis: _typeController.text,
      description: _descriptionController.text.trim().isEmpty
          ? null
          : _descriptionController.text.trim(),
    );
  }

  /// Réinitialise le formulaire pour la saisie d'un nouveau colis, en
  /// conservant le contenu déjà mis de côté dans le panier (_panier).
  void _reinitialiserFormulaire() {
    setState(() {
      _currentStep = 1;
      _selectedCountry = null;
      _countryPricing = null;
      _selectedShippingType = null;
      _needsPickup = false;
      _needsDelivery = false;
      _selectedDestinataire = null;
      _rechercheController.clear();
      _resultatsRecherche = [];
      _typeController.clear();
      _poidsController.clear();
      _descriptionController.clear();
    });
  }

  /// Ajoute le colis actuellement configuré au lot, puis réinitialise le
  /// formulaire pour permettre la saisie d'un colis supplémentaire.
  void _ajouterAuPanier() {
    if (_selectedDestinataire == null) {
      showErrorToast(context, 'Veuillez sélectionner un destinataire.');
      return;
    }
    final params = _buildCurrentParams();
    if (params == null) return;

    final nomDestinataire =
        '${_selectedDestinataire!.prenom} ${_selectedDestinataire!.nom}'.trim();

    setState(() {
      _panier.add(_PanierItem(
        params: params,
        destinataireNom: nomDestinataire,
        paysNom: _selectedCountry?.name ?? '',
      ));
    });
    showToast(
      context,
      'Colis ajouté au lot',
      '${_panier.length} colis prêt${_panier.length > 1 ? 's' : ''} à être envoyé${_panier.length > 1 ? 's' : ''} ensemble.',
      ToastificationType.success,
    );
    _reinitialiserFormulaire();
  }

  void _retirerDuPanier(int index) {
    setState(() => _panier.removeAt(index));
  }

  void _envoyer() async {
    // ── Regroupement : un lot est déjà constitué, on envoie tout d'un coup ──
    if (_panier.isNotEmpty) {
      await _envoyerLot();
      return;
    }

    if (_selectedDestinataire == null) {
      showErrorToast(context, 'Veuillez sélectionner un destinataire.');
      return;
    }
    if (!_formKeyStep2.currentState!.validate()) return;

    final double poids = double.tryParse(_poidsController.text) ?? 0.0;
    final double total = _totalEstime;

    try {
      final reference = await sl<EnvoyerColis>()(EnvoyerColisParams(
        recepteurId: _selectedDestinataire!.id,
        poids: poids,
        prix: total,
        destination: _selectedCountry!.name,
        typeColis: _typeController.text,
        description: _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim(),
      ));
      if (mounted) {
        final nomRecepteur =
            '${_selectedDestinataire!.prenom} ${_selectedDestinataire!.nom}'.trim();
        final titre = reference != null
            ? 'Colis #$reference envoyé !'
            : 'Colis envoyé avec succès !';
        showToast(
          context,
          titre,
          'Envoyé à $nomRecepteur avec succès.',
          ToastificationType.success,
        );
        if (context.mounted) {
          try {
            context.read<ColisBloc>().add(LoadColisEnvoyes());
          } catch (_) {}
        }
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        showToast(
          context,
          'Échec de l\'envoi',
          'Une erreur est survenue. Veuillez réessayer.',
          ToastificationType.error,
        );
      }
    }
  }

  /// Envoie tous les colis du panier en une seule commande groupée. Si le
  /// formulaire actuellement affiché contient un colis valide non encore
  /// ajouté, il est inclus automatiquement (sans bloquer l'envoi s'il est
  /// incomplet — l'utilisateur a simplement fini d'ajouter des colis).
  Future<void> _envoyerLot() async {
    final items = List<EnvoyerColisParams>.from(_panier.map((p) => p.params));
    final dernierItem = _buildCurrentParams();
    if (dernierItem != null) items.add(dernierItem);

    try {
      final colisCrees = await sl<EnvoyerColisLot>()(items);
      if (mounted) {
        showToast(
          context,
          '${colisCrees.length} colis envoyés !',
          'Votre lot a été créé avec succès.',
          ToastificationType.success,
        );
        try {
          context.read<ColisBloc>().add(LoadColisEnvoyes());
        } catch (_) {}
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        showToast(
          context,
          "Échec de l'envoi du lot",
          'Une erreur est survenue. Veuillez réessayer.',
          ToastificationType.error,
        );
      }
    }
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            _buildStepper(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (_panier.isNotEmpty) ...[
                      _buildPanierSummary(),
                      const SizedBox(height: 20),
                    ],
                    _currentStep == 1
                        ? _buildStep1Form()
                        : _buildStep2Form(),
                  ],
                ),
              ),
            ),
            _buildButtons(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      color: Colors.white,
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
              'Envoyer un colis',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: AppColor.kGrayscaleDark100,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepper() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 20),
      child: Row(
        children: [
          _stepChip(1, 'Destination', _currentStep >= 1),
          Expanded(
            child: Container(
              height: 2,
              margin: const EdgeInsets.symmetric(horizontal: 10),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(2),
                color: _currentStep >= 2
                    ? AppColor.kPrimary
                    : const Color(0xFFE5E7EB),
              ),
            ),
          ),
          _stepChip(2, 'Destinataire', _currentStep >= 2),
        ],
      ),
    );
  }

  Widget _stepChip(int n, String label, bool active) {
    return Row(
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: active ? AppColor.kPrimary : const Color(0xFFE5E7EB),
          ),
          child: Center(
            child: Text(
              '$n',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: active ? Colors.white : AppColor.kGrayscale40,
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: active ? AppColor.kPrimary : AppColor.kGrayscale40,
          ),
        ),
      ],
    );
  }

  // ── Panier (regroupement de colis) ───────────────────────────────────────
  Widget _buildPanierSummary() {
    final total = _panier.fold<double>(0, (sum, p) => sum + p.params.prix);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF6FF),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFBFDBFE)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.inventory_2_rounded, size: 18, color: Color(0xFF2563EB)),
              const SizedBox(width: 8),
              Text(
                'Lot en cours : ${_panier.length} colis',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14, fontWeight: FontWeight.w800, color: const Color(0xFF1E3A8A),
                ),
              ),
              const Spacer(),
              Text(
                total.toEurFcfa(),
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14, fontWeight: FontWeight.w800, color: const Color(0xFF2563EB),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ...List.generate(_panier.length, (i) {
            final item = _panier[i];
            return Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      '${item.destinataireNom} — ${item.paysNom} (${item.params.poids.toStringAsFixed(1)} kg)',
                      style: GoogleFonts.plusJakartaSans(fontSize: 12.5, color: const Color(0xFF1E3A8A)),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  GestureDetector(
                    onTap: () => _retirerDuPanier(i),
                    child: const Icon(Icons.close_rounded, size: 16, color: Color(0xFF60A5FA)),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  // ── Step 1 ────────────────────────────────────────────────────────────────
  Widget _buildStep1Form() {
    return Form(
      key: _formKeyStep1,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Pays de destination
          _label('Pays de destination'),
          const SizedBox(height: 8),
          _PaysSelector(
            selected: _selectedCountry,
            isLoading: _isLoadingCountries,
            onTap: _ouvrirSelecteurPays,
          ),
          const SizedBox(height: 6),
          FormField<CountryItem>(
            validator: (_) =>
                _selectedCountry == null ? 'Veuillez sélectionner un pays' : null,
            builder: (field) => field.hasError
                ? Padding(
                    padding: const EdgeInsets.only(left: 12),
                    child: Text(
                      field.errorText!,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        color: Colors.redAccent,
                      ),
                    ),
                  )
                : const SizedBox.shrink(),
          ),

          // Type de transport
          if (_selectedCountry != null) ...[
            const SizedBox(height: 20),
            _label('Type de transport'),
            const SizedBox(height: 8),
            if (_isLoadingPricing)
              const Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
              )
            else
              _buildShippingTypeSelector(),
          ],

          const SizedBox(height: 20),

          // Type de colis
          _label('Type de colis'),
          const SizedBox(height: 8),
          TextFormField(
            controller: _typeController,
            focusNode: _typeFocus,
            textInputAction: TextInputAction.next,
            onFieldSubmitted: (_) =>
                FocusScope.of(context).requestFocus(_poidsFocus),
            style: _textStyle(),
            decoration: _inputDeco(
              hint: 'Ex: Document, Vêtement, Électronique...',
              icon: Icons.category_outlined,
              focused: _typeFocused,
            ),
            validator: (v) =>
                (v == null || v.trim().isEmpty) ? 'Ce champ est requis' : null,
          ),

          const SizedBox(height: 20),

          // Poids
          _label('Poids (kg)'),
          const SizedBox(height: 8),
          TextFormField(
            controller: _poidsController,
            focusNode: _poidsFocus,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            textInputAction: TextInputAction.next,
            onFieldSubmitted: (_) =>
                FocusScope.of(context).requestFocus(_descFocus),
            style: _textStyle(),
            decoration: _inputDeco(
              hint: 'Ex: 2.5',
              icon: Icons.scale_outlined,
              focused: _poidsFocused,
              suffix: Text(
                'kg',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColor.kGrayscale40,
                ),
              ),
            ),
            validator: (v) {
              if (v == null || v.trim().isEmpty) return 'Le poids est requis';
              final d = double.tryParse(v);
              if (d == null) return 'Entrez un nombre valide';
              if (d <= 0) return 'Le poids doit être supérieur à 0';
              return null;
            },
          ),

          const SizedBox(height: 20),

          // Prix estimé
          if (_selectedCountry != null && _selectedShippingType != null) ...[
            _buildPrixEstime(),
            const SizedBox(height: 20),
          ],

          // Description
          _label('Description (optionnelle)'),
          const SizedBox(height: 8),
          TextFormField(
            controller: _descriptionController,
            focusNode: _descFocus,
            maxLines: 3,
            style: _textStyle(),
            decoration: _inputDeco(
              hint: 'Contenu du colis, précautions particulières...',
              icon: Icons.notes_rounded,
              focused: _descFocused,
            ),
          ),

          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildShippingTypeSelector() {
    final types = _countryPricing?.shippingPrices
            .map((p) => p.type)
            .toSet()
            .toList() ??
        [];

    if (types.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFFFEF3C7),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          'Aucun tarif disponible pour ce pays.',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 13,
            color: const Color(0xFF92400E),
          ),
        ),
      );
    }

    return Row(
      children: types.map((type) {
        final isSelected = _selectedShippingType == type;
        final icon = type == 'aérien'
            ? Icons.flight_rounded
            : Icons.directions_boat_rounded;
        // Affiche le pricePerKg du premier tarif trouvé (indicatif)
        final pricePerKg = _countryPricing!.shippingPrices
            .firstWhere((p) => p.type == type)
            .pricePerKg;

        return Expanded(
          child: GestureDetector(
            onTap: () => setState(() => _selectedShippingType = type),
            child: Container(
              margin: EdgeInsets.only(right: type == types.first && types.length > 1 ? 8 : 0),
              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
              decoration: BoxDecoration(
                color: isSelected ? AppColor.kAccentSoft : Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isSelected ? AppColor.kPrimary : AppColor.kLine,
                  width: isSelected ? 2 : 1.5,
                ),
              ),
              child: Column(
                children: [
                  Icon(icon,
                      size: 24,
                      color: isSelected
                          ? AppColor.kPrimary
                          : AppColor.kGrayscale40),
                  const SizedBox(height: 6),
                  Text(
                    type[0].toUpperCase() + type.substring(1),
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: isSelected
                          ? AppColor.kPrimary
                          : AppColor.kGrayscaleDark100,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    pricePerKg.toEurFcfaPerKg(),
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      color: isSelected
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
    );
  }

  Widget _buildPrixEstime() {
    final poids = double.tryParse(_poidsController.text) ?? 0.0;
    final shipping = poids * _pricePerKg;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColor.kAccentSoft,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline_rounded,
              size: 16, color: AppColor.kPrimary),
          const SizedBox(width: 8),
          Text(
            'Prix transport estimé : ',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              color: AppColor.kGrayscale60,
            ),
          ),
          Text(
            shipping.toEurFcfa(),
            style: GoogleFonts.plusJakartaSans(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: AppColor.kPrimary,
            ),
          ),
          const Spacer(),
          Text(
            _pricePerKg.toEurFcfaPerKg(),
            style: GoogleFonts.plusJakartaSans(
              fontSize: 11,
              color: AppColor.kGrayscale40,
            ),
          ),
        ],
      ),
    );
  }

  // ── Step 2 ────────────────────────────────────────────────────────────────
  Widget _buildStep2Form() {
    return Form(
      key: _formKeyStep2,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildRecap(),

          const SizedBox(height: 24),

          // Recherche destinataire
          _label('Rechercher le destinataire'),
          const SizedBox(height: 8),
          TextFormField(
            controller: _rechercheController,
            focusNode: _rechercheFocus,
            style: _textStyle(),
            decoration: _inputDeco(
              hint: 'Nom, prénom, email...',
              icon: Icons.search_rounded,
              focused: _rechercheFocused,
            ),
            validator: (_) => _selectedDestinataire == null
                ? 'Veuillez sélectionner un destinataire'
                : null,
          ),

          if (_isLoadingRecherche)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            ),

          if (_resultatsRecherche.isNotEmpty)
            Container(
              margin: const EdgeInsets.only(top: 8),
              constraints: const BoxConstraints(maxHeight: 220),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 20,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: _resultatsRecherche.length,
                  separatorBuilder: (_, __) =>
                      Divider(height: 1, color: Colors.grey.shade100),
                  itemBuilder: (_, i) {
                    final c = _resultatsRecherche[i];
                    final initiale =
                        '${c.nom.isNotEmpty ? c.nom[0] : ''}${c.prenom.isNotEmpty ? c.prenom[0] : ''}'
                            .toUpperCase();
                    return InkWell(
                      onTap: () => setState(() {
                        _selectedDestinataire = c;
                        _rechercheController.text =
                            '${c.nom} ${c.prenom}';
                        _resultatsRecherche.clear();
                        _rechercheFocus.unfocus();
                      }),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                        child: Row(
                          children: [
                            Container(
                              width: 38,
                              height: 38,
                              decoration: BoxDecoration(
                                color: AppColor.kAccentSoft,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Center(
                                child: Text(
                                  initiale,
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w800,
                                    color: AppColor.kPrimary,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '${c.nom} ${c.prenom}',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                      color: AppColor.kGrayscaleDark100,
                                    ),
                                  ),
                                  Text(
                                    c.email,
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 11,
                                      color: AppColor.kGrayscale40,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Icon(
                              Icons.chevron_right_rounded,
                              size: 18,
                              color: Color(0xFFD1D5DB),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),

          if (_selectedDestinataire != null) ...[
            const SizedBox(height: 12),
            _buildDestinataireCard(),
          ],

          const SizedBox(height: 24),

          // ── Services optionnels ──────────────────────────────────────────
          _label('Services additionnels'),
          const SizedBox(height: 12),
          _buildServiceCheckbox(
            question:
                'Voulez-vous qu\'on vienne récupérer le colis ?',
            prix: _pickupPriceDisplay,
            value: _needsPickup,
            onChanged: (v) => setState(() => _needsPickup = v ?? false),
          ),
          const SizedBox(height: 12),
          _buildServiceCheckbox(
            question:
                'Voulez-vous une livraison à destination ?',
            prix: _deliveryPriceDisplay,
            value: _needsDelivery,
            onChanged: (v) => setState(() => _needsDelivery = v ?? false),
          ),

          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildServiceCheckbox({
    required String question,
    required double prix,
    required bool value,
    required ValueChanged<bool?> onChanged,
  }) {
    return GestureDetector(
      onTap: () => onChanged(!value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: value ? AppColor.kAccentSoft : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: value ? AppColor.kPrimary : AppColor.kLine,
            width: value ? 2 : 1.5,
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    question,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: value
                          ? AppColor.kPrimary
                          : AppColor.kGrayscaleDark100,
                    ),
                  ),
                  if (prix > 0) ...[
                    const SizedBox(height: 4),
                    Text(
                      prix == 0
                          ? 'Tarif non disponible'
                          : '+${prix.toEurFcfa()}',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: value
                            ? AppColor.kPrimary
                            : AppColor.kGrayscale40,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Checkbox(
              value: value,
              onChanged: onChanged,
              activeColor: AppColor.kPrimary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(5),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecap() {
    final poids = double.tryParse(_poidsController.text) ?? 0.0;
    final shipping = poids * _pricePerKg;
    final total = _totalEstime;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
              color: AppColor.kGrayscaleDark100,
              child: Row(
                children: [
                  const Icon(Icons.receipt_long_rounded,
                      size: 16, color: Colors.white),
                  const SizedBox(width: 8),
                  Text(
                    'Récapitulatif',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _recapRow(
                    Icons.flight_takeoff_rounded,
                    'Destination',
                    _selectedCountry?.name ?? '—',
                    const Color(0xFF2563EB),
                  ),
                  const SizedBox(height: 12),
                  _recapRow(
                    _selectedShippingType == 'aérien'
                        ? Icons.flight_rounded
                        : Icons.directions_boat_rounded,
                    'Transport',
                    _selectedShippingType != null
                        ? (_selectedShippingType![0].toUpperCase() +
                            _selectedShippingType!.substring(1))
                        : '—',
                    const Color(0xFF7C3AED),
                  ),
                  const SizedBox(height: 12),
                  _recapRow(
                    Icons.category_outlined,
                    'Type',
                    _typeController.text.isNotEmpty
                        ? _typeController.text
                        : '—',
                    const Color(0xFF059669),
                  ),
                  const SizedBox(height: 12),
                  _recapRow(
                    Icons.scale_outlined,
                    'Poids',
                    '${poids.toStringAsFixed(2)} kg',
                    AppColor.kGrayscale60,
                  ),
                  const SizedBox(height: 12),
                  _recapRow(
                    Icons.local_shipping_outlined,
                    'Frais transport',
                    shipping.toEurFcfa(),
                    AppColor.kGrayscale60,
                  ),
                  if (_needsPickup && _pickupPrice > 0) ...[
                    const SizedBox(height: 8),
                    _recapRow(
                      Icons.home_outlined,
                      'Récupération',
                      '+${_pickupPrice.toEurFcfa()}',
                      const Color(0xFFD97706),
                    ),
                  ],
                  if (_needsDelivery && _deliveryPrice > 0) ...[
                    const SizedBox(height: 8),
                    _recapRow(
                      Icons.delivery_dining_outlined,
                      'Livraison',
                      '+${_deliveryPrice.toEurFcfa()}',
                      const Color(0xFFD97706),
                    ),
                  ],
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Divider(height: 1, color: Colors.grey.shade100),
                  ),
                  Row(
                    children: [
                      Text(
                        'Total estimé',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColor.kGrayscale60,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        total.toEurFcfa(),
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: AppColor.kPrimary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _recapRow(IconData icon, String label, String value, Color color) {
    return Row(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 16, color: color),
        ),
        const SizedBox(width: 12),
        Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 12,
            color: AppColor.kGrayscale40,
            fontWeight: FontWeight.w500,
          ),
        ),
        const Spacer(),
        Text(
          value,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: AppColor.kGrayscaleDark100,
          ),
        ),
      ],
    );
  }

  Widget _buildDestinataireCard() {
    final d = _selectedDestinataire!;
    final initiale =
        '${d.nom.isNotEmpty ? d.nom[0] : ''}${d.prenom.isNotEmpty ? d.prenom[0] : ''}'
            .toUpperCase();
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFD1FAE5),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: const Color(0xFF059669),
              borderRadius: BorderRadius.circular(12),
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
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${d.nom} ${d.prenom}',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF065F46),
                  ),
                ),
                Text(
                  d.email,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    color: const Color(0xFF059669),
                  ),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: () => setState(() {
              _selectedDestinataire = null;
              _rechercheController.clear();
            }),
            child: Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.close_rounded,
                  size: 16, color: Color(0xFF065F46)),
            ),
          ),
        ],
      ),
    );
  }

  // ── Boutons navigation ────────────────────────────────────────────────────
  Widget _buildButtons() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
      child: Column(
        children: [
          // Regroupement : mettre le colis actuel de côté pour en ajouter un
          // autre, avant d'envoyer toute la commande groupée.
          if (_currentStep == 2 && _selectedDestinataire != null) ...[
            SizedBox(
              width: double.infinity,
              height: 48,
              child: OutlinedButton.icon(
                onPressed: _ajouterAuPanier,
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppColor.kPrimary, width: 1.5),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                icon: const Icon(Icons.add_rounded, size: 18, color: AppColor.kPrimary),
                label: Text(
                  'Ajouter un autre colis au lot',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13.5, fontWeight: FontWeight.w700, color: AppColor.kPrimary,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
          ],
          _buildMainButtonsRow(),
        ],
      ),
    );
  }

  Widget _buildMainButtonsRow() {
    final envoiLot = _currentStep == 2 && _panier.isNotEmpty;
    // Ne relance jamais la validation du formulaire ici (build()) : juste un
    // indicateur léger, sans effet de bord, pour annoncer que le colis en
    // cours de saisie sera inclus automatiquement à l'envoi du lot.
    final colisEnCoursInclus = _selectedDestinataire != null;
    final tailleLotAffichee = _panier.length + (envoiLot && colisEnCoursInclus ? 1 : 0);
    final labelPrincipal = _currentStep == 1
        ? 'Continuer'
        : (envoiLot ? 'Envoyer le lot ($tailleLotAffichee)' : 'Envoyer le colis');

    return Row(
      children: [
        if (_currentStep == 2) ...[
            GestureDetector(
              onTap: _retour,
              child: Container(
                height: 54,
                width: 54,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColor.kLine, width: 1.5),
                ),
                child: const Icon(
                  Icons.arrow_back_ios_new_rounded,
                  size: 18,
                  color: AppColor.kGrayscaleDark100,
                ),
              ),
            ),
            const SizedBox(width: 12),
          ],
          Expanded(
            child: Container(
              height: 54,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                gradient: const LinearGradient(
                  colors: [AppColor.kPrimary, AppColor.kPrimaryDark],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColor.kPrimary.withValues(alpha: 0.35),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(14),
                child: InkWell(
                  onTap: _currentStep == 1 ? _suivant : _envoyer,
                  borderRadius: BorderRadius.circular(14),
                  splashColor: Colors.white.withValues(alpha: 0.15),
                  child: Center(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          labelPrincipal,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Icon(
                          _currentStep == 1
                              ? Icons.arrow_forward_rounded
                              : Icons.send_rounded,
                          color: Colors.white,
                          size: 18,
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

  // ── Helpers ───────────────────────────────────────────────────────────────
  Widget _label(String text) => Text(
        text,
        style: GoogleFonts.plusJakartaSans(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: AppColor.kGrayscale80,
        ),
      );

  TextStyle _textStyle() => GoogleFonts.plusJakartaSans(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: AppColor.kGrayscaleDark100,
      );

  InputDecoration _inputDeco({
    required String hint,
    required IconData icon,
    required bool focused,
    Widget? suffix,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle: GoogleFonts.plusJakartaSans(
        fontSize: 14,
        color: AppColor.kGrayscale20,
        fontWeight: FontWeight.w400,
      ),
      prefixIcon: Padding(
        padding: const EdgeInsets.only(left: 14, right: 10),
        child: Icon(
          icon,
          size: 20,
          color: focused ? AppColor.kPrimary : AppColor.kGrayscale40,
        ),
      ),
      prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
      suffixIcon: suffix != null
          ? Padding(
              padding: const EdgeInsets.only(right: 14),
              child: suffix,
            )
          : null,
      suffixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
      filled: true,
      fillColor: focused ? AppColor.kAccentSoft : Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColor.kLine, width: 1.5),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColor.kPrimary, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Colors.redAccent, width: 1.5),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Colors.redAccent, width: 2),
      ),
      errorStyle: GoogleFonts.plusJakartaSans(
        fontSize: 12,
        color: Colors.redAccent,
      ),
    );
  }
}

// ── Sélecteur pays ────────────────────────────────────────────────────────────

class _PaysSelector extends StatelessWidget {
  final CountryItem? selected;
  final bool isLoading;
  final VoidCallback onTap;

  const _PaysSelector({
    required this.selected,
    required this.isLoading,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 54,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: selected != null ? AppColor.kAccentSoft : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected != null ? AppColor.kPrimary : AppColor.kLine,
            width: selected != null ? 2 : 1.5,
          ),
        ),
        child: Row(
          children: [
            Icon(
              Icons.flight_takeoff_rounded,
              size: 20,
              color: selected != null
                  ? AppColor.kPrimary
                  : AppColor.kGrayscale40,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: isLoading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : selected == null
                      ? Text(
                          'Sélectionnez un pays',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 14,
                            color: AppColor.kGrayscale20,
                            fontWeight: FontWeight.w400,
                          ),
                        )
                      : Text(
                          selected!.name,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppColor.kGrayscaleDark100,
                          ),
                        ),
            ),
            Icon(
              Icons.keyboard_arrow_down_rounded,
              color: selected != null
                  ? AppColor.kPrimary
                  : AppColor.kGrayscale40,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Bottom sheet pays ─────────────────────────────────────────────────────────

class _PaysBottomSheet extends StatelessWidget {
  final List<CountryItem> countries;
  final CountryItem? selected;
  final void Function(CountryItem) onSelect;

  const _PaysBottomSheet({
    required this.countries,
    required this.selected,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 12, bottom: 8),
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: const Color(0xFFE5E7EB),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 4),
            child: Row(
              children: [
                Text(
                  'Pays de destination',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF1E1E1E),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          if (countries.isEmpty)
            Padding(
              padding: const EdgeInsets.all(20),
              child: Text(
                'Aucun pays disponible.',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  color: const Color(0xFF9CA3AF),
                ),
              ),
            )
          else
            ...countries.map((c) => _PaysItem(
                  country: c,
                  isSelected: selected?.id == c.id,
                  onTap: () => onSelect(c),
                )),
          SizedBox(height: MediaQuery.of(context).padding.bottom + 16),
        ],
      ),
    );
  }
}

class _PaysItem extends StatelessWidget {
  final CountryItem country;
  final bool isSelected;
  final VoidCallback onTap;

  const _PaysItem({
    required this.country,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: isSelected ? AppColor.kAccentSoft : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? AppColor.kPrimary : const Color(0xFFF3F4F6),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColor.kPrimary.withValues(alpha: 0.1)
                    : const Color(0xFFF3F4F6),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  country.code.length >= 2
                      ? country.code.substring(0, 2)
                      : country.code,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: isSelected
                        ? AppColor.kPrimary
                        : AppColor.kGrayscale60,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                country.name,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: isSelected
                      ? AppColor.kPrimary
                      : const Color(0xFF1E1E1E),
                ),
              ),
            ),
            if (isSelected)
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: AppColor.kPrimary,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check_rounded,
                    size: 14, color: Colors.white),
              ),
          ],
        ),
      ),
    );
  }
}
