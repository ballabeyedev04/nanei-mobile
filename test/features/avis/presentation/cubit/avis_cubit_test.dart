import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nanei/core/utils/app_logger.dart';
import 'package:mocktail/mocktail.dart';
import 'package:nanei/core/errors/failure.dart';
import 'package:nanei/core/utils/pagination.dart';
import 'package:nanei/features/avis/domain/entities/avis_entity.dart';
import 'package:nanei/features/avis/domain/usecases/donner_avis.dart';
import 'package:nanei/features/avis/domain/usecases/get_mes_avis.dart';
import 'package:nanei/features/avis/presentation/cubit/avis_cubit.dart';
import 'package:nanei/features/avis/presentation/cubit/avis_state.dart';

class MockDonnerAvis extends Mock implements DonnerAvis {}
class MockGetMesAvis extends Mock implements GetMesAvis {}

void main() {
  // Les blocs journalisent via AppLogger, qui doit être initialisé.
  setUpAll(AppLogger.init);

  late AvisCubit cubit;
  late MockDonnerAvis mockDonner;
  late MockGetMesAvis mockGet;

  setUp(() {
    mockDonner = MockDonnerAvis();
    mockGet = MockGetMesAvis();
    cubit = AvisCubit(donnerAvis: mockDonner, getMesAvis: mockGet);
  });

  tearDown(() => cubit.close());

  group('envoyerAvis', () {
    blocTest<AvisCubit, AvisState>(
      'émet [AvisEnvoi, AvisEnvoye] si l\'avis est envoyé avec succès',
      build: () {
        when(() => mockDonner(colisId: any(named: 'colisId'), note: any(named: 'note'), commentaire: any(named: 'commentaire')))
            .thenAnswer((_) async => const Right(null));
        return cubit;
      },
      act: (c) => c.envoyerAvis(colisId: 'colis123', note: 5),
      expect: () => [isA<AvisEnvoi>(), isA<AvisEnvoye>()],
    );

    blocTest<AvisCubit, AvisState>(
      'émet [AvisEnvoi, AvisError] si l\'envoi échoue',
      build: () {
        when(() => mockDonner(colisId: any(named: 'colisId'), note: any(named: 'note'), commentaire: any(named: 'commentaire')))
            .thenAnswer((_) async => Left(ServerFailure(errorMessage: 'Erreur réseau')));
        return cubit;
      },
      act: (c) => c.envoyerAvis(colisId: 'colis123', note: 3),
      expect: () => [isA<AvisEnvoi>(), isA<AvisError>()],
    );
  });
  group('chargerMesAvis (paginé)', () {
    blocTest<AvisCubit, AvisState>(
      'demande la page et expose la pagination',
      build: () {
        when(() => mockGet(page: 2, limit: kTaillePage)).thenAnswer(
          (_) async => const Right(PageResultat<AvisEntity>(
            elements: [AvisEntity(id: 'a1', colisId: 'c1', note: 4)],
            pagination:
                InfoPagination(page: 2, limit: 20, total: 25, pages: 2),
          )),
        );
        return cubit;
      },
      act: (c) => c.chargerMesAvis(page: 2),
      expect: () => [
        isA<AvisChargement>(),
        isA<AvisCharges>()
            .having((s) => s.avis.length, 'avis', 1)
            .having((s) => s.pagination.page, 'page', 2)
            .having((s) => s.pagination.pages, 'pages', 2),
      ],
      verify: (c) => expect(c.pageCourante, 2),
    );

    blocTest<AvisCubit, AvisState>(
      'émet AvisError si le chargement échoue',
      build: () {
        when(() => mockGet(page: any(named: 'page'), limit: any(named: 'limit')))
            .thenAnswer((_) async => Left(ServerFailure(errorMessage: 'KO')));
        return cubit;
      },
      act: (c) => c.chargerMesAvis(),
      expect: () => [isA<AvisChargement>(), isA<AvisError>()],
    );
  });

  blocTest<AvisCubit, AvisState>(
    '409 (avis déjà donné) : AvisDejaDonne, traité comme un succès',
    build: () {
      when(() => mockDonner(
              colisId: any(named: 'colisId'),
              note: any(named: 'note'),
              commentaire: any(named: 'commentaire')))
          .thenAnswer((_) async =>
              Left(AvisDejaDonneFailure(errorMessage: 'déjà noté')));
      return cubit;
    },
    act: (c) async => expect(await c.envoyerAvis(colisId: 'c', note: 4), isTrue),
    expect: () => [isA<AvisEnvoi>(), isA<AvisDejaDonne>()],
  );
}
