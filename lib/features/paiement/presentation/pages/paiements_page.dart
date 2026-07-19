import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:nanei/core/theme/app_color.dart';
import 'package:nanei/core/utils/security_validators.dart';
import '../bloc/paiement_bloc.dart';
import '../bloc/paiement_event.dart';
import '../bloc/paiement_state.dart';
import '../../domain/entities/paiement.dart';
// Réactiver quand le paiement en ligne (Wave/Orange Money) sera géré côté
// backend — voir _afficherChoixPaiement ci-dessous.
// import '../widgets/choix_paiement_sheet.dart';
import '../widgets/service_indisponible_sheet.dart';
import '../widgets/facture_button.dart';

class PaiementsPage extends StatefulWidget {
  const PaiementsPage({super.key});

  @override
  State<PaiementsPage> createState() => _PaiementsPageState();
}

class _PaiementsPageState extends State<PaiementsPage>
    with WidgetsBindingObserver {
  bool _returningFromBrowser = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    context.read<PaiementBloc>().add(LoadMesPaiements());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && _returningFromBrowser) {
      _returningFromBrowser = false;
      context.read<PaiementBloc>().add(RefreshPaiements());
    }
  }

  Future<void> _ouvrirUrl(String url) async {
    final uri = SecurityValidators.validatePaymentUrl(url);
    if (uri == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Lien de paiement invalide ou non sécurisé.'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }
    _returningFromBrowser = true;
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      _returningFromBrowser = false;
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Impossible d'ouvrir le lien de paiement")),
        );
      }
    }
  }

  void _afficherChoixPaiement(Paiement paiement) {
    // TEMPORAIRE : le paiement en ligne n'est pas encore géré côté backend.
    // Une fois prêt, décommenter le bloc ci-dessous et supprimer l'appel à
    // ServiceIndisponibleSheet.
    //
    // showModalBottomSheet(
    //   context: context,
    //   backgroundColor: Colors.transparent,
    //   isScrollControlled: true,
    //   builder: (_) => ChoixPaiementSheet(
    //     reference: paiement.reference,
    //     montant: paiement.prixTotal,
    //     onChoix: (moyen) {
    //       context.read<PaiementBloc>().add(InitierPaiementEvent(
    //         colisId: paiement.colisId,
    //         moyenPaiement: moyen,
    //       ));
    //     },
    //   ),
    // );

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => const ServiceIndisponibleSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FB),
      body: BlocListener<PaiementBloc, PaiementState>(
        listener: (context, state) {
          if (state is PaiementUrlReady) {
            _ouvrirUrl(state.checkoutUrl);
          } else if (state is PaiementInitiationError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.red.shade600,
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        },
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              pinned: true,
              backgroundColor: Colors.white,
              surfaceTintColor: Colors.transparent,
              elevation: 0,
              title: Text('Mes Paiements',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 20, fontWeight: FontWeight.w800, color: const Color(0xFF111827))),
              centerTitle: false,
              actions: [
                BlocBuilder<PaiementBloc, PaiementState>(
                  builder: (ctx, state) {
                    if (state is PaiementInitiating) {
                      return const Padding(
                        padding: EdgeInsets.only(right: 16),
                        child: Center(child: SizedBox(
                          width: 20, height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: AppColor.kPrimary),
                        )),
                      );
                    }
                    return IconButton(
                      icon: const Icon(Icons.refresh_rounded, color: Color(0xFF6B7280)),
                      onPressed: () => context.read<PaiementBloc>().add(RefreshPaiements()),
                    );
                  },
                ),
              ],
            ),
            SliverToBoxAdapter(
              child: Container(
                color: Colors.white,
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                child: _SummaryRow(),
              ),
            ),
            BlocBuilder<PaiementBloc, PaiementState>(
              builder: (context, state) {
                if (state is PaiementLoading) {
                  return const SliverFillRemaining(
                    child: Center(child: CircularProgressIndicator(color: AppColor.kPrimary)),
                  );
                }
                if (state is PaiementError) {
                  return SliverFillRemaining(
                    child: _ErrorView(message: state.message, onRetry: () {
                      context.read<PaiementBloc>().add(LoadMesPaiements());
                    }),
                  );
                }
                if (state is PaiementLoaded) {
                  if (state.paiements.isEmpty) {
                    return const SliverFillRemaining(child: _EmptyView());
                  }
                  return SliverPadding(
                    padding: const EdgeInsets.all(16),
                    sliver: SliverList.separated(
                      itemCount: state.paiements.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (_, i) => _PaiementCard(
                        paiement: state.paiements[i],
                        onPayer: () => _afficherChoixPaiement(state.paiements[i]),
                      ),
                    ),
                  );
                }
                return const SliverToBoxAdapter(child: SizedBox.shrink());
              },
            ),
          ],
        ),
      ),
    );
  }
}

