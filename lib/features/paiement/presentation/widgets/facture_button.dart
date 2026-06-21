import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
import 'package:nanei/core/config/env.dart';
import 'package:nanei/core/services/token_service.dart';
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

  Future<void> _ouvrirFacture() async {
    if (_loading) return;
    setState(() => _loading = true);

    try {
      final token = await sl<TokenService>().getToken();
      if (token == null || token.isEmpty) {
        _showError('Session expirée, veuillez vous reconnecter');
        return;
      }

      final dio = Dio(BaseOptions(
        baseUrl: Env.baseUrl,
        receiveTimeout: const Duration(seconds: 60),
        headers: {'Authorization': 'Bearer $token'},
        responseType: ResponseType.bytes,
      ));

      // Télécharger vers un fichier temporaire
      final dir     = await getTemporaryDirectory();
      final path    = '${dir.path}/facture-${widget.reference}.pdf';
      final file    = File(path);

      final resp = await dio.get('/factures/${widget.paiementId}');
      await file.writeAsBytes(resp.data as List<int>, flush: true);

      // Ouvrir le PDF
      final result = await OpenFile.open(path);
      if (result.type != ResultType.done && mounted) {
        _showError('Impossible d\'ouvrir le PDF. Installez un lecteur PDF.');
      }
    } catch (e) {
      _showError('Erreur lors de la récupération de la facture');
    } finally {
      if (mounted) setState(() => _loading = false);
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

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: _loading ? null : _ouvrirFacture,
      icon: _loading
        ? const SizedBox(
            width: 14, height: 14,
            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
          )
        : const Icon(Icons.receipt_long_rounded, size: 15),
      label: Text(
        _loading ? 'Chargement…' : 'Voir Facture',
        style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w800),
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
