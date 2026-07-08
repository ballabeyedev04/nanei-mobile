import 'package:dio/dio.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../../../core/config/env.dart';
import '../../../../core/constants/storage_keys.dart';
import '../../../../core/services/token_service.dart';
import '../../../../core/utils/app_logger.dart';
import '../../../../injection_container.dart';
import '../../domain/usecases/login_user.dart';
import '../../domain/usecases/register_user.dart';
import 'auth_event.dart';
import 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final LoginUser loginUser;
  final RegisterUser registerUser;

  AuthBloc({
    required this.loginUser,
    required this.registerUser,
  }) : super(AuthInitial()) {
    on<LoginRequested>(_onLoginRequested);
    on<RegisterRequested>(_onRegisterRequested);
    on<LogoutRequested>(_onLogoutRequested);
    on<ResetAuthState>((event, emit) {
      emit(AuthInitial());
    });
  }

  Future<void> _onLoginRequested(
      LoginRequested event,
      Emitter<AuthState> emit,
      ) async {
    emit(AuthLoading());

    final result = await loginUser(
      event.identifiant,
      event.mot_de_passe,
    );

    result.fold(
          (failure) {
            AppLogger.warning('État erreur: AuthBloc', failure.errorMessage);
            emit(AuthFailure(message: failure.errorMessage, action: AuthAction.login));
          },
          (user) {
            AppLogger.authEvent('Connexion réussie', userId: user.id, email: user.email);
            emit(AuthSuccess(user: user, action: AuthAction.login));
          },
    );
  }

  Future<void> _onRegisterRequested(
      RegisterRequested event,
      Emitter<AuthState> emit,
      ) async {
    emit(AuthLoading());

    final result = await registerUser.call(
      nom: event.nom,
      prenom: event.prenom,
      email: event.email,
      mot_de_passe: event.mot_de_passe,
      adresse: event.adresse,
      telephone: event.telephone
    );

    result.fold(
          (failure) {
            AppLogger.warning('État erreur: AuthBloc inscription', failure.errorMessage);
            emit(AuthFailure(message: failure.errorMessage, action: AuthAction.register));
          },
          (user) {
            AppLogger.authEvent('Inscription réussie', userId: user.id, email: user.email);
            emit(AuthSuccess(user: user, action: AuthAction.register));
          },
    );
  }

  Future<void> _onLogoutRequested(
      LogoutRequested event,
      Emitter<AuthState> emit,
      ) async {
    emit(AuthLoading());

    try {
      final tokenService = sl<TokenService>();
      final storage = sl<FlutterSecureStorage>();

      // Appel backend best-effort (token révocation)
      final refreshToken = await storage.read(key: StorageKeys.refreshToken);
      if (refreshToken != null) {
        try {
          await sl<Dio>().post(
            Env.authLogout,
            data: {'refreshToken': refreshToken},
          );
        } catch (_) {
          // Ignore — on déconnecte localement quoi qu'il arrive
        }
      }

      await tokenService.clearToken();
      await storage.delete(key: StorageKeys.userId);
      await storage.delete(key: StorageKeys.refreshToken);

      AppLogger.authEvent('Déconnexion réussie');
      emit(AuthInitial());
    } catch (e, st) {
      AppLogger.error('Erreur dans AuthBloc._onLogoutRequested', e, st);
      emit(AuthFailure(message: 'Erreur lors de la déconnexion : $e', action: AuthAction.logout));
    }
  }
}
