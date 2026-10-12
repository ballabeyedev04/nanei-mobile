import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nanei/core/constants/storage_keys.dart';
import 'package:nanei/core/routes/app_router.dart';
import 'package:nanei/core/services/token_service.dart';
import 'package:nanei/core/services/verrou_biometrique.dart';
import 'package:nanei/core/theme/theme_cubit.dart';
import 'package:nanei/features/home/presentation/pages/client/profils_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../../helpers/dio_espion.dart';
import '../../../../../helpers/environnement.dart';
import '../../../../../helpers/pompe_page.dart';

/// Écran Profil — cinq appels `sl<Dio>()` directs (`/account/*`).
///
/// ## Ce que ce fichier rend impossible
///
///  - le profil lu ailleurs que `GET /account/me` → `utilisateur` ;
///  - un changement de mot de passe envoyé avec d'autres clés que
///    `oldPassword` / `newPassword` (`changePasswordSchema`), ou qui
///    n'enregistre pas les NOUVEAUX jetons renvoyés : le back révoque toutes
///    les autres sessions, l'application serait déconnectée au prochain
///    appel ;
///  - un refus (« Ancien mot de passe incorrect », `details` Joi) masqué par
///    un message générique — et des jetons écrasés malgré l'échec ;
///  - une modification de profil partie en multipart, sans rechargement ;
///  - une suppression de compte qui laisserait les jetons sur le téléphone.
void main() {
  late DioEspion espion;
  late FlutterSecureStorage stockage;

  setUpAll(initialiserEnvironnementDeTest);

  setUp(() async {
    await viderSl();
    SharedPreferences.setMockInitialValues({});
    FlutterSecureStorage.setMockInitialValues({
      StorageKeys.jwtToken: 'jwt-ancien',
      StorageKeys.refreshToken: 'rt-ancien',
    });
    stockage = const FlutterSecureStorage();
    espion = DioEspion();
    enregistrerDio(dioDeTest(espion));
    remplacerDansSl<TokenService>(TokenService(secureStorage: stockage));
    remplacerDansSl<VerrouBiometrique>(
        VerrouBiometrique(prefs: await SharedPreferences.getInstance()));
    espion.repond({
      'utilisateur': {
        'id': 'u-1',
        'nom': 'Beye',
        'prenom': 'Balla',
        'email': 'balla@exemple.fr',
        'adresse': 'Paris',
        'telephone': '+33600000000',
        'role': 'Particulier',
        'statut': 'actif',
        'photoProfil': null,
      },
    }, pour: 'GET /account/me');
  });

  tearDown(viderSl);

  Future<List<String?>> monter(WidgetTester tester) async {
    final routes = <String?>[];
    final theme = ThemeCubit();
    addTearDown(theme.close);
    await pomperPage(
      tester,
      const ProfilsPage(),
      enveloppe: (app) => BlocProvider<ThemeCubit>.value(value: theme, child: app),
      onGenerateRoute: (s) {
        routes.add(s.name);
        return MaterialPageRoute(builder: (_) => const Scaffold(body: Text('login')));
      },
    );
    await laisserRepondre(tester);
    return routes;
  }

  Future<void> ouvrirTuile(WidgetTester tester, String libelle) async {
    await tester.scrollUntilVisible(find.text(libelle), 200,
        scrollable: find.byType(Scrollable).first);
    await tester.ensureVisible(find.text(libelle));
    await tester.pumpAndSettle();
    await tester.tap(find.text(libelle));
    await tester.pumpAndSettle();
  }

  Future<void> changerMotDePasse(WidgetTester tester) async {
    await ouvrirTuile(tester, 'Changer le mot de passe');
    final champs = find.byType(TextFormField);
    await tester.enterText(champs.at(0), 'Ancien-Secret-1');
    await tester.enterText(champs.at(1), 'Nouveau-Secret-2026');
    await tester.enterText(champs.at(2), 'Nouveau-Secret-2026');
    await tester.ensureVisible(find.text('Modifier le mot de passe'));
    await tester.tap(find.text('Modifier le mot de passe'));
    await laisserRepondre(tester);
  }

  testWidgets('GET /account/me : identité affichée', (tester) async {
    await monter(tester);

    expect(espion.requetePour('/account/me').method, 'GET');
    expect(find.textContaining('balla@exemple.fr'), findsWidgets);
    expect(find.textContaining('Balla'), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  testWidgets('mot de passe : PUT { oldPassword, newPassword } et NOUVEAUX jetons gardés',
      (tester) async {
    espion.repond({
      'message': 'Mot de passe modifié avec succès',
      'token': 'jwt-neuf',
      'refreshToken': 'rt-neuf',
    }, pour: 'PUT /account/change-password');
    await monter(tester);

    await changerMotDePasse(tester);

    final r = espion.requetePour('/account/change-password');
    expect(r.method, 'PUT');
    expect(corpsEnvoye(r),
        {'oldPassword': 'Ancien-Secret-1', 'newPassword': 'Nouveau-Secret-2026'});
    expect(await stockage.read(key: StorageKeys.jwtToken), 'jwt-neuf');
    expect(await stockage.read(key: StorageKeys.refreshToken), 'rt-neuf');
    await laisserToastSeFermer(tester);
  });

  testWidgets('mot de passe refusé (400) : message du back, jetons intacts',
      (tester) async {
    espion.repondErreur(400,
        corps: {'message': 'Ancien mot de passe incorrect'},
        pour: 'PUT /account/change-password');
    await monter(tester);

    await changerMotDePasse(tester);

    expect(find.text('Ancien mot de passe incorrect'), findsOneWidget);
    expect(await stockage.read(key: StorageKeys.jwtToken), 'jwt-ancien');
    expect(await stockage.read(key: StorageKeys.refreshToken), 'rt-ancien');
    await laisserToastSeFermer(tester);
  });

  testWidgets('mot de passe trop faible : aucun appel', (tester) async {
    await monter(tester);
    await ouvrirTuile(tester, 'Changer le mot de passe');
    final champs = find.byType(TextFormField);
    await tester.enterText(champs.at(0), 'x');
    await tester.enterText(champs.at(1), 'faible');
    await tester.enterText(champs.at(2), 'faible');
    await tester.ensureVisible(find.text('Modifier le mot de passe'));
    await tester.tap(find.text('Modifier le mot de passe'));
    await tester.pump();

    expect(espion.appels.where((a) => a.contains('change-password')), isEmpty);
    expect(find.text('Minimum 12 caractères'), findsOneWidget);
  });

  testWidgets('profil : PUT JSON (champs du modifierProfilSchema) puis rechargement',
      (tester) async {
    espion.repond({'message': 'Profil mis à jour', 'utilisateur': {}},
        pour: 'PUT /account/modifier-profil');
    await monter(tester);

    await ouvrirTuile(tester, 'Modifier mon profil');
    await tester.enterText(find.widgetWithText(TextFormField, 'Adresse'), 'Bamako');
    await tester.ensureVisible(find.text('Enregistrer'));
    await tester.tap(find.text('Enregistrer'));
    await laisserRepondre(tester);

    final r = espion.requetePour('/account/modifier-profil');
    expect(r.method, 'PUT');
    expect(r.data, isNot(isA<FormData>()));
    expect(corpsEnvoye(r), {
      'nom': 'Beye',
      'prenom': 'Balla',
      'email': 'balla@exemple.fr',
      'adresse': 'Bamako',
      'telephone': '+33600000000',
    });
    expect(espion.appels.where((a) => a == 'GET /account/me'), hasLength(2));
    await laisserToastSeFermer(tester);
  });

  testWidgets('suppression : DELETE /account, jetons effacés, retour connexion',
      (tester) async {
    espion.repond({'message': 'Compte supprimé'}, pour: 'DELETE /account');
    final routes = await monter(tester);

    await ouvrirTuile(tester, 'Supprimer mon compte');
    await tester.tap(find.text('Supprimer'));
    await laisserRepondre(tester);

    expect(espion.appels, contains('DELETE /account'));
    expect(await stockage.read(key: StorageKeys.jwtToken), isNull);
    expect(await stockage.read(key: StorageKeys.refreshToken), isNull);
    expect(routes, contains(AppRouter.loginRoute));
  });

  testWidgets('photo : PUT multipart, champ photoProfil typé image/jpeg',
      (tester) async {
    final dossier = Directory.systemTemp.createTempSync('photo_profil');
    addTearDown(() {
      // Sous Windows, le flux multipart peut encore tenir le fichier : le
      // dossier temporaire sera alors nettoyé par le système.
      try {
        dossier.deleteSync(recursive: true);
      } on FileSystemException {
        // ignoré
      }
    });
    final photo = File('${dossier.path}/moi.jpg')..writeAsBytesSync([1, 2, 3]);
    final messager =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    const canal = MethodChannel('plugins.flutter.io/image_picker');
    messager.setMockMethodCallHandler(canal, (_) async => photo.path);
    addTearDown(() => messager.setMockMethodCallHandler(canal, null));
    espion.repond({
      'message': 'Profil mis à jour',
      'utilisateur': {'id': 'u-1', 'nom': 'Beye', 'prenom': 'Balla', 'photoProfil': 'https://cdn.test/p.jpg'},
    }, pour: 'PUT /account/modifier-profil');
    await monter(tester);

    await tester.tap(find.byIcon(Icons.photo_camera_rounded));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Choisir dans la galerie'));
    await attendreAvecEntreesSorties(
        tester, () => espion.appels.contains('PUT /account/modifier-profil'));

    final r = espion.requetePour('/account/modifier-profil');
    expect(r.method, 'PUT');
    expect(r.headers[Headers.contentTypeHeader],
        startsWith('multipart/form-data; boundary='));
    final fd = r.data as FormData;
    expect(fd.files.single.key, 'photoProfil');
    expect(fd.files.single.value.contentType.toString(), 'image/jpeg');
    // Fin de l'envoi (vraies E/S), puis expiration du toast.
    await attendreAvecEntreesSorties(tester,
        () => find.byType(CircularProgressIndicator).evaluate().isEmpty);
    await tester.pump(const Duration(seconds: 10));
  });
}
