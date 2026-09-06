import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../../../core/errors/failure.dart';
import '../../../../core/services/token_service.dart';
import '../../../../injection_container.dart';
import '../../domain/entities/user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_remote_datasource.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource remoteDataSource;

  AuthRepositoryImpl({required this.remoteDataSource});

  @override
  Future<Either<Failure, User>> login(
      String identifiant,
      String motDePasse,
      ) async {
    try {
      final authResponse =
      await remoteDataSource.login(identifiant, motDePasse);

      await sl<TokenService>().setToken(authResponse.token);
      // Persiste le refresh token pour le renouvellement automatique du JWT
      // (voir l'intercepteur Dio + TokenService.tryRefresh).
      await sl<TokenService>().setRefreshToken(authResponse.refreshToken);

      await sl<FlutterSecureStorage>().write(
        key: 'user_id',
        value: authResponse.user.id.toString(),
      );

      return Right(authResponse.user);
    } on DioException catch (e) {
      return Left(ServerFailure(errorMessage: _friendlyError(e)));
    } catch (e) {
      return Left(ServerFailure(errorMessage: e.toString()));
    }
  }

  @override
  Future<Either<Failure, User>> register({
    required String nom,
    required String prenom,
    required String email,
    required String mot_de_passe,
    required String adresse,
    required String telephone
  }) async {
    try {
      final authResponse = await remoteDataSource.register(
        nom: nom,
        prenom: prenom,
        email: email,
        mot_de_passe: mot_de_passe,
        adresse: adresse,
        telephone: telephone
      );

      // `POST /auth/register` ne renvoie PAS de token (par conception : le
      // parcours mobile redirige vers l'écran de connexion après inscription,
      // cf. register_page.dart). On ne stocke donc aucun token ici — si le
      // backend en fournit un un jour, on l'enregistre.
      if (authResponse.token.isNotEmpty) {
        await sl<TokenService>().setToken(authResponse.token);
        if (authResponse.refreshToken.isNotEmpty) {
          await sl<TokenService>().setRefreshToken(authResponse.refreshToken);
        }
      }

      return Right(authResponse.user);
    } on DioException catch (e) {
      return Left(ServerFailure(errorMessage: _friendlyError(e)));
    } catch (e) {
      return Left(ServerFailure(errorMessage: e.toString()));
    }
  }

  String _friendlyError(DioException e) {
    final data = e.response?.data;
    if (data is Map && data['message'] != null) {
      final msg = data['message'].toString();
      // Erreurs de validation Joi : { message: 'Données invalides',
      // details: ['"email" doit être un email valide', ...] }. On expose le
      // détail plutôt que le message générique.
      final details = data['details'];
      if (details is List && details.isNotEmpty) {
        return details.map((d) => d.toString()).join('\n');
      }
      return msg;
    }
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
        return 'Connexion trop lente. Vérifiez votre réseau.';
      case DioExceptionType.receiveTimeout:
        return 'Le serveur met du temps à répondre. Veuillez réessayer dans quelques secondes.';
      case DioExceptionType.connectionError:
        return 'Impossible de joindre le serveur. Vérifiez votre connexion internet.';
      case DioExceptionType.badResponse:
        return 'Erreur serveur (${e.response?.statusCode}). Réessayez plus tard.';
      default:
        return 'Une erreur est survenue. Réessayez.';
    }
  }
}