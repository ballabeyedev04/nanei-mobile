import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:nanei/core/theme/app_color.dart';
import 'package:nanei/features/auth/domain/entities/user.dart';
import 'package:nanei/injection_container.dart';
import '../../../domain/usecases/rechercher_colis_par_reference.dart';
import 'colis_detail_page.dart';
import 'suivi_page.dart' show state_isReception;

/// Scanner le QR code d'une étiquette pour ouvrir directement la fiche du
/// colis correspondant, sans avoir à le chercher dans la liste. Le QR code
/// encode l'URL publique de suivi (voir etiquette.template.js côté backend) —
/// on en extrait la référence pour rechercher le colis côté client.
class ScanColisPage extends StatefulWidget {
  final User? user;
  const ScanColisPage({super.key, this.user});

  @override
  State<ScanColisPage> createState() => _ScanColisPageState();
}

class _ScanColisPageState extends State<ScanColisPage> {
  final MobileScannerController _controller = MobileScannerController(
    formats: [BarcodeFormat.qrCode],
  );
  bool _traitementEnCours = false;
  String? _erreur;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// Extrait la référence colis à partir du contenu scanné : soit l'URL
  /// publique de suivi (.../nanei/suivi/COL-...), soit la référence brute
  /// si un autre type de QR/texte a été scanné.
  String? _extraireReference(String raw) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) return null;
    final segments = trimmed.split('/').where((s) => s.isNotEmpty).toList();
    return segments.isNotEmpty ? segments.last : trimmed;
  }

  Future<void> _onDetect(BarcodeCapture capture) async {
    if (_traitementEnCours) return;
    final raw = capture.barcodes.isNotEmpty ? capture.barcodes.first.rawValue : null;
    final reference = raw != null ? _extraireReference(raw) : null;
    if (reference == null || reference.isEmpty) return;

    setState(() {
      _traitementEnCours = true;
      _erreur = null;
    });

    try {
      final colis = await sl<RechercherColisParReference>()(reference);
      if (!mounted) return;
      final reception = state_isReception(colis, widget.user?.id);
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => ColisDetailPage(colis: colis, isReception: reception),
        ),
      );
    } catch (e) {
      String message = "Colis introuvable ou inaccessible.";
      if (e is DioException) {
        final data = e.response?.data;
        if (data is Map && data['message'] is String) {
          message = data['message'] as String;
        }
      }
      if (mounted) {
        setState(() {
          _erreur = message;
          _traitementEnCours = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          MobileScanner(
            controller: _controller,
            onDetect: _onDetect,
          ),

          // Overlay sombre avec fenêtre de visée
          _ScanOverlay(actif: !_traitementEnCours),

          // AppBar transparente
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                children: [
                  _RoundIconButton(
                    icon: Icons.arrow_back_rounded,
                    onTap: () => Navigator.of(context).pop(),
                  ),
                  const Spacer(),
                  ValueListenableBuilder(
                    valueListenable: _controller,
                    builder: (context, state, __) => _RoundIconButton(
                      icon: state.torchState == TorchState.on
                          ? Icons.flash_on_rounded
                          : Icons.flash_off_rounded,
                      onTap: () => _controller.toggleTorch(),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Instructions / état
          Positioned(
            left: 24,
            right: 24,
            bottom: 48,
            child: Column(
              children: [
                if (_traitementEnCours)
                  const Padding(
                    padding: EdgeInsets.only(bottom: 16),
                    child: CircularProgressIndicator(color: Colors.white),
                  ),
                if (_erreur != null)
                  Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEF4444).withValues(alpha: 0.95),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Text(
                      _erreur!,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13, fontWeight: FontWeight.w600, color: Colors.white,
                      ),
                    ),
                  ),
                Text(
                  'Placez le QR code de l\'étiquette dans le cadre',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RoundIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _RoundIconButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.4),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: Colors.white, size: 20),
      ),
    );
  }
}

class _ScanOverlay extends StatelessWidget {
  final bool actif;
  const _ScanOverlay({required this.actif});

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Center(
        child: Container(
          width: 260,
          height: 260,
          decoration: BoxDecoration(
            border: Border.all(
              color: actif ? AppColor.kPrimary : Colors.white54,
              width: 3,
            ),
            borderRadius: BorderRadius.circular(24),
          ),
        ),
      ),
    );
  }
}
