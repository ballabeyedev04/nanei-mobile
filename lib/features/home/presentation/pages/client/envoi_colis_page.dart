import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:toastification/toastification.dart';
import 'dart:async';
import 'package:nanei/core/theme/app_color.dart';
import 'package:nanei/core/widgets/app_toast.dart';
import 'package:nanei/core/widgets/toastNotif.dart';
import '../../bloc/colis_bloc.dart';
import '../../bloc/colis_event.dart';
import '../../../domain/entities/client_recherche.dart';
import '../../../domain/usecases/envoyer_colis.dart';
import '../../../domain/usecases/rechercher_client.dart';
import 'package:nanei/injection_container.dart';

// ── Données pays ────────────────────────────────────────────────────────────

class _Pays {
  final String nom;
  final String drapeau;
  final double prixParKg;
  const _Pays(this.nom, this.drapeau, this.prixParKg);
}

const _listePays = [
  _Pays('Sénégal', '🇸🇳', 10.0),
  _Pays('Mali', '🇲🇱', 14.0),
  _Pays("Côte d'Ivoire", '🇨🇮', 12.0),
  _Pays('France', '🇫🇷', 20.0),
];

// ── Page ────────────────────────────────────────────────────────────────────

class EnvoiColisPage extends StatefulWidget {
  const EnvoiColisPage({super.key});

  @override
  State<EnvoiColisPage> createState() => _EnvoiColisPageState();
}

class _EnvoiColisPageState extends State<EnvoiColisPage> {
  int _currentStep = 1;
  _Pays? _selectedPays;

  final _poidsController = TextEditingController();
  final _typeController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _rechercheController = TextEditingController();
  final _rechercheFocus = FocusNode();
  final _formKeyStep1 = GlobalKey<FormState>();
  final _formKeyStep2 = GlobalKey<FormState>();

  // Focus nodes step 1
  final _poidsFocus = FocusNode();
  final _typeFocus = FocusNode();
  final _descFocus = FocusNode();
  bool _poidsFocused = false;
  bool _typeFocused = false;
  bool _descFocused = false;
  bool _rechercheFocused = false;

  List<ClientRecherche> _resultatsRecherche = [];
  ClientRecherche? _selectedDestinataire;
  bool _isLoadingRecherche = false;
  Timer? _debounceTimer;

