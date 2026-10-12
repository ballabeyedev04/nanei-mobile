import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:nanei/core/config/env.dart';
import 'package:nanei/features/home/data/datasources/colis_remote_datasource.dart';

class MockDio extends Mock implements Dio {}

Response<dynamic> _reponse(String path, Map<String, dynamic> data) => Response(
      requestOptions: RequestOptions(path: path),
      statusCode: 200,
      data: data,
    );

void main() {
  late MockDio dio;
  late ColisRemoteDataSourceImpl ds;

  setUp(() {
    dio = MockDio();
    ds = ColisRemoteDataSourceImpl(dio: dio);
  });

  test('notifications : envoie page/limit et lit pagination + non_lues',
      () async {
    when(() => dio.get(Env.notificationsMes,
            queryParameters: any(named: 'queryParameters')))
        .thenAnswer((_) async => _reponse(Env.notificationsMes, {
              'data': [
                {'id': 'n1', 'statut': 'lu', 'createdAt': '2026-10-01T10:00:00Z'},
              ],
              'non_lues': 12,
              'pagination': {'page': 2, 'limit': 20, 'total': 41, 'pages': 3},
            }));

    final r = await ds.getNotifications(page: 2, limit: 20);

    verify(() => dio.get(Env.notificationsMes,
        queryParameters: {'page': 2, 'limit': 20})).called(1);
    expect(r.elements.single.id, 'n1');
    expect(r.nonLues, 12); // total toutes pages, pas le calcul sur la page
    expect(r.pagination.page, 2);
    expect(r.pagination.pages, 3);
  });

  test('colis envoyés sans page : aucun paramètre, une seule page', () async {
    when(() => dio.get(Env.colisEnvoyes,
            queryParameters: any(named: 'queryParameters')))
        .thenAnswer((_) async => _reponse(Env.colisEnvoyes, {'data': []}));

    final r = await ds.getColisEnvoyes();

    verify(() => dio.get(Env.colisEnvoyes, queryParameters: const {}))
        .called(1);
    expect(r.elements, isEmpty);
    expect(r.pagination.pages, 1);
  });
  test('colis reçus : envoie statut + page, lit par_statut', () async {
    when(() => dio.get(Env.colisRecus,
            queryParameters: any(named: 'queryParameters')))
        .thenAnswer((_) async => _reponse(Env.colisRecus, {
              'data': [],
              'par_statut': {
                'en_attente': 2,
                'recupere': 0,
                'livre': 7,
                'total': 9,
              },
              'pagination': {'page': 1, 'limit': 20, 'total': 7, 'pages': 1},
            }));

    final r = await ds.getColisRecus(page: 1, limit: 20, statut: 'livre');

    verify(() => dio.get(Env.colisRecus,
        queryParameters: {'page': 1, 'limit': 20, 'statut': 'livre'})).called(1);
    expect(r.compte('livre'), 7);
    expect(r.compte('total'), 9);
    expect(r.pagination.total, 7); // total du filtre
  });

  test("statut 'tous' : paramètre non envoyé", () async {
    when(() => dio.get(Env.colisEnvoyes,
            queryParameters: any(named: 'queryParameters')))
        .thenAnswer((_) async => _reponse(Env.colisEnvoyes, {'data': []}));

    await ds.getColisEnvoyes(page: 2, limit: 20, statut: 'tous');

    verify(() => dio.get(Env.colisEnvoyes,
        queryParameters: {'page': 2, 'limit': 20})).called(1);
  });
}
