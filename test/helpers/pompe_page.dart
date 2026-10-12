import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

/// Échafaudage commun aux tests d'écran.
///
/// ## Le problème de GoogleFonts, et pourquoi on ne l'évite pas
///
/// Presque chaque texte de l'application passe par
/// `GoogleFonts.plusJakartaSans(...)`. En test, le paquet cherche la police
/// dans les assets, puis la TÉLÉCHARGE ; `flutter_test` renvoie un 400 à
/// toute requête HTTP, le chargement échoue et l'erreur asynchrone fait
/// tomber le test — pour une raison sans rapport avec l'écran vérifié.
///
/// Plutôt que de renoncer à tester ces écrans, [neutraliserGoogleFonts] :
///  1. interdit tout téléchargement (`allowRuntimeFetching = false`) : aucun
///     appel réseau réel, jamais ;
///  2. déclare dans le manifeste d'assets de TEST des fichiers
///     `PlusJakartaSans-<Graisse>.ttf`, servis avec une POLICE DE REPLI :
///     Roboto, livrée avec le SDK Flutter (`bin/cache/artifacts/
///     material_fonts`), dans la graisse la plus proche. Ses métriques sont
///     celles d'une vraie police de texte : un débordement (`RenderFlex
///     overflowed`) détecté en test existe aussi sur un vrai téléphone. Si le
///     SDK n'est pas trouvé, `MaterialIcons-Regular.otf` (toujours présente
///     dans les assets de test) sert de dernier recours.
///
/// Rien n'est ajouté au `pubspec.yaml` : l'application livrée est inchangée.
void neutraliserGoogleFonts() {
  GoogleFonts.config.allowRuntimeFetching = false;
  final dossier = Platform.environment['UNIT_TEST_ASSETS'];
  if (dossier == null) return;

  const familles = ['PlusJakartaSans'];
  const graisses = [
    'Thin', 'ExtraLight', 'Light', 'Regular', 'Medium',
    'SemiBold', 'Bold', 'ExtraBold', 'Black',
  ];
  // Asset déclaré → fichier Roboto de même graisse (et même style).
  final polices = <String, File>{};
  final roboto = _dossierRoboto();
  final dernierRecours = File('$dossier/fonts/MaterialIcons-Regular.otf');
  File repli(String graisse, bool italique) {
    if (roboto == null) return dernierRecours;
    final g = _grasseRoboto[graisse]!;
    final nom = italique ? (g == 'regular' ? 'italic' : '${g}italic') : g;
    final f = File('${roboto.path}/roboto-$nom.ttf');
    return f.existsSync() ? f : dernierRecours;
  }

  for (final f in familles) {
    for (final g in graisses) {
      polices['polices_test/$f-$g.ttf'] = repli(g, false);
      polices['polices_test/$f-${g == 'Regular' ? '' : g}Italic.ttf'] =
          repli(g, true);
    }
  }

  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMessageHandler('flutter/assets', (ByteData? message) {
    final cle = utf8.decode(message!.buffer
        .asUint8List(message.offsetInBytes, message.lengthInBytes));
    final police = polices[cle];
    if (police != null) {
      return SynchronousFuture(_octets(police.readAsBytesSync()));
    }
    final fichier = File('$dossier/$cle');
    if (!fichier.existsSync()) return Future.value(null);
    final octets = fichier.readAsBytesSync();
    if (cle == 'AssetManifest.bin') {
      final manifeste = Map<Object?, Object?>.from(
          const StandardMessageCodec().decodeMessage(_octets(octets)) as Map);
      for (final p in polices.keys) {
        manifeste[p] = [
          {'asset': p}
        ];
      }
      return SynchronousFuture(
          const StandardMessageCodec().encodeMessage(manifeste));
    }
    return SynchronousFuture(_octets(octets));
  });
}

const _grasseRoboto = {
  'Thin': 'thin',
  'ExtraLight': 'thin',
  'Light': 'light',
  'Regular': 'regular',
  'Medium': 'medium',
  'SemiBold': 'medium',
  'Bold': 'bold',
  'ExtraBold': 'black',
  'Black': 'black',
};

/// `<sdk>/bin/cache/artifacts/material_fonts`, retrouvé à partir de
/// l'exécutable `flutter_tester` (`<sdk>/bin/cache/artifacts/engine/<os>/`).
Directory? _dossierRoboto() {
  var d = File(Platform.resolvedExecutable).parent;
  for (var i = 0; i < 6; i++) {
    final candidat = Directory('${d.path}/material_fonts');
    if (File('${candidat.path}/roboto-regular.ttf').existsSync()) return candidat;
    d = d.parent;
  }
  return null;
}

