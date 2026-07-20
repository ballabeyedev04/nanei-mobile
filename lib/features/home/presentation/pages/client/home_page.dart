import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nanei/core/widgets/logout_dialog.dart';
import 'package:nanei/core/widgets/support_sheet.dart';
import 'package:nanei/core/widgets/calculateur_sheet.dart';
import 'package:nanei/features/home/presentation/pages/client/profils_page.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:nanei/core/theme/app_color.dart';
import 'package:nanei/features/auth/domain/entities/user.dart';
import '../../bloc/colis_bloc.dart';
import '../../bloc/colis_event.dart';
import '../../bloc/colis_state.dart';
import 'envoi_colis_page.dart';
import 'scan_colis_page.dart';

class HomePage extends StatelessWidget {
  final User? user;
  const HomePage({super.key, this.user});

  @override
  Widget build(BuildContext context) {
    final String nomComplet =
        user != null ? '${user!.prenom} ${user!.nom}'.trim() : 'Invité';
    final String email = user?.email ?? '';
    final String initiales = user != null
        ? ('${user!.prenom.isNotEmpty ? user!.prenom[0] : ''}'
                '${user!.nom.isNotEmpty ? user!.nom[0] : ''}')
            .toUpperCase()
        : '?';

    return BlocBuilder<ColisBloc, ColisState>(
      builder: (context, state) {
        return Scaffold(
          backgroundColor: const Color(0xFFF4F6FA),
          body: RefreshIndicator(
            onRefresh: () async {
              context.read<ColisBloc>()
                ..add(LoadStatistiques())
                ..add(LoadColisEnvoyes())
                ..add(LoadColisRecus());
            },
            color: AppColor.kPrimary,
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                _buildHeader(context, nomComplet, email, initiales),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildStatsRow(state),
                        const SizedBox(height: 28),
                        _label('Actions rapides'),
                        const SizedBox(height: 14),
                        _buildActionsRow(context),
                        const SizedBox(height: 28),
                        _label('Expédition'),
                        const SizedBox(height: 14),
                        _buildShipCTA(context),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader(BuildContext context, String nomComplet, String email,
      String initiales) {
    return SliverToBoxAdapter(
      child: Container(
        color: Colors.white,
        child: SafeArea(
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
            child: Row(
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: AppColor.kPrimary,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Center(
                    child: Text(
                      initiales.isEmpty ? '?' : initiales,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 16,
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
                        nomComplet.isEmpty ? 'Invité' : nomComplet,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: AppColor.kGrayscaleDark100,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (email.isNotEmpty)
                        Text(
                          email,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            color: AppColor.kGrayscale40,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                    ],
                  ),
                ),
                _iconBtn(
                  Icons.person_outline_rounded,
                  () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const ProfilsPage()),
                  ),
                ),

                const SizedBox(width: 8),
                _logoutBtn(context),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _logoutBtn(BuildContext context) {
    return GestureDetector(
      onTap: () => showLogoutDialog(context),
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: const Color(0xFFFF4444).withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(
          Icons.power_settings_new_rounded,
          size: 19,
          color: Color(0xFFFF4444),
        ),
      ),
    );
  }

  Widget _iconBtn(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: const Color(0xFFF4F6FA),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, size: 20, color: AppColor.kGrayscale60),
      ),
    );
  }

  Widget _buildStatsRow(ColisState state) {
    return Row(
      children: [
        Expanded(
          child: _statCard(
            icon: Icons.send_rounded,
            label: 'Envoyés',
            count: state.loadingStats ? null : state.nbEnvoyes,
            iconColor: AppColor.kPrimary,
            iconBg: AppColor.kAccentSoft,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _statCard(
            icon: Icons.inbox_rounded,
            label: 'Reçus',
            count: state.loadingStats ? null : state.nbRecus,
            iconColor: const Color(0xFF0EA5E9),
            iconBg: const Color(0xFFE0F2FE),
          ),
        ),
      ],
    );
  }

  Widget _statCard({
    required IconData icon,
    required String label,
    required int? count,
    required Color iconColor,
    required Color iconBg,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
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
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, size: 20, color: iconColor),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              count == null
                  ? SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: iconColor),
                    )
                  : Text(
                      '$count',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        color: AppColor.kGrayscaleDark100,
                        height: 1,
                      ),
                    ),
              const SizedBox(height: 3),
              Text(
                label,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: AppColor.kGrayscale40,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionsRow(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _actionCard(
            context: context,
            icon: Icons.send_rounded,
            label: 'Envoyer',
            sub: 'Nouveau colis',
            iconColor: AppColor.kPrimary,
            iconBg: AppColor.kAccentSoft,
            onTap: () async {
              final result = await Navigator.of(context).push<bool>(
                MaterialPageRoute(builder: (_) => const EnvoiColisPage()),
              );
              if (result == true && context.mounted) {
                context.read<ColisBloc>()
                  ..add(LoadStatistiques())
                  ..add(LoadColisEnvoyes());
              }
            },
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _actionCard(
            context: context,
            icon: Icons.calculate_rounded,
            label: 'Calculer',
            sub: 'Estimer le tarif',
            iconColor: const Color(0xFF7C3AED),
            iconBg: const Color(0xFFEDE9FE),
            onTap: () => showCalculateurSheet(context),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _actionCard(
            context: context,
            icon: Icons.support_agent_rounded,
            label: 'Support',
            sub: 'Nous contacter',
            iconColor: const Color(0xFF0EA5E9),
            iconBg: const Color(0xFFE0F2FE),
            onTap: () => showSupportSheet(context),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _actionCard(
            context: context,
            icon: Icons.qr_code_scanner_rounded,
            label: 'Scanner',
            sub: 'Ouvrir un colis',
            iconColor: const Color(0xFF16A34A),
            iconBg: const Color(0xFFDCFCE7),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => ScanColisPage(user: user)),
            ),
          ),
        ),
      ],
    );
  }

  Widget _actionCard({
    required BuildContext context,
    required IconData icon,
    required String label,
    required String sub,
    required Color iconColor,
    required Color iconBg,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        splashColor: iconColor.withValues(alpha: 0.07),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 12,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                    color: iconBg,
                    borderRadius: BorderRadius.circular(12)),
                child: Icon(icon, size: 20, color: iconColor),
              ),
              const SizedBox(height: 10),
              Text(
                label,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColor.kGrayscaleDark100,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                sub,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 10,
                  color: AppColor.kGrayscale40,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildShipCTA(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColor.kGrayscaleDark100,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColor.kPrimary.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    'NOUVEAU',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                      color: AppColor.kPrimary,
                      letterSpacing: 1,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'Expédiez votre\ncolis maintenant',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Rapide · Fiable · Suivi en temps réel',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    color: Colors.white.withValues(alpha: 0.5),
                  ),
                ),
                const SizedBox(height: 16),
                GestureDetector(
                  onTap: () async {
                    final result =
                        await Navigator.of(context).push<bool>(
                      MaterialPageRoute(
                          builder: (_) => const EnvoiColisPage()),
                    );
                    if (result == true && context.mounted) {
                      context.read<ColisBloc>()
                        ..add(LoadStatistiques())
                        ..add(LoadColisEnvoyes());
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 18, vertical: 10),
                    decoration: BoxDecoration(
                      color: AppColor.kPrimary,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      'Commencer',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Icon(
            Icons.local_shipping_rounded,
            size: 80,
            color: Colors.white.withValues(alpha: 0.08),
          ),
        ],
      ),
    );
  }

  Widget _label(String text) => Text(
        text,
        style: GoogleFonts.plusJakartaSans(
          fontSize: 15,
          fontWeight: FontWeight.w700,
          color: AppColor.kGrayscaleDark100,
        ),
      );
}
