import 'package:francomalishipp/core/routes/app_router.dart';
import 'package:francomalishipp/core/widgets/primary_text_formField.dart';
import 'package:francomalishipp/features/auth/presentation/widgets/PasswordTextField.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:toastification/toastification.dart';
import 'package:intl_phone_field/intl_phone_field.dart';
import '../../../../core/theme/app_color.dart';
import '../../../../core/widgets/toastNotif.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/auth_event.dart';
import '../bloc/auth_state.dart';
import 'package:flutter/gestures.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  // Contrôleurs pour les champs
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _passwordController = TextEditingController();

  final _formKey = GlobalKey<FormState>();
  String? _completePhoneNumber; // Stocke le numéro complet avec indicatif

  void _submitRegistration() {
    if (_formKey.currentState!.validate()) {
      context.read<AuthBloc>().add(
        RegisterRequested(
          nom: _lastNameController.text.trim(),
          prenom: _firstNameController.text.trim(),
          email: _emailController.text.trim(),
          mot_de_passe: _passwordController.text,
          adresse: _addressController.text.trim(),
          telephone: _completePhoneNumber ?? _phoneController.text.trim()
        ),
      );
    }
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
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
              // Background avec effet de gradient
              _buildBackground(),

              // Bouton retour
              Positioned(
                top: 48,
                left: 16,
                child: GestureDetector(
                  onTap: () => Navigator.of(context).pop(),
                  child: Container(
                    height: 44,
                    width: 44,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.08),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.arrow_back_ios_new,
                      size: 18,
                      color: Colors.black,
                    ),
                  ),
                ),
              ),

              SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 40),

                      // Header
                      _buildHeader(),
                      const SizedBox(height: 32),

                      // Formulaire unique
                      _buildForm(isLoading),
                      const SizedBox(height: 32),

                      // Bouton d'inscription
                      _buildSubmitButton(isLoading),
                      const SizedBox(height: 40),

                      // Termes et conditions
                      _buildTermsAndPrivacy(),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildBackground() {
    return Column(
      children: [
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  AppColor.kPrimary.withOpacity(0.05),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 25),
        Text(
          'Créez votre compte',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 32,
            fontWeight: FontWeight.w800,
            color: AppColor.kGrayscaleDark100,
            height: 1.2,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Remplissez vos informations pour commencer',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: AppColor.kGrayscale40,
            height: 1.4,
          ),
        ),
      ],
    );
  }

  Widget _buildForm(bool isLoading) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColor.kPrimary.withOpacity(0.1),
            blurRadius: 40,
            offset: const Offset(0, 8),
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(24),
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            // Prénom
            _buildTextFieldWithLabel(
              label: 'Prénom',
              hint: 'Ex: Jane',
              controller: _firstNameController,
              prefixIcon: Icons.person_outline,
              isRequired: true,
            ),
            const SizedBox(height: 16),

            // Nom
            _buildTextFieldWithLabel(
              label: 'Nom',
              hint: 'Ex: Doe',
              controller: _lastNameController,
              prefixIcon: Icons.person_outline,
              isRequired: true,
            ),
            const SizedBox(height: 16),

            // Téléphone avec indicatif
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'Téléphone',
                      style: GoogleFonts.plusJakartaSans(
                        color: AppColor.kGrayscaleDark100,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                    Text(
                      ' *',
                      style: GoogleFonts.plusJakartaSans(
                        color: Colors.red,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                IntlPhoneField(
                  controller: _phoneController,
                  decoration: InputDecoration(
                    hintText: '77 123 45 67',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: const BorderSide(color: AppColor.kLine),
                    ),
                  ),
                  initialCountryCode: 'SN',
                  onChanged: (phone) {
                    setState(() {
                      _completePhoneNumber = phone.completeNumber;
                    });
                  },
                  validator: (phone) {
                    if (phone == null || phone.number.isEmpty) {
                      return 'Numéro requis';
                    }
                    if (phone.number.length < 7) {
                      return 'Numéro invalide';
                    }
                    return null;
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Email
            _buildTextFieldWithLabel(
              label: 'Adresse e-mail',
              hint: 'exemple@gmail.com',
              controller: _emailController,
              prefixIcon: Icons.email_outlined,
              keyboardType: TextInputType.emailAddress,
              validator: (value) {
                if (value == null || value.isEmpty) return 'Ce champ est requis';
                if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
                  return 'Email invalide';
                }
                return null;
              },
              isRequired: true,
            ),
            const SizedBox(height: 16),

            // Mot de passe
            _buildPasswordField(),
            const SizedBox(height: 16),

            // Adresse
            _buildTextFieldWithLabel(
              label: 'Adresse complète',
              hint: 'Ex: Dakar, Sénégal',
              controller: _addressController,
              prefixIcon: Icons.location_on_outlined,
              isRequired: true,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextFieldWithLabel({
    required String label,
    required String hint,
    required TextEditingController controller,
    required IconData prefixIcon,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
    bool isRequired = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              label,
              style: GoogleFonts.plusJakartaSans(
                color: AppColor.kGrayscaleDark100,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
            if (isRequired)
              Text(
                ' *',
                style: GoogleFonts.plusJakartaSans(
                  color: Colors.red,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          height: 52,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColor.kLine, width: 1.5),
          ),
          child: Row(
            children: [
              Padding(
                padding: const EdgeInsets.only(left: 16),
                child: Icon(
                  prefixIcon,
                  color: AppColor.kPrimary,
                  size: 20,
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(right: 16),
                  child: PrimaryTextFormField(
                    controller: controller,
                    hintText: hint,
                    height: 50,
                    width: double.infinity,
                    keyboardType: keyboardType,
                    validator: validator,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPasswordField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Mot de passe',
              style: GoogleFonts.plusJakartaSans(
                color: AppColor.kGrayscaleDark100,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
            Text(
              ' *',
              style: GoogleFonts.plusJakartaSans(
                color: Colors.red,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          height: 52,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColor.kLine, width: 1.5),
          ),
          child: Row(
            children: [
              Padding(
                padding: const EdgeInsets.only(left: 16),
                child: Icon(
                  Icons.lock_outline,
                  color: AppColor.kPrimary,
                  size: 20,
                ),
              ),
              Expanded(
                child: PasswordTextField(
                  controller: _passwordController,
                  hintText: 'Créez un mot de passe sécurisé',
                  height: 50,
                  width: double.infinity,
                  borderRadius: BorderRadius.circular(12),
                  validator: (value) {
                    if (value == null || value.isEmpty) return 'Ce champ est requis';
                    if (value.length < 6) {
                      return 'Le mot de passe doit contenir au moins 6 caractères';
                    }
                    return null;
                  },
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSubmitButton(bool isLoading) {
    return SizedBox(
      height: 56,
      width: double.infinity,
      child: Material(
        borderRadius: BorderRadius.circular(16),
        elevation: 0,
        color: AppColor.kPrimary,
        child: InkWell(
          onTap: isLoading ? null : _submitRegistration,
          borderRadius: BorderRadius.circular(16),
          splashColor: Colors.white.withOpacity(0.2),
          highlightColor: Colors.white.withOpacity(0.1),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 24),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: isLoading
                  ? null
                  : LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                colors: [
                  AppColor.kPrimary,
                  AppColor.kPrimary.withOpacity(0.8),
                ],
              ),
              boxShadow: isLoading
                  ? null
                  : [
                BoxShadow(
                  color: AppColor.kPrimary.withOpacity(0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Center(
              child: isLoading
                  ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation(Colors.white),
                ),
              )
                  : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'S\'inscrire',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Icon(
                    Icons.check_circle_outline_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTermsAndPrivacy() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Text.rich(
          TextSpan(
            children: [
              const TextSpan(
                text: 'En vous inscrivant, vous acceptez nos ',
              ),
              TextSpan(
                text: 'Conditions d\'utilisation',
                style: GoogleFonts.plusJakartaSans(
                  fontWeight: FontWeight.w700,
                  color: AppColor.kPrimary,
                ),
                recognizer: TapGestureRecognizer()
                  ..onTap = () {
                    Navigator.of(context).pushNamed(
                      AppRouter.contiditionUtilisationRoute,
                    );
                  },
              ),
              const TextSpan(
                text: ' et notre ',
              ),
              TextSpan(
                text: 'Politique de confidentialité',
                style: GoogleFonts.plusJakartaSans(
                  fontWeight: FontWeight.w700,
                  color: AppColor.kPrimary,
                ),
                recognizer: TapGestureRecognizer()
                  ..onTap = () {
                    Navigator.of(context).pushNamed(
                      AppRouter.politiqueConfRoute,
                    );
                  },
              ),
            ],
          ),
          textAlign: TextAlign.center,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 12,
            fontWeight: FontWeight.w400,
            color: AppColor.kGrayscale40,
            height: 1.6,
          ),
        ),
      ),
    );
  }
}