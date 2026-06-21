import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:nanei/core/theme/app_color.dart';
import 'package:nanei/injection_container.dart';
import 'package:dio/dio.dart';
import 'package:nanei/core/config/env.dart';
import '../cubit/reclamations_cubit.dart';
import '../cubit/reclamations_state.dart';

class NouvelleReclamationPage extends StatefulWidget {
  final String? colisIdPreRempli;
  const NouvelleReclamationPage({super.key, this.colisIdPreRempli});

  @override
  State<NouvelleReclamationPage> createState() =>
      _NouvelleReclamationPageState();
}

class _NouvelleReclamationPageState extends State<NouvelleReclamationPage> {
  final _formKey = GlobalKey<FormState>();
  final _descriptionCtrl = TextEditingController();
  String? _colisIdSelectionne;
  String _typeSelectionne = 'perdu';
  final List<XFile> _photos = [];
  List<Map<String, dynamic>> _mesColis = [];
  bool _loadingColis = true;
  final _picker = ImagePicker();

  static const _types = [
    {'value': 'perdu', 'label': 'Colis perdu'},
    {'value': 'endommage', 'label': 'Colis endommagé'},
    {'value': 'retard', 'label': 'Retard de livraison'},
    {'value': 'autre', 'label': 'Autre'},
  ];

  @override
  void initState() {
    super.initState();
    _colisIdSelectionne = widget.colisIdPreRempli;
    _chargerColis();
  }

  Future<void> _chargerColis() async {
    try {
      final res = await sl<Dio>().get(Env.colisEnvoyes);
      final List data = res.data['data'] ?? [];
      setState(() {
        _mesColis = data.cast<Map<String, dynamic>>();
        _loadingColis = false;
      });
    } catch (_) {
      setState(() => _loadingColis = false);
    }
  }

  @override
  void dispose() {
    _descriptionCtrl.dispose();
    super.dispose();
  }

