import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:francomalishipp/features/auth/domain/entities/user.dart';
import '../../../../../core/theme/app_color.dart';
import '../../../../../core/widgets/primary_text_formField.dart';

class ClientPage extends StatefulWidget {
  final User? user;

  const ClientPage({super.key, this.user});

  @override
  State<ClientPage> createState() => _ProfessionnelPageState();
}

class _ProfessionnelPageState extends State<ClientPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _currentIndex = 0; // Pour la BottomNavigationBar

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    print('Professionnel connecté: ${widget.user?.toJson()}');
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColor.kBackground,
      appBar: AppBar(
        backgroundColor: AppColor.kWhite,
        elevation: 0,
        centerTitle: true,
        title: Text(
          'SUIVI DE COLIS',
          style: TextStyle(
            color: AppColor.kBlack,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColor.kPrimary,
          labelColor: AppColor.kPrimary,
          unselectedLabelColor: AppColor.kGrayscale60,
          labelStyle: const TextStyle(fontWeight: FontWeight.w600),
          tabs: const [
            Tab(text: 'RÉCEPTION'),
            Tab(text: 'ENVOI'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Onglet RÉCEPTION
          _buildReceptionTab(),
          // Onglet ENVOI
          _buildEnvoiTab(),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
          // Gérer la navigation si nécessaire
        },
        type: BottomNavigationBarType.fixed,
        backgroundColor: AppColor.kWhite,
        selectedItemColor: AppColor.kPrimary,
        unselectedItemColor: AppColor.kGrayscale40,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.inbox), label: 'Suivre'),
          BottomNavigationBarItem(icon: Icon(Icons.send), label: 'Envoyer'),
          BottomNavigationBarItem(icon: Icon(Icons.location_on), label: 'Localiser'),
          BottomNavigationBarItem(icon: Icon(Icons.notifications), label: 'Notifications'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Compte'),
        ],
      ),
    );
  }

  Widget _buildReceptionTab() {
    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        // Message "Aucun colis à l’horizon"
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColor.kWhite,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColor.kLine),
          ),
          child: Column(
            children: [
              Icon(
                Icons.inbox,
                size: 50,
                color: AppColor.kGrayscale40,
              ),
              const SizedBox(height: 8),
              Text(
                'Aucun colis à l’horizon pour le moment.',
                style: TextStyle(
                  fontSize: 16,
                  color: AppColor.kGrayscale80,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                'Voulez-vous ajouter un suivi ?',
                style: TextStyle(
                  fontSize: 14,
                  color: AppColor.kGrayscale60,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () {
                  // Action "Ajouter un suivi"
                },
                child: Text(
                  'Ajouter un suivi',
                  style: TextStyle(
                    color: AppColor.kPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        // Lien "Voir mes colis livrés/archivés"
        Center(
          child: TextButton(
            onPressed: () {
              // Action vers la liste des colis livrés/archivés
            },
            child: Text(
              'Voir mes colis livrés/archivés',
              style: TextStyle(
                color: AppColor.kPrimary,
                fontWeight: FontWeight.w500,
                decoration: TextDecoration.underline,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEnvoiTab() {
    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        // Bloc "Envoyez vos colis dès 4,10€"
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColor.kAccentSoft,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColor.kLine),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Envoyez vos colis dès 4,10€ grâce à l\'app !',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColor.kBlack,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Un anniversaire, un cadeau à faire ou un objet à renvoyer ?',
                style: TextStyle(
                  fontSize: 14,
                  color: AppColor.kGrayscale60,
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const EnvoiColisPage(),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColor.kPrimary,
                  foregroundColor: AppColor.kWhite,
                  minimumSize: const Size(double.infinity, 45),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25),
                  ),
                ),
                child: const Text('Envoyez votre colis'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        // Lien "Voir mes colis livrés/archivés" (identique à l'autre onglet)
        Center(
          child: TextButton(
            onPressed: () {
              // Action vers la liste des colis livrés/archivés
            },
            child: Text(
              'Voir mes colis livrés/archivés',
              style: TextStyle(
                color: AppColor.kPrimary,
                fontWeight: FontWeight.w500,
                decoration: TextDecoration.underline,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// Nouvelle page d'envoi de colis (intégrée dans le même fichier)
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

  final _formKeyStep1 = GlobalKey<FormState>();
  final _formKeyStep2 = GlobalKey<FormState>();

  @override
  void dispose() {
    _poidsController.dispose();
    _rechercheController.dispose();
    super.dispose();
  }

  void _suivant() {
    if (_formKeyStep1.currentState!.validate()) {
      setState(() {
        _currentStep = 2;
      });
    }
  }

  void _retour() {
    setState(() {
      _currentStep = 1;
    });
  }

  void _envoyer() {
    if (_formKeyStep2.currentState!.validate()) {
      // TODO: implémenter l'envoi du colis
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Colis envoyé avec succès !')),
      );
      Navigator.of(context).pop();
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
              // Indicateur d'étape
              Row(
                children: [
                  _buildStepIndicator(1, 'Destination', _currentStep >= 1),
                  const Expanded(
                    child: Divider(
                      color: AppColor.kLine,
                      thickness: 1.5,
                    ),
                  ),
                  _buildStepIndicator(2, 'Destinataire', _currentStep >= 2),
                ],
              ),
              const SizedBox(height: 32),

              // Formulaire étape 1
              if (_currentStep == 1) ...[
                _buildStep1Form(),
                const SizedBox(height: 32),
                _buildNavigationButtons(
                  onSuivant: _suivant,
                  onRetour: null, // Pas de retour à l'étape 1
                  isLastStep: false,
                ),
              ],

              // Formulaire étape 2
              if (_currentStep == 2) ...[
                _buildStep2Form(),
                const SizedBox(height: 32),
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
          // Pays de destination
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
              onChanged: (value) {
                setState(() {
                  _selectedPays = value;
                });
              },
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Veuillez sélectionner un pays';
                }
                return null;
              },
            ),
          ),
          const SizedBox(height: 24),

          // Poids
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
                  child: Icon(
                    Icons.scale,
                    color: AppColor.kPrimary,
                    size: 20,
                  ),
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
    return Form(
      key: _formKeyStep2,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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
                  child: Icon(
                    Icons.search,
                    color: AppColor.kPrimary,
                    size: 20,
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(right: 16),
                    child: PrimaryTextFormField(
                      controller: _rechercheController,
                      hintText: 'Nom, Prenom, Email...',
                      height: 50,
                      width: double.infinity,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Veuillez entrer une adresse';
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