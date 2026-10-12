import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nanei/core/config/env.dart';
import 'package:nanei/core/routes/app_router.dart';
import 'package:nanei/features/auth/presentation/pages/forgot_password_page.dart';
import 'package:nanei/features/auth/presentation/pages/reset_password_page.dart';

import '../../../../helpers/dio_espion.dart';
import '../../../../helpers/environnement.dart';
import '../../../../helpers/pompe_page.dart';

/// Parcours « mot de passe oublié » : deux écrans qui appellent `sl<Dio>()`
/// directement.
///
/// ## Ce que ce fichier rend impossible
///
///  - un code demandé ou un mot de passe changé sur une autre route que
///    `POST /auth/oublier-password` / `POST /auth/reset-password`, ou avec
///    d'autres noms de champs que `email` / `code` / `mot_de_passe`
///    (`resetPasswordSchema` : Joi `stripUnknown` retirerait le champ
///    inconnu, et le back répondrait « Données invalides ») ;
///  - un refus du back (code incorrect, 429 de la limite par e-mail) perdu
///    derrière un message générique ;
///  - un BOUTON BLOQUÉ en chargement quand la réponse d'erreur n'est pas du
///    JSON (page HTML d'un proxy) : `data['message']` sur une chaîne levait
///    une exception hors du `catch`.
void main() {
  late DioEspion espion;

  setUpAll(initialiserEnvironnementDeTest);

  setUp(() async {
    await viderSl();
    espion = DioEspion();
    remplacerDansSl<Dio>(dioDeTest(espion));
  });

  tearDown(viderSl);

  group('ForgotPasswordPage', () {
    Future<List<RouteSettings>> monter(WidgetTester tester) async {
      final routes = <RouteSettings>[];
      await pomperPage(
        tester,
        const ForgotPasswordPage(),
        onGenerateRoute: (s) {
          routes.add(s);
          return MaterialPageRoute(
              builder: (_) => const Scaffold(body: Text('écran suivant')));
        },
      );
      return routes;
    }

    testWidgets('POST /auth/oublier-password { email } puis écran du code',
        (tester) async {
      espion.repond({
        'success': true,
        'message': 'Si un compte existe avec cet email, un code de réinitialisation a été envoyé.',
      });
      final routes = await monter(tester);

      await tester.enterText(find.byType(TextFormField), ' awa@exemple.ml ');
      await tester.tap(find.text('Envoyer le code'));
      await laisserRepondre(tester);

      expect(espion.appel, 'POST ${Env.authOublierPassword}');
      expect(Env.authOublierPassword, '/auth/oublier-password');
      // Client Dio COMMUN : baseUrl (préfixe /nanei compris) appliqué une fois.
      expect(espion.requete.uri.toString(),
          '$baseUrlDeTest/auth/oublier-password');
      expect(corpsEnvoye(espion.requete), {'email': 'awa@exemple.ml'});
      expect(routes.single.name, AppRouter.resetPasswordRoute);
      expect(routes.single.arguments, 'awa@exemple.ml');
    });

    testWidgets('e-mail invalide : aucun appel', (tester) async {
      await monter(tester);
      await tester.enterText(find.byType(TextFormField), 'awa@');
      await tester.tap(find.text('Envoyer le code'));
      await tester.pump();
      expect(espion.requetes, isEmpty);
      expect(find.text('Email invalide'), findsOneWidget);
    });

    testWidgets('400 Joi : détail de validation affiché', (tester) async {
      espion.repondErreur(400, corps: {
        'message': 'Données invalides',
        'details': ['"email" must be a valid email'],
      });
      await monter(tester);
      await tester.enterText(find.byType(TextFormField), 'awa@exemple.ml');
      await tester.tap(find.text('Envoyer le code'));
      await laisserRepondre(tester);

      expect(find.text('"email" must be a valid email'), findsOneWidget);
    });

    testWidgets('429 de la limite par e-mail : message du back', (tester) async {
      espion.repondErreur(429, corps: {
        'success': false,
        'message': 'Trop de tentatives pour cet email. Réessayez dans 15 minutes.',
      });
      await monter(tester);
      await tester.enterText(find.byType(TextFormField), 'awa@exemple.ml');
      await tester.tap(find.text('Envoyer le code'));
      await laisserRepondre(tester);

      expect(find.text('Trop de tentatives pour cet email. Réessayez dans 15 minutes.'),
          findsOneWidget);
      expect(find.text('Envoyer le code'), findsOneWidget);
    });

    testWidgets('502 en HTML : message de repli et bouton de nouveau actif',
        (tester) async {
      espion.repondTexte('<html><body>502 Bad Gateway</body></html>', statut: 502);
      await monter(tester);
      await tester.enterText(find.byType(TextFormField), 'awa@exemple.ml');
      await tester.tap(find.text('Envoyer le code'));
      await laisserRepondre(tester);

      expect(tester.takeException(), isNull);
      expect(find.text('Une erreur est survenue. Vérifiez votre connexion.'),
          findsOneWidget);
      // Plus d'indicateur : l'utilisateur peut réessayer.
      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(find.text('Envoyer le code'), findsOneWidget);
    });
  });

  group('ResetPasswordPage', () {
    Future<List<RouteSettings>> monter(WidgetTester tester) async {
      final routes = <RouteSettings>[];
      await pomperPage(
        tester,
        const ResetPasswordPage(email: 'awa@exemple.ml'),
        onGenerateRoute: (s) {
          routes.add(s);
          return MaterialPageRoute(
              builder: (_) => const Scaffold(body: Text('connexion')));
        },
      );
      return routes;
    }

    Future<void> remplir(WidgetTester tester,
        {String code = '123456', String mdp = 'Colis-Bamako-2026'}) async {
      final champs = find.byType(TextFormField);
      await tester.enterText(champs.at(0), code);
      await tester.enterText(champs.at(1), mdp);
      await tester.enterText(champs.at(2), mdp);
      await tester.ensureVisible(find.text('Changer le mot de passe'));
      await tester.tap(find.text('Changer le mot de passe'));
    }

    testWidgets('POST /auth/reset-password { email, code, mot_de_passe } puis connexion',
        (tester) async {
      espion.repond({'success': true, 'message': 'Mot de passe réinitialisé avec succès'});
      final routes = await monter(tester);

      await remplir(tester);
      await laisserRepondre(tester);

      expect(espion.appel, 'POST ${Env.authResetPassword}');
      expect(Env.authResetPassword, '/auth/reset-password');
      expect(espion.requete.uri.toString(), '$baseUrlDeTest/auth/reset-password');
      expect(corpsEnvoye(espion.requete), {
        'email': 'awa@exemple.ml',
        'code': '123456',
        'mot_de_passe': 'Colis-Bamako-2026',
      });
      expect(routes.single.name, AppRouter.loginRoute);
      await tester.pumpAndSettle(const Duration(seconds: 5));
    });

    testWidgets('code incorrect : message du back (tentatives restantes)',
        (tester) async {
      espion.repondErreur(400, corps: {
        'success': false,
        'message': 'Code incorrect (2 tentatives restantes).',
      });
      final routes = await monter(tester);

      await remplir(tester);
      await laisserRepondre(tester);

      expect(find.text('Code incorrect (2 tentatives restantes).'), findsOneWidget);
      expect(routes, isEmpty);
    });

    testWidgets('429 (motDePasseRateLimit) : message du back', (tester) async {
      espion.repondErreur(429, corps: {
        'message': 'Trop de tentatives. Veuillez réessayer dans 15 minutes.',
      });
      await monter(tester);

      await remplir(tester);
      await laisserRepondre(tester);

      expect(find.text('Trop de tentatives. Veuillez réessayer dans 15 minutes.'),
          findsOneWidget);
    });

    testWidgets('mot de passe trop faible ou code incomplet : aucun appel',
        (tester) async {
      await monter(tester);
      await remplir(tester, code: '123', mdp: 'court');
      await tester.pump();

      expect(espion.requetes, isEmpty);
      expect(find.text('Le code doit contenir 6 chiffres'), findsOneWidget);
      expect(find.text('Minimum 12 caractères'), findsOneWidget);
    });
  });
}
