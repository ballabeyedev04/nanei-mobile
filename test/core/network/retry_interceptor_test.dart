import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nanei/core/network/retry_interceptor.dart';

import '../../helpers/dio_espion.dart';

/// Nouvel essai automatique sur coupure réseau.
///
/// ## Ce que ce fichier rend impossible
///
///  - rejouer une requête que le SERVEUR a refusée (400, 401, 500) : un
///    `POST /client/envoie-colis` rejoué après un 500 pourrait créer deux
///    colis ; un 401 est l'affaire de l'intercepteur d'authentification ;
///  - abandonner au premier hoquet réseau (réseau mobile instable).
void main() {
  late DioEspion espion;
  late Dio dio;

  setUp(() {
    espion = DioEspion();
    dio = dioDeTest(espion);
    // Un seul essai supplémentaire (délai 1 s) : suffisant pour vérifier le
    // comportement sans allonger la suite.
    dio.interceptors.add(RetryInterceptor(dio: dio, maxRetries: 1));
  });

  test('coupure réseau puis succès : la requête aboutit', () async {
    espion.coupeReseau();
    espion.repond({'ok': true});

    final r = await dio.get('/client/colis-envoyes');

    expect(r.data, {'ok': true});
    expect(espion.requetes, hasLength(2));
  });

  test('coupure persistante : abandon après maxRetries', () async {
    espion.coupeReseau();

    await expectLater(dio.get('/x'),
        throwsA(isA<DioException>().having((e) => e.type, 'type',
            DioExceptionType.connectionError)));
    expect(espion.requetes, hasLength(2));
  });

  for (final statut in [400, 401, 500]) {
    test('$statut du serveur : jamais rejoué', () async {
      espion.repondErreur(statut, corps: {'message': 'refus'});
      await expectLater(dio.post('/client/envoie-colis'), throwsA(isA<DioException>()));
      expect(espion.requetes, hasLength(1));
    });
  }
}
