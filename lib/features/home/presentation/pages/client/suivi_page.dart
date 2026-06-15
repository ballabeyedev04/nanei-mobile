import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:nanei/core/theme/app_color.dart';
import 'package:nanei/features/auth/domain/entities/user.dart';
import '../../../domain/entities/colis.dart';
import '../../../domain/entities/personne.dart';
import '../../bloc/colis_bloc.dart';
import '../../bloc/colis_event.dart';
import '../../bloc/colis_state.dart';
import '../../widgets/empty_state.dart';

class SuiviPage extends StatefulWidget {
  final User? user;
  const SuiviPage({super.key, this.user});

  @override
  State<SuiviPage> createState() => _SuiviPageState();
}

class _SuiviPageState extends State<SuiviPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  String _filtreTous = 'Tous';
  String _filtreEnvoyes = 'Tous';
  String _filtreRecus = 'Tous';

  static const _filtres = ['Tous', 'En attente', 'Récupéré', 'Livré'];

  static const _statutMap = {
    'En attente': 'en_attente',
    'Récupéré': 'recupere',
    'Livré': 'livré',
  };

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  List<Colis> _applyFiltre(List<Colis> list, String filtre) {
    if (filtre == 'Tous') return list;
    final code = _statutMap[filtre] ?? filtre.toLowerCase();
    return list.where((c) => c.statut.toLowerCase() == code).toList();
  }

  int _countStatut(List<Colis> list, String code) =>
      list.where((c) => c.statut.toLowerCase() == code).length;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ColisBloc, ColisState>(
      builder: (context, state) {
        final tous = [...state.colisEnvoyes, ...state.colisRecus];

        return Scaffold(
          backgroundColor: const Color(0xFFF2F4F8),
          body: NestedScrollView(
            headerSliverBuilder: (_, __) => [
              _buildHeader(context, state, tous),
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
                        loading: state.loadingEnvoyes || state.loadingRecus,
                        colis: tous,
                        filtre: _filtreTous,
                        onFiltreChange: (f) => setState(() => _filtreTous = f),
                        onRefresh: () async {
                          context.read<ColisBloc>()
                            ..add(LoadColisEnvoyes())
                            ..add(LoadColisRecus());
                        },
                        isReception: null,
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
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ── Header ─────────────────────────────────────────────────────────────────

  Widget _buildHeader(
      BuildContext context, ColisState state, List<Colis> tous) {
    final loading = state.loadingEnvoyes || state.loadingRecus;
    final nbTotal = tous.length;
    final nbAttente = _countStatut(tous, 'en_attente');
    final nbLivres = _countStatut(tous, 'livré');

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
                            'Suivi des colis',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 26,
                              fontWeight: FontWeight.w800,
                              color: AppColor.kGrayscaleDark100,
                              height: 1,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Suivez l\'état de vos expéditions',
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
                child: loading
                    ? Row(
                        children: List.generate(
                            3,
                            (_) => Expanded(
                                  child: Container(
                                    margin: const EdgeInsets.only(right: 8),
                                    height: 72,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFF2F4F8),
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                  ),
                                )),
                      )
                    : Row(
                        children: [
                          Expanded(
                            child: _statCard(
                              label: 'Total',
                              count: nbTotal,
                              icon: Icons.all_inbox_rounded,
                              color: const Color(0xFF7C3AED),
                              bg: const Color(0xFFF5F3FF),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _statCard(
                              label: 'En attente',
                              count: nbAttente,
                              icon: Icons.schedule_rounded,
                              color: const Color(0xFFB45309),
                              bg: const Color(0xFFFEF3C7),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _statCard(
                              label: 'Livrés',
                              count: nbLivres,
                              icon: Icons.check_circle_rounded,
                              color: const Color(0xFF059669),
                              bg: const Color(0xFFD1FAE5),
                            ),
                          ),
                        ],
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _statCard({
    required String label,
    required int count,
    required IconData icon,
    required Color color,
    required Color bg,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(14),
      ),
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
          Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 11,
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  // ── Onglets segmentés ──────────────────────────────────────────────────────

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
              _segTab(0, 'Tous', Icons.all_inbox_rounded, idx),
              const SizedBox(width: 10),
              _segTab(1, 'Envoyés', Icons.send_rounded, idx),
              const SizedBox(width: 10),
              _segTab(2, 'Reçus', Icons.move_to_inbox_rounded, idx),
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
              const SizedBox(width: 6),
              Text(
                label,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
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

  // ── Tab content ────────────────────────────────────────────────────────────

  Widget _buildTab({
    required BuildContext context,
    required bool loading,
    required List<Colis> colis,
    required String filtre,
    required ValueChanged<String> onFiltreChange,
    required Future<void> Function() onRefresh,
    required bool? isReception,
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
        // Filter pills
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
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
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
                      color: active ? Colors.white : AppColor.kGrayscale60,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 14),
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
                  icon: Icons.local_shipping_rounded,
                  message: filtre == 'Tous'
                      ? 'Aucun colis à suivre pour le moment.'
                      : 'Aucun colis "$filtre".',
                )
              : RefreshIndicator(
                  onRefresh: onRefresh,
                  color: AppColor.kPrimary,
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 40),
                    itemCount: filtered.length,
                    itemBuilder: (_, i) {
                      final c = filtered[i];
                      final reception = isReception ??
                          state_isReception(c, widget.user?.id);
                      return _SuiviColisCard(
                        colis: c,
                        isReception: reception,
                      );
                    },
                  ),
                ),
        ),
      ],
    );
  }
}

/// Pour l'onglet "Tous", détermine si c'est une réception ou un envoi
/// en comparant l'id de l'expéditeur avec l'id de l'utilisateur courant.
bool state_isReception(Colis c, String? userId) {
  if (userId == null) return false;
  return c.expediteur?.id != userId;
}

// ── Helpers statut ─────────────────────────────────────────────────────────

class _StatusInfo {
  final String label;
  final Color color;
  final Color bg;
  const _StatusInfo(this.label, this.color, this.bg);
}

_StatusInfo _statusOf(String raw) {
  switch (raw.toLowerCase()) {
    case 'livré':
    case 'livrée':
      return const _StatusInfo(
          'Livré', Color(0xFF059669), Color(0xFFD1FAE5));
    case 'recupere':
      return const _StatusInfo(
          'Récupéré', Color(0xFF2563EB), Color(0xFFDBEAFE));
    default:
      return const _StatusInfo(
          'En attente', Color(0xFFB45309), Color(0xFFFEF3C7));
  }
}

// ── Carte Suivi ────────────────────────────────────────────────────────────

class _SuiviColisCard extends StatelessWidget {
  final Colis colis;
  final bool isReception;

  const _SuiviColisCard({required this.colis, required this.isReception});

  @override
  Widget build(BuildContext context) {
    final Personne? personne =
        isReception ? colis.expediteur : colis.recepteur;
    final String personneNom = personne?.nomComplet ?? 'Inconnu';
    final String initiale =
        personneNom.isNotEmpty ? personneNom[0].toUpperCase() : '?';
    final String personneLabel = isReception ? 'Expéditeur' : 'Destinataire';
    final status = _statusOf(colis.statut);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Accent gauche coloré
              Container(width: 5, color: status.color),
              // Contenu
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Référence + badge statut
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  isReception ? 'Colis reçu' : 'Colis envoyé',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                    color: AppColor.kGrayscale40,
                                    letterSpacing: 0.4,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '#${colis.reference}',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w800,
                                    color: AppColor.kGrayscaleDark100,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: status.bg,
                              borderRadius: BorderRadius.circular(30),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 6,
                                  height: 6,
                                  decoration: BoxDecoration(
                                    color: status.color,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 5),
                                Text(
                                  status.label,
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: status.color,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      // Destination
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.flight_takeoff_rounded,
                                size: 14, color: AppColor.kGrayscale40),
                            const SizedBox(width: 8),
                            Text(
                              'Vers ',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 12,
                                color: AppColor.kGrayscale40,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            Expanded(
                              child: Text(
                                colis.destination,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: AppColor.kGrayscaleDark100,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),
                      // Personne
                      Row(
                        children: [
                          Container(
                            width: 38,
                            height: 38,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: isReception
                                    ? [
                                        const Color(0xFF2563EB),
                                        const Color(0xFF60A5FA),
                                      ]
                                    : [
                                        AppColor.kPrimary,
                                        AppColor.kPrimaryLight,
                                      ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(10),
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
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  personneLabel,
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 10,
                                    color: AppColor.kGrayscale40,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                Text(
                                  personneNom,
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: AppColor.kGrayscaleDark100,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                                if (personne?.email != null &&
                                    personne!.email.isNotEmpty)
                                  Text(
                                    personne.email,
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 10,
                                      color: AppColor.kGrayscale40,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Divider(height: 1, color: Colors.grey.shade100),
                      const SizedBox(height: 14),
                      // Stepper de progression
                      _buildStepper(),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStepper() {
    const steps = [
      _Step(
        label: 'En attente',
        code: 'en_attente',
        icon: Icons.schedule_rounded,
        color: Color(0xFFB45309),
        bg: Color(0xFFFEF3C7),
      ),
      _Step(
        label: 'Récupéré',
        code: 'recupere',
        icon: Icons.inventory_2_rounded,
        color: Color(0xFF2563EB),
        bg: Color(0xFFDBEAFE),
      ),
      _Step(
        label: 'Livré',
        code: 'livré',
        icon: Icons.check_circle_rounded,
        color: Color(0xFF059669),
        bg: Color(0xFFD1FAE5),
      ),
    ];

    final statut = colis.statut.toLowerCase();
    int currentIdx = steps.indexWhere((s) => statut == s.code);
    if (currentIdx == -1) currentIdx = 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
            children: List.generate(steps.length * 2 - 1, (i) {
              if (i.isOdd) {
                // Connecteur
                final stepIdx = i ~/ 2;
                final active = stepIdx < currentIdx;
                return Expanded(
                  child: Container(
                    height: 2,
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    decoration: BoxDecoration(
                      gradient: active
                          ? LinearGradient(
                              colors: [
                                steps[stepIdx].color,
                                steps[stepIdx + 1].color,
                              ],
                            )
                          : null,
                      color: active ? null : const Color(0xFFE5E7EB),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                );
              }

              final stepIdx = i ~/ 2;
              final step = steps[stepIdx];
              final isDone = stepIdx < currentIdx;
              final isCurrent = stepIdx == currentIdx;

              return _StepDot(
                step: step,
                isDone: isDone,
                isCurrent: isCurrent,
              );
            }),
          ),
          const SizedBox(height: 10),
          // Labels sous les dots
          Row(
            children: List.generate(steps.length * 2 - 1, (i) {
              if (i.isOdd) return const Expanded(child: SizedBox());
              final stepIdx = i ~/ 2;
              final step = steps[stepIdx];
              final isDone = stepIdx < currentIdx;
              final isCurrent = stepIdx == currentIdx;
              return SizedBox(
                width: 62,
                child: Text(
                  step.label,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 10,
                    fontWeight:
                        isCurrent ? FontWeight.w700 : FontWeight.w500,
                    color: isCurrent
                        ? step.color
                        : isDone
                            ? AppColor.kGrayscale60
                            : AppColor.kGrayscale20,
                  ),
                ),
              );
            }),
          ),
        ],
      );
  }
}

class _Step {
  final String label;
  final String code;
  final IconData icon;
  final Color color;
  final Color bg;
  const _Step({
    required this.label,
    required this.code,
    required this.icon,
    required this.color,
    required this.bg,
  });
}

class _StepDot extends StatelessWidget {
  final _Step step;
  final bool isDone;
  final bool isCurrent;

  const _StepDot({
    required this.step,
    required this.isDone,
    required this.isCurrent,
  });

  @override
  Widget build(BuildContext context) {
    if (isCurrent) {
      return Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          color: step.bg,
          shape: BoxShape.circle,
          border: Border.all(color: step.color, width: 2),
        ),
        child: Icon(step.icon, size: 16, color: step.color),
      );
    }
    if (isDone) {
      return Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          color: step.color,
          shape: BoxShape.circle,
        ),
        child: const Icon(Icons.check_rounded, size: 14, color: Colors.white),
      );
    }
    return Container(
      width: 28,
      height: 28,
      decoration: const BoxDecoration(
        color: Color(0xFFF2F4F8),
        shape: BoxShape.circle,
      ),
      child: Icon(step.icon, size: 14, color: const Color(0xFFCBD5E1)),
    );
  }
}
