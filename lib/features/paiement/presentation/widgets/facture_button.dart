import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
import 'package:nanei/core/config/env.dart';
import 'package:nanei/injection_container.dart';

class FactureButton extends StatefulWidget {
  final String paiementId;
  final String reference;
  const FactureButton({super.key, required this.paiementId, required this.reference});

  @override
  State<FactureButton> createState() => _FactureButtonState();
}

class _FactureButtonState extends State<FactureButton> {
  bool _loading = false;
  bool _downloading = false;

  /// Téléchargement d'un PDF avec le client Dio PARTAGÉ : il ajoute le jeton
  /// et le renouvelle automatiquement (refresh token) s'il a expiré — un
  /// client Dio dédié échouait systématiquement après 1 h.
  Future<List<int>> _telechargerPdf(String path) async {
    final resp = await sl<Dio>().get<List<int>>(
      path,
      options: Options(
        responseType: ResponseType.bytes,
        receiveTimeout: const Duration(seconds: 60),
        headers: {'Accept': 'application/pdf'},
      ),
    );
    return resp.data ?? const <int>[];
  }

  /// Message d'erreur du back : en mode `bytes`, le corps JSON d'erreur
  /// arrive lui aussi en octets — on le décode.
  String _messageErreur(Object e, String fallback) {
    if (e is DioException) {
      final data = e.response?.data;
      if (data is List<int>) {
        try {
          final json = jsonDecode(utf8.decode(data));
          if (json is Map && json['message'] is String) {
            return json['message'] as String;
          }
        } catch (_) {}
      }
      if (e.response?.statusCode == 401) {
        return 'Session expirée, veuillez vous reconnecter';
      }
    }
    return fallback;
  }

  /// Aperçu inline : GET /factures/:id
  Future<void> _ouvrirFacture() async {
    if (_loading || _downloading) return;
    setState(() => _loading = true);
    try {
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/facture-${widget.reference}.pdf');

      final octets = await _telechargerPdf(Env.factureApercu(widget.paiementId));
      await file.writeAsBytes(octets, flush: true);

      final result = await OpenFile.open(file.path);
      if (result.type != ResultType.done && mounted) {
        _showError('Impossible d\'ouvrir le PDF. Installez un lecteur PDF.');
      }
    } catch (e) {
      _showError(_messageErreur(e, 'Erreur lors de la récupération de la facture'));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  /// Téléchargement (force download) : GET /factures/:id/download
  /// Enregistre dans le dossier Documents/Téléchargements de l'app puis ouvre.
  Future<void> _telechargerFacture() async {
    if (_loading || _downloading) return;
    setState(() => _downloading = true);
    try {
      final baseDir = Platform.isAndroid
          ? (await getExternalStorageDirectory() ??
              await getApplicationDocumentsDirectory())
          : await getApplicationDocumentsDirectory();
      final file = File('${baseDir.path}/Facture-${widget.reference}.pdf');

      final octets =
          await _telechargerPdf(Env.factureDownload(widget.paiementId));
      await file.writeAsBytes(octets, flush: true);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Facture enregistrée : ${file.path.split('/').last}'),
        backgroundColor: const Color(0xFF0F9D58),
        behavior: SnackBarBehavior.floating,
      ));
      await OpenFile.open(file.path);
    } catch (e) {
      _showError(_messageErreur(e, 'Erreur lors du téléchargement de la facture'));
    } finally {
      if (mounted) setState(() => _downloading = false);
    }
  }

  void _showError(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: Colors.red.shade600,
      behavior: SnackBarBehavior.floating,
    ));
  }

  Future<void> _ouvrirMenu() async {
    if (_loading || _downloading) return;
    final choix = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFE5E7EB),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.visibility_rounded,
                  color: Color(0xFF0F9D58)),
              title: Text('Aperçu de la facture',
                  style: GoogleFonts.plusJakartaSans(
                      fontWeight: FontWeight.w700, fontSize: 14)),
              onTap: () => Navigator.pop(context, 'apercu'),
            ),
            ListTile(
              leading: const Icon(Icons.download_rounded,
                  color: Color(0xFF0F9D58)),
              title: Text('Télécharger le PDF',
                  style: GoogleFonts.plusJakartaSans(
                      fontWeight: FontWeight.w700, fontSize: 14)),
              onTap: () => Navigator.pop(context, 'download'),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
    if (choix == 'apercu') await _ouvrirFacture();
    if (choix == 'download') await _telechargerFacture();
  }

  @override
  Widget build(BuildContext context) {
    final busy = _loading || _downloading;
    return ElevatedButton.icon(
      onPressed: busy ? null : _ouvrirMenu,
      icon: busy
          ? const SizedBox(
              width: 14,
              height: 14,
              child:
                  CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
            )
          : const Icon(Icons.receipt_long_rounded, size: 15),
      label: Text(
        busy ? 'Chargement…' : 'Facture',
        style:
            GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w800),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF0F9D58),
        foregroundColor: Colors.white,
        disabledBackgroundColor: const Color(0xFF0F9D58).withValues(alpha: 0.7),
        disabledForegroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 0,
      ),
    );
  }
}
