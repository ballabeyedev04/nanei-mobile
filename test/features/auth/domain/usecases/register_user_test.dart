import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:nanei/core/errors/failure.dart';
import 'package:nanei/features/auth/domain/entities/user.dart';
import 'package:nanei/features/auth/domain/repositories/auth_repository.dart';
import 'package:nanei/features/auth/domain/usecases/register_user.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  late RegisterUser useCase;
  late MockAuthRepository mockRepo;

  setUp(() {
    mockRepo = MockAuthRepository();
    useCase = RegisterUser(mockRepo);
  });

  const tUser = User(
    id: '2',
    email: 'nouveau@nanei.com',
    nom: 'BEYE',
    prenom: 'Balla',
    mot_de_passe: '',
    adresse: 'Dakar',
    telephone: '+221701234567',
  );

  test('doit retourner User si l\'inscription réussit', () async {
    when(() => mockRepo.register(
          nom: 'BEYE',
          prenom: 'Balla',
          email: 'nouveau@nanei.com',
          mot_de_passe: 'Motdepasse1!',
          adresse: 'Dakar',
          telephone: '+221701234567',
        )).thenAnswer((_) async => const Right(tUser));

    final result = await useCase(
      nom: 'BEYE',
      prenom: 'Balla',
      email: 'nouveau@nanei.com',
      mot_de_passe: 'Motdepasse1!',
      adresse: 'Dakar',
      telephone: '+221701234567',
    );

    expect(result, const Right(tUser));
  });

  test('doit retourner ServerFailure si l\'email est déjà utilisé', () async {
    final tFailure = ServerFailure(errorMessage: 'Cet email est déjà utilisé.');
    when(() => mockRepo.register(
          nom: any(named: 'nom'),
          prenom: any(named: 'prenom'),
          email: any(named: 'email'),
          mot_de_passe: any(named: 'mot_de_passe'),
          adresse: any(named: 'adresse'),
          telephone: any(named: 'telephone'),
        )).thenAnswer((_) async => Left(tFailure));

    final result = await useCase(
      nom: 'BEYE',
      prenom: 'Balla',
      email: 'nouveau@nanei.com',
      mot_de_passe: 'Motdepasse1!',
      adresse: 'Dakar',
      telephone: '+221701234567',
    );

    expect(result, isA<Left<Failure, User>>());
  });
}
