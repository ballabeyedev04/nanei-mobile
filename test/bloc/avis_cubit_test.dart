import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:nanei/core/errors/failure.dart';
import 'package:nanei/features/avis/domain/usecases/donner_avis.dart';
import 'package:nanei/features/avis/domain/usecases/get_mes_avis.dart';
import 'package:nanei/features/avis/presentation/cubit/avis_cubit.dart';
import 'package:nanei/features/avis/presentation/cubit/avis_state.dart';

class MockDonnerAvis extends Mock implements DonnerAvis {}
class MockGetMesAvis extends Mock implements GetMesAvis {}

void main() {
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
}
