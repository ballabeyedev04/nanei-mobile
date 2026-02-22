import 'package:flutter/material.dart';
import 'package:francomalishipp/features/auth/domain/entities/user.dart';
// Importer d'autres packages si nécessaire (bloc, etc.)
import '../../../../../core/theme/app_color.dart';

class ProfessionnelPage extends StatefulWidget {
  final User? user;

  const ProfessionnelPage({super.key, this.user});

  @override
  State<ProfessionnelPage> createState() => _ProfessionnelPageState();
}

class _ProfessionnelPageState extends State<ProfessionnelPage>
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
                  // Action "Envoyez votre colis"
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