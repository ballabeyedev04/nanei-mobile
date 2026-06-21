import 'package:dio/dio.dart';
import '../models/client_model.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:nanei/core/utils/app_logger.dart';

abstract class AuthRemoteDataSource {
  Future<AuthResponseModel> login(String identifiant, String motDePasse);
  Future<AuthResponseModel> register({
    required String nom,
    required String prenom,
    required String email,
    required String mot_de_passe,
    required String adresse,
    required String telephone,
  });
}

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final Dio dio;
  final String _loginPath;
  final String _registerPath;

  AuthRemoteDataSourceImpl({required this.dio})
      : _loginPath = _normalisePath(
    dotenv.get(
      'AUTH_LOGIN_PATH',
      fallback: '/auth/login',
    ),
  ),
        _registerPath = _normalisePath(
          dotenv.get(
            'AUTH_REGISTER_PATH',
            fallback: '/auth/register',
          ),
        );

  static String _normalisePath(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) {
      throw StateError(
        'Les chemins AUTH_LOGIN_PATH et AUTH_REGISTER_PATH ne peuvent pas être vides.',
      );
    }
    return trimmed.startsWith('/') ? trimmed : '/$trimmed';
  }

  @override
  Future<AuthResponseModel> login(
      String identifiant,
      String motDePasse,
      ) async {
    AppLogger.debug('Tentative de connexion', {'identifiant': maskEmail(identifiant)});

    try {
      final response = await dio.post(
        _loginPath,
        data: {
          'identifiant': identifiant,
          'mot_de_passe': motDePasse,
        },
      );

      AppLogger.debug('Réponse API login', {'status': response.statusCode});

      if (response.statusCode == 200) {
        return AuthResponseModel.fromJson(response.data);
      }

      throw DioException(
        requestOptions: response.requestOptions,
        response: response,
        type: DioExceptionType.badResponse,
        error: response.data['message'] ?? 'Erreur de connexion',
      );
    } on DioException catch (e, st) {
      AppLogger.error('Erreur Dio login: $_loginPath', e, st);
      rethrow;
    }
  }

  @override
  Future<AuthResponseModel> register({
    required String nom,
    required String prenom,
    required String email,
    required String mot_de_passe,
    required String adresse,
    required String telephone,
  }) async {
    try {
      AppLogger.debug('Tentative d\'inscription', {'endpoint': _registerPath});

      // Envoyer directement un JSON
      final data = {
        'nom': nom,
        'prenom': prenom,
        'email': email,
        'mot_de_passe': mot_de_passe,
        'adresse': adresse,
        'telephone': telephone,
      };

      final response = await dio.post(
        _registerPath,
        data: data,
        options: Options(
          contentType: 'application/json', // <- JSON
        ),
      );

      AppLogger.debug('Réponse inscription', {'status': response.statusCode});

      return AuthResponseModel.fromJson(response.data);

    } on DioException catch (e, st) {
      AppLogger.error('Erreur Dio inscription: $_registerPath', e, st);

      if (e.response?.statusCode == 400) {
        final errorData = e.response?.data;
        final errorMessage = errorData is Map && errorData.containsKey('message')
            ? errorData['message']
            : 'Données invalides';
        throw DioException(
          requestOptions: e.requestOptions,
          response: e.response,
          type: DioExceptionType.badResponse,
          error: errorMessage,
        );
      }

      rethrow;
    } catch (e, st) {
      AppLogger.error('Erreur inconnue inscription', e, st);
      rethrow;
    }
  }
}
