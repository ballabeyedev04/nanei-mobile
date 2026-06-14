import 'package:flutter/material.dart';
import 'package:francomalishipp/features/auth/presentation/pages/login_page.dart';
import 'package:francomalishipp/features/auth/presentation/pages/register_page.dart';
import 'package:francomalishipp/features/home/presentation/pages/client/main_client_page.dart';
import 'package:francomalishipp/features/auth/domain/entities/user.dart';
import 'package:francomalishipp/features/home/presentation/pages/client/envoi_colis_page.dart';

class AppRouter {
  static const String loginRoute = '/login';
  static const String registerRoute = '/register';
  static const String homeRoute = '/home';
  static const String clientRoute = '/client';
  static const String envoieColiRoute = '/envoie-colis';

  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case loginRoute:
        return MaterialPageRoute(builder: (_) => LoginPage());

      case registerRoute:
        return MaterialPageRoute(builder: (_) => const RegisterPage());


      case clientRoute:
        final user = settings.arguments as User?;
        return MaterialPageRoute(
          builder: (_) => MainClientPage(user: user),
        );

      case envoieColiRoute:
        return MaterialPageRoute(builder: (_) => const EnvoiColisPage());
      default:
        return MaterialPageRoute(
          builder: (_) => const LoginPage(),
        );
    }
  }
}