/// Charge les polices AVANT le premier rendu.
///
/// Sans cela, la première image est mise en page avec la police par défaut
/// de `flutter_test` (chaque glyphe est un carré d'1 em, bien plus large
/// qu'un vrai texte) : de faux `RenderFlex overflowed` apparaissent, puis
/// disparaissent quand la police arrive — mais le test a déjà échoué.
Future<void> prechargerPolices(WidgetTester tester) async {
  await tester.runAsync(() async {
    for (final graisse in FontWeight.values) {
      GoogleFonts.plusJakartaSans(fontWeight: graisse);
      GoogleFonts.plusJakartaSans(fontWeight: graisse, fontStyle: FontStyle.italic);
    }
    await GoogleFonts.pendingFonts();
  });
}

ByteData _octets(List<int> o) => Uint8List.fromList(o).buffer.asByteData();

/// Taille de référence : un téléphone courant. La surface par défaut de
/// `flutter_test` (800×600) n'existe sur aucun appareil.
const Size ecranTelephone = Size(390, 844);

/// Monte [page] dans une `MaterialApp`, polices neutralisées, sur un écran
/// de téléphone. [enveloppe] permet d'insérer des `BlocProvider` au-dessus
/// de la page (au-dessus du `Navigator`, comme dans `main.dart`).
Future<void> pomperPage(
  WidgetTester tester,
  Widget page, {
  Size taille = ecranTelephone,
  Widget Function(Widget app)? enveloppe,
  Map<String, WidgetBuilder> routes = const {},
  RouteFactory? onGenerateRoute,
}) async {
  neutraliserGoogleFonts();
  await prechargerPolices(tester);
  tester.view.physicalSize = taille;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  final app = MaterialApp(
    home: page,
    routes: routes,
    onGenerateRoute: onGenerateRoute,
  );
  await tester.pumpWidget(enveloppe == null ? app : enveloppe(app));
  await tester.pump();
}

/// Laisse aboutir un appel réseau (simulé) et ce qu'il déclenche.
///
/// L'espion répond tout de suite, mais la réponse traverse plusieurs
/// étapes asynchrones de Dio (flux, transformation JSON, intercepteurs), puis
/// l'écran anime un toast. Un seul `pump()` ne suffit pas ; `pumpAndSettle()`
/// non plus quand un indicateur de chargement tourne indéfiniment.
Future<void> laisserRepondre(WidgetTester tester, {int images = 10}) async {
  await tester.pump();
  for (var i = 0; i < images; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

/// Comme [laisserRepondre], quand l'écran fait de VRAIES entrées/sorties
/// (fichier écrit, `MultipartFile.fromFile`) : la zone de test simule le
/// temps et ne les verrait jamais aboutir. On alterne images et attente réelle
/// jusqu'à [condition] (ou ~3 s).
Future<void> attendreAvecEntreesSorties(
    WidgetTester tester, bool Function() condition) async {
  for (var i = 0; i < 60 && !condition(); i++) {
    await tester.pump(const Duration(milliseconds: 20));
    await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 30)));
  }
  await laisserRepondre(tester, images: 3);
}

/// Fait expirer les toasts (toastification) : un minuteur encore en attente à
/// la fin d'un test le fait échouer.
Future<void> laisserToastSeFermer(WidgetTester tester) async {
  await tester.pump(const Duration(seconds: 10));
  await tester.pumpAndSettle();
}

/// Remplace les greffons « fichiers » utilisés par les téléchargements de
/// PDF (facture, étiquette) :
///  - `path_provider` : le dossier temporaire devient [dossier] ;
///  - `open_file` : rien n'est ouvert, le chemin demandé est ajouté à la
///    liste renvoyée, et le greffon répond « done » (ou [resultat]).
///
/// Sans eux, `getTemporaryDirectory()` lève `MissingPluginException` en
/// test et le téléchargement échoue avant même la requête.
List<String> simulerGreffonsFichiers(Directory dossier, {int resultat = 0}) {
  final ouverts = <String>[];
  final messager =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  messager.setMockMethodCallHandler(
      const MethodChannel('plugins.flutter.io/path_provider'), (appel) async {
    return dossier.path;
  });
  messager.setMockMethodCallHandler(const MethodChannel('open_file'),
      (appel) async {
    ouverts.add((appel.arguments as Map)['file_path'] as String);
    return jsonEncode({'type': resultat, 'message': 'test'});
  });
  addTearDown(() {
    messager.setMockMethodCallHandler(
        const MethodChannel('plugins.flutter.io/path_provider'), null);
    messager.setMockMethodCallHandler(const MethodChannel('open_file'), null);
  });
  return ouverts;
}

/// Rappel : un test qui veut prouver que l'écran s'est monté SANS incident
/// termine par `expect(tester.takeException(), isNull);` — `flutter_test`
/// capture les exceptions de construction au lieu de les faire remonter.
