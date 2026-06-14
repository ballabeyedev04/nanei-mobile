import 'package:francomalishipp/core/routes/app_router.dart';
import 'package:francomalishipp/core/theme/app_theme.dart';
import 'package:francomalishipp/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:francomalishipp/features/auth/presentation/pages/splash_page.dart';
import 'package:francomalishipp/injection_container.dart' as di;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter/services.dart';
import 'package:toastification/toastification.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: '.env');
  await di.init();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => di.sl<AuthBloc>()),
      ],
      child: ToastificationWrapper(
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'FrancoMaliShip',
          theme: AppTheme.light(),
          home: const SplashPage(),
          onGenerateRoute: AppRouter.onGenerateRoute,
        ),
      ),
    );
  }
}
