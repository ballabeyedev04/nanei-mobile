import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../injection_container.dart';
import '../../../../core/routes/app_router.dart';
import '../../../../core/services/token_service.dart';
import '../../../../core/config/env.dart';
import '../../../../core/utils/app_logger.dart';
import '../../../auth/domain/entities/user.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _slideY;
  late final Animation<double> _fade;

  @override
  void initState() {
    super.initState();

    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ));

    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    // Logo monte du bas (120px) vers le centre
    _slideY = Tween<double>(begin: 120.0, end: 0.0).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic),
    );

    // Fade in en même temps
    _fade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _ctrl, curve: const Interval(0.0, 0.7, curve: Curves.easeOut)),
    );

    _ctrl.forward();
    _checkAuthStatus();
  }

  Future<void> _checkAuthStatus() async {
    await Future.delayed(const Duration(milliseconds: 1600));
    if (!mounted) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      final onboardingDone = prefs.getBool('onboarding_done') ?? false;
      if (!onboardingDone) {
        if (!mounted) return;
        Navigator.of(context).pushReplacementNamed(AppRouter.onboardingRoute);
        return;
      }

      final tokenService = sl<TokenService>();
      // Le jeton d'accès ne dure qu'1 h, le refresh token 7 jours : un jeton
      // d'accès expiré ne suffit PAS à renvoyer vers la connexion. L'appel à
      // /account/me ci-dessous le renouvelle automatiquement (intercepteur
      // Dio) tant que le refresh token est valide.
      final accesValide = await tokenService.isAuthenticated;
      final peutRafraichir = await tokenService.aUnRefreshToken;
      if (!mounted) return;

      if (!accesValide && !peutRafraichir) {
        AppLogger.info('Splash: aucune session → login');
        Navigator.of(context).pushReplacementNamed(AppRouter.loginRoute);
        return;
      }

      User? user;
      try {
        final res = await sl<Dio>().get(Env.accountMe);
        final data = res.data['utilisateur'] as Map<String, dynamic>?;
        if (data != null) {
          user = User(
            id: data['id']?.toString() ?? '',
            nom: data['nom']?.toString() ?? '',
            prenom: data['prenom']?.toString() ?? '',
            email: data['email']?.toString() ?? '',
            mot_de_passe: '',
            adresse: data['adresse']?.toString() ?? '',
            telephone: data['telephone']?.toString() ?? '',
          );
        }
      } on DioException catch (e) {
        final status = e.response?.statusCode;
        // 401 (refresh refusé) / 403 (compte désactivé) / 404 (compte
        // supprimé) : la session n'est plus utilisable.
        if (status == 401 || status == 403 || status == 404) {
          AppLogger.info('Splash: session refusée ($status) → login');
          await tokenService.clearToken();
          if (!mounted) return;
          Navigator.of(context).pushReplacementNamed(AppRouter.loginRoute);
          return;
        }
        // Réseau indisponible : on garde la session, les appels suivants
        // renouvelleront le jeton.
        AppLogger.warning('Splash: erreur chargement profil', e.toString());
      } catch (e) {
        AppLogger.warning('Splash: erreur chargement profil', e.toString());
      }

      if (!mounted) return;
      Navigator.of(context).pushReplacementNamed(
        AppRouter.clientRoute,
        arguments: user,
      );
    } catch (e) {
      AppLogger.error('Splash: erreur auth', e);
      if (!mounted) return;
      Navigator.of(context).pushReplacementNamed(AppRouter.loginRoute);
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: AnimatedBuilder(
        animation: _ctrl,
        builder: (_, child) => Transform.translate(
          offset: Offset(0, _slideY.value),
          child: Opacity(
            opacity: _fade.value,
            child: child,
          ),
        ),
        child: Center(
          child: Image.asset(
            'assets/images/logo.png',
            width: 110,
            height: 110,
            fit: BoxFit.contain,
          ),
        ),
      ),
    );
  }
}
