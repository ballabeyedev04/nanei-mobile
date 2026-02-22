import 'package:francomalishipp/features/auth/data/datasources/auth_remote_datasource.dart';
import 'package:francomalishipp/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:francomalishipp/features/auth/domain/repositories/auth_repository.dart';
import 'package:francomalishipp/features/auth/domain/usecases/login_user.dart';
import 'package:francomalishipp/features/auth/domain/usecases/register_user.dart';
import 'package:francomalishipp/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:dio/dio.dart';
import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'core/services/token_service.dart';

// Service Locator
final sl = GetIt.instance;

Future<void> init() async {
  //================================================
  // INITIALISATION DES SERVICES EXTERNES
  //================================================

  // Initialisation de dotenv
  await dotenv.load(fileName: '.env');

  // SharedPreferences
  final sharedPreferences = await SharedPreferences.getInstance();
  sl.registerLazySingleton(() => sharedPreferences);

  // SecureStorage
  sl.registerLazySingleton(() => const FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
    ),
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock,
    ),
  ));

  //================================================
  // CORE SERVICES
  //================================================

  // Services
  sl.registerLazySingleton(() => TokenService(secureStorage: sl()));

  //================================================
  // EXTERNAL - DIO HTTP CLIENT
  //================================================

  sl.registerLazySingleton(() {
    final baseUrl = dotenv.maybeGet('API_BASE_URL')?.trim();
    if (baseUrl == null || baseUrl.isEmpty) {
      throw StateError(
        'API_BASE_URL est manquant dans votre fichier .env. '
            'Ajoutez-le avant de lancer l\'application.',
      );
    }

    // Configuration améliorée de Dio
    final dio = Dio(
      BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 60),
        sendTimeout: const Duration(seconds: 60),
        contentType: 'application/json',
        headers: {
          'Accept': 'application/json',
        },
      ),
    );

    // Intercepteurs pour logging et gestion du token
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          // Logging des requêtes
          print('🌐 [REQUEST] ${options.method} ${options.path}');
          if (options.data != null) {
            if (options.data is FormData) {
              final formData = options.data as FormData;
              print('📦 FormData fields:');
              formData.fields.forEach((field) {
                print('  ${field.key}: ${field.value}');
              });
              formData.files.forEach((file) {
                print('  ${file.key}: ${file.value.filename}');
              });
            } else {
              print('📦 Body: ${options.data}');
            }
          }

          // Ajout du token JWT sauf pour login/register
          final path = options.path.split('?')[0].trim();
          final isAuthEndpoint = path.endsWith('/auth/login') ||
              path.endsWith('/auth/register');

          if (!isAuthEndpoint) {
            try {
              final token = await sl<TokenService>().getToken();

              if (token != null && token.isNotEmpty) {
                options.headers['Authorization'] = 'Bearer $token';
                print('🔑 Token ajouté à la requête');
              }
            } catch (e) {
              print('⚠️ Erreur lors de la récupération du token: $e');
            }
          }

          return handler.next(options);
        },
        onResponse: (response, handler) {
          print('✅ [RESPONSE] ${response.statusCode} ${response.requestOptions.path}');
          if (response.data != null && response.data is Map) {
            print('📥 Data: ${response.data}');
          }
          return handler.next(response);
        },
        onError: (DioException e, handler) {
          print('❌ [ERROR] ${e.type} ${e.requestOptions.path}');
          print('📝 Message: ${e.message}');
          if (e.response != null) {
            print('📊 Status: ${e.response!.statusCode}');
            print('📋 Data: ${e.response!.data}');
          }
          return handler.next(e);
        },
      ),
    );

    return dio;
  });

  //================================================
  // FEATURES - AUTHENTICATION
  //================================================

  // Data Sources
  sl.registerLazySingleton<AuthRemoteDataSource>(
        () => AuthRemoteDataSourceImpl(dio: sl()),
  );

  // Repository
  sl.registerLazySingleton<AuthRepository>(
        () => AuthRepositoryImpl(remoteDataSource: sl()),
  );

  // Use Cases
  sl.registerLazySingleton(() => LoginUser(sl()));
  sl.registerLazySingleton(() => RegisterUser(sl()));

  // BLoC
  sl.registerFactory(() => AuthBloc(
    loginUser: sl(),
    registerUser: sl(),
  ));

  //================================================
  // VÉRIFICATION DES VARIABLES D'ENVIRONNEMENT
  //================================================

  _validateEnvVariables();
}

void _validateEnvVariables() {
  final requiredVariables = [
    'API_BASE_URL',
    'AUTH_LOGIN_PATH',
    'AUTH_REGISTER_PATH',
  ];

  final missingVariables = <String>[];

  for (final variable in requiredVariables) {
    final value = dotenv.maybeGet(variable)?.trim();
    if (value == null || value.isEmpty) {
      missingVariables.add(variable);
    }
  }

  if (missingVariables.isNotEmpty) {
    throw StateError(
      'Les variables d\'environnement suivantes sont manquantes dans votre fichier .env:\n'
          '${missingVariables.join('\n')}\n\n'
          'Assurez-vous qu\'elles sont définies avant de lancer l\'application.',
    );
  }

  print('✅ Toutes les variables d\'environnement sont configurées');
  print('🌐 API Base URL: ${dotenv.get('API_BASE_URL')}');
  print('🔑 Auth Login Path: ${dotenv.get('AUTH_LOGIN_PATH')}');
  print('📝 Auth Register Path: ${dotenv.get('AUTH_REGISTER_PATH')}');
}