import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:francomalishipp/core/theme/app_color.dart';
import 'package:francomalishipp/features/auth/domain/entities/user.dart';
import 'package:francomalishipp/injection_container.dart';
import '../../../domain/entities/colis.dart';
import '../../widgets/colis_card.dart';
import '../../widgets/empty_state.dart';
import 'envoi_colis_page.dart';

class ReceptionEnvoiPage extends StatefulWidget {
  final User? user;
  const ReceptionEnvoiPage({super.key, this.user});

  @override
  State<ReceptionEnvoiPage> createState() => _ReceptionEnvoiPageState();
}

class _ReceptionEnvoiPageState extends State<ReceptionEnvoiPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<Colis> _colisRecus = [];
  List<Colis> _colisEnvoyes = [];
  bool _loadingRecus = false;
  bool _loadingEnvoyes = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _fetchColisRecus();
    _fetchColisEnvoyes();
  }

  Future<void> _fetchColisRecus() async {
    setState(() => _loadingRecus = true);
    try {
      final dio = sl<Dio>();
      final response = await dio.get('/client/colis-recus');
      if (response.statusCode == 200) {
        final List data = response.data['data'] ?? [];
        setState(() {
          _colisRecus = data.map((e) => Colis.fromJson(e)).toList();
          _loadingRecus = false;
        });
      }
    } catch (e) {
      setState(() => _loadingRecus = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur chargement colis reçus: $e')),
        );
      }
    }
  }

  Future<void> _fetchColisEnvoyes() async {
    setState(() => _loadingEnvoyes = true);
    try {
      final dio = sl<Dio>();
      final response = await dio.get('/client/colis-envoyes');
      if (response.statusCode == 200) {
        final List data = response.data['data'] ?? [];
        setState(() {
          _colisEnvoyes = data.map((e) => Colis.fromJson(e)).toList();
          _loadingEnvoyes = false;
        });
      }
    } catch (e) {
      setState(() => _loadingEnvoyes = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur chargement colis envoyés: $e')),
        );
      }
    }
  }

  void _refreshCurrentTab() {
    if (_tabController.index == 0) {
      _fetchColisRecus();
    } else {
      _fetchColisEnvoyes();
    }
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
          'MES COLIS',
          style: TextStyle(
            color: AppColor.kBlack,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshCurrentTab,
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
            Tab(text: 'RÉCEPTION'),
            Tab(text: 'ENVOI'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildList(_colisRecus, _loadingRecus, isReception: true),
          _buildList(_colisEnvoyes, _loadingEnvoyes, isReception: false),
        ],
      ),
    );
  }

  Widget _buildList(List<Colis> colis, bool loading, {required bool isReception}) {
    if (loading) return const Center(child: CircularProgressIndicator());
    if (colis.isEmpty) {
      return buildEmptyState(
        icon: isReception ? Icons.inbox : Icons.send,
        message: isReception
            ? 'Aucun colis reçu pour le moment.'
            : 'Aucun colis envoyé pour le moment.',
        buttonText: isReception ? null : 'Envoyer un colis',
        onPressed: isReception
            ? null
            : () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => const EnvoiColisPage(),
            ),
          );
        },
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: colis.length,
      itemBuilder: (context, index) {
        return buildColisCard(colis: colis[index], isReception: isReception);
      },
    );
  }
}