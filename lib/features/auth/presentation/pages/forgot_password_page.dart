import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/config/env.dart';
import '../../../../core/routes/app_router.dart';
import '../../../../core/theme/app_color.dart';
import '../../../../injection_container.dart';

class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final _emailCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _emailCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _loading = true; _error = null; });

    try {
      final dio = sl<Dio>();
      await dio.post(
        '${Env.baseUrl}/auth/oublier-password',
        data: {'email': _emailCtrl.text.trim()},
      );
      if (!mounted) return;
      // Naviguer vers la page reset avec l'email pour l'identifier
      Navigator.of(context).pushNamed(
        AppRouter.resetPasswordRoute,
        arguments: _emailCtrl.text.trim(),
      );
    } on DioException catch (e) {
      final msg = e.response?.data?['message'] as String? ??
          'Une erreur est survenue. Vérifiez votre connexion.';
      if (mounted) setState(() { _error = msg; _loading = false; });
    } catch (_) {
      if (mounted) setState(() { _error = 'Une erreur inattendue est survenue.'; _loading = false; });
    }
  }

  InputDecoration _inputDeco({required String hint, required IconData icon}) =>
      InputDecoration(
        hintText: hint,
        hintStyle: GoogleFonts.plusJakartaSans(color: Colors.grey[400], fontSize: 14),
        prefixIcon: Icon(icon, color: Colors.grey, size: 20),
        filled: true,
        fillColor: const Color(0xFFF7F7F7),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColor.kPrimary, width: 1.5)),
        errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.red, width: 1.5)),
        focusedErrorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.red, width: 1.5)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.black87, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 16),
                Container(
                  width: 64, height: 64,
                  decoration: BoxDecoration(
                    color: AppColor.kPrimary.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.lock_reset_rounded, color: AppColor.kPrimary, size: 32),
                ),
                const SizedBox(height: 24),
                Text('Mot de passe oublié ?',
                  style: GoogleFonts.plusJakartaSans(fontSize: 24, fontWeight: FontWeight.w700, color: Colors.black87)),
                const SizedBox(height: 8),
                Text('Entrez votre adresse email. Vous recevrez un code à 6 chiffres pour réinitialiser votre mot de passe.',
                  style: GoogleFonts.plusJakartaSans(fontSize: 14, color: Colors.grey[600], height: 1.5)),
                const SizedBox(height: 32),
                Text('Adresse email',
                  style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.black87)),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _emailCtrl,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.done,
                  onFieldSubmitted: (_) => _submit(),
                  decoration: _inputDeco(hint: 'exemple@email.com', icon: Icons.email_outlined),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'L\'email est requis';
                    if (!RegExp(r'^[\w\.-]+@[\w\.-]+\.\w{2,}$').hasMatch(v.trim())) return 'Email invalide';
                    return null;
                  },
                ),
                if (_error != null) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.red.shade200),
                    ),
                    child: Row(children: [
                      Icon(Icons.error_outline, color: Colors.red.shade400, size: 18),
                      const SizedBox(width: 8),
                      Expanded(child: Text(_error!,
                        style: GoogleFonts.plusJakartaSans(fontSize: 13, color: Colors.red.shade700))),
                    ]),
                  ),
                ],
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity, height: 52,
                  child: ElevatedButton(
                    onPressed: _loading ? null : _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColor.kPrimary,
                      disabledBackgroundColor: AppColor.kPrimary.withOpacity(0.6),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                    ),
                    child: _loading
                        ? const SizedBox(width: 22, height: 22,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : Text('Envoyer le code',
                            style: GoogleFonts.plusJakartaSans(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.white)),
                  ),
                ),
                const SizedBox(height: 24),
                Center(
                  child: TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text('Retour à la connexion',
                      style: GoogleFonts.plusJakartaSans(fontSize: 13, color: Colors.grey[600], fontWeight: FontWeight.w500)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
