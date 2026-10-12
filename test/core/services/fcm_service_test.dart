import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nanei/core/constants/storage_keys.dart';
import 'package:nanei/core/services/fcm_service.dart';
import 'package:nanei/core/services/token_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../helpers/dio_espion.dart';
import '../../helpers/environnement.dart';

/// Envoi du jeton de notification (FCM) au back — appel `sl<Dio>()` direct.
///
/// ## Ce que ce fichier rend impossible
///
///  - un jeton envoyé ailleurs que `POST /account/fcm-token`, ou sous un
///    autre nom que `fcm_token` (`account.controller.js` répond alors
///    « fcm_token est requis » et l'utilisateur ne reçoit plus AUCUNE
///    notification de colis) ;
///  - un envoi anonyme (sans `Authorization`) : 401 assuré ;
///  - un jeton perdu sur une panne : il doit être gardé « en attente » et
///    renvoyé au démarrage suivant.
void main() {
  late DioEspion espion;

  setUpAll(initialiserEnvironnementDeTest);

  setUp(() async {
    await viderSl();
    SharedPreferences.setMockInitialValues({});
    FlutterSecureStorage.setMockInitialValues({StorageKeys.jwtToken: 'jwt-1'});
    espion = DioEspion();
    remplacerDansSl<Dio>(dioDeTest(espion));
    remplacerDansSl<TokenService>(
        TokenService(secureStorage: const FlutterSecureStorage()));
  });

  tearDown(viderSl);

  test('POST /account/fcm-token { fcm_token } avec le jeton de session', () async {
    espion.repond({'message': 'FCM token enregistré'});

    final ok = await FcmService.envoyerTokenAuBackendPourTest('fcm-abc');

    expect(ok, isTrue);
    expect(espion.appel, 'POST /account/fcm-token');
    expect(corpsEnvoye(espion.requete), {'fcm_token': 'fcm-abc'});
    expect(espion.requete.headers['Authorization'], 'Bearer jwt-1');
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString(StorageKeys.fcmTokenPending), isNull);
  });

  test('échec du serveur : jeton conservé pour le prochain démarrage', () async {
    espion.repondErreur(500, corps: {'message': 'Erreur serveur'});

    final ok = await FcmService.envoyerTokenAuBackendPourTest('fcm-abc');

    expect(ok, isFalse);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString(StorageKeys.fcmTokenPending), 'fcm-abc');
  });

  test('pas de session : aucun envoi', () async {
    FlutterSecureStorage.setMockInitialValues({});
    final ok = await FcmService.envoyerTokenAuBackendPourTest('fcm-abc');
    expect(ok, isFalse);
    expect(espion.requetes, isEmpty);
  });
}
