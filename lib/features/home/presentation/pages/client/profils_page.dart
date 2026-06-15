import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:nanei/core/config/env.dart';
import 'package:nanei/core/theme/app_color.dart';
import 'package:nanei/core/widgets/app_toast.dart';
import 'package:nanei/injection_container.dart';

class ProfilsPage extends StatefulWidget {
  const ProfilsPage({super.key});

  @override
  State<ProfilsPage> createState() => _ProfilsPageState();
}

class _ProfilsPageState extends State<ProfilsPage>
    with SingleTickerProviderStateMixin {
  Map<String, dynamic>? _user;
  bool _loading = true;
  String? _error;

  late final AnimationController _fadeCtrl;
  late final Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 500));
    _fade = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeIn);
    _loadMe();
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadMe() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final res = await sl<Dio>().get(Env.accountMe);
      final data = res.data;
      setState(() {
        _user = data['utilisateur'] as Map<String, dynamic>?;
        _loading = false;
      });
      _fadeCtrl.forward(from: 0);
    } catch (e) {
      setState(() {
        _error = 'Impossible de charger le profil.';
        _loading = false;
      });
    }
  }

  String get _initiales {
    final prenom = (_user?['prenom'] as String? ?? '');
    final nom = (_user?['nom'] as String? ?? '');
    return '${prenom.isNotEmpty ? prenom[0] : ''}${nom.isNotEmpty ? nom[0] : ''}'
        .toUpperCase();
  }

  String get _nomComplet {
    final prenom = (_user?['prenom'] as String? ?? '');
    final nom = (_user?['nom'] as String? ?? '');
    return '$prenom $nom'.trim();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FA),
      body: CustomScrollView(
        slivers: [
          _buildHeader(context),
          if (_loading)
            const SliverFillRemaining(
              child: Center(
                child: CircularProgressIndicator(color: Color(0xFFFF7A00)),
              ),
            )
          else if (_error != null)
            SliverFillRemaining(child: _buildError())
          else
            SliverToBoxAdapter(
              child: FadeTransition(
                opacity: _fade,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 40),
                  child: Column(
                    children: [
                      const SizedBox(height: 20),
                      _buildDetailsCard(),
                      const SizedBox(height: 20),
                      _buildSectionLabel('Paramètres du compte'),
                      const SizedBox(height: 12),
                      _buildActionTile(
                        icon: Icons.edit_rounded,
                        iconColor: const Color(0xFFFF7A00),
                        iconBg: const Color(0xFFFFF0E0),
                        label: 'Modifier mon profil',
                        sub: 'Nom, prénom, email, adresse',
                        onTap: _showEditSheet,
                      ),
                      const SizedBox(height: 10),
                      _buildActionTile(
                        icon: Icons.lock_rounded,
                        iconColor: const Color(0xFF7C3AED),
                        iconBg: const Color(0xFFEDE9FE),
                        label: 'Changer le mot de passe',
                        sub: 'Sécuriser votre compte',
                        onTap: _showPasswordSheet,
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSectionLabel(String label) => Align(
        alignment: Alignment.centerLeft,
        child: Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: AppColor.kGrayscale40,
            letterSpacing: 0.4,
          ),
        ),
      );

  // ── Header ──────────────────────────────────────────────────────────────────

  Widget _buildHeader(BuildContext context) {
    return SliverToBoxAdapter(
      child: Container(
        color: Colors.white,
        child: SafeArea(
          bottom: false,
          child: Column(
            children: [
              // Barre navigation
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.of(context).pop(),
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: const Color(0xFFF4F6FA),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.arrow_back_ios_new_rounded,
                            color: Colors.black, size: 18),
                      ),
                    ),
                    const Spacer(),
                    Text(
                      'Mon Profil',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: Colors.black,
                      ),
                    ),
                    const Spacer(),
                    GestureDetector(
                      onTap: _loadMe,
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: const Color(0xFFF4F6FA),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.refresh_rounded,
                            color: Colors.black, size: 20),
                      ),
                    ),
                  ],
                ),
              ),

              // Avatar + nom + email
              if (!_loading && _error == null) ...[
                const SizedBox(height: 28),
                // Avatar avec badge orange
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      width: 96,
                      height: 96,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: const Color(0xFFF4F6FA),
                        border: Border.all(
                            color: const Color(0xFFE5E9F2), width: 3),
                      ),
                      child: Center(
                        child: Text(
                          _initiales.isEmpty ? '?' : _initiales,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 32,
                            fontWeight: FontWeight.w800,
                            color: Colors.black,
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 2,
                      right: 2,
                      child: Container(
                        width: 22,
                        height: 22,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Color(0xFF059669),
                        ),
                        child: const Icon(Icons.check,
                            color: Colors.white, size: 13),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Text(
                  _nomComplet.isEmpty ? 'Utilisateur' : _nomComplet,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  (_user?['email'] as String? ?? ''),
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    color: AppColor.kGrayscale40,
                  ),
                ),
                const SizedBox(height: 10),
                // Badge rôle
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 5),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF0E0),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.local_shipping_rounded,
                          size: 13, color: Color(0xFFFF7A00)),
                      const SizedBox(width: 5),
                      Text(
                        'Client Nanei',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFFFF7A00),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 28),
              ] else
                const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  // ── Carte détails ──────────────────────────────────────────────────────────

  Widget _buildDetailsCard() {
    final tel = _user?['telephone'] as String?;
    final adresse = _user?['adresse'] as String?;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: _cardDecor(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Informations personnelles',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppColor.kGrayscaleDark100,
            ),
          ),
          const SizedBox(height: 16),
          _detailRow(
            icon: Icons.person_rounded,
            label: 'Nom complet',
            value: _nomComplet.isEmpty ? '—' : _nomComplet,
          ),
          _divider(),
          _detailRow(
            icon: Icons.mail_rounded,
            label: 'Email',
            value: (_user?['email'] as String?) ?? '—',
          ),
          if (tel != null && tel.isNotEmpty) ...[
            _divider(),
            _detailRow(
              icon: Icons.phone_rounded,
              label: 'Téléphone',
              value: tel,
            ),
          ],
          if (adresse != null && adresse.isNotEmpty) ...[
            _divider(),
            _detailRow(
              icon: Icons.location_on_rounded,
              label: 'Adresse',
              value: adresse,
            ),
          ],
        ],
      ),
    );
  }

  Widget _detailRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: const Color(0xFFF4F6FA),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 18, color: const Color(0xFFFF7A00)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    color: AppColor.kGrayscale40,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColor.kGrayscaleDark100,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _divider() => const Divider(height: 1, color: Color(0xFFF0F0F0));

  // ── Action tile ────────────────────────────────────────────────────────────

  Widget _buildActionTile({
    required IconData icon,
    required Color iconColor,
    required Color iconBg,
    required String label,
    required String sub,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        splashColor: iconColor.withValues(alpha: 0.07),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 12,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: iconBg,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, size: 22, color: iconColor),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColor.kGrayscaleDark100,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      sub,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        color: AppColor.kGrayscale40,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded,
                  color: AppColor.kGrayscale20, size: 22),
            ],
          ),
        ),
      ),
    );
  }

  // ── Erreur ──────────────────────────────────────────────────────────────────

  Widget _buildError() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.wifi_off_rounded, size: 56, color: AppColor.kGrayscale20),
          const SizedBox(height: 16),
          Text(
            _error!,
            style: GoogleFonts.plusJakartaSans(
                fontSize: 14, color: AppColor.kGrayscale40),
          ),
          const SizedBox(height: 20),
          GestureDetector(
            onTap: _loadMe,
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFFFF7A00),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                'Réessayer',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Décor carte ────────────────────────────────────────────────────────────

  BoxDecoration _cardDecor() => BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      );

  // ── Sheet modifier profil ──────────────────────────────────────────────────

  void _showEditSheet() {
    final nomCtrl =
        TextEditingController(text: _user?['nom'] as String? ?? '');
    final prenomCtrl =
        TextEditingController(text: _user?['prenom'] as String? ?? '');
    final emailCtrl =
        TextEditingController(text: _user?['email'] as String? ?? '');
    final adresseCtrl =
        TextEditingController(text: _user?['adresse'] as String? ?? '');
    final telCtrl =
        TextEditingController(text: _user?['telephone'] as String? ?? '');
    final formKey = GlobalKey<FormState>();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _EditSheet(
        formKey: formKey,
        nomCtrl: nomCtrl,
        prenomCtrl: prenomCtrl,
        emailCtrl: emailCtrl,
        adresseCtrl: adresseCtrl,
        telCtrl: telCtrl,
        onSave: (data) async {
          await sl<Dio>().put(Env.accountModifierProfil, data: data);
          await _loadMe();
        },
      ),
    );
  }

  // ── Sheet changer mot de passe ─────────────────────────────────────────────

  void _showPasswordSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _PasswordSheet(
        onSave: (data) async {
          await sl<Dio>().put(Env.accountChangePassword, data: data);
        },
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════
// Sheet — modifier profil
// ════════════════════════════════════════════════════════════════════════════

class _EditSheet extends StatefulWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController nomCtrl;
  final TextEditingController prenomCtrl;
  final TextEditingController emailCtrl;
  final TextEditingController adresseCtrl;
  final TextEditingController telCtrl;
  final Future<void> Function(Map<String, dynamic>) onSave;

  const _EditSheet({
    required this.formKey,
    required this.nomCtrl,
    required this.prenomCtrl,
    required this.emailCtrl,
    required this.adresseCtrl,
    required this.telCtrl,
    required this.onSave,
  });

  @override
  State<_EditSheet> createState() => _EditSheetState();
}

