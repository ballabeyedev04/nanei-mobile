import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nanei/features/auth/presentation/pages/login_page.dart';
import 'package:nanei/features/auth/presentation/pages/register_page.dart';
import 'package:nanei/features/home/presentation/pages/client/main_client_page.dart';
import 'package:nanei/features/auth/domain/entities/user.dart';
import 'package:nanei/features/home/presentation/pages/client/envoi_colis_page.dart';
import 'package:nanei/features/onboarding/presentation/pages/onboarding_page.dart';
import 'package:nanei/features/contacts/presentation/pages/contacts_page.dart';
import 'package:nanei/features/contacts/presentation/cubit/contacts_cubit.dart';
import 'package:nanei/features/reclamations/presentation/pages/reclamations_page.dart';
import 'package:nanei/features/reclamations/presentation/cubit/reclamations_cubit.dart';
import 'package:nanei/features/auth/presentation/pages/forgot_password_page.dart';
import 'package:nanei/features/auth/presentation/pages/reset_password_page.dart';
import 'package:nanei/features/avis/presentation/cubit/avis_cubit.dart';
import 'package:nanei/features/avis/presentation/pages/mes_avis_page.dart';
import 'package:nanei/injection_container.dart' as di;
import 'package:nanei/core/utils/security_validators.dart';

class AppRouter {
  static const String loginRoute = '/login';
  static const String registerRoute = '/register';
  static const String homeRoute = '/home';
  static const String clientRoute = '/client';
  static const String envoieColiRoute = '/envoie-colis';
  static const String onboardingRoute = '/onboarding';
  static const String contactsRoute = '/contacts';
  static const String reclamationsRoute = '/reclamations';
  static const String forgotPasswordRoute = '/forgot-password';
  static const String resetPasswordRoute = '/reset-password';
  static const String mesAvisRoute = '/mes-avis';

  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case loginRoute:
        return MaterialPageRoute(builder: (_) => LoginPage());

      case registerRoute:
        return MaterialPageRoute(builder: (_) => const RegisterPage());

      case onboardingRoute:
        return MaterialPageRoute(builder: (_) => const OnboardingPage());

      case clientRoute:
        final user = settings.arguments as User?;
        return MaterialPageRoute(
          builder: (_) => MainClientPage(user: user),
        );

      case envoieColiRoute:
        return MaterialPageRoute(builder: (_) => const EnvoiColisPage());

      case contactsRoute:
        return MaterialPageRoute(
          builder: (_) => BlocProvider(
            create: (_) => di.sl<ContactsCubit>(),
            child: const ContactsPage(),
          ),
        );

      case reclamationsRoute:
        return MaterialPageRoute(
          builder: (_) => BlocProvider(
            create: (_) => di.sl<ReclamationsCubit>(),
            child: const ReclamationsPage(),
          ),
        );

      case forgotPasswordRoute:
        return MaterialPageRoute(builder: (_) => const ForgotPasswordPage());

      case resetPasswordRoute:
        final email = SecurityValidators.validateRouteEmail(settings.arguments);
        if (email == null) {
          return MaterialPageRoute(builder: (_) => const LoginPage());
        }
        return MaterialPageRoute(
          builder: (_) => ResetPasswordPage(email: email),
        );

      case mesAvisRoute:
        return MaterialPageRoute(
          builder: (_) => BlocProvider(
            create: (_) => di.sl<AvisCubit>(),
            child: const MesAvisPage(),
          ),
        );

      default:
        return MaterialPageRoute(
          builder: (_) => const LoginPage(),
        );
    }
  }
}