  @override
  void initState() {
    super.initState();
    _rechercheController.addListener(_onSearchChanged);
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

  void _ouvrirSelecteurPays() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _PaysBottomSheet(
        selected: _selectedPays,
        onSelect: (p) {
          setState(() => _selectedPays = p);
          Navigator.of(context).pop();
        },
      ),
    );
  }

  void _suivant() {
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

  void _envoyer() async {
    if (_selectedDestinataire == null) {
      showErrorToast(context, 'Veuillez sélectionner un destinataire.');
      return;
    }
    if (!_formKeyStep2.currentState!.validate()) return;

    final double poids = double.tryParse(_poidsController.text) ?? 0.0;
    final double total = poids * (_selectedPays?.prixParKg ?? 0.0);

    try {
      final reference = await sl<EnvoyerColis>()(EnvoyerColisParams(
        recepteurId: _selectedDestinataire!.id,
        poids: poids,
        prix: total,
        destination: _selectedPays!.nom,
        typeColis: _typeController.text,
        description: _descriptionController.text,
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
        // Rafraîchir le BLoC si disponible dans le contexte
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
                child: _currentStep == 1
                    ? _buildStep1Form()
                    : _buildStep2Form(),
              ),
            ),
            _buildButtons(),
          ],
        ),
      ),
    );
  }

  // ── AppBar custom ─────────────────────────────────────────────────────────
  Widget _buildHeader() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(4, 8, 20, 12),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(
                Icons.arrow_back_ios_new_rounded, size: 20),
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

  // ── Stepper ───────────────────────────────────────────────────────────────
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
            selected: _selectedPays,
            onTap: _ouvrirSelecteurPays,
            hasError: false,
          ),
          const SizedBox(height: 6),
          // Validation invisible pour le pays
          FormField<_Pays>(
            validator: (_) => _selectedPays == null
                ? 'Veuillez sélectionner un pays'
                : null,
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

          // Prix estimé (affichage dynamique)
          if (_selectedPays != null) ...[
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

  Widget _buildPrixEstime() {
    final poids = double.tryParse(_poidsController.text) ?? 0.0;
    final prix = poids * (_selectedPays?.prixParKg ?? 0.0);
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
            'Prix estimé : ',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              color: AppColor.kGrayscale60,
            ),
          ),
          Text(
            '${prix.toStringAsFixed(2)} €',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: AppColor.kPrimary,
            ),
          ),
          const Spacer(),
          Text(
            '${_selectedPays!.prixParKg.toStringAsFixed(0)} €/kg',
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
    final poids = double.tryParse(_poidsController.text) ?? 0.0;
    final total = poids * (_selectedPays?.prixParKg ?? 0.0);

    return Form(
      key: _formKeyStep2,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Récapitulatif premium
          _buildRecap(poids, total),

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

          // Loader
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

          // Résultats
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
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
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

          // Destinataire sélectionné
          if (_selectedDestinataire != null) ...[
            const SizedBox(height: 12),
            _buildDestinataireCard(),
          ],

          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildRecap(double poids, double total) {
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
            // Header
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
            // Lignes
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _recapRow(
                    Icons.flight_takeoff_rounded,
                    'Destination',
                    _selectedPays != null
                        ? '${_selectedPays!.drapeau}  ${_selectedPays!.nom}'
                        : '—',
                    const Color(0xFF2563EB),
                  ),
                  const SizedBox(height: 12),
                  _recapRow(
                    Icons.category_outlined,
                    'Type',
                    _typeController.text.isNotEmpty
                        ? _typeController.text
                        : '—',
                    const Color(0xFF7C3AED),
                  ),
                  const SizedBox(height: 12),
                  _recapRow(
                    Icons.scale_outlined,
                    'Poids',
                    '${poids.toStringAsFixed(2)} kg',
                    AppColor.kGrayscale60,
                  ),
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
                        '${total.toStringAsFixed(2)} €',
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
      child: Row(
        children: [
          if (_currentStep == 2) ...[
            GestureDetector(
              onTap: _retour,
              child: Container(
                height: 54,
                width: 54,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: AppColor.kLine,
                    width: 1.5,
                  ),
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
                          _currentStep == 1 ? 'Continuer' : 'Envoyer le colis',
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
      ),
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
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide:
            const BorderSide(color: AppColor.kLine, width: 1.5),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColor.kPrimary, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide:
            const BorderSide(color: Colors.redAccent, width: 1.5),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide:
            const BorderSide(color: Colors.redAccent, width: 2),
      ),
      errorStyle: GoogleFonts.plusJakartaSans(
        fontSize: 12,
        color: Colors.redAccent,
      ),
    );
  }
}

// ── Sélecteur pays (tap-to-open) ─────────────────────────────────────────────

class _PaysSelector extends StatelessWidget {
  final _Pays? selected;
  final VoidCallback onTap;
  final bool hasError;

  const _PaysSelector({
    required this.selected,
    required this.onTap,
    required this.hasError,
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
            color: hasError
                ? Colors.redAccent
                : selected != null
                    ? AppColor.kPrimary
                    : AppColor.kLine,
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
              child: selected == null
                  ? Text(
                      'Sélectionnez un pays',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14,
                        color: AppColor.kGrayscale20,
                        fontWeight: FontWeight.w400,
                      ),
                    )
                  : Row(
                      children: [
                        Text(
                          selected!.drapeau,
                          style: const TextStyle(fontSize: 22),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          selected!.nom,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppColor.kGrayscaleDark100,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 7, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppColor.kPrimary
                                .withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            '${selected!.prixParKg.toStringAsFixed(0)} €/kg',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: AppColor.kPrimary,
                            ),
                          ),
                        ),
                      ],
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

// ── Bottom sheet sélection pays ───────────────────────────────────────────────

class _PaysBottomSheet extends StatelessWidget {
  final _Pays? selected;
  final void Function(_Pays) onSelect;

  const _PaysBottomSheet({required this.selected, required this.onSelect});

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
          // Drag handle
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
          ..._listePays.map((pays) => _PaysItem(
                pays: pays,
                isSelected: selected?.nom == pays.nom,
                onTap: () => onSelect(pays),
              )),
          SizedBox(
              height: MediaQuery.of(context).padding.bottom + 16),
        ],
      ),
    );
  }
}

class _PaysItem extends StatelessWidget {
  final _Pays pays;
  final bool isSelected;
  final VoidCallback onTap;

  const _PaysItem({
    required this.pays,
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
            color:
                isSelected ? AppColor.kPrimary : const Color(0xFFF3F4F6),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Text(pays.drapeau, style: const TextStyle(fontSize: 28)),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    pays.nom,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: isSelected
                          ? AppColor.kPrimary
                          : const Color(0xFF1E1E1E),
                    ),
                  ),
                  Text(
                    '${pays.prixParKg.toStringAsFixed(0)} € par kg',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      color: isSelected
                          ? AppColor.kPrimary
                          : const Color(0xFF9CA3AF),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
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
