import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:async';
import 'package:francomalishipp/core/theme/app_color.dart';
import 'package:francomalishipp/core/widgets/primary_text_formField.dart';
import 'package:francomalishipp/features/home/data/datasources/colis_api.dart';
import '../../../domain/entities/client_recherche.dart';

class EnvoiColisPage extends StatefulWidget {
  const EnvoiColisPage({super.key});

  @override
  State<EnvoiColisPage> createState() => _EnvoiColisPageState();
}

class _EnvoiColisPageState extends State<EnvoiColisPage> {
  int _currentStep = 1;
  final List<String> _pays = ['Sénégal', 'Mali', 'Côte d\'Ivoire', 'France'];
  String? _selectedPays;
  final TextEditingController _poidsController = TextEditingController();
  final TextEditingController _rechercheController = TextEditingController();
  final FocusNode _rechercheFocus = FocusNode();

  final _formKeyStep1 = GlobalKey<FormState>();
  final _formKeyStep2 = GlobalKey<FormState>();

  List<ClientRecherche> _resultatsRecherche = [];
  ClientRecherche? _selectedDestinataire;
  bool _isLoadingRecherche = false;
  Timer? _debounceTimer;

  double _getPrixParKg(String? pays) {
    switch (pays) {
      case 'Mali':
        return 14.0;
      case 'Sénégal':
        return 10.0;
      case 'Côte d\'Ivoire':
        return 12.0;
      case 'France':
        return 20.0;
      default:
        return 0.0;
    }
  }