class _EditSheetState extends State<_EditSheet> {
  bool _loading = false;

  Future<void> _submit() async {
    if (!widget.formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      await widget.onSave({
        'nom': widget.nomCtrl.text.trim(),
        'prenom': widget.prenomCtrl.text.trim(),
        'email': widget.emailCtrl.text.trim(),
        'adresse': widget.adresseCtrl.text.trim(),
        'telephone': widget.telCtrl.text.trim(),
      });
      if (mounted) {
        Navigator.of(context).pop();
        showSuccessToast(context, 'Profil mis à jour avec succès !');
      }
    } catch (e) {
      if (mounted) {
        showErrorToast(context, 'Erreur lors de la mise à jour.');
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.fromLTRB(24, 0, 24, 24 + bottom),
      child: SingleChildScrollView(
        child: Form(
          key: widget.formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _handle(),
              _sheetTitle(
                  Icons.edit_rounded, 'Modifier le profil', 'Mettez vos infos à jour'),
              const SizedBox(height: 24),
              _field(widget.prenomCtrl, 'Prénom', Icons.person_rounded,
                  required: true),
              const SizedBox(height: 14),
              _field(widget.nomCtrl, 'Nom', Icons.person_outline_rounded,
                  required: true),
              const SizedBox(height: 14),
              _field(widget.emailCtrl, 'Email', Icons.mail_rounded,
                  keyboard: TextInputType.emailAddress, required: true),
              const SizedBox(height: 14),
              _field(widget.telCtrl, 'Téléphone', Icons.phone_rounded,
                  keyboard: TextInputType.phone),
              const SizedBox(height: 14),
              _field(widget.adresseCtrl, 'Adresse', Icons.location_on_rounded,
                  maxLines: 2),
              const SizedBox(height: 24),
              _submitBtn('Enregistrer', _loading, _submit),
            ],
          ),
        ),
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════
// Sheet — changer mot de passe
// ════════════════════════════════════════════════════════════════════════════

class _PasswordSheet extends StatefulWidget {
  final Future<void> Function(Map<String, dynamic>) onSave;
  const _PasswordSheet({required this.onSave});

  @override
  State<_PasswordSheet> createState() => _PasswordSheetState();
}

class _PasswordSheetState extends State<_PasswordSheet> {
  final _formKey = GlobalKey<FormState>();
  final _oldCtrl = TextEditingController();
  final _newCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  bool _loading = false;
  bool _showOld = false;
  bool _showNew = false;
  bool _showConfirm = false;

  @override
  void dispose() {
    _oldCtrl.dispose();
    _newCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      await widget.onSave({
        'ancienMotDePasse': _oldCtrl.text,
        'nouveauMotDePasse': _newCtrl.text,
      });
      if (mounted) {
        Navigator.of(context).pop();
        showSuccessToast(context, 'Mot de passe modifié avec succès !');
      }
    } catch (e) {
      if (mounted) {
        showErrorToast(context, 'Mot de passe actuel incorrect.');
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.fromLTRB(24, 0, 24, 24 + bottom),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _handle(),
              _sheetTitle(Icons.lock_rounded, 'Changer le mot de passe',
                  'Sécurisez votre compte',
                  color: const Color(0xFF7C3AED)),
              const SizedBox(height: 24),
              _passwordField(_oldCtrl, 'Mot de passe actuel', _showOld,
                  () => setState(() => _showOld = !_showOld),
                  validator: (v) =>
                      v == null || v.isEmpty ? 'Requis' : null),
              const SizedBox(height: 14),
              _passwordField(_newCtrl, 'Nouveau mot de passe', _showNew,
                  () => setState(() => _showNew = !_showNew),
                  validator: (v) => v == null || v.length < 8
                      ? 'Minimum 8 caractères'
                      : null),
              const SizedBox(height: 14),
              _passwordField(
                  _confirmCtrl, 'Confirmer le mot de passe', _showConfirm,
                  () => setState(() => _showConfirm = !_showConfirm),
                  validator: (v) => v != _newCtrl.text
                      ? 'Les mots de passe ne correspondent pas'
                      : null),
              const SizedBox(height: 24),
              _submitBtn('Modifier le mot de passe', _loading, _submit,
                  color: const Color(0xFF7C3AED)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _passwordField(
    TextEditingController ctrl,
    String label,
    bool show,
    VoidCallback toggle, {
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: ctrl,
      obscureText: !show,
      validator: validator,
      style: GoogleFonts.plusJakartaSans(
          fontSize: 14, color: AppColor.kGrayscaleDark100),
      decoration: _inputDecor(label, Icons.lock_rounded).copyWith(
        suffixIcon: IconButton(
          icon: Icon(show ? Icons.visibility_off_rounded : Icons.visibility_rounded,
              size: 20, color: AppColor.kGrayscale40),
          onPressed: toggle,
        ),
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════
// Helpers communs
// ════════════════════════════════════════════════════════════════════════════

Widget _handle() => Center(
      child: Container(
        margin: const EdgeInsets.only(top: 12, bottom: 20),
        width: 40,
        height: 4,
        decoration: BoxDecoration(
          color: const Color(0xFFE5E7EB),
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );

Widget _sheetTitle(IconData icon, String title, String sub,
    {Color color = const Color(0xFFFF7A00)}) {
  return Row(
    children: [
      Container(
        width: 46,
        height: 46,
        decoration: BoxDecoration(
          gradient: LinearGradient(
              colors: [color, color.withValues(alpha: 0.7)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight),
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
                color: color.withValues(alpha: 0.3),
                blurRadius: 12,
                offset: const Offset(0, 4))
          ],
        ),
        child: Icon(icon, color: Colors.white, size: 22),
      ),
      const SizedBox(width: 14),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title,
                style: GoogleFonts.plusJakartaSans(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: AppColor.kGrayscaleDark100)),
            Text(sub,
                style: GoogleFonts.plusJakartaSans(
                    fontSize: 12, color: AppColor.kGrayscale40)),
          ],
        ),
      ),
    ],
  );
}

Widget _field(
  TextEditingController ctrl,
  String label,
  IconData icon, {
  TextInputType? keyboard,
  int maxLines = 1,
  bool required = false,
}) {
  return TextFormField(
    controller: ctrl,
    keyboardType: keyboard,
    maxLines: maxLines,
    validator: required
        ? (v) => v == null || v.trim().isEmpty ? '$label requis' : null
        : null,
    style: GoogleFonts.plusJakartaSans(
        fontSize: 14, color: AppColor.kGrayscaleDark100),
    decoration: _inputDecor(label, icon),
  );
}

InputDecoration _inputDecor(String label, IconData icon) => InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, size: 20, color: AppColor.kGrayscale40),
      labelStyle:
          GoogleFonts.plusJakartaSans(fontSize: 13, color: AppColor.kGrayscale40),
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
      focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide:
              const BorderSide(color: Color(0xFFEF4444), width: 1.5)),
    );

Widget _submitBtn(String label, bool loading, VoidCallback onTap,
    {Color color = const Color(0xFFFF7A00)}) {
  return SizedBox(
    width: double.infinity,
    child: GestureDetector(
      onTap: loading ? null : onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: 52,
        decoration: BoxDecoration(
          gradient: loading
              ? null
              : LinearGradient(
                  colors: [color, color.withValues(alpha: 0.8)]),
          color: loading ? const Color(0xFFE5E7EB) : null,
          borderRadius: BorderRadius.circular(16),
          boxShadow: loading
              ? []
              : [
                  BoxShadow(
                      color: color.withValues(alpha: 0.35),
                      blurRadius: 14,
                      offset: const Offset(0, 5))
                ],
        ),
        child: Center(
          child: loading
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                      strokeWidth: 2.5, color: Colors.white),
                )
              : Text(
                  label,
                  style: GoogleFonts.plusJakartaSans(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: Colors.white),
                ),
        ),
      ),
    ),
  );
}
