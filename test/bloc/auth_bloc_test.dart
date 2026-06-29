import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:nanei/core/errors/failure.dart';
import 'package:nanei/features/auth/domain/entities/user.dart';
import 'package:nanei/features/auth/domain/usecases/login_user.dart';
import 'package:nanei/features/auth/domain/usecases/register_user.dart';
import 'package:nanei/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:nanei/features/auth/presentation/bloc/auth_event.dart';
import 'package:nanei/features/auth/presentation/bloc/auth_state.dart';

class MockLoginUser extends Mock implements LoginUser {}
class MockRegisterUser extends Mock implements RegisterUser {}

void main() {
  late AuthBloc bloc;
  late MockLoginUser mockLogin;
  late MockRegisterUser mockRegister;

  setUp(() {
    mockLogin = MockLoginUser();
    mockRegister = MockRegisterUser();
    bloc = AuthBloc(loginUser: mockLogin, registerUser: mockRegister);
  });

  tearDown(() => bloc.close());

  const tUser = User(
    id: '1',
    email: 'test@nanei.com',
    nom: 'Test',
    prenom: 'User',
    mot_de_passe: '',
    adresse: '',
    telephone: '',
  );

  group('LoginRequested', () {
    blocTest<AuthBloc, AuthState>(
      'émet [AuthLoading, AuthSuccess] si le login réussit',
      build: () {
        when(() => mockLogin(any(), any()))
            .thenAnswer((_) async => const Right(tUser));
        return bloc;
      },
      act: (b) => b.add(const LoginRequested(
        identifiant: 'test@nanei.com',
        mot_de_passe: 'Motdepasse1!',
      )),
      expect: () => [isA<AuthLoading>(), isA<AuthSuccess>()],
    );

    blocTest<AuthBloc, AuthState>(
      'émet [AuthLoading, AuthFailure] si les identifiants sont invalides',
      build: () {
        when(() => mockLogin(any(), any()))
            .thenAnswer((_) async => Left(
                ServerFailure(errorMessage: 'Identifiants invalides')));
        return bloc;
      },
      act: (b) => b.add(const LoginRequested(
        identifiant: 'bad@test.com',
        mot_de_passe: 'wrong',
      )),
      expect: () => [isA<AuthLoading>(), isA<AuthFailure>()],
    );
  });
}
