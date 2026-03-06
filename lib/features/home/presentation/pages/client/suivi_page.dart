import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:francomalishipp/core/theme/app_color.dart';
import 'package:francomalishipp/features/auth/domain/entities/user.dart';
import 'package:francomalishipp/injection_container.dart';
import '../../../domain/entities/colis.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/detail_chip.dart';

class SuiviPage extends StatefulWidget {
  final User? user;
  const SuiviPage({super.key, this.user});

  @override
  State<SuiviPage> createState() => _SuiviPageState();
}

class _SuiviPageState extends State<SuiviPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<Colis> _colisEnAttente = [];
  List<Colis> _colisRecuperes = [];
  List<Colis> _colisLivres = [];
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _fetchAllColis();
  }

  Future<void> _fetchAllColis() async {
    setState(() => _loading = true);
    try {
      final dio = sl<Dio>();
      final responseEnv = await dio.get('/client/colis-envoyes');
      final responseRec = await dio.get('/client/colis-recus');
      List<Colis> tous = [];
      if (responseEnv.statusCode == 200) {
        tous.addAll((responseEnv.data['data'] as List).map((e) => Colis.fromJson(e)));
      }
      if (responseRec.statusCode == 200) {
        tous.addAll((responseRec.data['data'] as List).map((e) => Colis.fromJson(e)));
      }

      setState(() {
        _colisEnAttente = tous.where((c) => c.statut.toLowerCase() == 'en_attente').toList();
        _colisRecuperes = tous.where((c) => c.statut.toLowerCase() == 'recupere').toList();
        _colisLivres = tous.where((c) => c.statut.toLowerCase() == 'livré').toList();
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur chargement: $e')),
        );
      }
    }
  }

  void _refresh() {
    _fetchAllColis();
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
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
          'SUIVI',
          style: TextStyle(
            color: AppColor.kBlack,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refresh,
            tooltip: 'Actualiser',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColor.kPrimary,
          labelColor: AppColor.kPrimary,
          unselectedLabelColor: AppColor.kGrayscale60,
          labelStyle: const TextStyle(fontWeight: FontWeight.w600),
          tabs: const [
            Tab(text: 'EN ATTENTE'),
            Tab(text: 'RÉCUPÉRÉ'),
            Tab(text: 'LIVRÉ'),
          ],
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
        controller: _tabController,
        children: [
          _buildList(_colisEnAttente),
          _buildList(_colisRecuperes),
          _buildList(_colisLivres),
        ],
      ),
    );
  }

  Widget _buildList(List<Colis> colis) {
    if (colis.isEmpty) {
      return buildEmptyState(
        icon: Icons.local_shipping,
        message: 'Aucun colis dans cette catégorie.',
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: colis.length,
      itemBuilder: (context, index) {
        final c = colis[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: AppColor.kWhite,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.location_on, size: 18, color: AppColor.kPrimary),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        c.destination,
                        style: GoogleFonts.plusJakartaSans(
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                          color: AppColor.kGrayscaleDark100,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Expéditeur: ${c.expediteur?.nomComplet ?? 'Inconnu'}',
                        style: GoogleFonts.plusJakartaSans(fontSize: 14),
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Destinataire: ${c.recepteur?.nomComplet ?? 'Inconnu'}',
                        style: GoogleFonts.plusJakartaSans(fontSize: 14),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    buildDetailChip(
                      icon: Icons.scale,
                      label: '${c.poids.toStringAsFixed(2)} kg',
                    ),
                    const SizedBox(width: 8),
                    buildDetailChip(
                      icon: Icons.euro,
                      label: '${c.prix.toStringAsFixed(2)} €',
                    ),
                    const Spacer(),
                    Text(
                      _formatDate(c.createdAt),
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        color: AppColor.kGrayscale40,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}