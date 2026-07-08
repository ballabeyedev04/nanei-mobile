import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:safe_device/safe_device.dart';
import 'package:toastification/toastification.dart';

import 'core/observers/app_bloc_observer.dart';
import 'core/routes/app_router.dart';
import 'core/services/fcm_service.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_cubit.dart';
import 'core/theme/theme_notifier.dart';
import 'core/utils/app_logger.dart';
import 'features/auth/presentation/bloc/auth_bloc.dart';
import 'features/auth/presentation/pages/splash_page.dart';
import 'injection_container.dart' as di;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AppLogger.init();
  Bloc.observer = AppBlocObserver();
  AppLogger.info('Application Nanei démarrée', {'version': '1.0.0'});

  // ── Détection root / jailbreak ────────────────────────────────────────────
  if (!kDebugMode) {
    try {
      final isJailbroken = await SafeDevice.isJailBroken;
      if (isJailbroken) {
        AppLogger.warning('Appareil rooté ou en mode développeur détecté');
        runApp(const _DeviceCompromisedApp());
        return;
      }
    } catch (_) {}
  }

  await dotenv.load(fileName: '.env');
  await di.init();

  // ── Firebase + Crashlytics ────────────────────────────────────────────────
  try {
    await Firebase.initializeApp();

    // Crashlytics — capture toutes les erreurs Flutter en production
    if (!kDebugMode) {
      FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;
      PlatformDispatcher.instance.onError = (error, stack) {
        FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
        AppLogger.critical('Erreur non capturée', error, stack);
        return true;
      };
    } else {
      FlutterError.onError = (details) {
        AppLogger.error('Flutter erreur', details.exception, details.stack);
        FlutterError.presentError(details);
      };
      PlatformDispatcher.instance.onError = (error, stack) {
        AppLogger.critical('Erreur non capturée', error, stack);
        return false;
      };
    }

    await FcmService.init();
    AppLogger.info('Firebase initialisé avec succès');
  } catch (e) {
    // Fallback logging si Firebase non disponible
    FlutterError.onError = (details) {
      AppLogger.error('Flutter erreur', details.exception, details.stack);
      FlutterError.presentError(details);
    };
    PlatformDispatcher.instance.onError = (error, stack) {
      AppLogger.critical('Erreur non capturée', error, stack);
      return false;
    };
    AppLogger.warning('Firebase non configuré — Crashlytics désactivé.');
  }

  runApp(
    BlocProvider(
      create: (_) => di.sl<ThemeCubit>(),
      child: const MyApp(),
    ),
  );
}

// Écran affiché si l'appareil est rooté / jailbreaké
class _DeviceCompromisedApp extends StatelessWidget {
  const _DeviceCompromisedApp();
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: const Color(0xFF0f172a),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              const Icon(Icons.security_rounded, size: 72, color: Color(0xFFef4444)),
              const SizedBox(height: 24),
              const Text('Appareil non sécurisé',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: Colors.white)),
              const SizedBox(height: 12),
              const Text(
                'Nanei ne peut pas fonctionner sur un appareil rooté ou jailbreaké pour protéger vos données.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: Color(0xFF94a3b8), height: 1.6),
              ),
            ]),
          ),
        ),
      ),
    );
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => di.sl<AuthBloc>()),
      ],
      child: BlocBuilder<ThemeCubit, ThemeMode>(
        builder: (context, themeMode) {
          return ToastificationWrapper(
            child: MaterialApp(
              debugShowCheckedModeBanner: false,
              title: 'Nanei',
              theme: AppTheme.light(),
              darkTheme: AppTheme.dark(),
              themeMode: themeMode,
              home: const SplashPage(),
              onGenerateRoute: AppRouter.onGenerateRoute,
            ),
          );
        },
      ),
    );
  }
}
