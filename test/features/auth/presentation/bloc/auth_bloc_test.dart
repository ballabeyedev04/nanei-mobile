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
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:nanei/core/constants/storage_keys.dart';
import 'package:nanei/core/services/token_service.dart';
import '../../../../helpers/dio_espion.dart';
import '../../../../helpers/environnement.dart';

class MockLoginUser extends Mock implements LoginUser {}
class MockRegisterUser extends Mock implements RegisterUser {}

/// Le bloc d'authentification (connexion, inscription, déconnexion).
///
/// ## Ce que ce fichier rend impossible
///
///  - un échec affiché sur le mauvais écran : `AuthFailure.action` dit QUI
///    a échoué (login et register partagent la même instance du bloc) ;
///  - une déconnexion qui laisse le refresh token valide côté serveur
///    (`POST /auth/logout { refreshToken }` le révoque) ou des jetons sur le
///    téléphone ;
///  - une déconnexion BLOQUÉE par une coupure réseau : on se déconnecte
///    localement quoi qu'il arrive.
void main() {
  // Les blocs journalisent via AppLogger, qui doit être initialisé.
  setUpAll(initialiserEnvironnementDeTest);

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

  group('RegisterRequested', () {
    blocTest<AuthBloc, AuthState>(
      'succès et échec portent l’action « register »',
      build: () {
        when(() => mockRegister(
              nom: any(named: 'nom'),
              prenom: any(named: 'prenom'),
              email: 'ok@nanei.com',
              mot_de_passe: any(named: 'mot_de_passe'),
              adresse: any(named: 'adresse'),
              telephone: any(named: 'telephone'),
            )).thenAnswer((_) async => const Right(tUser));
        when(() => mockRegister(
              nom: any(named: 'nom'),
              prenom: any(named: 'prenom'),
              email: 'pris@nanei.com',
              mot_de_passe: any(named: 'mot_de_passe'),
              adresse: any(named: 'adresse'),
              telephone: any(named: 'telephone'),
            )).thenAnswer((_) async =>
            Left(ServerFailure(errorMessage: 'Cet email est déjà utilisé')));
        return bloc;
      },
      act: (b) => b
        ..add(const RegisterRequested(
            nom: 'N', prenom: 'P', email: 'ok@nanei.com',
            mot_de_passe: 'Secret123', adresse: '', telephone: ''))
        ..add(const RegisterRequested(
            nom: 'N', prenom: 'P', email: 'pris@nanei.com',
            mot_de_passe: 'Secret123', adresse: '', telephone: '')),
      expect: () => [
        isA<AuthLoading>(),
        isA<AuthSuccess>().having((s) => s.action, 'action', AuthAction.register),
        isA<AuthLoading>(),
        isA<AuthFailure>()
            .having((s) => s.action, 'action', AuthAction.register)
            .having((s) => s.message, 'message', 'Cet email est déjà utilisé'),
      ],
    );
  });

  group('LogoutRequested', () {
    late DioEspion espion;
    late FlutterSecureStorage stockage;

    setUp(() async {
      await viderSl();
      FlutterSecureStorage.setMockInitialValues({
        StorageKeys.jwtToken: 'jwt',
        StorageKeys.refreshToken: 'rt-1',
        StorageKeys.userId: 'u-1',
      });
      stockage = const FlutterSecureStorage();
      espion = DioEspion();
      remplacerDansSl<FlutterSecureStorage>(stockage);
      remplacerDansSl<TokenService>(TokenService(secureStorage: stockage));
      remplacerDansSl<Dio>(dioDeTest(espion));
    });

    tearDown(viderSl);

    blocTest<AuthBloc, AuthState>(
      'révoque le refresh token côté serveur puis efface tout localement',
      build: () {
        espion.repond({'message': 'Déconnexion réussie'});
        return bloc;
      },
      act: (b) => b.add(LogoutRequested()),
      // Vraies E/S (Dio + stockage) : laisser le gestionnaire finir.
      wait: const Duration(milliseconds: 300),
      expect: () => [isA<AuthLoading>(), isA<AuthInitial>()],
      verify: (_) async {
        expect(espion.appel, 'POST /auth/logout');
        expect(corpsEnvoye(espion.requete), {'refreshToken': 'rt-1'});
        expect(await stockage.read(key: StorageKeys.jwtToken), isNull);
        expect(await stockage.read(key: StorageKeys.refreshToken), isNull);
        expect(await stockage.read(key: StorageKeys.userId), isNull);
      },
    );

    blocTest<AuthBloc, AuthState>(
      'réseau coupé : déconnexion locale malgré tout',
      build: () {
        espion.coupeReseau();
        return bloc;
      },
      act: (b) => b.add(LogoutRequested()),
      // Vraies E/S (Dio + stockage) : laisser le gestionnaire finir.
      wait: const Duration(milliseconds: 300),
      expect: () => [isA<AuthLoading>(), isA<AuthInitial>()],
      verify: (_) async =>
          expect(await stockage.read(key: StorageKeys.jwtToken), isNull),
    );
  });
}
