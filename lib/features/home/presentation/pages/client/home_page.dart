import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:francomalishipp/core/theme/app_color.dart';
import 'package:francomalishipp/features/auth/domain/entities/user.dart';
import '../../../data/datasources/colis_api.dart';

class HomePage extends StatefulWidget {
  final User? user;
  const HomePage({super.key, this.user});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _nbEnvoyes = 0;
  int _nbRecus = 0;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    setState(() => _loading = true);
    try {
      final nbEnv = await ColisApi.getNombreColisEnvoyes();
      final nbRec = await ColisApi.getNombreColisRecus();
      setState(() {
        _nbEnvoyes = nbEnv;
        _nbRecus = nbRec;
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = widget.user;
    final String nomComplet = user != null
        ? '${user.prenom ?? ''} ${user.nom ?? ''}'.trim()
        : 'Invité';
    final String email = user?.email ?? 'Non connecté';
    final String initiales = user != null
        ? '${user.prenom?.isNotEmpty == true ? user.prenom![0] : ''}${user.nom?.isNotEmpty == true ? user.nom![0] : ''}'
        .toUpperCase()
        : '?';

    return Scaffold(
      backgroundColor: AppColor.kBackground,
      // ── AppBar ──────────────────────────────────────────────────────────
      appBar: AppBar(
        backgroundColor: AppColor.kPrimary,
        elevation: 0,
        centerTitle: true,
        title: Text(
          'ACCUEIL',
          style: GoogleFonts.plusJakartaSans(
            color: Colors.white,
            fontWeight: FontWeight.w800,
            fontSize: 17,
            letterSpacing: 1.5,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.notifications_outlined,
                  color: Colors.white, size: 20),
            ),
          ),
        ],
      ),

      body: _loading
          ? Center(
          child: CircularProgressIndicator(color: AppColor.kPrimary))
          : RefreshIndicator(
        onRefresh: _loadStats,
        color: AppColor.kPrimary,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Hero Banner ───────────────────────────────────────
              _buildHeroBanner(nomComplet, email, initiales),

              const SizedBox(height: 24),

              // ── Section Statistiques ──────────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  'STATISTIQUES',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColor.kGrayscale60,
                    letterSpacing: 1.2,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  children: [
                    _buildStatCard(
                      icon: Icons.send_rounded,
                      title: 'Colis envoyés',
                      count: _nbEnvoyes,
                      color: AppColor.kPrimary,
                      bgColor: AppColor.kPrimary.withOpacity(0.08),
                      subtitle: 'Total de vos envois',
                    ),
                    const SizedBox(height: 12),
                    _buildStatCard(
                      icon: Icons.inbox_rounded,
                      title: 'Colis reçus',
                      count: _nbRecus,
                      color: const Color(0xFF10B981),
                      bgColor: const Color(0xFF10B981).withOpacity(0.08),
                      subtitle: 'Total de vos réceptions',
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // ── Section Actions rapides ───────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  'ACTIONS RAPIDES',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColor.kGrayscale60,
                    letterSpacing: 1.2,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  mainAxisSpacing: 10,
                  crossAxisSpacing: 10,
                  childAspectRatio: 1.55,
                  children: [
                    _buildActionCard(
                      icon: Icons.send_rounded,
                      label: 'Envoyer',
                      sub: 'Nouveau colis',
                      bgColor: AppColor.kPrimary.withOpacity(0.08),
                      iconColor: AppColor.kPrimary,
                    ),
                    _buildActionCard(
                      icon: Icons.location_on_rounded,
                      label: 'Suivre',
                      sub: 'Localiser un colis',
                      bgColor: const Color(0xFF10B981).withOpacity(0.08),
                      iconColor: const Color(0xFF10B981),
                    ),
                    _buildActionCard(
                      icon: Icons.history_rounded,
                      label: 'Historique',
                      sub: 'Tous mes colis',
                      bgColor: const Color(0xFFF59E0B).withOpacity(0.08),
                      iconColor: const Color(0xFFF59E0B),
                    ),
                    _buildActionCard(
                      icon: Icons.person_rounded,
                      label: 'Profil',
                      sub: 'Mon compte',
                      bgColor: const Color(0xFF8B5CF6).withOpacity(0.08),
                      iconColor: const Color(0xFF8B5CF6),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  // ── Hero Banner ──────────────────────────────────────────────────────────

  Widget _buildHeroBanner(String nomComplet, String email, String initiales) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColor.kPrimary,
            AppColor.kPrimary.withOpacity(0.75),
          ],
        ),
      ),
      child: Stack(
        children: [
          // Cercles décoratifs en arrière-plan
          Positioned(
            top: -40, right: -40,
            child: Container(
              width: 180, height: 180,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.06),
              ),
            ),
          ),
          Positioned(
            bottom: -60, left: -20,
            child: Container(
              width: 220, height: 220,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.04),
              ),
            ),
          ),
          // Contenu
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Avatar + infos utilisateur
                Row(
                  children: [
                    Container(
                      width: 60, height: 60,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.18),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                            color: Colors.white.withOpacity(0.3), width: 2),
                      ),
                      child: Center(
                        child: Text(
                          initiales,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Bonjour 👋',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 13,
                              color: Colors.white.withOpacity(0.7),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            nomComplet.isEmpty ? 'Invité' : nomComplet,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            email,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12,
                              color: Colors.white.withOpacity(0.55),
                              fontWeight: FontWeight.w500,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                // Badges rapides
                Row(
                  children: [
                    Expanded(
                      child: _buildHeroBadge(
                          label: 'Envoyés', value: _nbEnvoyes.toString()),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _buildHeroBadge(
                          label: 'Reçus', value: _nbRecus.toString()),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _buildHeroBadge(
                          label: 'En transit', value: '—'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeroBadge({required String label, required String value}) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.12),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: Colors.white.withOpacity(0.65),
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }

  // ── Stat Card ────────────────────────────────────────────────────────────

  Widget _buildStatCard({
    required IconData icon,
    required String title,
    required int count,
    required Color color,
    required Color bgColor,
    required String subtitle,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColor.kWhite,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColor.kLine),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 52, height: 52,
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, size: 24, color: color),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColor.kGrayscale60,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  count.toString(),
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 32,
                    fontWeight: FontWeight.w800,
                    color: color,
                    height: 1.1,
                  ),
                ),
                Text(
                  subtitle,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    color: AppColor.kGrayscale40,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: 32, height: 32,
            decoration: BoxDecoration(
              color: AppColor.kBackground,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(Icons.chevron_right_rounded,
                color: AppColor.kGrayscale40, size: 20),
          ),
        ],
      ),
    );
  }

  // ── Action Card ──────────────────────────────────────────────────────────

  Widget _buildActionCard({
    required IconData icon,
    required String label,
    required String sub,
    required Color bgColor,
    required Color iconColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColor.kWhite,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColor.kLine),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 40, height: 40,
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, size: 20, color: iconColor),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppColor.kGrayscaleDark100,
            ),
          ),
          Text(
            sub,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 10,
              color: AppColor.kGrayscale60,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}