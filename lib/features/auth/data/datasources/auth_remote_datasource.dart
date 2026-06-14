import 'package:dio/dio.dart';
import 'package:francomalishipp/core/config/env.dart';
import '../models/user_model.dart';

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
  const AuthRemoteDataSourceImpl({required this.dio});

  @override
  Future<AuthResponseModel> login(
      String identifiant, String motDePasse) async {
    final response = await dio.post(
      Env.authLogin,
      data: {'identifiant': identifiant, 'mot_de_passe': motDePasse},
    );
    if (response.statusCode == 200) {
      return AuthResponseModel.fromJson(response.data);
    }
    throw DioException(
      requestOptions: response.requestOptions,
      response: response,
      type: DioExceptionType.badResponse,
      error: response.data['message'] ?? 'Erreur de connexion',
    );
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
    final response = await dio.post(
      Env.authRegister,
      data: {
        'nom': nom,
        'prenom': prenom,
        'email': email,
        'mot_de_passe': mot_de_passe,
        'adresse': adresse,
        'telephone': telephone,
      },
    );
    return AuthResponseModel.fromJson(response.data);
  }
}
