import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../injection_container.dart';
import '../../../../core/routes/app_router.dart';
import '../../../../core/services/token_service.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage>
    with TickerProviderStateMixin {
  // Logo : monte du bas vers le centre
  late final AnimationController _entryCtrl;
  late final Animation<Offset> _slideUp;
  late final Animation<double> _fadeIn;

  // Légère oscillation une fois en place
  late final AnimationController _floatCtrl;
  late final Animation<double> _floatY;

  // Texte apparaît après le logo
  late final AnimationController _textCtrl;
  late final Animation<double> _textFade;
  late final Animation<Offset> _textSlide;

  @override
  void initState() {
    super.initState();

    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ));

    // Logo monte du bas (1.2 → 0) avec fade
    _entryCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 900));
    _slideUp = Tween<Offset>(
            begin: const Offset(0, 1.2), end: Offset.zero)
        .animate(CurvedAnimation(parent: _entryCtrl, curve: Curves.easeOutCubic));
    _fadeIn = Tween<double>(begin: 0.0, end: 1.0)
        .animate(CurvedAnimation(parent: _entryCtrl, curve: Curves.easeIn));

    // Légère flottaison en boucle
    _floatCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 2600))
      ..repeat(reverse: true);
    _floatY = Tween<double>(begin: -7.0, end: 7.0).animate(
        CurvedAnimation(parent: _floatCtrl, curve: Curves.easeInOut));

    // Texte slide + fade
    _textCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600));
    _textFade = Tween<double>(begin: 0.0, end: 1.0)
        .animate(CurvedAnimation(parent: _textCtrl, curve: Curves.easeIn));
    _textSlide = Tween<Offset>(
            begin: const Offset(0, 0.3), end: Offset.zero)
        .animate(
            CurvedAnimation(parent: _textCtrl, curve: Curves.easeOutCubic));

    _startSequence();
  }

  Future<void> _startSequence() async {
    await Future.delayed(const Duration(milliseconds: 300));
    _entryCtrl.forward();
    await Future.delayed(const Duration(milliseconds: 700));
    _textCtrl.forward();
    await _checkAuthStatus();
  }

  Future<void> _checkAuthStatus() async {
    await Future.delayed(const Duration(milliseconds: 1800));
    if (!mounted) return;
    try {
      final tokenService = sl<TokenService>();
      final isAuth = await tokenService.isAuthenticated;
      if (!mounted) return;
      Navigator.of(context).pushReplacementNamed(
        isAuth ? AppRouter.clientRoute : AppRouter.loginRoute,
      );
    } catch (_) {
      if (!mounted) return;
      Navigator.of(context).pushReplacementNamed(AppRouter.loginRoute);
    }
  }

  @override
  void dispose() {
    _entryCtrl.dispose();
    _floatCtrl.dispose();
    _textCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Logo animé
            SlideTransition(
              position: _slideUp,
              child: FadeTransition(
                opacity: _fadeIn,
                child: AnimatedBuilder(
                  animation: _floatCtrl,
                  builder: (_, child) => Transform.translate(
                    offset: Offset(0, _floatY.value),
                    child: child,
                  ),
                  child: Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      color: Colors.black,
                      borderRadius: BorderRadius.circular(28),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.12),
                          blurRadius: 32,
                          offset: const Offset(0, 12),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.local_shipping_rounded,
                      size: 48,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 32),

            // Texte
            SlideTransition(
              position: _textSlide,
              child: FadeTransition(
                opacity: _textFade,
                child: Column(
                  children: [
                    const Text(
                      'Nanei',
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                        color: Colors.black,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Expédiez vos colis en toute confiance',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w400,
                        color: Colors.black.withValues(alpha: 0.4),
                        letterSpacing: 0.2,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
