import 'package:bloc_test/bloc_test.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:nanei/core/utils/app_logger.dart';
import 'package:nanei/core/utils/pagination.dart';
import 'package:nanei/features/reclamations/domain/entities/reclamation_entity.dart';
import 'package:nanei/features/reclamations/domain/repositories/reclamation_repository.dart';
import 'package:nanei/features/reclamations/presentation/cubit/reclamations_cubit.dart';
import 'package:nanei/features/reclamations/presentation/cubit/reclamations_state.dart';

class _Depot extends Mock implements ReclamationRepository {}

/// Le cubit Réclamations.
///
/// ## Ce que ce fichier rend impossible
///
///  - une réclamation refusée par le back (« Ce colis ne vous appartient
///    pas », « Type de réclamation invalide ») affichée avec un texte
///    générique, ou pire, l'écran fermé comme si elle était partie ;
///  - une page vide affichée après la résolution de la dernière réclamation
///    d'une page (repli sur la dernière page existante).
void main() {
  setUpAll(() {
    AppLogger.init();
    registerFallbackValue(<String>[]);
  });

  late _Depot depot;
  setUp(() => depot = _Depot());

  ReclamationEntity rec(String id) => ReclamationEntity(
        id: id,
        colisId: 'c',
        type: 'perdu',
        description: 'd',
        statut: 'ouverte',
        photos: const [],
        createdAt: DateTime(2026, 10, 1),
      );

  PageResultat<ReclamationEntity> page(int n, List<ReclamationEntity> e, {int pages = 2}) =>
      PageResultat(
          elements: e,
          pagination: InfoPagination(page: n, limit: kTaillePage, total: 21, pages: pages));

  blocTest<ReclamationsCubit, ReclamationsState>(
    'page vide demandée → repli sur la dernière page existante',
    build: () {
      when(() => depot.getReclamations(page: 3, limit: kTaillePage))
          .thenAnswer((_) async => page(3, [], pages: 2));
      when(() => depot.getReclamations(page: 2, limit: kTaillePage))
          .thenAnswer((_) async => page(2, [rec('r21')]));
      return ReclamationsCubit(repository: depot);
    },
    act: (c) => c.loadReclamations(page: 3),
    expect: () => [
      isA<ReclamationsLoading>(),
      isA<ReclamationsLoaded>()
          .having((s) => s.pagination.page, 'page', 2)
          .having((s) => s.reclamations.single.id, 'id', 'r21'),
    ],
    verify: (c) => expect(c.pageCourante, 2),
  );

  blocTest<ReclamationsCubit, ReclamationsState>(
    'création réussie : ReclamationEnvoyee, et `true` pour fermer l’écran',
    build: () {
      when(() => depot.creerReclamation(
              colisId: 'c-1', type: 'endommagé', description: 'd', photos: const ['a.jpg']))
          .thenAnswer((_) async => rec('r1'));
      return ReclamationsCubit(repository: depot);
    },
    act: (c) async => expect(
        await c.creerReclamation(
            colisId: 'c-1', type: 'endommagé', description: 'd', photos: const ['a.jpg']),
        isTrue),
    expect: () => [isA<ReclamationEnvoi>(), isA<ReclamationEnvoyee>()],
  );

  blocTest<ReclamationsCubit, ReclamationsState>(
    'refus 403 : message du back, `false` (l’écran reste ouvert)',
    build: () {
      when(() => depot.creerReclamation(
            colisId: any(named: 'colisId'),
            type: any(named: 'type'),
            description: any(named: 'description'),
            photos: any(named: 'photos'),
          )).thenThrow(DioException(
        requestOptions: RequestOptions(path: '/reclamations'),
        response: Response(
          requestOptions: RequestOptions(path: '/reclamations'),
          statusCode: 403,
          data: {'success': false, 'message': 'Ce colis ne vous appartient pas'},
        ),
        type: DioExceptionType.badResponse,
      ));
      return ReclamationsCubit(repository: depot);
    },
    act: (c) async => expect(
        await c.creerReclamation(colisId: 'c', type: 'perdu', description: 'd', photos: const []),
        isFalse),
    expect: () => [
      isA<ReclamationEnvoi>(),
      isA<ReclamationsError>()
          .having((s) => s.message, 'message', 'Ce colis ne vous appartient pas'),
    ],
  );

  blocTest<ReclamationsCubit, ReclamationsState>(
    'liste en panne réseau : message compréhensible',
    build: () {
      when(() => depot.getReclamations(page: any(named: 'page'), limit: any(named: 'limit')))
          .thenThrow(DioException.connectionError(
              requestOptions: RequestOptions(path: '/reclamations'), reason: 'off'));
      return ReclamationsCubit(repository: depot);
    },
    act: (c) => c.loadReclamations(),
    expect: () => [
      isA<ReclamationsLoading>(),
      isA<ReclamationsError>().having(
          (s) => s.message, 'message', contains('Impossible de joindre le serveur')),
    ],
  );
}
