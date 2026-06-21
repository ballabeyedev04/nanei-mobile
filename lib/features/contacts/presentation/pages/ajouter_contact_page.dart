import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:nanei/core/theme/app_color.dart';
import '../cubit/contacts_cubit.dart';

class AjouterContactPage extends StatefulWidget {
  const AjouterContactPage({super.key});

  @override
  State<AjouterContactPage> createState() => _AjouterContactPageState();
}

class _AjouterContactPageState extends State<AjouterContactPage> {
  final _formKey = GlobalKey<FormState>();
  final _nomCtrl = TextEditingController();
  final _prenomCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _telCtrl = TextEditingController();
  final _villeCtrl = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _nomCtrl.dispose();
    _prenomCtrl.dispose();
    _emailCtrl.dispose();
    _telCtrl.dispose();
    _villeCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    final data = {
      'nom': _nomCtrl.text.trim(),
      'prenom': _prenomCtrl.text.trim(),
      'email': _emailCtrl.text.trim().isEmpty ? null : _emailCtrl.text.trim(),
      'telephone': _telCtrl.text.trim(),
      'ville': _villeCtrl.text.trim().isEmpty ? null : _villeCtrl.text.trim(),
    };
    final ok = await context.read<ContactsCubit>().ajouterContact(data);
    if (!mounted) return;
    setState(() => _loading = false);
    if (ok) {
      Navigator.of(context).pop(true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Erreur lors de la sauvegarde.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FA),
      appBar: AppBar(
        title: Text(
          'Nouveau contact',
          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildCard(children: [
                _field(_prenomCtrl, 'Prénom *', Icons.person_rounded,
                    required: true),
                const SizedBox(height: 14),
                _field(_nomCtrl, 'Nom *', Icons.person_outline_rounded,
                    required: true),
                const SizedBox(height: 14),
                _field(_telCtrl, 'Téléphone *', Icons.phone_rounded,
                    required: true,
                    keyboard: TextInputType.phone),
                const SizedBox(height: 14),
                _field(_emailCtrl, 'Email', Icons.mail_rounded,
                    keyboard: TextInputType.emailAddress),
                const SizedBox(height: 14),
                _field(_villeCtrl, 'Ville', Icons.location_city_rounded),
              ]),
              const SizedBox(height: 28),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _loading ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColor.kPrimary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                  child: _loading
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                              strokeWidth: 2.5, color: Colors.white),
                        )
                      : Text(
                          'Sauvegarder',
                          style: GoogleFonts.plusJakartaSans(
                              fontWeight: FontWeight.w700, fontSize: 15),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCard({required List<Widget> children}) {
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
      child: Column(children: children),
    );
  }

  Widget _field(
    TextEditingController ctrl,
    String label,
    IconData icon, {
    TextInputType? keyboard,
    bool required = false,
  }) {
    return TextFormField(
      controller: ctrl,
      keyboardType: keyboard,
      validator: required
          ? (v) => v == null || v.trim().isEmpty ? 'Champ requis' : null
          : null,
      style: GoogleFonts.plusJakartaSans(fontSize: 14),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, size: 20, color: AppColor.kGrayscale40),
        labelStyle: GoogleFonts.plusJakartaSans(
            fontSize: 13, color: AppColor.kGrayscale40),
        filled: true,
        fillColor: const Color(0xFFF8FAFC),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Color(0xFFE5E9F2))),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Color(0xFFE5E9F2))),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide:
                const BorderSide(color: Color(0xFFFF7A00), width: 1.5)),
        errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Color(0xFFEF4444))),
      ),
    );
  }
}
