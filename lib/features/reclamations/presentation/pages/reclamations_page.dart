import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:nanei/core/theme/app_color.dart';
import '../../domain/entities/reclamation_entity.dart';
import '../cubit/reclamations_cubit.dart';
import '../cubit/reclamations_state.dart';
import 'nouvelle_reclamation_page.dart';

class ReclamationsPage extends StatefulWidget {
  const ReclamationsPage({super.key});

  @override
  State<ReclamationsPage> createState() => _ReclamationsPageState();
}

class _ReclamationsPageState extends State<ReclamationsPage> {
  @override
  void initState() {
    super.initState();
    context.read<ReclamationsCubit>().loadReclamations();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FA),
      appBar: AppBar(
        title: Text('Mes réclamations',
            style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColor.kPrimary,
        onPressed: _ouvrirNouvelle,
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: Text('Nouvelle réclamation',
            style: GoogleFonts.plusJakartaSans(
                fontWeight: FontWeight.w700, color: Colors.white)),
      ),
      body: BlocConsumer<ReclamationsCubit, ReclamationsState>(
        listener: (context, state) {
          if (state is ReclamationEnvoyee) {
            context.read<ReclamationsCubit>().loadReclamations();
          }
        },
        builder: (context, state) {
          if (state is ReclamationsLoading || state is ReclamationEnvoi) {
            return const Center(
                child: CircularProgressIndicator(color: Color(0xFFFF7A00)));
          }
          if (state is ReclamationsError) {
            return _buildError(state.message);
          }
          if (state is ReclamationsLoaded) {
            if (state.reclamations.isEmpty) return _buildEmpty();
            return RefreshIndicator(
              onRefresh: () =>
                  context.read<ReclamationsCubit>().loadReclamations(),
              color: AppColor.kPrimary,
              child: ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
                itemCount: state.reclamations.length,
                itemBuilder: (_, i) =>
                    _buildCard(state.reclamations[i]),
              ),
            );
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _buildCard(ReclamationEntity r) {
    final info = _statutInfo(r.statut);
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 12,
            offset: const Offset(0, 3),
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
                Expanded(
                  child: Text(
                    _typeLabel(r.type),
                    style: GoogleFonts.plusJakartaSans(
                        fontWeight: FontWeight.w700, fontSize: 14),
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: info.bg,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    info.label,
                    style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: info.color),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              r.description,
              style: GoogleFonts.plusJakartaSans(
                  fontSize: 12, color: AppColor.kGrayscale40),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 8),
            Text(
              DateFormat('dd/MM/yyyy HH:mm').format(r.createdAt),
              style: GoogleFonts.plusJakartaSans(
                  fontSize: 11, color: AppColor.kGrayscale20),
            ),
          ],
        ),
      ),
    );
  }

  _StatutInfo _statutInfo(String statut) {
    switch (statut.toLowerCase()) {
      case 'resolu':
      case 'résolu':
        return _StatutInfo('Résolu', const Color(0xFF059669), const Color(0xFFD1FAE5));
      case 'en_cours':
        return _StatutInfo('En cours', const Color(0xFF2563EB), const Color(0xFFDBEAFE));
      default:
        return _StatutInfo('En attente', const Color(0xFFB45309), const Color(0xFFFEF3C7));
    }
  }

  String _typeLabel(String type) {
    switch (type) {
      case 'perdu':
        return 'Colis perdu';
      case 'endommage':
      case 'endommagé':
        return 'Colis endommagé';
      case 'retard':
        return 'Retard de livraison';
      default:
        return 'Autre problème';
    }
  }

  Widget _buildEmpty() => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.report_problem_rounded, size: 60, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            Text('Aucune réclamation',
                style: GoogleFonts.plusJakartaSans(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppColor.kGrayscale40)),
          ],
        ),
      );

  Widget _buildError(String msg) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.wifi_off_rounded, size: 56, color: Colors.grey.shade300),
            const SizedBox(height: 12),
            Text(msg,
                style:
                    GoogleFonts.plusJakartaSans(color: AppColor.kGrayscale40)),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () =>
                  context.read<ReclamationsCubit>().loadReclamations(),
              child: const Text('Réessayer'),
            ),
          ],
        ),
      );

  Future<void> _ouvrirNouvelle({String? colisId}) async {
    await Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => BlocProvider.value(
        value: context.read<ReclamationsCubit>(),
        child: NouvelleReclamationPage(colisIdPreRempli: colisId),
      ),
    ));
  }
}

class _StatutInfo {
  final String label;
  final Color color;
  final Color bg;
  const _StatutInfo(this.label, this.color, this.bg);
}