// ── Summary row dans le SliverAppBar ──────────────────────────────────────────

class _SummaryRow extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PaiementBloc, PaiementState>(
      builder: (_, state) {
        if (state is! PaiementLoaded) return const SizedBox.shrink();
        final total   = state.paiements.length;
        final payes   = state.paiements.where((p) => p.estPaye).length;
        final attente = state.paiements.where((p) => p.estEnAttente || p.estEchoue).length;
        return Row(children: [
          _MiniStat(label: 'Total', value: '$total', color: const Color(0xFF6366F1)),
          const SizedBox(width: 10),
          _MiniStat(label: 'Payés', value: '$payes', color: const Color(0xFF22C55E)),
          const SizedBox(width: 10),
          _MiniStat(label: 'En attente', value: '$attente', color: AppColor.kPrimary),
        ]);
      },
    );
  }
}

class _MiniStat extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _MiniStat({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(child: Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(children: [
        Text(value, style: GoogleFonts.plusJakartaSans(
          fontSize: 18, fontWeight: FontWeight.w800, color: color)),
        const SizedBox(height: 2),
        Text(label, style: GoogleFonts.plusJakartaSans(
          fontSize: 10, color: color.withValues(alpha: 0.7), fontWeight: FontWeight.w600)),
      ]),
    ));
  }
}

// ── Card paiement ─────────────────────────────────────────────────────────────

class _PaiementCard extends StatelessWidget {
  final Paiement paiement;
  final VoidCallback onPayer;
  const _PaiementCard({required this.paiement, required this.onPayer});

  String get _moyenLabel => switch (paiement.moyenPaiement) {
    'wave'         => '🔵 Wave',
    'orange_money' => '🟠 Orange Money',
    _              => '',
  };

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(
          color: Colors.black.withValues(alpha: 0.05),
          blurRadius: 12, offset: const Offset(0, 2),
        )],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(child: Text(paiement.reference,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 14, fontWeight: FontWeight.w700, color: const Color(0xFF111827)))),
          _StatutBadge(statut: paiement.statut),
        ]),
        const SizedBox(height: 10),
        Row(children: [
          _InfoChip(icon: Icons.location_on_rounded, text: paiement.destination),
          const SizedBox(width: 8),
          _InfoChip(icon: Icons.scale_rounded,
            text: '${paiement.poids.toStringAsFixed(1)} kg'),
        ]),
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 12),
          child: Divider(height: 1, color: Color(0xFFF3F4F6)),
        ),
        Row(children: [
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Montant', style: GoogleFonts.plusJakartaSans(
              fontSize: 11, color: const Color(0xFF9CA3AF), fontWeight: FontWeight.w500)),
            const SizedBox(height: 2),
            Text('${paiement.prixTotal.toStringAsFixed(2)} €',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 16, fontWeight: FontWeight.w800, color: const Color(0xFF111827))),
          ]),
          if (paiement.estPaye) ...[
            const SizedBox(width: 16),
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Payé', style: GoogleFonts.plusJakartaSans(
                fontSize: 11, color: const Color(0xFF9CA3AF), fontWeight: FontWeight.w500)),
              const SizedBox(height: 2),
              Text('${paiement.montantPaye.toStringAsFixed(2)} €',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 16, fontWeight: FontWeight.w700, color: const Color(0xFF22C55E))),
              if (_moyenLabel.isNotEmpty) ...[
                const SizedBox(height: 2),
                Text(_moyenLabel, style: GoogleFonts.plusJakartaSans(
                  fontSize: 11, color: const Color(0xFF6B7280), fontWeight: FontWeight.w500)),
              ],
            ]),
          ],
          const Spacer(),
          // ── Bouton contextuel ──────────────────────────────────────
          if (paiement.estPaye)
            FactureButton(
              paiementId: paiement.id,
              reference:  paiement.reference,
            )
          else if (paiement.peutPayer)
            ElevatedButton(
              onPressed: onPayer,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColor.kPrimary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
              child: Text('Payer', style: GoogleFonts.plusJakartaSans(
                fontSize: 13, fontWeight: FontWeight.w800)),
            ),
        ]),
      ]),
    );
  }
}

