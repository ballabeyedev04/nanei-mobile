import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';
import 'package:toastification/toastification.dart';

import 'core/observers/app_bloc_observer.dart';
import 'core/routes/app_router.dart';
import 'core/services/fcm_service.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_notifier.dart';
import 'core/utils/app_logger.dart';
import 'features/auth/presentation/bloc/auth_bloc.dart';
import 'features/auth/presentation/pages/splash_page.dart';
import 'injection_container.dart' as di;

// Nécessite google-services.json (Android) et GoogleService-Info.plist (iOS) de Firebase Console

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AppLogger.init();
  Bloc.observer = AppBlocObserver();
  AppLogger.info('Application Nanei démarrée', {'version': '1.0.0'});

  FlutterError.onError = (details) {
    AppLogger.error('Flutter erreur', details.exception, details.stack);
    FlutterError.presentError(details);
  };

  PlatformDispatcher.instance.onError = (error, stack) {
    AppLogger.critical('Erreur non capturée', error, stack);
    return false;
  };

  await dotenv.load(fileName: '.env');
  await di.init();

  // Initialiser Firebase (optionnel — nécessite google-services.json)
  try {
    await Firebase.initializeApp();
    await FcmService.init();
    AppLogger.info('Firebase initialisé avec succès');
  } catch (e) {
    AppLogger.warning(
      'Firebase non configuré — notifications push désactivées. '
      'Ajoutez google-services.json dans android/app/ pour activer.',
    );
  }

  runApp(
    ChangeNotifierProvider(
      create: (_) => ThemeNotifier(),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => di.sl<AuthBloc>()),
      ],
      child: Consumer<ThemeNotifier>(
        builder: (context, themeNotifier, _) {
          return ToastificationWrapper(
            child: MaterialApp(
              debugShowCheckedModeBanner: false,
              title: 'Nanei',
              theme: AppTheme.light(),
              darkTheme: AppTheme.dark(),
              themeMode: themeNotifier.themeMode,
              home: const SplashPage(),
              onGenerateRoute: AppRouter.onGenerateRoute,
            ),
          );
        },
      ),
    );
  }
}
