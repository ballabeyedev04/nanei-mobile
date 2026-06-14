import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:toastification/toastification.dart';
import 'package:intl_phone_field/intl_phone_field.dart';

import '../../../../core/routes/app_router.dart';
import '../../../../core/theme/app_color.dart';
import '../../../../core/widgets/toastNotif.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/auth_event.dart';
import '../bloc/auth_state.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage>
    with SingleTickerProviderStateMixin {
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _passwordController = TextEditingController();

  final _firstNameFocus = FocusNode();
  final _lastNameFocus = FocusNode();
  final _emailFocus = FocusNode();
  final _addressFocus = FocusNode();
  final _passwordFocus = FocusNode();

  bool _firstNameFocused = false;
  bool _lastNameFocused = false;
  bool _emailFocused = false;
  bool _addressFocused = false;
  bool _passwordFocused = false;
  bool _obscurePassword = true;

  final _formKey = GlobalKey<FormState>();
  String? _completePhoneNumber;

  late AnimationController _animController;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnim =
        CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _animController.forward();

    void listenFocus(FocusNode node, VoidCallback cb) =>
        node.addListener(() => setState(cb));

    listenFocus(_firstNameFocus, () => _firstNameFocused = _firstNameFocus.hasFocus);
    listenFocus(_lastNameFocus, () => _lastNameFocused = _lastNameFocus.hasFocus);
    listenFocus(_emailFocus, () => _emailFocused = _emailFocus.hasFocus);
    listenFocus(_addressFocus, () => _addressFocused = _addressFocus.hasFocus);
    listenFocus(_passwordFocus, () => _passwordFocused = _passwordFocus.hasFocus);
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _passwordController.dispose();
    _firstNameFocus.dispose();
    _lastNameFocus.dispose();
    _emailFocus.dispose();
    _addressFocus.dispose();
    _passwordFocus.dispose();
    _animController.dispose();
    super.dispose();
  }

  void _submitRegistration() {
    FocusScope.of(context).unfocus();
    if (_formKey.currentState!.validate()) {
      context.read<AuthBloc>().add(
            RegisterRequested(
              nom: _lastNameController.text.trim(),
              prenom: _firstNameController.text.trim(),
              email: _emailController.text.trim(),
              mot_de_passe: _passwordController.text,
              adresse: _addressController.text.trim(),
              telephone:
                  _completePhoneNumber ?? _phoneController.text.trim(),
            ),
          );
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final safePadding = MediaQuery.of(context).padding;

    return Scaffold(
      backgroundColor: AppColor.kBackground,
      body: BlocConsumer<AuthBloc, AuthState>(
        listenWhen: (previous, current) => previous != current,
        listener: (context, state) {
          if (state is AuthSuccess) {
            FocusScope.of(context).unfocus();
            showToast(
              context,
              'Inscription réussie',
              'Vous pouvez maintenant vous connecter !',
              ToastificationType.success,
            );
            Navigator.of(context).pushNamedAndRemoveUntil(
              AppRouter.loginRoute,
              (route) => false,
            );
            context.read<AuthBloc>().add(ResetAuthState());
          } else if (state is AuthFailure) {
            showToast(
              context,
              'Échec de l\'inscription',
              state.message,
              ToastificationType.error,
            );
          }
        },
        builder: (context, state) {
          final isLoading = state is AuthLoading;
          return Stack(
            children: [
              _buildDecorativeBackground(size),
              SafeArea(
                child: FadeTransition(
                  opacity: _fadeAnim,
                  child: SingleChildScrollView(
                    physics: const ClampingScrollPhysics(),
                    padding: EdgeInsets.fromLTRB(
                      24,
                      16,
                      24,
                      safePadding.bottom + 24,
                    ),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildBackButton(),
                          const SizedBox(height: 20),
                          _buildHeader(),
                          const SizedBox(height: 28),
                          _buildCard(isLoading),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  // ── Fond décoratif ─────────────────────────────────────────────────────────
  Widget _buildDecorativeBackground(Size size) {
    return Stack(
      children: [
        Container(color: AppColor.kBackground),
        Positioned(
          top: -size.width * 0.2,
          right: -size.width * 0.15,
          child: Container(
            width: size.width * 0.7,
            height: size.width * 0.7,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColor.kPrimary.withValues(alpha: 0.07),
            ),
          ),
        ),
        Positioned(
          bottom: size.height * 0.1,
          left: -size.width * 0.25,
          child: Container(
            width: size.width * 0.55,
            height: size.width * 0.55,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColor.kPrimary.withValues(alpha: 0.05),
            ),
          ),
        ),
      ],
    );
  }

  // ── Bouton retour ──────────────────────────────────────────────────────────
  Widget _buildBackButton() {
    return GestureDetector(
      onTap: () => Navigator.of(context).pop(),
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: const Icon(
          Icons.arrow_back_ios_new_rounded,
          size: 17,
          color: AppColor.kGrayscaleDark100,
        ),
      ),
    );
  }

  // ── En-tête ────────────────────────────────────────────────────────────────
  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            color: AppColor.kPrimary,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: AppColor.kPrimary.withValues(alpha: 0.35),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: const Icon(
            Icons.person_add_rounded,
            color: Colors.white,
            size: 26,
          ),
        ),
        const SizedBox(height: 20),
        RichText(
          text: TextSpan(
            children: [
              TextSpan(
                text: 'Créez votre\n',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: AppColor.kGrayscaleDark100,
                  height: 1.2,
                ),
              ),
              TextSpan(
                text: 'compte',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: AppColor.kPrimary,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Quelques informations et vous êtes prêt !',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: AppColor.kGrayscale40,
            height: 1.5,
          ),
        ),
      ],
    );
  }

  // ── Carte principale ───────────────────────────────────────────────────────
  Widget _buildCard(bool isLoading) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 40,
            offset: const Offset(0, 12),
          ),
          BoxShadow(
            color: AppColor.kPrimary.withValues(alpha: 0.06),
            blurRadius: 24,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Prénom + Nom côte à côte
          Row(
            children: [
              Expanded(
                child: _buildField(
                  label: 'Prénom',
                  hint: 'Jane',
                  controller: _firstNameController,
                  focusNode: _firstNameFocus,
                  isFocused: _firstNameFocused,
                  icon: Icons.badge_outlined,
                  nextFocus: _lastNameFocus,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildField(
                  label: 'Nom',
                  hint: 'Doe',
                  controller: _lastNameController,
                  focusNode: _lastNameFocus,
                  isFocused: _lastNameFocused,
                  icon: Icons.badge_outlined,
                  nextFocus: _emailFocus,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Téléphone
          _buildPhoneField(),
          const SizedBox(height: 20),

          // Email
          _buildField(
            label: 'Adresse e-mail',
            hint: 'exemple@gmail.com',
            controller: _emailController,
            focusNode: _emailFocus,
            isFocused: _emailFocused,
            icon: Icons.alternate_email_rounded,
            keyboardType: TextInputType.emailAddress,
            nextFocus: _passwordFocus,
            validator: (v) {
              if (v == null || v.trim().isEmpty) return 'Ce champ est requis';
              if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(v)) {
                return 'Email invalide';
              }
              return null;
            },
          ),
          const SizedBox(height: 20),

          // Mot de passe
          _buildPasswordField(),
          const SizedBox(height: 20),

          // Adresse
          _buildField(
            label: 'Adresse complète',
            hint: 'Ex: Dakar, Sénégal',
            controller: _addressController,
            focusNode: _addressFocus,
            isFocused: _addressFocused,
            icon: Icons.location_on_outlined,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _submitRegistration(),
          ),
          const SizedBox(height: 28),

          // Bouton s'inscrire
          _buildSubmitButton(isLoading),
          const SizedBox(height: 20),

          // Lien connexion
          _buildLoginLink(),
        ],
      ),
    );
  }

  // ── Champ texte générique ──────────────────────────────────────────────────
  Widget _buildField({
    required String label,
    required String hint,
    required TextEditingController controller,
    required FocusNode focusNode,
    required bool isFocused,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    TextInputAction textInputAction = TextInputAction.next,
    FocusNode? nextFocus,
    String? Function(String?)? validator,
    void Function(String)? onSubmitted,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _fieldLabel(label),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          focusNode: focusNode,
          keyboardType: keyboardType,
          textInputAction: textInputAction,
          onFieldSubmitted: onSubmitted ??
              (nextFocus != null
                  ? (_) => FocusScope.of(context).requestFocus(nextFocus)
                  : null),
          style: GoogleFonts.plusJakartaSans(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: AppColor.kGrayscaleDark100,
          ),
          validator: validator ??
              (v) => (v == null || v.trim().isEmpty)
                  ? 'Ce champ est requis'
                  : null,
          decoration: _inputDecoration(
            hint: hint,
            icon: icon,
            isFocused: isFocused,
          ),
        ),
      ],
    );
  }

  // ── Champ téléphone ────────────────────────────────────────────────────────
  Widget _buildPhoneField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _fieldLabel('Téléphone'),
        const SizedBox(height: 8),
        IntlPhoneField(
          controller: _phoneController,
          initialCountryCode: 'SN',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: AppColor.kGrayscaleDark100,
          ),
          dropdownTextStyle: GoogleFonts.plusJakartaSans(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: AppColor.kGrayscaleDark100,
          ),
          decoration: InputDecoration(
            hintText: '77 123 45 67',
            hintStyle: GoogleFonts.plusJakartaSans(
              fontSize: 14,
              color: AppColor.kGrayscale20,
            ),
            filled: true,
            fillColor: AppColor.kBackground,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: AppColor.kLine, width: 1.5),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide:
                  const BorderSide(color: AppColor.kPrimary, width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide:
                  const BorderSide(color: Colors.redAccent, width: 1.5),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: Colors.redAccent, width: 2),
            ),
            errorStyle: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Colors.redAccent,
            ),
          ),
          onChanged: (phone) {
            setState(() => _completePhoneNumber = phone.completeNumber);
          },
          validator: (phone) {
            if (phone == null || phone.number.isEmpty) {
              return 'Numéro requis';
            }
            if (phone.number.length < 7) return 'Numéro invalide';
            return null;
          },
        ),
      ],
    );
  }

  // ── Champ mot de passe ─────────────────────────────────────────────────────
  Widget _buildPasswordField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _fieldLabel('Mot de passe'),
        const SizedBox(height: 8),
        TextFormField(
          controller: _passwordController,
          focusNode: _passwordFocus,
          obscureText: _obscurePassword,
          textInputAction: TextInputAction.next,
          onFieldSubmitted: (_) =>
              FocusScope.of(context).requestFocus(_addressFocus),
          style: GoogleFonts.plusJakartaSans(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: AppColor.kGrayscaleDark100,
          ),
          validator: (v) {
            if (v == null || v.isEmpty) return 'Ce champ est requis';
            if (v.length < 6) return 'Minimum 6 caractères';
            return null;
          },
          decoration: _inputDecoration(
            hint: 'Créez un mot de passe sécurisé',
            icon: Icons.lock_outline_rounded,
            isFocused: _passwordFocused,
          ).copyWith(
            suffixIcon: IconButton(
              icon: Icon(
                _obscurePassword
                    ? Icons.visibility_outlined
                    : Icons.visibility_off_outlined,
                size: 20,
                color: _passwordFocused
                    ? AppColor.kPrimary
                    : AppColor.kGrayscale40,
              ),
              onPressed: () =>
                  setState(() => _obscurePassword = !_obscurePassword),
              splashRadius: 20,
            ),
          ),
        ),
      ],
    );
  }

  // ── Bouton s'inscrire ──────────────────────────────────────────────────────
  Widget _buildSubmitButton(bool isLoading) {
    return AnimatedOpacity(
      opacity: isLoading ? 0.75 : 1.0,
      duration: const Duration(milliseconds: 200),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: const LinearGradient(
              colors: [AppColor.kPrimary, AppColor.kPrimaryDark],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColor.kPrimary.withValues(alpha: 0.35),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: InkWell(
            onTap: isLoading ? null : _submitRegistration,
            borderRadius: BorderRadius.circular(16),
            splashColor: Colors.white.withValues(alpha: 0.15),
            highlightColor: Colors.white.withValues(alpha: 0.08),
            child: SizedBox(
              height: 54,
              child: Center(
                child: isLoading
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Créer mon compte',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                              letterSpacing: 0.3,
                            ),
                          ),
                          const SizedBox(width: 10),
                          const Icon(
                            Icons.check_circle_outline_rounded,
                            color: Colors.white,
                            size: 18,
                          ),
                        ],
                      ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ── Lien "Déjà un compte ?" ────────────────────────────────────────────────
  Widget _buildLoginLink() {
    return Wrap(
      alignment: WrapAlignment.center,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Text(
          'Déjà un compte ? ',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: AppColor.kGrayscale40,
          ),
        ),
        GestureDetector(
          onTap: () => Navigator.of(context).pushNamed('/login'),
          child: Text(
            'Se connecter',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppColor.kPrimary,
            ),
          ),
        ),
      ],
    );
  }

  // ── Helpers ────────────────────────────────────────────────────────────────
  Widget _fieldLabel(String text) {
    return Text(
      text,
      style: GoogleFonts.plusJakartaSans(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: AppColor.kGrayscale80,
      ),
    );
  }

  InputDecoration _inputDecoration({
    required String hint,
    required IconData icon,
    required bool isFocused,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle: GoogleFonts.plusJakartaSans(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: AppColor.kGrayscale20,
      ),
      prefixIcon: Padding(
        padding: const EdgeInsets.only(left: 14, right: 10),
        child: Icon(
          icon,
          size: 20,
          color: isFocused ? AppColor.kPrimary : AppColor.kGrayscale40,
        ),
      ),
      prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
      filled: true,
      fillColor: isFocused ? AppColor.kAccentSoft : AppColor.kBackground,
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColor.kLine, width: 1.5),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColor.kPrimary, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Colors.redAccent, width: 1.5),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Colors.redAccent, width: 2),
      ),
      errorStyle: GoogleFonts.plusJakartaSans(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: Colors.redAccent,
      ),
    );
  }
}
