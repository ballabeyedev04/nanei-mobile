import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:nanei/core/errors/failure.dart';
import 'package:nanei/features/auth/domain/entities/user.dart';
import 'package:nanei/features/auth/domain/repositories/auth_repository.dart';
import 'package:nanei/features/auth/domain/usecases/login_user.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  late LoginUser useCase;
  late MockAuthRepository mockRepo;

  setUp(() {
    mockRepo = MockAuthRepository();
    useCase = LoginUser(mockRepo);
  });

  const tIdentifiant = 'test@nanei.com';
  const tMotDePasse = 'Motdepasse1!';
  const tUser = User(
    id: '1',
    email: tIdentifiant,
    nom: 'Test',
    prenom: 'User',
    mot_de_passe: '',
    adresse: '',
    telephone: '',
  );

  test('doit retourner User si les identifiants sont corrects', () async {
    when(() => mockRepo.login(tIdentifiant, tMotDePasse))
        .thenAnswer((_) async => const Right(tUser));

    final result = await useCase(tIdentifiant, tMotDePasse);

    expect(result, const Right(tUser));
    verify(() => mockRepo.login(tIdentifiant, tMotDePasse)).called(1);
  });

  test('doit retourner ServerFailure si le serveur répond avec une erreur', () async {
    final tFailure = ServerFailure(errorMessage: 'Identifiants invalides');
    when(() => mockRepo.login(tIdentifiant, tMotDePasse))
        .thenAnswer((_) async => Left(tFailure));

    final result = await useCase(tIdentifiant, tMotDePasse);

    expect(result, isA<Left<Failure, User>>());
  });
}
