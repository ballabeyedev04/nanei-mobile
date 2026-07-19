import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:nanei/core/config/env.dart';
import 'package:nanei/core/theme/app_color.dart';
import 'package:nanei/features/avis/presentation/cubit/avis_cubit.dart';
import 'package:nanei/features/avis/presentation/widgets/rating_dialog.dart';
import 'package:nanei/features/avis/presentation/widgets/star_rating.dart';
import 'package:nanei/features/colis/presentation/widgets/share_tracking_widget.dart';
import 'package:nanei/features/reclamations/presentation/cubit/reclamations_cubit.dart';
import 'package:nanei/features/reclamations/presentation/pages/nouvelle_reclamation_page.dart';
import 'package:nanei/injection_container.dart';
import 'package:dio/dio.dart';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
import '../../../domain/entities/colis.dart';
import '../../../domain/entities/personne.dart';

class ColisDetailPage extends StatefulWidget {
  final Colis colis;
  final bool isReception;

  const ColisDetailPage({
    super.key,
    required this.colis,
    required this.isReception,
  });

  @override
  State<ColisDetailPage> createState() => _ColisDetailPageState();
}

class _ColisDetailPageState extends State<ColisDetailPage> {
  String? _preuveUrl;
  bool _loadingPreuve = true;
  bool _aDejaUnAvis = false;
  bool _loadingEtiquette = false;

  Colis get colis => widget.colis;
  bool get isLivre =>
      colis.statut.toLowerCase() == 'livré' ||
      colis.statut.toLowerCase() == 'livrée';

  @override
  void initState() {
    super.initState();
    if (isLivre) {
      _chargerPreuve();
    } else {
      setState(() => _loadingPreuve = false);
    }
  }

