import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'core/config/env.dart';
import 'core/services/token_service.dart';

// Auth
import 'features/auth/data/datasources/auth_remote_datasource.dart';
import 'features/auth/data/repositories/auth_repository_impl.dart';
import 'features/auth/domain/repositories/auth_repository.dart';
import 'features/auth/domain/usecases/login_user.dart';
import 'features/auth/domain/usecases/register_user.dart';
import 'features/auth/presentation/bloc/auth_bloc.dart';

// Home / Colis
import 'features/home/data/datasources/colis_remote_datasource.dart';
import 'features/home/data/repositories/colis_repository_impl.dart';
import 'features/home/domain/repositories/colis_repository.dart';
import 'features/home/domain/usecases/envoyer_colis.dart';
import 'features/home/domain/usecases/get_colis_envoyes.dart';
import 'features/home/domain/usecases/get_colis_recus.dart';
import 'features/home/domain/usecases/get_statistiques_colis.dart';
import 'features/home/domain/usecases/get_notifications.dart';
import 'features/home/domain/usecases/marquer_notification_lue.dart';
import 'features/home/domain/usecases/rechercher_client.dart';
import 'features/home/presentation/bloc/colis_bloc.dart';

final sl = GetIt.instance;

Future<void> init() async {
  // ── Dotenv ─────────────────────────────────────────────────────────────────
  await dotenv.load(fileName: '.env');

  // ── Services externes ──────────────────────────────────────────────────────
  final prefs = await SharedPreferences.getInstance();
  sl.registerLazySingleton(() => prefs);

  sl.registerLazySingleton(() => const FlutterSecureStorage(
        aOptions: AndroidOptions(encryptedSharedPreferences: true),
        iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
      ));

  // ── Core ───────────────────────────────────────────────────────────────────
  sl.registerLazySingleton(() => TokenService(secureStorage: sl()));

  // ── Dio ────────────────────────────────────────────────────────────────────
  sl.registerLazySingleton(() {
    final dio = Dio(
      BaseOptions(
        baseUrl: Env.baseUrl,
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 30),
        sendTimeout: const Duration(seconds: 30),
        contentType: 'application/json',
        headers: {'Accept': 'application/json'},
      ),
    );

    dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        if (kDebugMode) {
          debugPrint('[REQ] ${options.method} ${options.path}');
        }
        final path = options.path.split('?')[0].trim();
        final isAuth = path.endsWith(Env.authLogin) ||
            path.endsWith(Env.authRegister);
        if (!isAuth) {
          final token = await sl<TokenService>().getToken();
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }
        }
        return handler.next(options);
      },
      onResponse: (response, handler) {
        if (kDebugMode) {
          debugPrint('[RES] ${response.statusCode} ${response.requestOptions.path}');
        }
        return handler.next(response);
      },
      onError: (DioException e, handler) {
        if (kDebugMode) {
          debugPrint('[ERR] ${e.type} ${e.requestOptions.path} — ${e.response?.statusCode}');
        }
        return handler.next(e);
      },
    ));

    return dio;
  });

  // ── Feature : Auth ─────────────────────────────────────────────────────────
  sl.registerLazySingleton<AuthRemoteDataSource>(
    () => AuthRemoteDataSourceImpl(dio: sl()),
  );
  sl.registerLazySingleton<AuthRepository>(
    () => AuthRepositoryImpl(remoteDataSource: sl()),
  );
  sl.registerLazySingleton(() => LoginUser(sl()));
  sl.registerLazySingleton(() => RegisterUser(sl()));
  sl.registerFactory(
    () => AuthBloc(loginUser: sl(), registerUser: sl()),
  );

  // ── Feature : Home / Colis ─────────────────────────────────────────────────
  sl.registerLazySingleton<ColisRemoteDataSource>(
    () => ColisRemoteDataSourceImpl(dio: sl()),
  );
  sl.registerLazySingleton<ColisRepository>(
    () => ColisRepositoryImpl(remoteDataSource: sl()),
  );
  sl.registerLazySingleton(() => GetColisEnvoyes(sl()));
  sl.registerLazySingleton(() => GetColisRecus(sl()));
  sl.registerLazySingleton(() => GetStatistiquesColis(sl()));
  sl.registerLazySingleton(() => EnvoyerColis(sl()));
  sl.registerLazySingleton(() => RechercherClient(sl()));
  sl.registerLazySingleton(() => GetNotifications(sl()));
  sl.registerLazySingleton(() => MarquerNotificationLue(sl()));
  sl.registerFactory(() => ColisBloc(
        getColisEnvoyes: sl(),
        getColisRecus: sl(),
        getStatistiques: sl(),
        envoyerColis: sl(),
        rechercherClient: sl(),
        getNotifications: sl(),
        marquerNotificationLue: sl(),
      ));
}
