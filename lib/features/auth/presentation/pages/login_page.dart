import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:toastification/toastification.dart';

import '../../../../core/routes/app_router.dart';
import '../../../../core/theme/app_color.dart';
import '../../../../core/widgets/primary_text_button.dart';
import '../../../../core/widgets/primary_text_formField.dart';
import '../../../../core/widgets/toastNotif.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/auth_event.dart';
import '../bloc/auth_state.dart';
import '../widgets/PasswordTextField.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _identifiantController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  void _onLoginPressed() {
    if (_formKey.currentState!.validate()) {
      context.read<AuthBloc>().add(
        LoginRequested(
          identifiant: _identifiantController.text,
          mot_de_passe: _passwordController.text,
        ),
      );
    }
  }

  @override
  void dispose() {
    _identifiantController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: BlocConsumer<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is AuthSuccess) {
            String route = AppRouter.homeRoute;
            dynamic arguments = state.user;

            // Choix de la route selon le rôle (ici simplifié)
            route = AppRouter.clientRoute;

            Navigator.of(context).pushNamedAndRemoveUntil(
              route,
                  (route) => false,
              arguments: arguments,
            );

            showToast(
              context,
              'Connexion réussie',
              'Bienvenue de retour !',
              ToastificationType.success,
            );
          } else if (state is AuthFailure) {
            showToast(
              context,
              'Échec de la connexion',
              'Identifiant ou mot de passe incorrect !',
              ToastificationType.error,
            );
          }
        },
        builder: (context, state) {
          final isLoading = state is AuthLoading;

          return Stack(
            children: [
              // Fond blanc avec effet de gradient subtil (optionnel)
              _buildBackground(),

              SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 40),

                        // En-tête
                        _buildHeader(),
                        const SizedBox(height: 32),

                        // Carte de connexion
                        _buildLoginCard(isLoading),
                        const SizedBox(height: 32),

                      ],
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

  // Fond blanc avec un léger dégradé pour plus de profondeur (comme la page d'inscription)
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

  // En-tête avec titre et sous-titre
  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 60),
        RichText(
          text: TextSpan(
            children: [
              TextSpan(
                text: 'Ravi de vous ',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 32,
                  fontWeight: FontWeight.w800,
                  color: AppColor.kGrayscaleDark100,
                  height: 1.2,
                ),
              ),
              TextSpan(
                text: 'revoir !',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 32,
                  fontWeight: FontWeight.w800,
                  color: AppColor.kPrimary, // Orange pour accent
                  height: 1.2,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Accédez à votre espace pour envoyer, recevoir et suivre vos colis',
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

  // Carte de connexion (fond blanc, ombres)
  Widget _buildLoginCard(bool isLoading) {
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
      child: Column(
        children: [
          // Champ identifiant
          _buildTextFieldWithLabel(
            label: 'Email ou téléphone',
            hint: 'exemple@entreprise.com ou 77XXXXXXX',
            controller: _identifiantController,
            prefixIcon: Icons.person_outline,
            keyboardType: TextInputType.emailAddress,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Ce champ est requis';
              }
              return null;
            },
          ),
          const SizedBox(height: 30),

          // Champ mot de passe
          _buildPasswordField(),
          const SizedBox(height: 20),

          // Mot de passe oublié
          _buildRememberForgotRow(),
          const SizedBox(height: 50),

          // Bouton de connexion (orange)
          _buildLoginButton(isLoading),
          const SizedBox(height: 30),

          // Lien d'inscription
          _buildRegisterLink(),
        ],
      ),
    );
  }

  // Champ avec icône et label
  Widget _buildTextFieldWithLabel({
    required String label,
    required String hint,
    required TextEditingController controller,
    required IconData prefixIcon,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            color: AppColor.kGrayscaleDark100,
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
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

  // Champ mot de passe avec œil
  Widget _buildPasswordField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Mot de passe',
          style: GoogleFonts.plusJakartaSans(
            color: AppColor.kGrayscaleDark100,
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
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
                  hintText: 'Votre mot de passe',
                  height: 50,
                  width: double.infinity,
                  borderRadius: BorderRadius.circular(12),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Ce champ est requis';
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

  // Lien "Mot de passe oublié ?"
  Widget _buildRememberForgotRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        PrimaryTextButton(
          onPressed: () {
            Navigator.of(context).pushNamed('/forgot-password');
          },
          titre: 'Mot de passe oublié ?',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColor.kPrimary,
          ),
        ),
      ],
    );
  }

  // Bouton de connexion (orange, texte noir)
  Widget _buildLoginButton(bool isLoading) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: Material(
        borderRadius: BorderRadius.circular(16),
        elevation: 0,
        color: AppColor.kPrimary,
        child: InkWell(
          onTap: isLoading ? null : _onLoginPressed,
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
                    'Se connecter',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Icon(
                    Icons.arrow_forward_rounded,
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

  // Lien "Créer un compte"
  Widget _buildRegisterLink() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'Nouveau chez nous ? ',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 15,
            fontWeight: FontWeight.w500,
            color: AppColor.kGrayscale40,
          ),
        ),
        GestureDetector(
          onTap: () {
            Navigator.of(context).pushNamed('/register');
          },
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
            child: Text(
              'Créer un compte',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: AppColor.kPrimary,
              ),
            ),
          ),
        ),
      ],
    );
  }

}