  Future<void> _telechargerEtiquette() async {
    setState(() => _loadingEtiquette = true);
    try {
      final response = await sl<Dio>().get(
        Env.etiquetteColis(colis.id),
        options: Options(responseType: ResponseType.bytes),
      );
      final dir = await getTemporaryDirectory();
      // Nom de fichier basé sur la référence colis (lisible), pas l'UUID
      // interne — c'est ce nom qui s'affiche dans le lecteur PDF du téléphone.
      final file = File('${dir.path}/Etiquette-${colis.reference}.pdf');
      await file.writeAsBytes(response.data as List<int>);
      await OpenFile.open(file.path);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Impossible de télécharger l\'étiquette.',
              style: GoogleFonts.plusJakartaSans(fontSize: 13),
            ),
            backgroundColor: const Color(0xFFEF4444),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _loadingEtiquette = false);
    }
  }

  Future<void> _chargerPreuve() async {
    try {
      final res =
          await sl<Dio>().get(Env.preuveLivraison(colis.id));
      final data = res.data['data'];
      setState(() {
        _preuveUrl = data?['photoUrl']?.toString() ??
            data?['url']?.toString();
        _loadingPreuve = false;
      });
    } catch (_) {
      setState(() => _loadingPreuve = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final status = _statusOf(colis.statut);
    final Personne? personne =
        widget.isReception ? colis.expediteur : colis.recepteur;
    final personneLabel =
        widget.isReception ? 'Expéditeur' : 'Destinataire';

    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => sl<AvisCubit>()),
        BlocProvider(create: (_) => sl<ReclamationsCubit>()),
      ],
      child: Scaffold(
        backgroundColor: const Color(0xFFF4F6FA),
        appBar: AppBar(
          title: Text(
            '#${colis.reference}',
            style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700),
          ),
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          elevation: 0,
          actions: [
            ShareTrackingWidget(reference: colis.reference),
          ],
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Statut
              _buildStatutCard(status),
              const SizedBox(height: 16),
              // Infos colis
              _buildInfoCard(personne, personneLabel),

              // Preuve de livraison (si livré)
              if (isLivre) ...[
                const SizedBox(height: 16),
                _buildPreuveLivraison(),
              ],

              // Banner avis (si livré et pas encore noté)
              if (isLivre && !_aDejaUnAvis) ...[
                const SizedBox(height: 16),
                _buildAvisBanner(),
              ],

              const SizedBox(height: 16),
              // Bouton signaler un problème
              _buildSignalerBtn(),

              // Bouton étiquette (expéditeur uniquement)
              if (!widget.isReception) ...[
                const SizedBox(height: 12),
                _buildEtiquetteBtn(),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatutCard(_StatusInfo status) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: status.bg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: status.color.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: status.color,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  status.label,
                  style: GoogleFonts.plusJakartaSans(
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                      color: Colors.white),
                ),
              ),
              const Spacer(),
              Icon(Icons.local_shipping_rounded,
                  color: status.color, size: 22),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Destination : ${colis.destination}',
            style: GoogleFonts.plusJakartaSans(
                fontWeight: FontWeight.w700,
                fontSize: 15,
                color: AppColor.kGrayscaleDark100),
          ),
          const SizedBox(height: 4),
          Text(
            '${colis.poids} kg · ${colis.prix.toStringAsFixed(0)} FCFA · ${colis.type}',
            style: GoogleFonts.plusJakartaSans(
                fontSize: 13, color: AppColor.kGrayscale40),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard(Personne? personne, String label) {
    return Container(
      padding: const EdgeInsets.all(20),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Informations',
              style: GoogleFonts.plusJakartaSans(
                  fontWeight: FontWeight.w700, fontSize: 14)),
          const SizedBox(height: 16),
          _infoRow(Icons.person_rounded, label,
              personne?.nomComplet ?? 'Inconnu'),
          if (personne?.email.isNotEmpty == true)
            _infoRow(Icons.mail_rounded, 'Email', personne!.email),
          _infoRow(Icons.calendar_today_rounded, 'Date',
              '${colis.createdAt.day}/${colis.createdAt.month}/${colis.createdAt.year}'),
          if (colis.description != null && colis.description!.isNotEmpty)
            _infoRow(Icons.notes_rounded, 'Description', colis.description!),
        ],
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppColor.kPrimary),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: GoogleFonts.plusJakartaSans(
                        fontSize: 11, color: AppColor.kGrayscale40)),
                Text(value,
                    style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColor.kGrayscaleDark100)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPreuveLivraison() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Preuve de livraison',
              style: GoogleFonts.plusJakartaSans(
                  fontWeight: FontWeight.w700, fontSize: 14)),
          const SizedBox(height: 16),
          if (_loadingPreuve)
            const Center(child: CircularProgressIndicator())
          else if (_preuveUrl != null)
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                _preuveUrl!,
                width: double.infinity,
                height: 200,
                fit: BoxFit.cover,
                loadingBuilder: (_, child, progress) =>
                    progress == null
                        ? child
                        : const Center(
                            child: CircularProgressIndicator()),
                errorBuilder: (_, __, ___) => _preuveIndisponible(),
              ),
            )
          else
            _preuveIndisponible(),
        ],
      ),
    );
  }

  Widget _preuveIndisponible() {
    return Row(
      children: [
        const Icon(Icons.image_not_supported_rounded,
            color: Color(0xFFD1D5DB), size: 28),
        const SizedBox(width: 10),
        Text('Preuve non disponible',
            style: GoogleFonts.plusJakartaSans(
                fontSize: 13, color: AppColor.kGrayscale40)),
      ],
    );
  }

  Widget _buildAvisBanner() {
    return Builder(
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppColor.kPrimary.withValues(alpha: 0.1),
                AppColor.kPrimary.withValues(alpha: 0.05),
              ],
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
                color: AppColor.kPrimary.withValues(alpha: 0.3)),
          ),
          child: Row(
            children: [
              StarRating(note: 0, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Vous avez reçu votre colis ? Donnez votre avis',
                  style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColor.kGrayscaleDark100),
                ),
              ),
              TextButton(
                onPressed: () async {
                  await showRatingDialog(
                    context,
                    colis.id,
                    context.read<AvisCubit>(),
                  );
                  setState(() => _aDejaUnAvis = true);
                },
                child: Text('Noter',
                    style: GoogleFonts.plusJakartaSans(
                        fontWeight: FontWeight.w700,
                        color: AppColor.kPrimary)),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSignalerBtn() {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: () => Navigator.of(context).push(MaterialPageRoute(
          builder: (_) => BlocProvider(
            create: (_) => sl<ReclamationsCubit>(),
            child: NouvelleReclamationPage(colisIdPreRempli: colis.id),
          ),
        )),
        icon: const Icon(Icons.report_problem_rounded, size: 18),
        label: Text('Signaler un problème',
            style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700)),
        style: OutlinedButton.styleFrom(
          foregroundColor: const Color(0xFFEF4444),
          side: const BorderSide(color: Color(0xFFEF4444)),
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14)),
        ),
      ),
    );
  }

  Widget _buildEtiquetteBtn() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: _loadingEtiquette ? null : _telechargerEtiquette,
        icon: _loadingEtiquette
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : const Icon(Icons.qr_code_rounded, size: 18),
        label: Text(
          _loadingEtiquette ? 'Chargement...' : 'Étiquette',
          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColor.kPrimary,
          foregroundColor: Colors.white,
          disabledBackgroundColor: AppColor.kPrimary.withValues(alpha: 0.6),
          disabledForegroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14)),
          elevation: 0,
        ),
      ),
    );
  }
}

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