  Future<void> _ajouterPhotos() async {
    if (_photos.length >= 5) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Maximum 5 photos autorisées')),
      );
      return;
    }
    final List<XFile> selected = await _picker.pickMultiImage(
      imageQuality: 70,
    );
    if (selected.isNotEmpty) {
      setState(() {
        final remaining = 5 - _photos.length;
        _photos.addAll(selected.take(remaining));
      });
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_colisIdSelectionne == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez sélectionner un colis')),
      );
      return;
    }
    final ok = await context.read<ReclamationsCubit>().creerReclamation(
          colisId: _colisIdSelectionne!,
          type: _typeSelectionne,
          description: _descriptionCtrl.text.trim(),
          photos: _photos.map((f) => f.path).toList(),
        );
    if (!mounted) return;
    if (ok) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Réclamation envoyée avec succès !')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FA),
      appBar: AppBar(
        title: Text('Nouvelle réclamation',
            style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: BlocListener<ReclamationsCubit, ReclamationsState>(
        listener: (context, state) {
          if (state is ReclamationsError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message)),
            );
          }
        },
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildCard(children: [
                  // Sélecteur colis
                  _label('Colis concerné *'),
                  const SizedBox(height: 8),
                  _loadingColis
                      ? const Center(child: CircularProgressIndicator())
                      : DropdownButtonFormField<String>(
                          value: _colisIdSelectionne,
                          hint: Text('Sélectionnez un colis',
                              style: GoogleFonts.plusJakartaSans(
                                  fontSize: 13,
                                  color: AppColor.kGrayscale40)),
                          items: _mesColis
                              .map((c) => DropdownMenuItem<String>(
                                    value: c['id']?.toString(),
                                    child: Text(
                                      '#${c['reference'] ?? c['id']}',
                                      style: GoogleFonts.plusJakartaSans(
                                          fontSize: 13),
                                    ),
                                  ))
                              .toList(),
                          onChanged: (v) =>
                              setState(() => _colisIdSelectionne = v),
                          decoration: _dropDecor(),
                          validator: (v) =>
                              v == null ? 'Sélectionnez un colis' : null,
                        ),
                  const SizedBox(height: 16),
                  // Type
                  _label('Type de problème *'),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    value: _typeSelectionne,
                    items: _types
                        .map((t) => DropdownMenuItem<String>(
                              value: t['value'],
                              child: Text(t['label']!,
                                  style:
                                      GoogleFonts.plusJakartaSans(fontSize: 13)),
                            ))
                        .toList(),
                    onChanged: (v) =>
                        setState(() => _typeSelectionne = v ?? 'perdu'),
                    decoration: _dropDecor(),
                  ),
                  const SizedBox(height: 16),
                  // Description
                  _label('Description *'),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _descriptionCtrl,
                    maxLines: 4,
                    validator: (v) => v == null || v.trim().isEmpty
                        ? 'Description requise'
                        : null,
                    style: GoogleFonts.plusJakartaSans(fontSize: 14),
                    decoration: _inputDecor(
                        'Décrivez le problème en détail...', null),
                  ),
                ]),
                const SizedBox(height: 16),
                // Photos
                _buildCard(children: [
                  Row(
                    children: [
                      _label('Photos (max 5)'),
                      const Spacer(),
                      TextButton.icon(
                        onPressed: _ajouterPhotos,
                        icon: const Icon(Icons.add_photo_alternate_rounded,
                            size: 18),
                        label: Text('Ajouter',
                            style:
                                GoogleFonts.plusJakartaSans(fontSize: 13)),
                        style: TextButton.styleFrom(
                            foregroundColor: AppColor.kPrimary),
                      ),
                    ],
                  ),
                  if (_photos.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 80,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: _photos.length,
                        separatorBuilder: (_, __) =>
                            const SizedBox(width: 8),
                        itemBuilder: (_, i) => Stack(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: Image.network(
                                _photos[i].path,
                                width: 80,
                                height: 80,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => Container(
                                  width: 80,
                                  height: 80,
                                  color: Colors.grey.shade200,
                                  child: const Icon(Icons.image_rounded),
                                ),
                              ),
                            ),
                            Positioned(
                              top: 2,
                              right: 2,
                              child: GestureDetector(
                                onTap: () =>
                                    setState(() => _photos.removeAt(i)),
                                child: Container(
                                  width: 20,
                                  height: 20,
                                  decoration: const BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Colors.red,
                                  ),
                                  child: const Icon(Icons.close,
                                      size: 12, color: Colors.white),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ] else
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Text(
                        'Aucune photo sélectionnée',
                        style: GoogleFonts.plusJakartaSans(
                            fontSize: 13, color: AppColor.kGrayscale40),
                      ),
                    ),
                ]),
                const SizedBox(height: 28),
                BlocBuilder<ReclamationsCubit, ReclamationsState>(
                  builder: (context, state) {
                    final loading = state is ReclamationEnvoi;
                    return SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: loading ? null : _submit,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColor.kPrimary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14)),
                        ),
                        child: loading
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2.5, color: Colors.white))
                            : Text('Envoyer la réclamation',
                                style: GoogleFonts.plusJakartaSans(
                                    fontWeight: FontWeight.w700, fontSize: 15)),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _label(String text) => Text(
        text,
        style: GoogleFonts.plusJakartaSans(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: AppColor.kGrayscaleDark100),
      );

  Widget _buildCard({required List<Widget> children}) => Container(
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
            crossAxisAlignment: CrossAxisAlignment.start, children: children),
      );

  InputDecoration _dropDecor() => InputDecoration(
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
      );

  InputDecoration _inputDecor(String hint, IconData? icon) => InputDecoration(
        hintText: hint,
        hintStyle: GoogleFonts.plusJakartaSans(
            fontSize: 13, color: AppColor.kGrayscale40),
        prefixIcon: icon != null ? Icon(icon, size: 20) : null,
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
      );
}
