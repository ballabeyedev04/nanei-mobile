import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:nanei/core/theme/app_color.dart';
import 'package:nanei/injection_container.dart';
import '../../../domain/entities/suivi_public.dart';
import '../../../domain/usecases/suivi_public_par_reference.dart';

/// Feuille de suivi public d'un colis par référence
/// (`GET /suivi/:reference?format=json`). Aucune authentification requise —
/// utilisable même par un destinataire sans compte.
Future<void> showSuiviPublicSheet(BuildContext context, {String? reference}) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _SuiviPublicSheet(referenceInitiale: reference),
  );
}

class _SuiviPublicSheet extends StatefulWidget {
  final String? referenceInitiale;
  const _SuiviPublicSheet({this.referenceInitiale});

  @override
  State<_SuiviPublicSheet> createState() => _SuiviPublicSheetState();
}

class _SuiviPublicSheetState extends State<_SuiviPublicSheet> {
  late final TextEditingController _refCtrl;
  bool _loading = false;
  String? _erreur;
  SuiviPublic? _resultat;

  @override
  void initState() {
    super.initState();
    _refCtrl = TextEditingController(text: widget.referenceInitiale ?? '');
    if ((widget.referenceInitiale ?? '').trim().isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _rechercher());
    }
  }

  @override
  void dispose() {
    _refCtrl.dispose();
    super.dispose();
  }

  Future<void> _rechercher() async {
    final ref = _refCtrl.text.trim();
    if (ref.isEmpty) {
      setState(() => _erreur = 'Saisissez une référence de colis.');
      return;
    }
    setState(() {
      _loading = true;
      _erreur = null;
      _resultat = null;
    });
    try {
      final r = await sl<SuiviPublicParReference>()(ref);
      setState(() {
        _resultat = r;
        _loading = false;
      });
    } catch (e) {
      String msg = 'Colis introuvable.';
      if (e is DioException) {
        final data = e.response?.data;
        if (data is Map && data['message'] is String) {
          msg = data['message'] as String;
        }
      }
      setState(() {
        _erreur = msg;
        _loading = false;
      });
    }
  }

  String _statutLabel(String s) {
    switch (s) {
      case 'en_attente':
        return 'En attente';
      case 'recupere':
      case 'récupéré':
        return 'Récupéré';
      case 'livre':
      case 'livré':
        return 'Livré';
      default:
        return s;
    }
  }

  Color _statutColor(String s) {
    switch (s) {
      case 'livre':
      case 'livré':
        return const Color(0xFF22C55E);
      case 'recupere':
      case 'récupéré':
        return const Color(0xFF3B82F6);
      default:
        return const Color(0xFFF59E0B);
    }
  }

  String _fmtDate(DateTime? d) =>
      d == null ? '—' : DateFormat('dd/MM/yyyy • HH:mm').format(d.toLocal());

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.85,
        ),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE5E7EB),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Suivre un colis',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: AppColor.kGrayscaleDark100,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Entrez la référence figurant sur l\'étiquette (ex: COL-2026-…).',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    color: AppColor.kGrayscale40,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _refCtrl,
                        textInputAction: TextInputAction.search,
                        onSubmitted: (_) => _rechercher(),
                        style: GoogleFonts.plusJakartaSans(fontSize: 14),
                        decoration: InputDecoration(
                          hintText: 'COL-2026-XXXXXX-XXXX',
                          prefixIcon: const Icon(Icons.qr_code_2_rounded,
                              size: 20, color: AppColor.kGrayscale40),
                          filled: true,
                          fillColor: const Color(0xFFF8FAFC),
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 14),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: const BorderSide(
                                color: AppColor.kLine, width: 1.5),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: const BorderSide(
                                color: AppColor.kPrimary, width: 2),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    SizedBox(
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _loading ? null : _rechercher,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColor.kPrimary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: _loading
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2, color: Colors.white),
                              )
                            : const Icon(Icons.search_rounded,
                                color: Colors.white),
                      ),
                    ),
                  ],
                ),
                if (_erreur != null) ...[
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF2F2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      _erreur!,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12.5,
                        color: const Color(0xFFB91C1C),
                      ),
                    ),
                  ),
                ],
                if (_resultat != null) ...[
                  const SizedBox(height: 20),
                  _buildResultat(_resultat!),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildResultat(SuiviPublic s) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              '#${s.reference}',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: AppColor.kGrayscaleDark100,
              ),
            ),
            const Spacer(),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: _statutColor(s.statut).withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                _statutLabel(s.statut),
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w800,
                  color: _statutColor(s.statut),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _ligne(Icons.flag_outlined, 'Destination', s.destination),
        _ligne(Icons.scale_outlined, 'Poids', '${s.poids.toStringAsFixed(1)} kg'),
        if (s.typeColis.isNotEmpty)
          _ligne(Icons.category_outlined, 'Type', s.typeColis),
        _ligne(Icons.event_outlined, 'Créé le', _fmtDate(s.createdAt)),
        if ((s.expediteurNom ?? '').isNotEmpty)
          _ligne(Icons.north_east_rounded, 'Expéditeur',
              '${s.expediteurPrenom ?? ''} ${s.expediteurNom ?? ''}'.trim()),
        if ((s.recepteurNom ?? '').isNotEmpty)
          _ligne(Icons.south_west_rounded, 'Destinataire',
              '${s.recepteurPrenom ?? ''} ${s.recepteurNom ?? ''}'.trim()),
        if (s.historique.isNotEmpty) ...[
          const SizedBox(height: 18),
          Text(
            'Historique',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: AppColor.kGrayscaleDark100,
            ),
          ),
          const SizedBox(height: 10),
          ...s.historique.map(_evenement),
        ],
      ],
    );
  }

  Widget _ligne(IconData icon, String label, String valeur) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Icon(icon, size: 16, color: AppColor.kGrayscale40),
          const SizedBox(width: 10),
          Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              color: AppColor.kGrayscale40,
            ),
          ),
          const Spacer(),
          Flexible(
            child: Text(
              valeur.isEmpty ? '—' : valeur,
              textAlign: TextAlign.right,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                color: AppColor.kGrayscaleDark100,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _evenement(SuiviEvenement e) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                '${_statutLabel(e.ancienStatut ?? '—')} → ${_statutLabel(e.nouveauStatut)}',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  color: AppColor.kGrayscaleDark100,
                ),
              ),
              const Spacer(),
              Text(
                _fmtDate(e.date),
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 10.5,
                  color: AppColor.kGrayscale40,
                ),
              ),
            ],
          ),
          if ((e.commentaire ?? '').isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              e.commentaire!,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                color: AppColor.kGrayscale60,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