  @override
  void initState() {
    super.initState();
    _rechercheController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _rechercheController.removeListener(_onSearchChanged);
    _rechercheController.dispose();
    _rechercheFocus.dispose();
    _poidsController.dispose();
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
        final results = await ColisApi.rechercherClient(query);
        setState(() {
          _resultatsRecherche = results;
          _isLoadingRecherche = false;
        });
      } catch (e) {
        setState(() => _isLoadingRecherche = false);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Erreur recherche: $e')),
          );
        }
      }
    });
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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez sélectionner un destinataire')),
      );
      return;
    }
    if (!_formKeyStep2.currentState!.validate()) return;

    final double poids = double.tryParse(_poidsController.text) ?? 0.0;
    final double prixParKg = _getPrixParKg(_selectedPays);
    final double total = poids * prixParKg;

    try {
      await ColisApi.envoyerColis(
        recepteurId: _selectedDestinataire!.id,
        poids: poids,
        prix: total,
        destination: _selectedPays!,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Colis envoyé avec succès !')),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur envoi: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'ENVOI DE COLIS',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: AppColor.kGrayscaleDark100,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _buildStepIndicator(1, 'Destination', _currentStep >= 1),
                  const Expanded(
                    child: Divider(color: AppColor.kLine, thickness: 1.5),
                  ),
                  _buildStepIndicator(2, 'Destinataire', _currentStep >= 2),
                ],
              ),
              const SizedBox(height: 32),
              if (_currentStep == 1) ...[
                _buildStep1Form(),
                const SizedBox(height: 32),
                _buildNavigationButtons(
                  onSuivant: _suivant,
                  onRetour: null,
                  isLastStep: false,
                ),
              ],
              if (_currentStep == 2) ...[
                Expanded(
                  child: SingleChildScrollView(
                    child: _buildStep2Form(),
                  ),
                ),
                const SizedBox(height: 16),
                _buildNavigationButtons(
                  onSuivant: _envoyer,
                  onRetour: _retour,
                  isLastStep: true,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStepIndicator(int step, String label, bool isActive) {
    return Column(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: isActive ? AppColor.kPrimary : AppColor.kGrayscale40,
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              '$step',
              style: GoogleFonts.plusJakartaSans(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 14,
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: isActive ? AppColor.kPrimary : AppColor.kGrayscale40,
          ),
        ),
      ],
    );
  }

  Widget _buildStep1Form() {
    return Form(
      key: _formKeyStep1,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Pays de destination',
            style: GoogleFonts.plusJakartaSans(
              color: AppColor.kGrayscaleDark100,
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColor.kLine, width: 1.5),
            ),
            child: DropdownButtonFormField<String>(
              value: _selectedPays,
              decoration: const InputDecoration(
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(horizontal: 16),
              ),
              hint: Text(
                'Sélectionnez un pays',
                style: GoogleFonts.plusJakartaSans(
                  color: AppColor.kGrayscale40,
                  fontSize: 16,
                ),
              ),
              items: _pays.map((pays) {
                return DropdownMenuItem<String>(
                  value: pays,
                  child: Text(
                    pays,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 16,
                      color: AppColor.kGrayscaleDark100,
                    ),
                  ),
                );
              }).toList(),
              onChanged: (value) => setState(() => _selectedPays = value),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Veuillez sélectionner un pays';
                }
                return null;
              },
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Poids (kg)',
            style: GoogleFonts.plusJakartaSans(
              color: AppColor.kGrayscaleDark100,
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            height: 52,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColor.kLine, width: 1.5),
            ),
            child: Row(
              children: [
                Padding(
                  padding: const EdgeInsets.only(left: 16),
                  child: Icon(Icons.scale, color: AppColor.kPrimary, size: 20),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(right: 16),
                    child: PrimaryTextFormField(
                      controller: _poidsController,
                      hintText: 'Ex: 2.5',
                      height: 50,
                      width: double.infinity,
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Le poids est requis';
                        }
                        if (double.tryParse(value) == null) {
                          return 'Veuillez entrer un nombre valide';
                        }
                        if (double.parse(value) <= 0) {
                          return 'Le poids doit être supérieur à 0';
                        }
                        return null;
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStep2Form() {
    final double poids = double.tryParse(_poidsController.text) ?? 0.0;
    final double prixParKg = _getPrixParKg(_selectedPays);
    final double total = poids * prixParKg;

    return Form(
      key: _formKeyStep2,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColor.kAccentSoft,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColor.kLine),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Récapitulatif de votre envoi',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColor.kGrayscaleDark100,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _buildRecapItem(
                        icon: Icons.location_on,
                        label: 'Pays',
                        value: _selectedPays ?? 'Non sélectionné',
                      ),
                    ),
                    Expanded(
                      child: _buildRecapItem(
                        icon: Icons.scale,
                        label: 'Poids',
                        value: '${poids.toStringAsFixed(2)} kg',
                      ),
                    ),
                    Expanded(
                      child: _buildRecapItem(
                        icon: Icons.euro,
                        label: 'Total',
                        value: '${total.toStringAsFixed(2)} €',
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Rechercher le destinataire',
            style: GoogleFonts.plusJakartaSans(
              color: AppColor.kGrayscaleDark100,
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            height: 52,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColor.kLine, width: 1.5),
            ),
            child: Row(
              children: [
                Padding(
                  padding: const EdgeInsets.only(left: 16),
                  child: Icon(Icons.search, color: AppColor.kPrimary, size: 20),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(right: 16),
                    child: TextFormField(
                      controller: _rechercheController,
                      focusNode: _rechercheFocus,
                      decoration: InputDecoration(
                        hintText: 'Nom, Prénom, Email...',
                        hintStyle: GoogleFonts.plusJakartaSans(
                          color: AppColor.kGrayscale40,
                        ),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.zero,
                      ),
                      style: GoogleFonts.plusJakartaSans(
                        color: AppColor.kGrayscaleDark100,
                      ),
                      validator: (_) => _selectedDestinataire == null
                          ? 'Veuillez sélectionner un destinataire'
                          : null,
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (_isLoadingRecherche)
            const Padding(
              padding: EdgeInsets.only(top: 8),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_resultatsRecherche.isNotEmpty)
            Container(
              margin: const EdgeInsets.only(top: 8),
              constraints: const BoxConstraints(maxHeight: 200),
              decoration: BoxDecoration(
                border: Border.all(color: AppColor.kLine),
                borderRadius: BorderRadius.circular(12),
                color: Colors.white,
              ),
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: _resultatsRecherche.length,
                separatorBuilder: (_, __) => Divider(height: 1, color: AppColor.kLine),
                itemBuilder: (context, index) {
                  final client = _resultatsRecherche[index];
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: AppColor.kPrimary,
                      child: Text(
                        (client.nom.isNotEmpty ? client.nom[0] : '') +
                            (client.prenom.isNotEmpty ? client.prenom[0] : ''),
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                    title: Text("${client.nom} ${client.prenom}"),
                    subtitle: Text(client.email),
                    onTap: () {
                      setState(() {
                        _selectedDestinataire = client;
                        _rechercheController.text = '${client.nom} ${client.prenom}';
                        _resultatsRecherche.clear();
                        _rechercheFocus.unfocus();
                      });
                    },
                  );
                },
              ),
            ),
          if (_selectedDestinataire != null) ...[
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColor.kPrimary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColor.kPrimary),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundColor: AppColor.kPrimary,
                    child: Text(
                      _selectedDestinataire != null
                          ? '${_selectedDestinataire!.nom} ${_selectedDestinataire!.prenom}'.isNotEmpty
                          ? '${_selectedDestinataire!.nom} ${_selectedDestinataire!.prenom}'[0]
                          : '?'
                          : '?',
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${_selectedDestinataire!.nom} ${_selectedDestinataire!.prenom}',
                          style: GoogleFonts.plusJakartaSans(
                            fontWeight: FontWeight.w600,
                            color: AppColor.kGrayscaleDark100,
                          ),
                        ),
                        Text(
                          _selectedDestinataire!.email,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            color: AppColor.kGrayscale60,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: AppColor.kGrayscale60),
                    onPressed: () {
                      setState(() {
                        _selectedDestinataire = null;
                        _rechercheController.clear();
                      });
                    },
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildRecapItem({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 16, color: AppColor.kPrimary),
            const SizedBox(width: 4),
            Text(
              label,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: AppColor.kGrayscale60,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: AppColor.kGrayscaleDark100,
          ),
        ),
      ],
    );
  }

  Widget _buildNavigationButtons({
    required VoidCallback onSuivant,
    VoidCallback? onRetour,
    required bool isLastStep,
  }) {
    return Row(
      children: [
        if (onRetour != null)
          Expanded(
            child: Container(
              height: 56,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColor.kPrimary, width: 1.5),
              ),
              child: Material(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(16),
                child: InkWell(
                  onTap: onRetour,
                  borderRadius: BorderRadius.circular(16),
                  child: Center(
                    child: Text(
                      'Retour',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColor.kPrimary,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        if (onRetour != null) const SizedBox(width: 16),
        Expanded(
          flex: onRetour == null ? 2 : 1,
          child: SizedBox(
            height: 56,
            child: Material(
              borderRadius: BorderRadius.circular(16),
              elevation: 0,
              color: AppColor.kPrimary,
              child: InkWell(
                onTap: onSuivant,
                borderRadius: BorderRadius.circular(16),
                splashColor: Colors.white.withOpacity(0.2),
                highlightColor: Colors.white.withOpacity(0.1),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    gradient: LinearGradient(
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                      colors: [
                        AppColor.kPrimary,
                        AppColor.kPrimary.withOpacity(0.8),
                      ],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppColor.kPrimary.withOpacity(0.3),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      isLastStep ? 'Envoyer' : 'Suivant',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}