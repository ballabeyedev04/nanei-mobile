import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:image_picker/image_picker.dart';

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

      await sl<FlutterSecureStorage>().write(
        key: 'user_id',
        value: authResponse.user.id.toString(),
      );

      return Right(authResponse.user);
    } on DioException catch (e) {
      String message = 'Une erreur est survenue';

      if (e.response?.data is Map &&
          e.response?.data['message'] != null) {
        message = e.response!.data['message'];
      } else if (e.message != null) {
        message = e.message!;
      }

      return Left(ServerFailure(errorMessage: message));
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

      await sl<TokenService>().setToken(authResponse.token);

      return Right(authResponse.user);
    } on DioException catch (e) {
      String message = 'Une erreur est survenue';

      if (e.response?.data is Map &&
          e.response?.data['message'] != null) {
        message = e.response!.data['message'];
      } else if (e.message != null) {
        message = e.message!;
      }

      return Left(ServerFailure(errorMessage: message));
    } catch (e) {
      return Left(ServerFailure(errorMessage: e.toString()));
    }
  }
}