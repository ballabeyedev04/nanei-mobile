import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:francomalishipp/core/theme/app_color.dart';
import 'package:francomalishipp/features/auth/domain/entities/user.dart';
import '../../bloc/colis_bloc.dart';
import '../../bloc/colis_event.dart';
import '../../bloc/colis_state.dart';
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
  String _filtreRecus = 'Tous';
  String _filtreEnvoyes = 'Tous';

  static const _filtres = ['Tous', 'En attente', 'Récupéré', 'Livré'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  List<Colis> _applyFiltre(List<Colis> list, String filtre) {
    if (filtre == 'Tous') return list;
    const map = {
      'En attente': 'en_attente',
      'Récupéré': 'recupere',
      'Livré': 'livré',
    };
    final code = map[filtre] ?? filtre.toLowerCase();
    return list.where((c) => c.statut.toLowerCase() == code).toList();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ColisBloc, ColisState>(
      builder: (context, state) {
        return Scaffold(
          backgroundColor: const Color(0xFFF2F4F8),
          body: NestedScrollView(
            headerSliverBuilder: (_, __) => [
              _buildSliverHeader(state),
            ],
            body: Column(
              children: [
                _buildSegmentedTabs(),
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildTab(
                        context: context,
                        loading: state.loadingRecus,
                        colis: state.colisRecus,
                        filtre: _filtreRecus,
                        onFiltreChange: (f) =>
                            setState(() => _filtreRecus = f),
                        onRefresh: () async =>
                            context.read<ColisBloc>().add(LoadColisRecus()),
                        isReception: true,
                      ),
                      _buildTab(
                        context: context,
                        loading: state.loadingEnvoyes,
                        colis: state.colisEnvoyes,
                        filtre: _filtreEnvoyes,
                        onFiltreChange: (f) =>
                            setState(() => _filtreEnvoyes = f),
                        onRefresh: () async =>
                            context.read<ColisBloc>().add(LoadColisEnvoyes()),
                        isReception: false,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          floatingActionButton: _buildFAB(context),
        );
      },
    );
  }

  Widget _buildSliverHeader(ColisState state) {
    return SliverToBoxAdapter(
      child: Container(
        color: Colors.white,
        child: SafeArea(
          bottom: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Mes colis',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 26,
                              fontWeight: FontWeight.w800,
                              color: AppColor.kGrayscaleDark100,
                              height: 1,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Suivez tous vos envois et réceptions',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 13,
                              color: AppColor.kGrayscale40,
                            ),
                          ),
                        ],
                      ),
                    ),
                    GestureDetector(
                      onTap: () => context.read<ColisBloc>()
                        ..add(LoadColisEnvoyes())
                        ..add(LoadColisRecus()),
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: const Color(0xFFF2F4F8),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.refresh_rounded,
                            size: 20, color: Color(0xFF6B7280)),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                child: Row(
                  children: [
                    Expanded(
                        child: _summaryCard(
                            label: 'Reçus',
                            count: state.colisRecus.length,
                            icon: Icons.move_to_inbox_rounded,
                            color: const Color(0xFF2563EB),
                            bg: const Color(0xFFEFF6FF))),
                    const SizedBox(width: 12),
                    Expanded(
                        child: _summaryCard(
                            label: 'Envoyés',
                            count: state.colisEnvoyes.length,
                            icon: Icons.send_rounded,
                            color: AppColor.kPrimary,
                            bg: AppColor.kAccentSoft)),
                    const SizedBox(width: 12),
                    Expanded(
                        child: _summaryCard(
                            label: 'Total',
                            count: state.colisRecus.length +
                                state.colisEnvoyes.length,
                            icon: Icons.all_inbox_rounded,
                            color: const Color(0xFF7C3AED),
                            bg: const Color(0xFFF5F3FF))),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _summaryCard({
    required String label,
    required int count,
    required IconData icon,
    required Color color,
    required Color bg,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
      decoration: BoxDecoration(
          color: bg, borderRadius: BorderRadius.circular(14)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(height: 8),
          Text(
            '$count',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: AppColor.kGrayscaleDark100,
              height: 1,
            ),
          ),
          const SizedBox(height: 2),
          Text(label,
              style: GoogleFonts.plusJakartaSans(
                  fontSize: 11, color: color, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _buildSegmentedTabs() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 14),
      child: AnimatedBuilder(
        animation: _tabController,
        builder: (_, __) {
          final idx = _tabController.index;
          return Row(
            children: [
              _segTab(0, 'Reçus', Icons.move_to_inbox_rounded, idx),
              const SizedBox(width: 10),
              _segTab(1, 'Envoyés', Icons.send_rounded, idx),
            ],
          );
        },
      ),
    );
  }

  Widget _segTab(int index, String label, IconData icon, int current) {
    final active = current == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => _tabController.animateTo(index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          height: 42,
          decoration: BoxDecoration(
            color: active
                ? AppColor.kGrayscaleDark100
                : const Color(0xFFF2F4F8),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon,
                  size: 15,
                  color: active ? Colors.white : AppColor.kGrayscale40),
              const SizedBox(width: 7),
              Text(
                label,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: active ? Colors.white : AppColor.kGrayscale40,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTab({
    required BuildContext context,
    required bool loading,
    required List<Colis> colis,
    required String filtre,
    required ValueChanged<String> onFiltreChange,
    required Future<void> Function() onRefresh,
    required bool isReception,
  }) {
    if (loading) {
      return Center(
        child: CircularProgressIndicator(
            color: AppColor.kPrimary, strokeWidth: 2),
      );
    }

    final filtered = _applyFiltre(colis, filtre);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        SizedBox(
          height: 34,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: _filtres.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (_, i) {
              final f = _filtres[i];
              final active = f == filtre;
              return GestureDetector(
                onTap: () => onFiltreChange(f),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: active
                        ? AppColor.kGrayscaleDark100
                        : Colors.white,
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(
                      color: active
                          ? AppColor.kGrayscaleDark100
                          : const Color(0xFFE5E7EB),
                    ),
                  ),
                  child: Text(
                    f,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color:
                          active ? Colors.white : AppColor.kGrayscale60,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 16),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Text(
            '${filtered.length} colis',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColor.kGrayscale40,
            ),
          ),
        ),
        const SizedBox(height: 10),
        Expanded(
          child: filtered.isEmpty
              ? buildEmptyState(
                  icon: isReception
                      ? Icons.move_to_inbox_rounded
                      : Icons.send_rounded,
                  message: filtre == 'Tous'
                      ? (isReception
                          ? 'Aucun colis reçu pour le moment.'
                          : 'Aucun colis envoyé pour le moment.')
                      : 'Aucun colis "$filtre".',
                )
              : RefreshIndicator(
                  onRefresh: onRefresh,
                  color: AppColor.kPrimary,
                  child: ListView.builder(
                    padding:
                        const EdgeInsets.fromLTRB(20, 0, 20, 110),
                    itemCount: filtered.length,
                    itemBuilder: (_, i) => buildColisCard(
                      colis: filtered[i],
                      isReception: isReception,
                    ),
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildFAB(BuildContext context) {
    return AnimatedBuilder(
      animation: _tabController,
      builder: (_, __) {
        final show = _tabController.index == 1;
        return AnimatedSlide(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOutCubic,
          offset: show ? Offset.zero : const Offset(0, 2.5),
          child: AnimatedOpacity(
            duration: const Duration(milliseconds: 200),
            opacity: show ? 1 : 0,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                gradient: LinearGradient(
                  colors: [AppColor.kPrimary, AppColor.kPrimaryDark],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColor.kPrimary.withValues(alpha: 0.4),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(16),
                child: InkWell(
                  onTap: show ? () => _goToEnvoi(context) : null,
                  borderRadius: BorderRadius.circular(16),
                  splashColor: Colors.white.withValues(alpha: 0.15),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 14),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.add_rounded,
                            color: Colors.white, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          'Envoyer un colis',
                          style: GoogleFonts.plusJakartaSans(
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _goToEnvoi(BuildContext context) async {
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => const EnvoiColisPage()),
    );
    if (result == true && context.mounted) {
      context.read<ColisBloc>().add(LoadColisEnvoyes());
    }
  }
}
