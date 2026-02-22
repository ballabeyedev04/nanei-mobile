import 'package:flutter/material.dart';
import 'package:francomalishipp/features/auth/presentation/pages/login_page.dart';
import 'package:francomalishipp/features/auth/presentation/pages/register_page.dart';
import 'package:francomalishipp/features/home/presentation/pages/home.dart';
import 'package:francomalishipp/features/home/presentation/pages/client/clientpage.dart';
import 'package:francomalishipp/features/home/presentation/pages/professionnel/professionnelpage.dart';
import 'package:francomalishipp/features/auth/presentation/widgets/ContiditionUtilisation.dart';
import 'package:francomalishipp/features/auth/presentation/widgets/PolitiqueConfidentialite.dart';
import 'package:francomalishipp/features/auth/domain/entities/user.dart';

class AppRouter {
  static const String loginRoute = '/login';
  static const String registerRoute = '/register';
  static const String homeRoute = '/home';
  static const String clientRoute = '/client';
  static const String professionnelRoute = '/professionnel';

  static const String politiqueConfRoute = '/politique-confidentialite';
  static const String contiditionUtilisationRoute = '/condition-utilisation';



  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case loginRoute:
        return MaterialPageRoute(builder: (_) => LoginPage());

      case registerRoute:
        return MaterialPageRoute(builder: (_) => const RegisterPage());

      case homeRoute:
        return MaterialPageRoute(builder: (_) => const HomePage());

      case clientRoute:
        final user = settings.arguments as User?;
        return MaterialPageRoute(
          builder: (_) => ClientPage(user: user),
        );

      case professionnelRoute:
        return MaterialPageRoute(builder: (_) => const ProfessionnelPage());

      case politiqueConfRoute:
        return MaterialPageRoute(builder: (_) => PolitiqueConfidentialite());

      case contiditionUtilisationRoute:
        return MaterialPageRoute(builder: (_) => const ConditionUtilisation());

      default:
        return MaterialPageRoute(
          builder: (_) => const LoginPage(),
        );
    }
  }
}
