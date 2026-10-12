import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:nanei/core/utils/app_logger.dart';
import 'package:nanei/core/utils/pagination.dart';
import 'package:nanei/features/paiement/domain/entities/paiement.dart';
import 'package:nanei/features/paiement/domain/usecases/get_mes_paiements.dart';
import 'package:nanei/features/paiement/domain/usecases/initier_paiement.dart';
import 'package:nanei/features/paiement/presentation/bloc/paiement_bloc.dart';
import 'package:nanei/features/paiement/presentation/bloc/paiement_event.dart';
import 'package:nanei/features/paiement/presentation/bloc/paiement_state.dart';
import 'package:nanei/core/errors/failure.dart';

class MockGetMesPaiements extends Mock implements GetMesPaiements {}

class MockInitierPaiement extends Mock implements InitierPaiement {}

void main() {
  setUpAll(AppLogger.init);

  late MockGetMesPaiements get;

  setUp(() => get = MockGetMesPaiements());

  blocTest<PaiementBloc, PaiementState>(
    'passe le filtre statut au serveur et expose par_statut',
    build: () {
      when(() => get(page: 1, limit: kTaillePage, statut: 'paye')).thenAnswer(
        (_) async => const Right(PageResultat<Paiement>(
          elements: [],
          pagination: InfoPagination(page: 1, limit: 20, total: 0, pages: 1),
          parStatut: {'paye': 10, 'en_attente': 4, 'echoue': 2, 'total': 17},
        )),
      );
      return PaiementBloc(
          getMesPaiements: get, initierPaiement: MockInitierPaiement());
    },
    act: (b) => b.add(LoadMesPaiements(page: 1, statut: 'paye')),
    expect: () => [
      isA<PaiementLoading>(),
      isA<PaiementLoaded>()
          .having((s) => s.statut, 'statut', 'paye')
          .having((s) => s.compte('paye'), 'payés', 10)
          .having((s) => s.compte('en_attente') + s.compte('echoue'),
              'en attente', 6),
    ],
  );

  blocTest<PaiementBloc, PaiementState>(
    'initiation : URL prête, ou message d’erreur du back',
    build: () {
      final initier = MockInitierPaiement();
      when(() => initier(colisId: 'c-1', moyenPaiement: 'wave'))
          .thenAnswer((_) async => const Right('https://pay.wave.com/c/x'));
      when(() => initier(colisId: 'c-2', moyenPaiement: 'wave')).thenAnswer(
          (_) async => Left(ServerFailure(errorMessage: 'Ce colis est déjà payé')));
      return PaiementBloc(getMesPaiements: get, initierPaiement: initier);
    },
    act: (b) => b
      ..add(InitierPaiementEvent(colisId: 'c-1', moyenPaiement: 'wave'))
      ..add(InitierPaiementEvent(colisId: 'c-2', moyenPaiement: 'wave')),
    expect: () => [
      isA<PaiementInitiating>(),
      isA<PaiementUrlReady>()
          .having((s) => s.checkoutUrl, 'url', 'https://pay.wave.com/c/x'),
      isA<PaiementInitiating>(),
      isA<PaiementInitiationError>()
          .having((s) => s.message, 'message', 'Ce colis est déjà payé'),
    ],
  );

  blocTest<PaiementBloc, PaiementState>(
    'échec du chargement : PaiementError avec le message ; Refresh garde le filtre',
    build: () {
      when(() => get(page: any(named: 'page'), limit: kTaillePage, statut: 'echoue'))
          .thenAnswer((_) async => Left(ServerFailure(errorMessage: 'Impossible de joindre le serveur.')));
      return PaiementBloc(getMesPaiements: get, initierPaiement: MockInitierPaiement());
    },
    act: (b) async {
      b.add(LoadMesPaiements(page: 1, statut: 'echoue'));
      await Future<void>.delayed(Duration.zero);
      b.add(RefreshPaiements());
    },
    expect: () => [
      isA<PaiementLoading>(),
      isA<PaiementError>().having((s) => s.message, 'message', 'Impossible de joindre le serveur.'),
      isA<PaiementLoading>(),
      isA<PaiementError>(),
    ],
    verify: (_) => verify(() => get(page: 1, limit: kTaillePage, statut: 'echoue')).called(2),
  );
}
