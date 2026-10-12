import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:nanei/core/services/taux_change_service.dart';
import 'package:nanei/core/utils/app_logger.dart';
import 'package:nanei/injection_container.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Prépare ce que l'application initialise dans `main()` et dont le code
/// testé a besoin sans qu'on le voie :
///
///  - `AppLogger` (un `late` non initialisé fait planter le premier log, donc
///    le premier bloc qui journalise une erreur — le test échouerait sur le
///    journal, pas sur ce qu'il vérifie) ;
///  - `dotenv` : `Env.authLogin` & co. lisent `.env` ; non chargé, il lève
///    `NotInitializedError`. Chargé VIDE ici, pour que les chemins testés
///    soient les valeurs par défaut du code — celles qui partent en
///    production quand `.env` ne les surcharge pas ;
///  - les stockages (sécurisé et préférences) en mémoire, vides.
Future<void> initialiserEnvironnementDeTest() async {
  await AppLogger.init();
  dotenv.testLoad(fileInput: '');
  FlutterSecureStorage.setMockInitialValues({});
  SharedPreferences.setMockInitialValues({});
}

/// Remplace (ou enregistre) l'instance [T] dans le conteneur `sl`.
///
/// Les pages et les dépôts vont chercher leurs dépendances dans `sl` : un
/// test qui veut contrôler l'une d'elles doit l'y déposer lui-même, et
/// nettoyer derrière lui ([viderSl]) pour ne pas contaminer le suivant.
void remplacerDansSl<T extends Object>(T instance) {
  if (sl.isRegistered<T>()) sl.unregister<T>();
  sl.registerSingleton<T>(instance);
}

/// Vide `sl` entre deux tests.
Future<void> viderSl() => sl.reset();

/// Enregistre le `Dio` de test et ce que les écrans en tirent directement :
/// `TauxChangeService` (les montants s'affichent en € ET en FCFA ; sans lui,
/// la moindre carte de prix lève « TauxChangeService is not registered »).
/// Le taux reste l'officiel (655,957) : aucun appel n'est fait.
void enregistrerDio(Dio dio) {
  remplacerDansSl<Dio>(dio);
  remplacerDansSl<TauxChangeService>(TauxChangeService(dio));
}
