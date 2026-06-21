import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/config/env.dart';
import '../../../../core/routes/app_router.dart';
import '../../../../core/theme/app_color.dart';
import '../../../../injection_container.dart';

class ResetPasswordPage extends StatefulWidget {
  final String email;

  const ResetPasswordPage({super.key, required this.email});

  @override
  State<ResetPasswordPage> createState() => _ResetPasswordPageState();
}

class _ResetPasswordPageState extends State<ResetPasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final _codeCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _codeCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _loading = true; _error = null; });

    try {
      final dio = sl<Dio>();
      await dio.post(
        '${Env.baseUrl}/auth/reset-password',
        data: {
          'email': widget.email,
          'code': _codeCtrl.text.trim(),
          'mot_de_passe': _passwordCtrl.text,
        },
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Mot de passe modifié avec succès !',
            style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600)),
          backgroundColor: Colors.green.shade600,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      Navigator.of(context).pushNamedAndRemoveUntil(AppRouter.loginRoute, (_) => false);
    } on DioException catch (e) {
      final msg = e.response?.data?['message'] as String? ?? 'Une erreur est survenue.';
      if (mounted) setState(() { _error = msg; _loading = false; });
    } catch (_) {
      if (mounted) setState(() { _error = 'Une erreur inattendue est survenue.'; _loading = false; });
    }
  }

  InputDecoration _inputDeco({
    required String hint,
    required IconData icon,
    Widget? suffix,
  }) =>
      InputDecoration(
        hintText: hint,
        hintStyle: GoogleFonts.plusJakartaSans(color: Colors.grey[400], fontSize: 14),
        prefixIcon: Icon(icon, color: Colors.grey, size: 20),
        suffixIcon: suffix,
        filled: true,
        fillColor: const Color(0xFFF7F7F7),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColor.kPrimary, width: 1.5)),
        errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.red, width: 1.5)),
        focusedErrorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.red, width: 1.5)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      );

  Widget _label(String text) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Text(text, style: GoogleFonts.plusJakartaSans(
      fontSize: 13, fontWeight: FontWeight.w600, color: Colors.black87)),
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
                  child: const Icon(Icons.verified_outlined, color: AppColor.kPrimary, size: 32),
                ),
                const SizedBox(height: 24),
                Text('Réinitialiser le mot de passe',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 22, fontWeight: FontWeight.w700, color: Colors.black87)),
                const SizedBox(height: 8),
                RichText(text: TextSpan(
                  style: GoogleFonts.plusJakartaSans(fontSize: 14, color: Colors.grey[600], height: 1.5),
                  children: [
                    const TextSpan(text: 'Saisissez le code à 6 chiffres envoyé à '),
                    TextSpan(text: widget.email,
                      style: const TextStyle(fontWeight: FontWeight.w700, color: Colors.black87)),
                  ],
                )),
                const SizedBox(height: 32),

                // ── Code OTP ──────────────────────────────────────────────
                _label('Code reçu par email'),
                TextFormField(
                  controller: _codeCtrl,
                  keyboardType: TextInputType.number,
                  textInputAction: TextInputAction.next,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(6),
                  ],
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 20, letterSpacing: 8, fontWeight: FontWeight.w700),
                  textAlign: TextAlign.center,
                  decoration: InputDecoration(
                    hintText: '• • • • • •',
                    hintStyle: GoogleFonts.plusJakartaSans(
                      color: Colors.grey[300], fontSize: 18, letterSpacing: 8),
                    filled: true,
                    fillColor: const Color(0xFFF7F7F7),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColor.kPrimary, width: 1.5)),
                    errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.red, width: 1.5)),
                    focusedErrorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.red, width: 1.5)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
                  ),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Le code est requis';
                    if (v.trim().length != 6) return 'Le code doit contenir 6 chiffres';
                    return null;
                  },
                ),
                const SizedBox(height: 20),

                // ── Nouveau mot de passe ──────────────────────────────────
                _label('Nouveau mot de passe'),
                TextFormField(
                  controller: _passwordCtrl,
                  obscureText: _obscurePassword,
                  textInputAction: TextInputAction.next,
                  decoration: _inputDeco(
                    hint: 'Minimum 6 caractères',
                    icon: Icons.lock_outline,
                    suffix: IconButton(
                      icon: Icon(
                        _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                        color: Colors.grey, size: 20),
                      onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                    ),
                  ),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Le mot de passe est requis';
                    if (v.length < 6) return 'Minimum 6 caractères';
                    return null;
                  },
                ),
                const SizedBox(height: 20),

                // ── Confirmer mot de passe ────────────────────────────────
                _label('Confirmer le mot de passe'),
                TextFormField(
                  controller: _confirmCtrl,
                  obscureText: _obscureConfirm,
                  textInputAction: TextInputAction.done,
                  onFieldSubmitted: (_) => _submit(),
                  decoration: _inputDeco(
                    hint: 'Répétez le mot de passe',
                    icon: Icons.lock_outline,
                    suffix: IconButton(
                      icon: Icon(
                        _obscureConfirm ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                        color: Colors.grey, size: 20),
                      onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm),
                    ),
                  ),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Confirmez votre mot de passe';
                    if (v != _passwordCtrl.text) return 'Les mots de passe ne correspondent pas';
                    return null;
                  },
                ),

                if (_error != null) ...[
                  const SizedBox(height: 16),
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
                        : Text('Changer le mot de passe',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 15, fontWeight: FontWeight.w600, color: Colors.white)),
                  ),
                ),
                const SizedBox(height: 16),
                Center(
                  child: TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text('Renvoyer le code',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13, color: AppColor.kPrimary, fontWeight: FontWeight.w600)),
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
