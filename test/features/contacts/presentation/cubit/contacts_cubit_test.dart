import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:nanei/core/utils/app_logger.dart';
import 'package:nanei/core/utils/pagination.dart';
import 'package:nanei/features/contacts/domain/entities/contact_favori.dart';
import 'package:nanei/features/contacts/domain/usecases/create_contact.dart';
import 'package:nanei/features/contacts/domain/usecases/delete_contact.dart';
import 'package:nanei/features/contacts/domain/usecases/get_contacts.dart';
import 'package:nanei/features/contacts/presentation/cubit/contacts_cubit.dart';
import 'package:nanei/features/contacts/presentation/cubit/contacts_state.dart';
import 'package:dio/dio.dart';

class MockGetContacts extends Mock implements GetContacts {}

class MockCreateContact extends Mock implements CreateContact {}

class MockDeleteContact extends Mock implements DeleteContact {}

const _c1 = ContactFavori(id: '1', nom: 'Diallo', prenom: 'Awa', telephone: '70');

PageResultat<ContactFavori> _page(int page, List<ContactFavori> elements,
        {required int total, required int pages}) =>
    PageResultat(
      elements: elements,
      pagination:
          InfoPagination(page: page, limit: kTaillePage, total: total, pages: pages),
    );

void main() {
  setUpAll(() {
    AppLogger.init();
    registerFallbackValue(<String, dynamic>{});
  });

  late MockGetContacts get;
  late MockCreateContact create;
  late MockDeleteContact delete;

  setUp(() {
    get = MockGetContacts();
    create = MockCreateContact();
    delete = MockDeleteContact();
  });

  ContactsCubit build() =>
      ContactsCubit(getContacts: get, createContact: create, deleteContact: delete);

  blocTest<ContactsCubit, ContactsState>(
    'charge la page demandée avec la taille de page commune',
    build: () {
      when(() => get(page: 2, limit: kTaillePage))
          .thenAnswer((_) async => _page(2, [_c1], total: 21, pages: 2));
      return build();
    },
    act: (c) => c.loadContacts(page: 2),
    expect: () => [
      isA<ContactsLoading>(),
      isA<ContactsLoaded>()
          .having((s) => s.pagination.page, 'page', 2)
          .having((s) => s.pagination.pages, 'pages', 2),
    ],
    verify: (c) => expect(c.pageCourante, 2),
  );

  blocTest<ContactsCubit, ContactsState>(
    'suppression du dernier contact de la page 2 → revient à la page 1',
    build: () {
      when(() => delete('1')).thenAnswer((_) async {});
      when(() => get(page: 2, limit: kTaillePage))
          .thenAnswer((_) async => _page(2, [], total: 20, pages: 1));
      when(() => get(page: 1, limit: kTaillePage))
          .thenAnswer((_) async => _page(1, [_c1], total: 20, pages: 1));
      return build();
    },
    act: (c) async {
      // Simule « on est sur la page 2 » puis la suppression.
      when(() => get(page: 2, limit: kTaillePage)).thenAnswer(
          (_) async => _page(2, [_c1], total: 21, pages: 2));
      await c.loadContacts(page: 2);
      when(() => get(page: 2, limit: kTaillePage))
          .thenAnswer((_) async => _page(2, [], total: 20, pages: 1));
      await c.supprimerContact('1');
    },
    skip: 2,
    expect: () => [
      isA<ContactsLoading>(),
      isA<ContactsLoaded>().having((s) => s.pagination.page, 'page', 1),
    ],
    verify: (c) => expect(c.pageCourante, 1),
  );

  blocTest<ContactsCubit, ContactsState>(
    'erreur du serveur : le MESSAGE du back, pas « DioException [...] »',
    build: () {
      when(() => get(page: any(named: 'page'), limit: any(named: 'limit')))
          .thenThrow(DioException(
        requestOptions: RequestOptions(path: '/contacts'),
        response: Response(
          requestOptions: RequestOptions(path: '/contacts'),
          statusCode: 429,
          data: {'message': 'Trop de requêtes. Veuillez réessayer dans quelques minutes.'},
        ),
        type: DioExceptionType.badResponse,
      ));
      return build();
    },
    act: (c) => c.loadContacts(),
    expect: () => [
      isA<ContactsLoading>(),
      isA<ContactsError>().having((s) => s.message, 'message',
          'Trop de requêtes. Veuillez réessayer dans quelques minutes.'),
    ],
  );

  blocTest<ContactsCubit, ContactsState>(
    'coupure réseau : message compréhensible',
    build: () {
      when(() => get(page: any(named: 'page'), limit: any(named: 'limit')))
          .thenThrow(DioException.connectionError(
              requestOptions: RequestOptions(path: '/contacts'), reason: 'off'));
      return build();
    },
    act: (c) => c.loadContacts(),
    expect: () => [
      isA<ContactsLoading>(),
      isA<ContactsError>().having((s) => s.message, 'message',
          contains('Impossible de joindre le serveur')),
    ],
  );

  test('ajout : true puis rechargement ; échec : false sans rechargement', () async {
    when(() => create(any())).thenAnswer((_) async =>
        const ContactFavori(id: 'n', nom: 'N', prenom: '', telephone: ''));
    when(() => get(page: any(named: 'page'), limit: any(named: 'limit')))
        .thenAnswer((_) async => _page(1, [_c1], total: 1, pages: 1));
    final c = build();
    expect(await c.ajouterContact({'nom': 'N'}), isTrue);
    verify(() => get(page: 1, limit: kTaillePage)).called(1);

    when(() => create(any())).thenThrow(Exception('refus'));
    expect(await c.ajouterContact({'nom': ''}), isFalse);
    verifyNever(() => get(page: any(named: 'page'), limit: any(named: 'limit')));
    await c.close();
  });
}