class _StatutBadge extends StatelessWidget {
  final String statut;
  const _StatutBadge({required this.statut});

  (Color, Color, String) get _config => switch (statut) {
    'paye'       => (const Color(0xFF22C55E), const Color(0xFFF0FDF4), 'Payé ✓'),
    'en_cours'   => (const Color(0xFF3B82F6), const Color(0xFFEFF6FF), 'En cours'),
    'echoue'     => (const Color(0xFFEF4444), const Color(0xFFFEF2F2), 'Échoué'),
    'rembourse'  => (const Color(0xFF8B5CF6), const Color(0xFFF5F3FF), 'Remboursé'),
    _            => (AppColor.kPrimary,       const Color(0xFFFFF7ED), 'En attente'),
  };

  @override
  Widget build(BuildContext context) {
    final (fg, bg, label) = _config;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg, borderRadius: BorderRadius.circular(20),
      ),
      child: Text(label, style: GoogleFonts.plusJakartaSans(
        fontSize: 11, fontWeight: FontWeight.w700, color: fg)),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String text;
  const _InfoChip({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(mainAxisSize: MainAxisSize.min, children: [
      Icon(icon, size: 13, color: const Color(0xFF9CA3AF)),
      const SizedBox(width: 4),
      Text(text, style: GoogleFonts.plusJakartaSans(
        fontSize: 12, color: const Color(0xFF6B7280), fontWeight: FontWeight.w500)),
    ]);
  }
}

// ── États vides / erreur ──────────────────────────────────────────────────────

class _EmptyView extends StatelessWidget {
  const _EmptyView();
  @override
  Widget build(BuildContext context) {
    return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      Container(padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppColor.kPrimary.withValues(alpha: 0.1),
          shape: BoxShape.circle,
        ),
        child: const Icon(Icons.receipt_long_rounded, size: 48, color: AppColor.kPrimary)),
      const SizedBox(height: 16),
      Text('Aucun paiement', style: GoogleFonts.plusJakartaSans(
        fontSize: 18, fontWeight: FontWeight.w700, color: const Color(0xFF111827))),
      const SizedBox(height: 6),
      Text('Vos paiements apparaîtront ici\naprès votre premier envoi.',
        textAlign: TextAlign.center,
        style: GoogleFonts.plusJakartaSans(fontSize: 13, color: const Color(0xFF9CA3AF))),
    ]));
  }
}

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      const Icon(Icons.wifi_off_rounded, size: 48, color: Color(0xFFD1D5DB)),
      const SizedBox(height: 16),
      Text(message, style: GoogleFonts.plusJakartaSans(
        fontSize: 15, color: const Color(0xFF6B7280))),
      const SizedBox(height: 16),
      ElevatedButton(
        onPressed: onRetry,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColor.kPrimary, foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
        child: const Text('Réessayer'),
      ),
    ]));
  }
}
